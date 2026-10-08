# FIM: giám sát tính toàn vẹn file
## Mục đích

FIM (File Integrity Monitoring) phát hiện file bị thêm, sửa, xóa. Trong SOC, đây là cách bắt các hành vi như thả webshell vào thư mục web, sửa file cấu hình hoặc mã hóa file hàng loạt (ransomware). Với whodata, Wazuh còn cho biết user và tiến trình nào đã thay đổi file, thay vì chỉ biết file đã được đổi.

## Cách hoạt động

Mặc định agent chỉ quét các thư mục theo lịch, nên thay đổi được phát hiện sau một khoảng thời gian dài. Hai thuộc tính trong thẻ <directories> thay đổi điều đó:

| Thuộc tính | Tác dụng |
| :--- | :--- |
| **`realtime="yes"`** | Phát hiện ngay khi file thay đổi |
| **`whodata="yes"`** | Thay thế `realtime`, vừa phát hiện thời gian thực vừa ghi nhận ai đã thay đổi file |
| **`report_changes="yes"`** | Lưu nội dung file để xem được phần đã sửa. Wazuh sao chép mọi file được giám sát sang một vị trí riêng, nên chỉ dùng cho thư mục nhỏ |

Trên Linux, whodata dựa vào auditd (đã cài ở 03-log-sources). Nếu whodata không khởi động được, Wazuh âm thầm rút về chế độ thời gian thực thường: vẫn có alert nhưng mất thông tin người sửa. Vì vậy ta cần kiểm tra whodata chạy thật, không chỉ nhìn agent active.

## A. UbuntuWeb

### Cấu hình

Thêm một dòng vào khối `<syscheck>` trong `/var/ossec/etc/ossec.conf` (xem ở phần fim-snippet.xml):

` <directories check_all="yes" whodata="yes" report_changes="yes">/var/www/html</directories> `

Mình sẽ chọn `/var/www/html` vì đây là thư mục web, nơi kẻ tấn công thường thả webshell.

### Kiểm tra whodata chạy ổn chưa

` sudo auditctl -l | grep -i wazuh `

<img width="885" height="625" alt="image" src="https://github.com/user-attachments/assets/c5e88a85-54dc-441d-a580-3f655ecc3620" />

<img width="762" height="185" alt="image" src="https://github.com/user-attachments/assets/5852c418-2dc2-4cdc-9992-1a0855281c16" />

### Thử nghiệm

Mình sẽ chạy từng lệnh sau để test thử chức năng fim cũng như whodata

`echo "test" | sudo tee /var/www/html/fim-test.txt          # thêm`

`echo "changed" | sudo tee -a /var/www/html/fim-test.txt    # sửa`

`sudo rm /var/www/html/fim-test.txt   # xóa `

<img width="655" height="140" alt="image" src="https://github.com/user-attachments/assets/8d4c7d8b-a494-4da7-9ad9-273c8ca80848" />

### Kết quả

| Hành động | Rule ID | Level | Mô tả Alert |
| :--- | :--- |:--- | :--- |
| **Thêm file** |`554` | `5` | `File added to the system` |
| **Sửa file** |`550` | `7` | `Integrity checksum changed` |
| **Xóa file** |`553` | `7` | `File deleted` |

### Về thông tin whodata(Mình sẽ lấy đại diện là alert sửa file)

| Field | Giá trị | Ý nghĩa |
| :--- | :--- | :--- |
| **`agent.name`** | `UbuntuWeb` | Tên Agent ghi nhận sự kiện thay đổi tệp tin |
| **`agent.id`** | `001` | Mã định danh của Agent trên Wazuh Manager |
| **`agent.ip`** | `192.168.56.30` | Địa chỉ IP của máy chủ xảy ra sự kiện |
| **`timestamp`** | `Oct 8, 2026 @ 14:38:18.797` | Thời điểm chính xác cảnh báo được Wazuh xử lý |
| **`syscheck.path`** | `/var/www/html/fim-test.txt` | Đường dẫn chính xác của tệp tin bị chỉnh sửa |
| **`syscheck.audit.login_user.name`** | `khangg` (UID: `1000`) | Tài khoản người dùng thực tế đã đăng nhập vào phiên làm việc |
| **`syscheck.audit.user.name`** | `root` (UID: `0`) | Quyền người dùng thực thi hành vi ghi tệp tin |
| **`syscheck.audit.process.parent_name`** | `/usr/bin/sudo` | Lệnh/Tiến trình cha được dùng để thực thi thao tác (`sudo`) |
| **`syscheck.audit.process.cwd`** | `/home/khangg` | Thư mục làm việc của người dùng tại thời điểm thực hiện lệnh |


## Win-Client1

### Cấu hình

Mình sẽ dùng thư mục riêng C:\FIM-Lab để log sạch. Thêm một dòng vào khối `<syscheck>` trong `C:\Program Files (x86)\ossec-agent\ossec.conf (xem fim-snippet.xml)`, sao lưu bản gốc trước, rồi Restart-Service -Name wazuh:

` <directories check_all="yes" whodata="yes" report_changes="yes">C:\FIM-Lab</directories>`

<img width="898" height="62" alt="image" src="https://github.com/user-attachments/assets/4c3fac30-f8b2-4f3a-b9d6-69562036127e" />

<img width="1592" height="167" alt="image" src="https://github.com/user-attachments/assets/52d10c34-c52f-4bbb-8b8c-56ee78eed19b" />

### Thử nghiệm

Mình sẽ chayh từng lệnh sau đây để test khả năng giám sát thêm, sửa, xóa file 

`"test" | Out-File C:\FIM-Lab\fim-test.txt`

`Add-Content C:\FIM-Lab\fim-test.txt "changed"`

`Remove-Item C:\FIM-Lab\fim-test.txt`

### Kết quả (về phần ảnh của alert xem ở phần fim-alert)

| Hành động | Rule ID | Level | Mô tả Alert |
| :--- | :--- | :--- | :--- |
| **Thêm file** | `554` | `5` | `File added to the system` |
| **Sửa file** | `550` | `7` | `Integrity checksum changed` |
| **Xóa file** | `553` | `7` | `File deleted` |

### Nhận xét

- Điểm mạnh: phát hiện gần như tức thời, có thông tin người sửa và nội dung đã đổi, đủ để điều tra "ai đã làm gì".
- Giới hạn: report_changes tốn dung lượng, chỉ phù hợp thư mục nhỏ. Nếu giám sát thư mục có nhiều thay đổi hợp lệ (ví dụ log), sẽ sinh nhiều alert nhiễu và cần loại trừ (ignore) hoặc chọn thư mục kỹ hơn.
- Liên hệ về sau: kịch bản ransomware giả lập ở giai đoạn mô phỏng tấn công sẽ dựa vào FIM của Windows (C:\FIM-Lab) để phát hiện chuỗi file bị sửa hàng loạt.

### Trạng thái hiện tại
- FIM trên Linux (/var/www/html) và FIM trên Windows (C:\FIM-Lab) đều đã hoạt động trơn tru.
