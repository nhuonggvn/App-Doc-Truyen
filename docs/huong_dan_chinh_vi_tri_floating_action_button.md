# Hướng Dẫn Tùy Chỉnh Vị Trí FloatingActionButton Trên Màn Hình Editor

## 1. Tóm Tắt & Lý Do Kỹ Thuật (Why & How)

### Nguyên nhân:
- Màn hình Editor (`MyStoriesScreen`) được lồng bên trong điều hướng chính `MainNavigation`.
- Thanh điều hướng đáy (`BottomNavigationBar`) được thiết kế dạng Floating Dock nổi với chiều cao 56px, lề đáy 8px cộng với vùng an toàn `SafeArea`.
- Mặc định, nút `FloatingActionButton` trong `Scaffold` chỉ cách đáy màn hình 16px. Do đó, nút "Thêm truyện" bị thanh điều hướng che khuất phần lớn nội dung, chỉ lộ một phần mép xanh ở đáy.

### Giải pháp kỹ thuật:
- Sử dụng widget `Padding` bọc bên ngoài `FloatingActionButton.extended`.
- Đổi thông số `padding: const EdgeInsets.only(bottom: 85)` để nâng lề dưới của nút lên thêm 15px, giúp nút nằm hoàn toàn phía trên thanh điều hướng và hiển thị rõ ràng, dễ thao tác.

---

## 2. Kiến Thức Cốt Lõi Cần Nhớ (Core Concepts)

1. **Tùy biến vị trí nút bấm nổi (FloatingActionButton Position):**
   - Không cần thay đổi kiến trúc `Scaffold`, chỉ cần bọc `FloatingActionButton` trong widget `Padding` hoặc `Container` để tinh chỉnh lề (`margin` / `padding`).
   - Cú pháp cơ bản:
     ```dart
     floatingActionButton: Padding(
       padding: const EdgeInsets.only(bottom: 85), // Nâng lề dưới thêm 15px
       child: FloatingActionButton.extended(
         onPressed: () {},
         icon: const Icon(Icons.add),
         label: const Text('Thêm mới'),
       ),
     )
     ```

2. **Quy tắc chống che khuất UI (Multi-Device Safe Rule):**
   - Khi sử dụng thanh điều hướng tùy biến (Custom Dock BottomNavigationBar) hoặc ứng dụng chạy trên thiết bị có thanh điều hướng cử chỉ, các thành phần tương tác ở đáy màn hình cần tính toán thêm lề an toàn (`bottom padding`) để tránh bị đè vạch cử chỉ hoặc đè thanh tab bar.

---

## 3. Hướng Dẫn Thực Hành Tự Tay (Self-Practice Challenge)

### Bài tập nhỏ:
Hãy tự tay mở file `lib/views/my_stories_screen.dart` và thử nghiệm tự điều chỉnh khoảng cách vị trí của nút bấm theo các bước sau:

1. Mở file `lib/views/my_stories_screen.dart`.
2. Tìm đến thuộc tính `floatingActionButton` của `Scaffold`.
3. Thay đổi giá trị `bottom: 85` thành `bottom: 90` hoặc `bottom: 75` để quan sát sự di chuyển vị trí của nút trên thiết bị/emulator.
4. Thử đổi biểu tượng icon từ `Icons.add` sang `Icons.post_add_rounded` để ghi nhớ cách tùy biến `FloatingActionButton`.
