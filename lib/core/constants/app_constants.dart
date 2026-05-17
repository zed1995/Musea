class AppConstants {
  AppConstants._();

  static const String appName = 'Musea';
  static const String appVersion = '1.0.0';
  
  static const int cacheMaxAge = 7 * 24 * 60 * 60; // 7 days in seconds
  static const int maxSearchHistory = 10;
  
  static const List<String> popularSearches = [
    'Nature',
    'Wallpaper',
    'Minimal',
    'Travel',
    'Architecture',
    'Food',
    'People',
    'Animals',
  ];
  
  static const Map<String, String> colorFilters = {
    'All': '',
    'Black and White': 'black_and_white',
    'Red': 'red',
    'Orange': 'orange',
    'Yellow': 'yellow',
    'Green': 'green',
    'Teal': 'teal',
    'Blue': 'blue',
    'Purple': 'purple',
    'Magenta': 'magenta',
    'White': 'white',
    'Black': 'black',
  };
}
