# Tài Liệu So Sánh Chức Năng Các Branch Và Hệ Thống Phân Quyền

Tài liệu này cung cấp cái nhìn tổng quan và chi tiết về chức năng của 4 nhánh (branch) chính trong dự án Manga App, giúp bạn dễ dàng nắm bắt được nhánh nào đang làm nhiệm vụ gì, sự khác biệt về kiến trúc và các tính năng đã được thêm mới trên từng nhánh.

---

## I. Tổng Quan Về 4 Nhánh (Branch) Chính

Dự án hiện tại đang được chia thành 4 nhánh phát triển song song và có các mục tiêu kỹ thuật khác nhau:

1. **main**: Nhánh nền tảng vững chắc. Tập trung vào đọc truyện Offline cục bộ (SQLite và Hive) và đọc truyện Online ở mức cơ bản thông qua API truyenmoi.
2. **phan-quyen**: Nhánh bắt đầu triển khai hệ thống phân quyền người dùng (Role-Based Access Control) thông qua Firebase Authentication và Cloud Firestore.
3. **feature**: Nhánh phát triển trung gian. Bổ sung các lớp dịch vụ chung và các thành phần UI tương tác để làm bàn đạp nâng cấp lên API và hệ thống thanh toán.
4. **API_Manga**: Nhánh cao cấp và hoàn thiện nhất của hệ thống. Chuyển sang xác thực hoàn toàn bằng API Server của công ty (bỏ Firebase Auth), tích hợp thanh toán gói VIP qua VNPay, đồng bộ hóa dữ liệu lên Cloud và bổ sung trình quản lý truyện Online dành cho Editor.

---

## II. Chi Tiết Chức Năng Và Thay Đổi Của Từng Branch

### 1. Nhánh main (Offline & Online Reader Cơ Bản)
Nhánh `main` là phiên bản tiêu chuẩn, tập trung vào trải nghiệm đọc truyện mà không cần đăng nhập phức tạp hay các chức năng thu phí.

* **Chức năng đã làm**:
  * **Đọc truyện Offline**: Hỗ trợ CRUD truyện và chương truyện lưu trữ cục bộ. Sử dụng SQLite để quản lý thông tin văn bản và Hive Database để lưu dữ liệu ảnh nhị phân (binary) của các trang truyện, giúp tối ưu hóa dung lượng và tăng tốc độ tải ảnh.
  * **Đọc truyện Online**: Kết nối API hệ thống tại địa chỉ `http://192.168.3.237:8180/api/v1` để lấy danh sách truyện mới và đọc các chương trực tuyến.
  * **Tiện ích đi kèm**: Xem lịch sử đọc truyện cục bộ, danh sách yêu thích cục bộ và viết bình luận. Hỗ trợ Dark/Light Mode.
* **Các thay đổi và tính năng làm thêm trên nhánh main**:
  * Chuyển đổi API từ `otruyen` sang API của Công ty (`http://192.168.3.237:8180/api/v1`).
  * Giải quyết lỗi tràn text (Overflow) tên truyện ở giao diện Online.
  * Cập nhật lại các lớp Model để hỗ trợ đếm số lượng chương tự động.

---

### 2. Nhánh phan-quyen (Phân Quyền Người Dùng Qua Firebase)
Nhánh `phan-quyen` bắt đầu xây dựng hệ thống phân quyền người dùng để kiểm soát quyền đọc truyện VIP và các menu chức năng.

* **Các chức năng đã thêm mới**:
  * **Xác thực người dùng**: Tích hợp Firebase Authentication hỗ trợ đăng ký/đăng nhập bằng Email và Google Sign-In trực tiếp.
  * **Lưu trữ thông tin user trên Firestore**: Mọi thông tin người dùng như Role, số dư xu (coins), trạng thái khóa tài khoản được lưu và đồng bộ real-time thông qua Firestore Stream.
  * **Phân chia 4 nhóm quyền rõ rệt (Role-Based Access Control)**:
    * **Admin (Quản trị viên)**: Xem dashboard quản trị, tìm kiếm người dùng, chỉnh sửa Role của user, cộng/trừ xu và khóa/mở khóa tài khoản người dùng vi phạm.
    * **Editor (Biên tập viên)**: Quyền truy cập Dashboard riêng để tạo truyện mới và chương mới cho truyện Offline.
    * **Member (Thành viên)**: Có thể đọc chương thường và chương VIP (mở khóa bằng cách tiêu xu hoặc xem quảng cáo).
    * **Guest (Khách)**: Chỉ xem được danh sách và đọc chương miễn phí, không thể sử dụng tính năng yêu thích hay đọc truyện VIP.
  * **Ví xu và Quảng cáo nhận xu**:
    * Xây dựng giao diện ví xu với các gói nạp xu giả lập.
    * Hiển thị hộp thoại quảng cáo (AdRewardDialog) đếm ngược 5 giây để người dùng Free xem và nhận lượt đọc chương VIP miễn phí.
    * Áp dụng Firestore Transaction để thực hiện trừ xu hoặc cộng xu an toàn, tránh xung đột dữ liệu.
  * **Tự động thay đổi giao diện theo Role**: Thanh điều hướng Bottom Navigation tự động ẩn/hiện các tab chức năng tương ứng với từng quyền hạn.

---

### 3. Nhánh feature (Cơ Cấu Nâng Cao & Cải Tiến UI/UX)
Nhánh `feature` đóng vai trò là cầu nối kỹ thuật để chuẩn bị nâng cấp toàn bộ ứng dụng lên phiên bản tích hợp API đồng bộ của công ty.

* **Các chức năng đã làm thêm so với main và phan-quyen**:
  * **Tách biệt Auth Service**: Tạo mới lớp `CustomAuthService` để chuẩn bị cho việc đăng nhập bằng token của API Server và giảm sự phụ thuộc vào Firebase.
  * **Xây dựng Admin Provider**: Đưa vào `AdminProvider` để quản lý trạng thái tải dữ liệu người dùng và thống kê hệ thống.
  * **Giao diện phản hồi giao dịch (Transaction Feedback)**: Xây dựng widget phản hồi trạng thái `TransactionFeedback` bất đồng bộ, hỗ trợ thông báo nạp tiền hoặc mở khóa chương thành công cho người dùng một cách chuyên nghiệp và không bị lag UI.

---

### 4. Nhánh API_Manga (Tích Hợp API Toàn Diện & Thanh Toán VNPay)
Đây là nhánh cao cấp và hoàn thiện nhất của dự án, chuyển đổi toàn bộ luồng xác thực, phân quyền và quản lý nội dung qua hệ thống API Server thực tế của công ty.

* **Các chức năng đã làm thêm nổi bật**:
  * **Loại bỏ xác thực Firebase Auth**: Thay thế bằng hệ thống đăng nhập và phân quyền bằng JSON Web Token (JWT) cấp từ API Server của công ty.
  * **Đồng bộ Cloud động trực tiếp**: Danh sách truyện yêu thích (Favorites) và tiến trình đọc truyện (Reading History) của thành viên được gửi và lưu trữ trực tiếp trên hệ thống Cloud thông qua các đầu API phù hợp, chứ không còn chỉ lưu ở SQLite cục bộ.
  * **Cổng thanh toán trực tuyến VNPay**:
    * Lấy danh sách gói cước Premium từ API Server.
    * Khởi tạo URL thanh toán và điều hướng người dùng đến trang web VNPay để giao dịch thực tế.
    * Tự động quét lại thông tin và nâng cấp tài khoản lên Premium (VIP Member) khi người dùng quay lại app sau khi thanh toán thành công.
  * **Trình quản lý nội dung Online dành cho Editor**:
    * Editor không chỉ quản lý truyện Offline trên máy nữa mà có thể dùng `EditorDashboardScreen` Online để tạo truyện và chương mới trên Cloud Server.
    * Hỗ trợ tải lên danh sách ảnh chương cùng lúc bằng Multipart HTTP Request đến API Server.
  * **Thống kê hệ thống cho Admin**: Sử dụng Firestore Aggregation thông qua hàm `count()` chạy song song để lấy số liệu tổng số user và số lượng truyện nhanh chóng mà không gây tốn kém chi phí đọc Firestore.
  * **Nâng cấp SQLite lên Version 5**: Chuyển đổi database từ v4 lên v5, sử dụng cơ chế Auto Migration (`ALTER TABLE`) để thêm trường `is_vip` vào bảng truyện và chương tự động mà không làm mất mát hay lỗi dữ liệu Offline sẵn có của người dùng.

---

## III. Bảng So Sánh Chức Năng Nhanh Giữa Các Branch

| Chức năng | main | phan-quyen | feature | API_Manga |
| :--- | :---: | :---: | :---: | :---: |
| **Đọc truyện Offline (SQLite & Hive)** | Có (v4) | Có (v4) | Có (v4) | Có (v5 - Auto Migration) |
| **Đọc truyện Online qua API công ty** | Có (Cơ bản) | Có | Có | Có (Nâng cao) |
| **Xác thực Người dùng** | Không | Firebase Auth / Google | Custom Auth / Firebase | API Token (Bỏ Firebase Auth) |
| **Phân quyền (Admin/Editor/Member)** | Không | Có (Firestore Stream) | Có | Có (Đối chiếu đường dẫn qua API) |
| **Đồng bộ Yêu thích & Lịch sử** | Cục bộ | Cục bộ | Cục bộ | Đồng bộ Cloud (API Công ty) |
| **Nạp xu và Ví xu** | Không | Có (Firestore Transaction) | Có | Có (API & Custom Feedback) |
| **Xem quảng cáo nhận lượt đọc** | Không | Có (AdRewardDialog 5s) | Có | Có (AdRewardDialog 5s) |
| **Thanh toán VNPay (Mua gói VIP)** | Không | Không | Không | Có (Tích hợp trình duyệt ngoài) |
| **Editor upload truyện lên Cloud** | Không | Không | Không | Có (Multipart HTTP Upload) |
| **Admin Thống kê hệ thống** | Không | Không | Có (Cơ bản) | Có (Firestore Aggregation Stats) |

---

## IV. Các Tệp Mã Nguồn Quan Trọng Cần Lưu Ý

Dưới đây là danh sách các file quan trọng nhất được phát triển và thay đổi qua các nhánh mà bạn có thể vào đọc để kiểm tra:

* **Mô hình thông tin và logic phân quyền**:
  * Model người dùng: [app_user.dart](file:///Users/mac/Desktop/App-Truyen-Cty/lib/models/app_user.dart) (Chứa Role, Coins, trạng thái Khóa).
  * Lớp dịch vụ Firestore: [firestore_service.dart](file:///Users/mac/Desktop/App-Truyen-Cty/lib/services/firestore_service.dart) (Chứa các hàm thống kê, đồng bộ quyền hạn và giao dịch xu).
  * ViewModel xác thực: [auth_provider.dart](file:///Users/mac/Desktop/App-Truyen-Cty/lib/viewmodels/auth_provider.dart) (Quản lý trạng thái đăng nhập và thông tin user hiện tại).
* **Giao tiếp API và Thanh toán VNPay**:
  * Lớp gọi API: [manga_api_service.dart](file:///Users/mac/Desktop/App-Truyen-Cty/lib/services/manga_api_service.dart) (Xử lý tích hợp VNPay và Multipart upload ảnh cho Editor).
  * Dịch vụ đăng nhập: [custom_auth_service.dart](file:///Users/mac/Desktop/App-Truyen-Cty/lib/services/custom_auth_service.dart) (Quản lý phiên đăng nhập token API).
* **Giao diện chức năng**:
  * Dashboard Admin: [admin_dashboard_screen.dart](file:///Users/mac/Desktop/App-Truyen-Cty/lib/views/admin/admin_dashboard_screen.dart).
  * Quản lý User: [user_management_screen.dart](file:///Users/mac/Desktop/App-Truyen-Cty/lib/views/admin/user_management_screen.dart).
  * Dashboard Editor: [editor_dashboard_screen.dart](file:///Users/mac/Desktop/App-Truyen-Cty/lib/views/editor/editor_dashboard_screen.dart).
  * Ví Xu: [coin_wallet_screen.dart](file:///Users/mac/Desktop/App-Truyen-Cty/lib/views/member/coin_wallet_screen.dart).
  * Widget phản hồi: [transaction_feedback.dart](file:///Users/mac/Desktop/App-Truyen-Cty/lib/views/widgets/transaction_feedback.dart).
