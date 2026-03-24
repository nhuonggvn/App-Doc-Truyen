# 📖 Flutter App Đọc Truyện

Ứng dụng đọc truyện tranh (images) được xây dựng bằng Flutter với Firebase Authentication, SQLite database và tích hợp API đọc truyện online.

---

## 🚀 Tính năng chính

- 🔐 **Đăng nhập/Đăng ký**: Xác thực với Firebase Auth.
- 📚 **Quản lý truyện nội bộ**: Thêm, sửa, xóa truyện cá nhân (lưu SQLite).
- 📑 **Quản lý chương**: Thêm chương với nhiều ảnh cho truyện nội bộ.
- 🌐 **Đọc truyện Online**: Kết nối với API bên ngoài để xem hàng ngàn truyện mới nhất.
- 📖 **Trải nghiệm đọc mượt mà**: Hỗ trợ đọc offline bằng cách cache ảnh vào Hive database.
- ❤️ **Yêu thích**: Lưu truyện yêu thích để theo dõi.
- 📜 **Lịch sử đọc**: Theo dõi các chương đã đọc (cả nội bộ và online).
- 💬 **Bình luận**: Gửi và xem bình luận trên từng truyện.
- 🌙 **Giao diện đa dạng**: Chế độ sáng/tối với hiệu ứng gradient hiện đại.
- 👤 **Hồ sơ cá nhân**: Quản lý thông tin người dùng, đổi avatar.

---

## 📂 Cấu trúc thư mục

```
lib/
├── main.dart                              # Nơi bắt đầu ứng dụng, khởi tạo Hive & Firebase
├── firebase_options.dart                  # Cấu hình Firebase tự động
│
├── models/                                # Các lớp dữ liệu
│   ├── story.dart                         # Model truyện nội bộ
│   ├── chapter.dart                       # Model chương nội bộ
│   ├── comment.dart                       # Model bình luận
│   ├── reading_history.dart               # Model lịch sử đọc
│   └── otruyen_models.dart                # Model dữ liệu từ API Online
│
├── services/                              # Xử lý logic và API
│   ├── database_helper.dart               # SQLite CRUD (truyện nội bộ)
│   ├── firebase_service.dart              # Dịch vụ Firebase Auth & Store
│   ├── otruyen_api_service.dart           # Lấy dữ liệu từ API truyện online
│   └── image_database_service.dart        # Cache ảnh và nội dung vào Hive
│
├── viewmodels/                            # Quản lý trạng thái (Provider)
│   ├── auth_provider.dart                 # Xử lý xác thực người dùng
│   ├── story_provider.dart                # Logic nghiệp vụ về truyện & chương
│   └── theme_provider.dart                # Quản lý giao diện sáng/tối
│
└── views/                                 # Giao diện người dùng
    ├── main_navigation.dart               # Điều hướng Bottom Navigation
    ├── auth_screen.dart                   # Đăng nhập & Đăng ký
    ├── home_screen.dart                   # Danh sách truyện nội bộ
    ├── otruyen_home_screen.dart           # Trang chủ truyện Online
    ├── otruyen_detail_screen.dart         # Chi tiết truyện Online
    ├── otruyen_reading_screen.dart        # Màn hình đọc truyện Online
    ├── my_stories_screen.dart             # Quản lý truyện cá nhân
    ├── story_detail_screen.dart           # Chi tiết truyện nội bộ
    ├── story_form_screen.dart             # Form thêm/sửa truyện nội bộ
    ├── chapter_form_screen.dart           # Thêm chương mới
    ├── chapter_reading_screen.dart        # Màn hình đọc truyện nội bộ
    ├── reading_history_screen.dart        # Lịch sử đã đọc
    ├── profile_screen.dart                # Thông tin cá nhân
    └── widgets/                           # Các thành phần giao diện dùng chung
        └── story_card.dart                # Card hiển thị thông tin truyện
```

---

## 🏗️ Kiến trúc

Ứng dụng tuân thủ mô hình **MVVM** (Model-View-ViewModel) đảm bảo tách biệt logic và giao diện:

```
┌─────────────────────────────────────────────────────────────┐
│                         VIEWS                               │
│  (UI Screens: Home, Detail, Reading, Profile, ...)          │
└─────────────────────────┬───────────────────────────────────┘
                          │ Provider.of<T> / Consumer<T>
┌─────────────────────────▼───────────────────────────────────┐
│                      VIEWMODELS                             │
│  (State Management: Auth, Story, Theme Providers)           │
└─────────────────────────┬───────────────────────────────────┘
                          │ Gọi Services
┌─────────────────────────▼───────────────────────────────────┐
│                       SERVICES                              │
│  (Data Access: SQLite, Firebase, OTRUYEN API, Hive)         │
└─────────────────────────┬───────────────────────────────────┘
                          │ Đi đến
┌─────────────────────────▼───────────────────────────────────┐
│                        MODELS                               │
│  (Data Classes: Story, Chapter, OTruyen, Comment, ...)      │
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

## 🛠️ Cài đặt & Sửa lỗi

1. **Clone dự án**
   ```bash
   git clone https://github.com/nhuonggvn/App-Doc-Truyen.git
   cd App-Doc-Truyen
   ```

2. **Cài đặt thư viện**
   ```bash
   flutter pub get
   ```

3. **Thiết lập biến môi trường (.env)**
   Tạo file `.env` tại thư mục gốc và cung cấp các thông tin từ Firebase:
   ```env
   FIREBASE_API_KEY=xxx
   FIREBASE_APP_ID=xxx
   ...
   ```

4. **Cấu hình Firebase cho Android/iOS**
   Đảm bảo bạn đã đặt file `google-services.json` (Android) hoặc `GoogleService-Info.plist` (iOS) vào đúng vị trí theo tài liệu Firebase.

5. **Chạy ứng dụng**
   ```bash
   flutter run
   ```

---

## 📦 Dependencies chính

| Package | Mục đích |
|---------|----------|
| `provider` | Quản lý trạng thái ứng dụng |
| `sqflite` | Database SQLite cho dữ liệu nội bộ |
| `hive_flutter` | Database NoSQL để cache ảnh & dữ liệu API |
| `firebase_auth` | Xác thực người dùng |
| `http` | Gọi API lấy dữ liệu truyện online |
| `cached_network_image` | Hiển thị và cache ảnh từ internet |
| `flutter_dotenv` | Quản lý biến môi trường bảo mật |
| `image_picker` | Chọn ảnh bìa từ thư viện máy |

---

## 📱 Screenshots

### Giao diện sáng
<p>
<img src="Pictures/Screenshot_1.jpg" width="200"/>
<img src="Pictures/Screenshot_2.jpg" width="200"/>
<img src="Pictures/Screenshot_3.jpg" width="200"/>
<img src="Pictures/Screenshot_4.jpg" width="200"/>
<img src="Pictures/Screenshot_5.jpg" width="200"/>
<img src="Pictures/Screenshot_6.jpg" width="200"/>
<img src="Pictures/Screenshot_7.jpg" width="200"/>
<img src="Pictures/Screenshot_8.jpg" width="200"/>
<img src="Pictures/Screenshot_9.jpg" width="200"/>
<img src="Pictures/Screenshot_10.jpg" width="200"/>
<img src="Pictures/Screenshot_11.jpg" width="200"/>
<img src="Pictures/Screenshot_12.jpg" width="200"/>
</p>

### Giao diện tối
<p>
<img src="Pictures/Screenshot_1 (2).jpg" width="200"/>
<img src="Pictures/Screenshot_2 (2).jpg" width="200"/>
<img src="Pictures/Screenshot_3 (2).jpg" width="200"/>
<img src="Pictures/Screenshot_4 (2).jpg" width="200"/>
<img src="Pictures/Screenshot_5 (2).jpg" width="200"/>
<img src="Pictures/Screenshot_6 (2).jpg" width="200"/>
<img src="Pictures/Screenshot_7 (2).jpg" width="200"/>
<img src="Pictures/Screenshot_8 (2).jpg" width="200"/>
<img src="Pictures/Screenshot_9 (2).jpg" width="200"/>
</p>

---

## 📄 License

- Dự án được phát triển bởi **Nguyễn Văn Hưởng** dành cho mục đích học tập và nghiên cứu Flutter.
- Vui lòng ghi rõ nguồn nếu bạn sử dụng mã nguồn này.
- **Hà Nội, 2026.**
