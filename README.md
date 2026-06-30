# 📖 Flutter App Đọc Truyện Tranh (Branch: API_Manga)

Ứng dụng đọc truyện tranh đa nền tảng được phát triển bằng Flutter, kết hợp giữa cơ sở dữ liệu SQLite cục bộ để quản lý truyện cá nhân và REST API để đọc truyện Online từ Cloud Server. Dự án sử dụng Firebase Authentication để xác thực và Firestore làm nơi đồng bộ, quản lý người dùng, phân quyền hệ thống.

---

## 🚀 Các Tính Năng Chính Trên Branch API_Manga

### 1. Đăng Nhập & Xác Thực Người Dùng (Authentication)
* Xác thực tài khoản qua **Firebase Authentication** hỗ trợ:
  * Đăng nhập / Đăng ký bằng Email và Mật khẩu.
  * Đăng nhập nhanh bằng tài khoản Google (**Google Sign-In**).
* Tự động kiểm tra trạng thái tài khoản bị khóa trên hệ thống.

### 2. Đọc Truyện Online Qua API
* Kết nối trực tiếp với REST API Server tại địa chỉ: `http://192.168.3.237:8180/api/v1`.
* Đồng bộ danh sách truyện mới, thể loại, thông tin chi tiết và nội dung chương trực tiếp từ Cloud Server.
* Tự động lưu trữ danh sách truyện yêu thích (Favorites) và lịch sử, tiến trình đọc chương (Reading Progress) lên máy chủ Cloud khi đăng nhập.

### 3. Phân Quyền Người Dùng (Role-Based Access Control)
Hệ thống phân chia rõ ràng làm 4 nhóm quyền với giao diện Navigation và Menu điều khiển tự động thay đổi:
* **Admin (Quản Trị Viên):**
  * Theo dõi thống kê thời gian thực của hệ thống (Tổng số user, tổng số truyện) sử dụng công nghệ Firestore Aggregation `count()`.
  * Quản lý danh sách thành viên: Tìm kiếm người dùng, thay đổi vai trò (Role), điều chỉnh số dư xu và thực hiện khóa hoặc mở khóa tài khoản.
* **Editor (Biên Tập Viên):**
  * Quản lý kho nội dung trực tuyến thông qua Bảng điều khiển Editor (`EditorDashboardScreen`).
  * Thực hiện thêm truyện mới, cập nhật chương mới (hỗ trợ tải lên cùng lúc nhiều hình ảnh bằng Multipart HTTP Request).
  * Chỉ định trạng thái truyện/chương VIP để thu phí hội viên.
* **Member (Thành Viên):**
  * Đọc truyện miễn phí và lưu tiến trình đọc tự động.
  * Mở khóa đọc các chương truyện Cao Cấp (VIP) thông qua việc mua gói cước Premium hoặc xem video quảng cáo tích điểm.
* **Guest (Khách):**
  * Xem danh sách truyện và đọc các chương truyện thông thường không khóa phí.
  * Bị giới hạn các tính năng yêu thích Cloud, lịch sử Cloud và không đọc được truyện VIP.

### 4. Hệ Thống Gói Hội Viên Premium (VIP) & Thanh Toán VNPay
* Hỗ trợ nâng cấp tài khoản lên Premium để đọc toàn bộ kho truyện VIP không giới hạn và không có quảng cáo.
* Tích hợp cổng thanh toán trực tuyến **VNPay** để mua các gói cước VIP có thời hạn:
  * Lấy danh sách gói cước (Plans) và tạo URL thanh toán trực tiếp từ API Server.
  * Điều hướng người dùng ra trình duyệt ngoài để thực hiện giao dịch thanh toán an toàn.
  * Tự động phát hiện khi người dùng quay lại ứng dụng và thực hiện tải lại hồ sơ (`tryAutoLogin()`) để cập nhật quyền hạn mới.
* Đối với tài khoản thành viên thường, hệ thống hỗ trợ mở khóa chương VIP bằng cách xem video quảng cáo giả lập (`AdRewardDialog`) dài 5 giây với bộ đếm ngược.
* Sử dụng Component phản hồi giao dịch chuyên dụng `TransactionFeedback` để thông báo trạng thái nạp tiền, nạp xu hoặc mở khóa thành công.

### 5. Quản Lý Offline & Cơ Sở Dữ Liệu Cục Bộ (SQLite & Hive)
* Cơ sở dữ liệu SQLite cục bộ được nâng cấp lên **Version 5** để hỗ trợ truyện và chương Premium:
  * Cơ chế Auto Migration tự động thực hiện lệnh `ALTER TABLE` bổ sung trường `is_vip` an toàn mà không làm mất mát dữ liệu cũ của người dùng.
* Sử dụng Hive làm bộ lưu trữ ảnh Persistent Image Storage để tăng tốc độ tải ảnh bìa và tối ưu tài nguyên mạng.

---

## 📂 Cấu Trúc Mã Nguồn (Folder Structure)

Kiến trúc mã nguồn được tổ chức theo cấu trúc Modular / Feature-First dựa trên mô hình **MVVM** (Model-View-ViewModel):

```
lib/
├── main.dart                              # Khởi chạy ứng dụng, thiết lập providers
├── firebase_options.dart                  # Tệp cấu hình tự động của Firebase
│
├── models/                                # Các lớp mô hình dữ liệu (Data Models)
│   ├── app_user.dart                      # Mô hình người dùng, quản lý vai trò và xu
│   ├── chapter.dart                       # Mô hình chương truyện cục bộ (SQLite)
│   ├── comment.dart                       # Mô hình bình luận truyện
│   ├── online_manga.dart                  # Mô hình truyện và chương tải từ API
│   ├── reading_history.dart               # Mô hình lịch sử đọc cục bộ
│   └── story.dart                         # Mô hình truyện cục bộ (SQLite)
│
├── services/                              # Dịch vụ kết nối và xử lý logic nghiệp vụ
│   ├── custom_auth_service.dart           # Xác thực Firebase và xử lý token API
│   ├── database_helper.dart               # Quản lý SQLite cục bộ (CRUD & Migration)
│   ├── firebase_service.dart              # Khởi tạo Firebase Core
│   ├── firestore_service.dart             # Truy vấn, thống kê và cập nhật người dùng trên Firestore
│   ├── image_database_service.dart        # Lưu trữ ảnh đệm cục bộ qua Hive
│   └── manga_api_service.dart             # Gọi HTTP request tới API Manga Online & VNPay
│
├── viewmodels/                            # Quản lý trạng thái giao diện (State Management)
│   ├── admin_provider.dart                # Quản lý thống kê stats và tải dữ liệu hệ thống
│   ├── auth_provider.dart                 # Quản lý phiên đăng nhập Google/Email, cập nhật tiền, role
│   ├── online_manga_provider.dart         # Quản lý danh sách truyện online và danh mục yêu thích
│   ├── story_provider.dart                # Quản lý truyện và chương cục bộ (SQLite)
│   └── theme_provider.dart                # Quản lý giao diện sáng/tối (Dark/Light Mode)
│
└── views/                                 # Giao diện người dùng (UI Screens)
    ├── admin/                             # Giao diện dành riêng cho Admin
    │   ├── admin_dashboard_screen.dart    # Bảng điều khiển admin và thống kê stats hệ thống
    │   └── user_management_screen.dart    # Quản lý người dùng, chỉnh sửa role/tiền, khóa account
    │
    ├── editor/                            # Giao diện dành riêng cho Editor
    │   ├── chapter_form_screen.dart       # Form Editor thêm chương mới trực tuyến
    │   ├── editor_dashboard_screen.dart   # Bảng điều khiển quản lý của Editor
    │   ├── editor_manga_list_screen.dart  # Danh sách truyện Editor đang quản lý trên server
    │   └── manga_form_screen.dart         # Form Editor thêm truyện mới trực tuyến
    │
    ├── member/                            # Giao diện các tiện ích thành viên
    │   └── ad_reward_dialog.dart          # Dialog xem quảng cáo 5s để nhận lượt đọc
    │
    ├── widgets/                           # Các widgets thành phần tái sử dụng
    │   ├── story_card.dart                # Thẻ hiển thị truyện (hỗ trợ huy hiệu VIP 👑)
    │   └── transaction_feedback.dart      # Hộp thoại phản hồi kết quả giao dịch
    │
    ├── auth_screen.dart                   # Màn hình đăng nhập/đăng ký bằng Google hoặc Email
    ├── chapter_edit_screen.dart           # Màn hình sửa chương truyện cục bộ
    ├── chapter_form_screen.dart           # Màn hình thêm chương truyện cục bộ
    ├── chapter_reading_screen.dart        # Màn hình đọc truyện cục bộ (SQLite)
    ├── home_screen.dart                   # Trang chủ hiển thị danh sách truyện cục bộ
    ├── main_navigation.dart               # Trình điều hướng Tabs chính (thay đổi theo Role)
    ├── my_stories_screen.dart             # Màn hình quản lý truyện cá nhân cục bộ
    ├── online_chapter_reading_screen.dart # Màn hình đọc chương truyện Online từ API
    ├── online_manga_detail_screen.dart    # Chi tiết truyện online (chặn chapter VIP, xử lý VNPay)
    ├── online_screen.dart                 # Trang chủ xem và tìm kiếm truyện Online từ API
    ├── profile_screen.dart                # Hồ sơ cá nhân (avatar, gói VIP Premium, cài đặt theme)
    ├── reading_history_screen.dart        # Màn hình hiển thị lịch sử đọc
    ├── story_detail_screen.dart           # Chi tiết truyện cục bộ và quản lý chương
    └── story_form_screen.dart             # Màn hình thêm/sửa truyện cục bộ
```

---

## 📐 Kiến Trúc Hoạt Động (Architecture Flow)

Ứng dụng tuân thủ nghiêm ngặt mô hình **MVVM** với dòng chảy dữ liệu một chiều:

```
┌─────────────────────────────────────────────────────────────┐
│                            VIEWS                            │
│  (views/auth_screen.dart, views/online_screen.dart, v.v.)  │
└───────────────────────────┬─────────────────────────────────┘
                            │ Đọc State & Gửi Actions (Provider)
┌───────────────────────────▼─────────────────────────────────┐
│                         VIEWMODELS                          │
│  (viewmodels/auth_provider.dart, story_provider.dart, v.v.) │
└───────────────────────────┬─────────────────────────────────┘
                            │ Gọi phương thức nghiệp vụ
┌───────────────────────────▼─────────────────────────────────┐
│                          SERVICES                           │
│  (services/manga_api_service.dart, database_helper.dart)     │
└───────────────────────────┬─────────────────────────────────┘
                            │ Chuyển đổi phản hồi JSON/SQL
┌───────────────────────────▼─────────────────────────────────┐
│                           MODELS                            │
│  (models/app_user.dart, models/online_manga.dart, v.v.)     │
└─────────────────────────────────────────────────────────────┘
```

---

## 🗄️ Cơ Sở Dữ Liệu SQLite Schema (Version 5)

Dưới đây là cấu trúc các bảng dữ liệu cục bộ hỗ trợ đọc và quản lý truyện Offline:

```sql
-- Bảng truyện tranh
CREATE TABLE stories(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  author TEXT NOT NULL,
  description TEXT,
  cover_image TEXT,
  genres TEXT,
  status TEXT DEFAULT 'Đang cập nhật',
  views_count INTEGER DEFAULT 0,
  is_favorite INTEGER DEFAULT 0,
  is_vip INTEGER DEFAULT 0,              -- Cột mới thêm ở v5: Đánh dấu truyện Premium
  created_at TEXT NOT NULL
);

-- Bảng chương truyện
CREATE TABLE chapters(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  story_id INTEGER NOT NULL,
  chapter_number INTEGER NOT NULL,
  title TEXT,
  is_vip INTEGER DEFAULT 0,              -- Cột mới thêm ở v5: Đánh dấu chương VIP
  created_at TEXT NOT NULL,
  FOREIGN KEY (story_id) REFERENCES stories(id) ON DELETE CASCADE
);

-- Bảng lưu trữ đường dẫn ảnh của chương truyện
CREATE TABLE chapter_images(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  chapter_id INTEGER NOT NULL,
  image_path TEXT NOT NULL,
  order_index INTEGER NOT NULL,
  FOREIGN KEY (chapter_id) REFERENCES chapters(id) ON DELETE CASCADE
);

-- Bảng bình luận trên truyện (cục bộ)
CREATE TABLE comments(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  story_id INTEGER NOT NULL,
  username TEXT NOT NULL,
  avatar_path TEXT,
  content TEXT NOT NULL,
  created_at TEXT NOT NULL,
  FOREIGN KEY (story_id) REFERENCES stories(id) ON DELETE CASCADE
);

-- Bảng lịch sử đọc truyện
CREATE TABLE reading_history(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  story_id INTEGER NOT NULL,
  chapter_id INTEGER NOT NULL,
  read_at TEXT NOT NULL,
  FOREIGN KEY (story_id) REFERENCES stories(id) ON DELETE CASCADE,
  FOREIGN KEY (chapter_id) REFERENCES chapters(id) ON DELETE CASCADE,
  UNIQUE(story_id, chapter_id)
);
```

---

## 🛠️ Hướng Dẫn Cài Đặt & Cấu Hình Chạy Thử

### Bước 1: Clone Mã Nguồn Dự Án
Thực hiện chạy lệnh clone dự án về thư mục làm việc của bạn:
```bash
git clone https://github.com/nhuonggvn/App-Doc-Truyen.git
cd App-Doc-Truyen
```

### Bước 2: Cài Đặt Các Dependencies
Tải các thư viện được khai báo trong tệp `pubspec.yaml`:
```bash
flutter pub get
```

### Bước 3: Cấu Hình Firebase Project
Để tính năng xác thực đăng nhập hoạt động, bạn cần cấu hình Firebase của riêng bạn:
1. Tạo một dự án mới trên [Firebase Console](https://console.firebase.google.com/).
2. Bật tính năng **Authentication** và kích hoạt phương thức đăng nhập bằng **Email/Password** và **Google**.
3. Khởi tạo **Cloud Firestore** trên Firebase project để lưu trữ thông tin người dùng và phân quyền.
4. Tải tệp cấu hình về ứng dụng:
   * **Android:** Đặt tệp `google-services.json` vào đường dẫn `android/app/`.
   * **iOS:** Đặt tệp `GoogleService-Info.plist` vào đường dẫn `ios/Runner/`.

### Bước 4: Thiết Lập File Biến Môi Trường `.env`
Tạo một tệp tin mới tên là `.env` đặt ngay tại thư mục gốc của dự án (cùng cấp với tệp `pubspec.yaml`). Điền thông tin cấu hình Firebase API key từ dự án của bạn dựa theo mẫu dưới đây:
```env
FIREBASE_API_KEY=YOUR_API_KEY_HERE
FIREBASE_APP_ID_WEB=YOUR_APP_ID_WEB
FIREBASE_APP_ID_ANDROID=YOUR_APP_ID_ANDROID
FIREBASE_APP_ID_IOS=YOUR_APP_ID_IOS
FIREBASE_APP_ID_MACOS=YOUR_APP_ID_MACOS
FIREBASE_APP_ID_WINDOWS=YOUR_APP_ID_WINDOWS
FIREBASE_MESSAGING_SENDER_ID=YOUR_SENDER_ID
FIREBASE_PROJECT_ID=YOUR_PROJECT_ID
FIREBASE_AUTH_DOMAIN=YOUR_AUTH_DOMAIN
FIREBASE_STORAGE_BUCKET=YOUR_STORAGE_BUCKET
```

### Bước 5: Kết Nối API Server Online
Manga API Server mặc định được cấu hình trỏ tới địa chỉ IP `http://192.168.3.237:8180/api/v1`. 
* Đảm bảo thiết bị chạy ứng dụng hoặc máy ảo Android Emulator nằm chung mạng nội bộ hoặc có thể kết nối được tới địa chỉ IP trên.
* Nếu muốn chạy API Server ở một địa chỉ IP khác, bạn có thể chỉnh sửa lại giá trị biến `baseUrl` trong tệp [manga_api_service.dart](file:///Users/mac/Desktop/Congty-Spro/App-Truyen-Cty/lib/services/manga_api_service.dart):
  ```dart
  static const String baseUrl = 'http://IP_CUA_BAN:PORT/api/v1';
  ```

### Bước 6: Chạy Ứng Dụng
Sử dụng dòng lệnh để chạy dự án trên thiết bị thật hoặc máy ảo đã kết nối:
```bash
flutter run
```

---

## 📦 Các Thư Viện Phát Triển Chính (Main Dependencies)

Dự án sử dụng các thư viện chính thức và phổ biến trong hệ sinh thái Flutter:

| Tên Thư Viện | Phiên Bản | Công Dụng Chi Tiết |
| :--- | :--- | :--- |
| **`provider`** | `^6.1.5` | Quản lý trạng thái tập trung và cung cấp luồng dữ liệu (State Management). |
| **`sqflite`** | `^2.4.2` | Tương tác với cơ sở dữ liệu cục bộ SQLite của thiết bị. |
| **`firebase_core`** | `^3.12.1` | Khởi tạo cấu hình và kết nối với các dịch vụ của nền tảng Firebase. |
| **`firebase_auth`** | `^5.5.2` | Đăng nhập, đăng ký và quản lý phiên người dùng bằng Email/Google. |
| **`cloud_firestore`** | `^5.6.6` | Đồng bộ dữ liệu thành viên, ví xu, vai trò và thực hiện stats aggregation cục bộ. |
| **`google_sign_in`** | `^6.2.2` | Xác thực đăng nhập qua tài khoản Google của người dùng. |
| **`http`** | `^1.2.2` | Thực hiện các request GET, POST, PUT, DELETE tới Manga API Server. |
| **`cached_network_image`**| `^3.4.1`| Tải và đệm (cache) ảnh truyện trực tuyến từ server, tối ưu băng thông. |
| **`hive` / `hive_flutter`**| `^2.2.3` | Cơ sở dữ liệu NoSQL tốc độ cao dùng để lưu trữ dữ liệu ảnh và cấu hình đệm. |
| **`shared_preferences`** | `^2.3.5` | Lưu trữ cấu hình nhỏ gọn của thiết bị (Theme sáng/tối). |
| **`url_launcher`** | `^6.3.2` | Điều hướng mở URL thanh toán VNPay ra trình duyệt ngoài thiết bị. |
| **`flutter_dotenv`** | `^5.2.1` | Đọc cấu hình bảo mật từ tệp tin biến môi trường `.env`. |

---

## 📄 Bản Quyền & Giấy Phép (License)

* Dự án này được phát triển phục vụ mục đích nghiên cứu học tập về lập trình ứng dụng di động Flutter và tích hợp hệ thống Firebase + REST API.
* Vui lòng ghi rõ nguồn tham chiếu nếu sử dụng hoặc phân phối lại mã nguồn từ dự án này.
* Bản quyền thuộc về tác giả: Nguyễn Văn Hưởng - 2026.
