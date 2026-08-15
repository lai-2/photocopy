# indee

**Indee** - phần mềm quản lý tiệm photocopy / in ấn (desktop, Windows).

## Cài đặt

1. Vào tab **[Releases](../../releases)**, tải file `indee-<phiên bản>.zip` mới nhất.
2. Giải nén ra một thư mục bất kỳ.
3. Chạy `indee.exe`.

App tự kiểm tra bản mới mỗi lần mở và tự cập nhật khi có xác nhận - không cần tải lại thủ công sau lần cài đầu tiên.

## Yêu cầu hệ thống

- Windows 7 SP1, Windows 8.1, Windows 10, hoặc Windows 11
- .NET Framework 4.8 (đã có sẵn trên Windows 10/11 bản mới; Windows 7/8.1 cần cài thêm - xem hướng dẫn bên dưới)

## Cài đặt trên Windows 7

Windows 7 vẫn chạy được `indee.exe`, nhưng cần đúng bản vá trước khi cài .NET Framework 4.8 - nếu bỏ qua các bước dưới đây, trình cài .NET 4.8 (hoặc Windows Update) thường báo lỗi "không hỗ trợ"/không xác thực được, dù .NET 4.8 vẫn hỗ trợ chính thức Windows 7 SP1.

1. **Cài Windows 7 Service Pack 1 (SP1)**, nếu máy chưa có - kiểm tra tại
   *This PC → Properties*. Chưa có SP1 thì cài qua Windows Update hoặc gói cài
   SP1 độc lập từ Microsoft (không phải cài lại Windows, chỉ là một bản cập nhật).
2. **Cài 2 bản vá hỗ trợ ký SHA-2**, bắt buộc để Windows tin tưởng các gói cài
   đặt/Windows Update ký sau năm 2019 (Windows 7 gốc chỉ hỗ trợ chữ ký SHA-1):
   - `KB4474419` - SHA-2 code signing support update
   - `KB4490628` - Servicing stack update
   Có thể tải cả hai từ Microsoft Update Catalog nếu Windows Update tự động
   không tìm thấy.
3. **Tải và chạy bộ cài .NET Framework 4.8 offline** (`ndp48-x86-x64-allos-enu.exe`)
   từ trang tải chính thức của Microsoft: https://dotnet.microsoft.com/download/dotnet-framework/net48
   - bộ cài độc lập này thường cài được ngay cả khi Windows Update trên máy
   đang gặp trục trặc.
4. Khởi động lại máy, sau đó chạy `indee.exe` như bình thường.

Không cần cài lại Windows ở bất kỳ bước nào - toàn bộ chỉ là cập nhật/patch trên hệ điều hành hiện có.

## Gặp vấn đề?

Liên hệ quản trị viên/đơn vị triển khai để được hỗ trợ.
