# 📖 Flutter App Đọc Truyện

Ứng dụng đọc truyện tranh (images) được xây dựng bằng Flutter với Firebase Authentication và SQLite database.

---

## 🚀 Tính năng chính

- 🔐 **Đăng nhập/Đăng ký** với Firebase Auth
- 📚 **Quản lý truyện**: Thêm, sửa, xóa truyện
- 📑 **Quản lý chương**: Thêm chương với nhiều ảnh
- 📖 **Đọc truyện**: Xem chương với điều hướng mượt mà
- ❤️ **Yêu thích**: Lưu truyện yêu thích
- 📜 **Lịch sử đọc**: Theo dõi chương đã đọc
- 💬 **Bình luận**: Bình luận trên từng truyện
- 🌙 **Dark mode**: Chế độ sáng/tối
- 👤 **Hồ sơ**: Đổi avatar và tên hiển thị

---
```

lib/
├── main.dart                              # Entry point, khởi tạo providers
├── firebase_options.dart                  # Cấu hình Firebase
│
├── models/                                # Data models
│   ├── story.dart                         # Model truyện
│   ├── chapter.dart                       # Model chương + ChapterImage
│   ├── comment.dart                       # Model bình luận
│   └── reading_history.dart               # Model lịch sử đọc
│
├── services/                              # Business logic & data access
│   ├── database_helper.dart               # SQLite CRUD operations
│   └── firebase_service.dart              # Firebase services
│
├── viewmodels/                            # State management (Provider)
│   ├── auth_provider.dart                 # Xử lý đăng nhập/đăng ký
│   ├── story_provider.dart                # Quản lý truyện, chapters, comments
│   └── theme_provider.dart                # Quản lý theme sáng/tối
│
└── views/                                 # UI screens
    ├── main_navigation.dart               # Bottom navigation chính
    ├── auth_screen.dart                   # Màn hình đăng nhập/đăng ký
    ├── home_screen.dart                   # Trang chủ, danh sách truyện
    ├── my_stories_screen.dart             # Quản lý truyện của tôi
    ├── story_form_screen.dart             # Form thêm/sửa truyện
    ├── story_detail_screen.dart           # Chi tiết truyện, danh sách chương
    ├── chapter_form_screen.dart           # Form thêm chương mới
    ├── chapter_edit_screen.dart           # Sửa chương đã có
    ├── chapter_reading_screen.dart        # Màn hình đọc truyện
    ├── reading_history_screen.dart        # Lịch sử đọc
    ├── profile_screen.dart                # Hồ sơ người dùng
    └── widgets/                           # Reusable widgets
        └── story_card.dart                # Card hiển thị truyện
```
---


## 🏗️ Kiến trúc

Ứng dụng sử dụng mô hình **MVVM** (Model-View-ViewModel):

```
┌─────────────────────────────────────────────────────────────┐
│                         VIEWS                               │
│  (auth_screen, home_screen, story_detail_screen, ...)       │
└─────────────────────────┬───────────────────────────────────┘
                          │ Provider.of<>
┌─────────────────────────▼───────────────────────────────────┐
│                      VIEWMODELS                             │
│  (auth_provider, story_provider, theme_provider)            │
└─────────────────────────┬───────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────┐
│                       SERVICES                              │
│  (database_helper, firebase_service)                        │
└─────────────────────────┬───────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────┐
│                        MODELS                               │
│  (Story, Chapter, Comment, ReadingHistory)                  │
└─────────────────────────────────────────────────────────────┘
```

---

## 🗄️ Database Schema

```sql
-- Bảng truyện
stories(id, title, author, description, cover_image, status, genres, is_favorite, view_count, created_at)

-- Bảng chương
chapters(id, story_id, chapter_number, title, created_at)

-- Bảng ảnh chương
chapter_images(id, chapter_id, image_path, order_index)

-- Bảng bình luận
comments(id, story_id, username, avatar_path, content, created_at)

-- Bảng lịch sử đọc
reading_history(id, story_id, chapter_id, read_at)
```

---

## 🛠️ Cài đặt

1. **Clone project**
   ```bash
   git clone https://github.com/nhuonggvn/App-Doc-Truyen.git
   cd App-Doc-Truyen
   ```

2. **Cài dependencies**
   ```bash
   flutter pub get
   ```

3. **Cấu hình Firebase**
   - Tạo file `.env` với các key Firebase (xem `lib/firebase_options.dart`)
   - Đảm bảo `google-services.json` trong `android/app/`

4. **Chạy ứng dụng**
   ```bash
   flutter run
   ```

---

## 📦 Dependencies chính

| Package | Mục đích |
|---------|----------|
| `provider` | State management |
| `sqflite` | SQLite database |
| `firebase_auth` | Authentication |
| `firebase_core` | Firebase core |
| `image_picker` | Chọn ảnh từ gallery |
| `shared_preferences` | Lưu settings local |
| `path_provider` | Đường dẫn file system |
| `intl` | Format ngày tháng |

---

## 📱 Screenshots

### Giao diện sáng
<p>
<img src="Pictures\Screenshot_1.jpg" width="200"/>
<img src="Pictures\Screenshot_2.jpg" width="200"/>
<img src="Pictures\Screenshot_3.jpg" width="200"/>
<img src="Pictures\Screenshot_4.jpg" width="200"/>
<img src="Pictures\Screenshot_5.jpg" width="200"/>
<img src="Pictures\Screenshot_6.jpg" width="200"/>
<img src="Pictures\Screenshot_7.jpg" width="200"/>
<img src="Pictures\Screenshot_8.jpg" width="200"/>
<img src="Pictures\Screenshot_9.jpg" width="200"/>
<img src="Pictures\Screenshot_10.jpg" width="200"/>
<img src="Pictures\Screenshot_11.jpg" width="200"/>
<img src="Pictures\Screenshot_12.jpg" width="200"/>
</p>

### Giao diện tối
<p>
<img src="Pictures\Screenshot_1 (2).jpg" width="200"/>
<img src="Pictures\Screenshot_2 (2).jpg" width="200"/>
<img src="Pictures\Screenshot_3 (2).jpg" width="200"/>
<img src="Pictures\Screenshot_4 (2).jpg" width="200"/>
<img src="Pictures\Screenshot_5 (2).jpg" width="200"/>
<img src="Pictures\Screenshot_6 (2).jpg" width="200"/>
<img src="Pictures\Screenshot_7 (2).jpg" width="200"/>
<img src="Pictures\Screenshot_8 (2).jpg" width="200"/>
<img src="Pictures\Screenshot_9 (2).jpg" width="200"/>
</p>

---

## 📄 License

- Dự án này phát triển nhằm mục đích nghiên cứu và học tập về Flutter và Firebase.
- Nếu như có ai đó lấy mã nguồn và sử dụng thì xin vui lòng ghi rõ nguồn. Xin cảm ơn.
- Nguyễn Văn Hưởng - 2026
