# Musea MVP 实现路线图

> **版本**: v1.0
> **日期**: 2026-05-17
> **基于**: [功能设计](../musea-functional-design.md)
> **技术栈**: Flutter 3.x, Riverpod, GoRouter, Hive, Dio, CachedNetworkImage

---

## 总体策略

三阶段迭代，每个阶段交付可用的垂直功能切片。

| 阶段 | 交付价值 | 依赖 |
|------|---------|------|
| Phase 1 | 用户浏览图片 → 查看详情 → 下载 | 无需外部依赖 |
| Phase 2 | 浏览 Unsplash 官方收藏集 | Phase 1 的可复用组件 (PhotoCard) |
| Phase 3 | 搜索图片 + 个人设置 | Phase 1 的可复用组件 (PhotoCard) |

后续阶段（本 spec 范围外）：OAuth 登录 + 收藏集写操作 + 点赞同步 + 跨设备数据同步。

---

## Phase 1：核心体验闭环

### 目标

用户从发现页浏览图片，点击进入详情页查看完整信息，可以下载原图。

### 组件拆分

从现有的 `DiscoverPage` 提取为独立复用组件：

| 组件 | 位置 | 说明 |
|------|------|------|
| `PhotoCard` | `shared/widgets/photo_card.dart` | 全功能照片卡片：BlurHash 占位、自适应高度、底部渐变遮罩、点赞/下载按钮、头像+用户名（点击跳转） |
| `PhotoFeed` | `shared/widgets/photo_feed.dart` | 单列 Feed，内嵌 PhotoCard，支持无限滚动回调 |
| `TopicBar` | `shared/widgets/topic_bar.dart` | 横向滚动主题 Chip 列表，含"全部"选项 |

### 新增页面

#### 图片详情页 (`photo_detail/presentation/pages/photo_detail_page.dart`)

- 路由: `/photo/:id`
- Hero 共享元素过渡配合 `PageRouteBuilder`
- 内容：
  - 全屏图片展示 (`urls.regular` → `urls.full`)
  - 摄影师信息行 + 可点击跳转
  - 互动数据（点赞数、查看数、下载数）
  - EXIF 信息展示
  - 拍摄地点
  - 色调 / 标签（点击标签跳转探索页预填充）
  - 更多来自该摄影师（水平滚动）
  - 相似图片推荐（基于标签 `GET /search/photos`）
- 底部操作栏：点赞（本地状态）、下载（可操作）
- 下载流程：点击下载 → 尺寸选择 Sheet → `GET /photos/:id/download` → `dio.download()` 到本地
- 点击图片切换全屏模式

#### 摄影师页 (`photographer/presentation/pages/photographer_page.dart`)

- 路由: `/photographer/:username`
- 内容：
  - 头像 + 姓名 + Bio
  - 作品网格
- 数据源: `GET /users/:username` + `GET /users/:username/photos`

### 发现页修改

- 使用提取的 `PhotoCard`、`PhotoFeed`、`TopicBar` 替代内联代码
- 添加 BlurHash 占位
- 点击图片 → `context.go('/photo/${photo.id}')`
- 点击头像 → `context.go('/photographer/${photo.user.username}')`
- 随机骰子 → `randomPhotoProvider` → `context.go('/photo/${photo.id}')`
- 移除收藏按钮（Phase 3 或更晚再做）

### 关键依赖

```yaml
dependencies:
  blurhash: ^3.0.0            # BlurHash 解码 → PhotoCard 加载占位
  cached_network_image: ^3.3.0 # 图片缓存（已存在）
  image_gallery_saver: ^4.1.0  # 保存图片到相册
  photo_view: ^0.15.0          # 图片缩放/平移/全屏 → 详情页
  flutter_image_compress: ^2.1.0 # 下载前压缩（可选）
```

### Phase 1 不引入

- 无 `share_plus`（后续社交功能再引入）
- 无 `flutter_facebook_auth` / `google_sign_in`（OAuth 阶段再引入）

---

## Phase 2：收藏（Unsplash API 只读）

### 目标

用户浏览 Unsplash 官方收藏集列表，点击进入收藏集查看包含的图片（只读）。

### 新增模块

```
collections/
├── data/
│   ├── datasources/collection_remote_datasource.dart
│   ├── models/collection_model.dart
│   └── repositories/collection_repository_impl.dart
├── domain/
│   ├── entities/collection.dart
│   └── repositories/collection_repository.dart
└── presentation/
    ├── pages/
    │   ├── collections_page.dart
    │   └── collection_detail_page.dart
    └── providers/collections_provider.dart
```

### 数据源

| API | 用途 |
|-----|------|
| `GET /collections?page=N` | 收藏集列表（封面、名称、图片数） |
| `GET /collections/:id/photos?page=N` | 收藏集内图片列表 |

### 收藏页 UI

- 2 列网格布局，卡片包含封面图 + 标题 + 图片数
- 空状态：API 返回空 → 「暂无收藏集」
- 点击进入收藏集详情页
- 复用 `PhotoCard` 展示收藏集内图片

### 路由

- `collections_page` 替换 `app_router.dart` 中的占位
- 新增: `/collection/:id`

### 当前限制

- 发现页和详情页的"收藏"按钮本阶段不实现
- 无本地写操作

---

## Phase 3：探索 + 我的

### 目标

用户可以在发现页搜索图片，管理员设置深色模式等偏好。

### 探索页模块

```
explore/
├── data/datasources/search_remote_datasource.dart
├── presentation/
│   ├── pages/explore_page.dart
│   └── widgets/
│       ├── search_input.dart
│       ├── color_filter_bar.dart
│       ├── orientation_filter.dart
│       └── search_history.dart
└── providers/search_provider.dart
```

### 搜索 API

```
GET /search/photos?query={keyword}&color={color}&orientation={orientation}&order_by={relevant|latest}&page={page}
```

### 搜索页功能

- 搜索输入框：300ms 防抖自动触发
- 颜色过滤：12 个颜色 Chip（全部/黑白/红/橙/黄/绿/青/蓝/紫/品/白/黑）
- 方向过滤：全部 / 横向 / 竖向
- 排序切换：相关度 / 最新
- 结果列表：单列 Feed，复用 `PhotoCard`
- 空结果：引导建议 + 热门搜索标签
- 首次进入（未搜索）：展示搜索历史（本地存储最近 10 条）+ 热门预设词
- 搜索结果 Header：「搜索结果 (N) 排序: 相关度 ▼」

### 我的页模块

```
profile/
├── presentation/pages/profile_page.dart
└── providers/settings_provider.dart
```

### 我的页功能

| 功能 | 实现 |
|------|------|
| 数据统计 | 从 Hive 读取本地统计数据（浏览图片数、下载数） |
| 深色模式 | 开关切换 `ThemeMode`，持久化 Hive |
| 清除缓存 | `DefaultCacheManager().emptyCache()` + 显示当前缓存大小 |
| 关于 | 版本号 + 技术栈 + 数据来源: Unsplash API |

---

## 架构原则

### 现有架构不变

- 状态管理: Riverpod `FutureProvider.family`
- 路由: GoRouter ShellRoute
- 网络: Dio
- 本地存储: Hive
- 数据层: DataSource → Repository → Provider → UI

### 组件复用

- `PhotoCard` 是核心复用组件，在 Phase 1 提取后，Phase 2/3 直接使用
- 所有列表场景（发现、搜索、收藏集详情）统一使用 `PhotoFeed`

### 错误处理

- API 错误: 统一 `Failure` 类型 → Provider 抛出 → UI 层 `ErrorState` 组件显示
- 网络错误: `ErrorState` + 重试按钮
- 空数据: `EmptyState` 组件
- 加载中: `LoadingIndicator` / 骨架屏

---

## 不包含在 MVP 中的功能

- OAuth 用户登录/注册
- 收藏集 CRUD（创建、编辑、删除收藏集）
- 图片收藏到自定义收藏集
- 点赞状态同步到服务器
- 跨设备数据同步
- 图片上传
- 社交功能（关注、评论）

---

## 测试策略

- `PhotoCard` widget test（加载中、正常显示、错误状态）
- `PhotoDetailPage` widget test（数据展示、下载触发）
- 每个 Provider 的 unit test（mock API 响应）
- 路由跳转测试

---

## 文件变更清单

### Phase 1

| 操作 | 文件 |
|------|------|
| 新增 | `lib/shared/widgets/photo_card.dart` |
| 新增 | `lib/shared/widgets/photo_feed.dart` |
| 新增 | `lib/shared/widgets/topic_bar.dart` |
| 新增 | `lib/features/photo_detail/presentation/pages/photo_detail_page.dart` |
| 新增 | `lib/features/photo_detail/presentation/widgets/download_sheet.dart` |
| 新增 | `lib/features/photographer/presentation/pages/photographer_page.dart` |
| 修改 | `lib/features/discover/presentation/pages/discover_page.dart` |
| 修改 | `lib/router/app_router.dart` |
| 修改 | `pubspec.yaml` |

### Phase 2

| 操作 | 文件 |
|------|------|
| 新增 | `lib/features/collections/data/datasources/collection_remote_datasource.dart` |
| 新增 | `lib/features/collections/data/models/collection_model.dart` |
| 新增 | `lib/features/collections/data/repositories/collection_repository_impl.dart` |
| 新增 | `lib/features/collections/domain/entities/collection.dart` |
| 新增 | `lib/features/collections/domain/repositories/collection_repository.dart` |
| 新增 | `lib/features/collections/presentation/pages/collections_page.dart` |
| 新增 | `lib/features/collections/presentation/pages/collection_detail_page.dart` |
| 新增 | `lib/features/collections/presentation/providers/collections_provider.dart` |
| 修改 | `lib/router/app_router.dart` |

### Phase 3

| 操作 | 文件 |
|------|------|
| 新增 | `lib/features/explore/data/datasources/search_remote_datasource.dart` |
| 新增 | `lib/features/explore/presentation/pages/explore_page.dart` |
| 新增 | `lib/features/explore/presentation/widgets/search_input.dart` |
| 新增 | `lib/features/explore/presentation/widgets/color_filter_bar.dart` |
| 新增 | `lib/features/explore/presentation/widgets/orientation_filter.dart` |
| 新增 | `lib/features/explore/presentation/widgets/search_history.dart` |
| 新增 | `lib/features/explore/presentation/providers/search_provider.dart` |
| 新增 | `lib/features/profile/presentation/pages/profile_page.dart` |
| 新增 | `lib/features/profile/presentation/providers/settings_provider.dart` |
| 修改 | `lib/router/app_router.dart` |
