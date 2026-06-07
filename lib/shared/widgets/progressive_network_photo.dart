import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

typedef ProgressiveImageProviderBuilder = ImageProvider<Object> Function(
  String url,
);

class ProgressiveNetworkPhoto extends StatefulWidget {
  const ProgressiveNetworkPhoto({
    super.key,
    required this.thumbUrl,
    required this.imageUrl,
    this.aspectRatio,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.backgroundColor,
    this.enableSaturationReveal = true,
    this.revealDuration = const Duration(milliseconds: 220),
    this.imageProviderBuilder,
  });

  final String thumbUrl;
  final String imageUrl;
  final double? aspectRatio;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final bool enableSaturationReveal;
  final Duration revealDuration;
  final ProgressiveImageProviderBuilder? imageProviderBuilder;

  @override
  State<ProgressiveNetworkPhoto> createState() =>
      _ProgressiveNetworkPhotoState();
}

class _ProgressiveNetworkPhotoState extends State<ProgressiveNetworkPhoto>
    with SingleTickerProviderStateMixin {
  static const double _initialSaturation = 0.12;

  ImageStream? _thumbStream;
  ImageStream? _imageStream;
  ImageStreamListener? _thumbListener;
  ImageStreamListener? _imageListener;

  late final AnimationController _controller;
  late Animation<double> _saturation;

  bool _thumbReady = false;
  bool _imageReady = false;
  bool _hideThumbLayer = false;
  bool _hasPlayedReveal = false;
  bool _streamsAttached = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.revealDuration,
    );
    _saturation = _buildSaturationAnimation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_streamsAttached) return;
    _attachStreams();
    _streamsAttached = true;
  }

  @override
  void didUpdateWidget(covariant ProgressiveNetworkPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.revealDuration != widget.revealDuration) {
      _controller.duration = widget.revealDuration;
      _saturation = _buildSaturationAnimation();
    }

    if (oldWidget.thumbUrl != widget.thumbUrl ||
        oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.imageProviderBuilder != widget.imageProviderBuilder) {
      _detachStreams();
      _controller.stop();
      _controller.value = 0;
      _thumbReady = false;
      _imageReady = false;
      _hideThumbLayer = false;
      _hasPlayedReveal = false;
      _streamsAttached = false;
      _attachStreams();
      _streamsAttached = true;
    }
  }

  @override
  void dispose() {
    _detachStreams();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = Stack(
      fit: StackFit.expand,
      children: [
        if (_thumbReady && !_hideThumbLayer)
          _buildLayer(
            key: const ValueKey('progressive-thumb-layer'),
            image: _providerFor(widget.thumbUrl),
            saturation: _initialSaturation,
          ),
        if (_imageReady)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => _buildLayer(
              key: const ValueKey('progressive-full-layer'),
              image: _providerFor(widget.imageUrl),
              saturation:
                  widget.enableSaturationReveal ? _saturation.value : 1,
              opacity: _imageOpacity,
            ),
          ),
      ],
    );

    if (widget.aspectRatio != null) {
      child = AspectRatio(aspectRatio: widget.aspectRatio!, child: child);
    }

    if (widget.borderRadius != null) {
      child = ClipRRect(borderRadius: widget.borderRadius!, child: child);
    }

    return ColoredBox(
      color: widget.backgroundColor ?? Colors.transparent,
      child: child,
    );
  }

  Animation<double> _buildSaturationAnimation() {
    return Tween<double>(
      begin: _initialSaturation,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  double get _imageOpacity {
    if (!widget.enableSaturationReveal) return 1;
    return 0.85 + (_controller.value * 0.15);
  }

  void _attachStreams() {
    if (widget.thumbUrl.isNotEmpty) {
      final thumbProvider = _providerFor(widget.thumbUrl);
      _thumbStream = thumbProvider.resolve(createLocalImageConfiguration(context));
      _thumbListener = ImageStreamListener(
        (imageInfo, synchronousCall) {
          if (_thumbReady || !mounted) return;
          setState(() => _thumbReady = true);
        },
      );
      _thumbStream!.addListener(_thumbListener!);
    }

    if (widget.imageUrl.isNotEmpty) {
      final imageProvider = _providerFor(widget.imageUrl);
      _imageStream = imageProvider.resolve(createLocalImageConfiguration(context));
      _imageListener = ImageStreamListener(
        (imageInfo, synchronousCall) {
          if (!mounted) return;

          final shouldReveal = !_hasPlayedReveal;
          if (!_imageReady) {
            setState(() => _imageReady = true);
          }

          if (shouldReveal) {
            _hasPlayedReveal = true;
            _startReveal();
          }
        },
      );
      _imageStream!.addListener(_imageListener!);
    }
  }

  void _detachStreams() {
    if (_thumbStream != null && _thumbListener != null) {
      _thumbStream!.removeListener(_thumbListener!);
    }
    if (_imageStream != null && _imageListener != null) {
      _imageStream!.removeListener(_imageListener!);
    }
    _thumbStream = null;
    _imageStream = null;
    _thumbListener = null;
    _imageListener = null;
  }

  Future<void> _startReveal() async {
    if (!widget.enableSaturationReveal) {
      if (mounted) {
        setState(() => _hideThumbLayer = true);
      }
      return;
    }

    await _controller.forward(from: 0);
    if (!mounted) return;
    setState(() => _hideThumbLayer = true);
  }

  ImageProvider<Object> _providerFor(String url) {
    return widget.imageProviderBuilder?.call(url) ??
        CachedNetworkImageProvider(url);
  }

  Widget _buildLayer({
    required Key key,
    required ImageProvider<Object> image,
    required double saturation,
    double opacity = 1,
  }) {
    final imageWidget = Image(
      key: key,
      image: image,
      fit: widget.fit,
      width: double.infinity,
      height: double.infinity,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) => const SizedBox.expand(),
    );

    return Opacity(
      opacity: opacity,
      child: ColorFiltered(
        colorFilter: ColorFilter.matrix(_saturationMatrix(saturation)),
        child: imageWidget,
      ),
    );
  }

  List<double> _saturationMatrix(double saturation) {
    final value = saturation.clamp(0.0, 1.0);
    final inverse = 1 - value;
    final r = 0.213 * inverse;
    final g = 0.715 * inverse;
    final b = 0.072 * inverse;

    return <double>[
      r + value,
      g,
      b,
      0,
      0,
      r,
      g + value,
      b,
      0,
      0,
      r,
      g,
      b + value,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];
  }
}
