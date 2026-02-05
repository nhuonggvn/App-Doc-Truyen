# Hướng dẫn tích hợp OTruyen API

Tài liệu hướng dẫn cách tích hợp API từ **otruyenapi.com** vào dự án Flutter đọc truyện.

---

## 1. Cài đặt Dependencies

Thêm package `http` vào `pubspec.yaml`:

```yaml
dependencies:
  http: ^1.2.0
```

Chạy:
```bash
flutter pub get
```

---

## 2. Cấu trúc API

**Base URL**: `https://otruyenapi.com/v1/api`

| Endpoint | Mô tả | Ví dụ |
|----------|-------|-------|
| `/home` | Trang chủ | `/home` |
| `/danh-sach/{type}` | Danh sách theo loại | `/danh-sach/truyen-moi` |
| `/the-loai` | Tất cả thể loại | `/the-loai` |
| `/the-loai/{slug}` | Truyện theo thể loại | `/the-loai/action` |
| `/truyen-tranh/{slug}` | Chi tiết truyện | `/truyen-tranh/one-piece` |
| `/tim-kiem?keyword=...` | Tìm kiếm | `/tim-kiem?keyword=naruto` |

---

## 3. Files cần thiết

### 3.1 Models (`lib/models/otruyen_models.dart`)
Chứa các class:
- `OTruyenStory` - Thông tin truyện
- `OTruyenStoryDetail` - Chi tiết truyện + chapters
- `OTruyenChapterInfo` - Thông tin chapter
- `OTruyenChapterContent` - Nội dung chapter (ảnh)
- `OTruyenCategory` - Thể loại
- `OTruyenListResponse` - Response danh sách

### 3.2 API Service (`lib/services/otruyen_api_service.dart`)
Singleton service với các methods:
```dart
final api = OTruyenApiService();

// Lấy trang chủ
final home = await api.getHome();

// Danh sách theo loại
final list = await api.getStoryList('truyen-moi', page: 1);

// Lấy thể loại
final categories = await api.getCategories();

// Truyện theo thể loại
final actionStories = await api.getStoriesByCategory('action');

// Chi tiết truyện
final detail = await api.getStoryDetail('one-piece');

// Tìm kiếm
final results = await api.searchStories('naruto');

// Nội dung chapter
final content = await api.getChapterContent(chapterApiUrl);
```

### 3.3 UI Screens
- `otruyen_home_screen.dart` - Màn hình danh sách
- `otruyen_detail_screen.dart` - Chi tiết truyện
- `otruyen_reading_screen.dart` - Đọc truyện (xem ảnh)

---

## 4. Cách sử dụng

### 4.1 Hiển thị ảnh bìa
```dart
final thumbUrl = story.getFullThumbUrl(response.cdnImageDomain);
Image.network(thumbUrl)
```

### 4.2 Xem chi tiết truyện
```dart
Navigator.push(context, MaterialPageRoute(
  builder: (_) => OTruyenDetailScreen(
    storySlug: story.slug,
    storyName: story.name,
  ),
));
```

### 4.3 Đọc chapter
```dart
Navigator.push(context, MaterialPageRoute(
  builder: (_) => OTruyenReadingScreen(
    chapterApiData: chapter.chapterApiData,
    chapterName: chapter.displayName,
    storyName: storyName,
    chapters: allChapters,
    currentIndex: index,
  ),
));
```

---

## 5. Lưu ý quan trọng

> ⚠️ **API này cung cấp TRUYỆN TRANH (hình ảnh)**, không phải truyện chữ.

- Nội dung chapter là danh sách ảnh, không phải văn bản
- Một số truyện mới chưa có chapter (API trả về `chapters: []`)
- CDN domain có thể thay đổi, luôn lấy từ response `APP_DOMAIN_CDN_IMAGE`

---

## 6. Cấu trúc Response

### Response danh sách (`/home`, `/danh-sach/...`)
```json
{
  "status": "success",
  "data": {
    "items": [...],
    "params": {
      "pagination": {
        "totalItems": 25474,
        "totalItemsPerPage": 24,
        "currentPage": 1,
        "totalPages": 1062
      }
    },
    "APP_DOMAIN_CDN_IMAGE": "https://img.otruyenapi.com"
  }
}
```

### Response chi tiết (`/truyen-tranh/{slug}`)
```json
{
  "data": {
    "item": {
      "name": "...",
      "slug": "...",
      "thumb_url": "...",
      "author": ["..."],
      "chapters": [
        {
          "server_name": "Server #1",
          "server_data": [
            {
              "chapter_name": "1",
              "chapter_api_data": "https://..."
            }
          ]
        }
      ]
    }
  }
}
```
