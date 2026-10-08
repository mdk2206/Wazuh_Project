# SCA: đánh giá cấu hình theo chuẩn CIS

## Mục đích

SCA (Security Configuration Assessment) dùng để kiểm tra cấu hình của endpoint theo một bộ chuẩn (ở đây là CIS Benchmark) và cho biết mục nào đạt, mục nào không. SCA chạy tự động trên agent nên không cần cấu hình để bật. Phần việc của analyst là đọc kết quả, chọn mục khắc phục có cân nhắc rủi ro, quét lại và chứng minh sự cải thiện.

CIS Benchmark có hàng trăm mục, và một máy mới cài thường có nhiều mục Failed. Mục tiêu của mình ở đây không phải điểm 100% mà là chứng minh quy trình: đánh giá, chọn lọc có lý do, khắc phục, kiểm chứng. Vì vậy mình chỉ ghi chi tiết những mục đã sửa và những mục cố ý bỏ qua.

## A. UbuntuWeb

### Policy: CIS Microsoft Windows 10 Enterprise Benchmark v4.0.0.

| Thông tin | Trước | Sau | Thay đổi |
| :--- | :--- | :--- | :--- |
| **Passed** | `100` | `105` | `+5` |
| **Failed** | `97` | `92` | `-5` |
| **Not applicable** | `10` | `10` | `Không đổi` |
| **Điểm (%)** | `50` | `53` | `Tăng 3%` |

#### Trước khi khắc phục

<img width="1887" height="920" alt="image" src="https://github.com/user-attachments/assets/110d28ca-ef33-4cbb-b6dc-39c397dc9630" />

#### Sau khi khắc phục

<img width="1866" height="855" alt="image" src="https://github.com/user-attachments/assets/b8750c38-be40-4bb8-ab24-b2c75b35535f" />

### Các mục đã khắc phục

| Check ID | Nội dung | Điều kiện pass (từ Command) | Cách sửa | Trước | Sau |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **28538** | Banner cảnh báo đăng nhập (`/etc/issue`) | Tệp `/etc/issue` chứa câu cảnh báo truy cập hợp lệ và không chứa các ký tự nhận dạng OS (`\v`, `\r`, `\m`, `\s`) | `echo "Authorized uses only. All activity may be monitored." > /etc/issue` | **Failed** | **Passed** |
| **28539** | Banner cảnh báo đăng nhập (`/etc/issue.net`) | Tệp `/etc/issue.net` chứa câu cảnh báo truy cập hợp lệ và không chứa các ký tự nhận dạng OS | `echo "Authorized uses only. All activity may be monitored." > /etc/issue.net` | **Failed** | **Passed** |
| **28626** | Quyền `/etc/crontab` | Chủ `root:root`, không cấp quyền cho nhóm và người khác (quyền `600` hoặc `og-rwx`) | `sudo chown root:root /etc/crontab && sudo chmod og-rwx /etc/crontab` | **Failed** | **Passed** |
| **28627** | Quyền thư mục `/etc/cron.hourly` | Chủ `root:root`, không cấp quyền cho nhóm và người khác (quyền `700` hoặc `og-rwx`) | `sudo chown root:root /etc/cron.hourly && sudo chmod og-rwx /etc/cron.hourly` | **Failed** | **Passed** |
| **28634** | Quyền `/etc/ssh/sshd_config` | Chủ `root:root`, không cấp quyền cho nhóm và người khác (quyền `600` hoặc `og-rwx`) | `sudo chown root:root /etc/ssh/sshd_config && sudo chmod og-rwx /etc/ssh/sshd_config` | **Failed** | **Passed** |

- Các lệnh đầy đủ sẽ nằm trong `sca-remediation`

#### Vì sao các mục này quan trọng:

- Quyền file cron: cron chạy tác vụ bằng quyền root, nên cấu hình lỏng lẻo có thể bị lợi dụng để leo thang đặc quyền hoặc lộ lịch tác vụ. Cron và sshd chạy bằng root nên vẫn đọc được file sau khi siết quyền.
- sshd_config: cấu hình SSH chứa các thiết lập nhạy cảm (cho phép root, phương thức xác thực...), chỉ nên đọc và ghi bởi root.
- Banner: hiển thị cảnh báo pháp lý trước khi đăng nhập và không nên lộ thông tin hệ điều hành cho người chưa xác thực.

#### Trạng thái trước và sau của quyền file:

| Check ID | Nội dung | Điều kiện pass (từ Command) | Cách sửa | Trước | Sau |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **28626** | Quyền `/etc/crontab` | Chủ `root:root`, không cấp quyền cho nhóm và người khác | `sudo chown root:root /etc/crontab && sudo chmod 600 /etc/crontab` | **Failed (644 root:root)** | **Passed (600 root:root)** |
| **28627** | Quyền thư mục `/etc/cron.hourly` | Chủ `root:root`, không cấp quyền cho nhóm và người khác | `sudo chown root:root /etc/cron.hourly && sudo chmod 700 /etc/cron.hourly` | **Failed (755 root:root)** | **Passed (700 root:root)** |
| **28634** | Quyền `/etc/ssh/sshd_config` | Chủ `root:root`, không cấp quyền cho nhóm và người khác | `sudo chown root:root /etc/ssh/sshd_config && sudo chmod 600 /etc/ssh/sshd_config` | **Failed (644 root:root)** | **Passed (600 root:root)** |

#### Trạng thái quyền file và banner trước khi sửa

<img width="347" height="106" alt="image" src="https://github.com/user-attachments/assets/54a20170-6256-48ba-85b5-a80ef65f903e" />

<img width="500" height="57" alt="image" src="https://github.com/user-attachments/assets/a5729e52-f64d-4080-b16a-685bb504764d" />

<img width="540" height="57" alt="image" src="https://github.com/user-attachments/assets/cde01a9d-1530-487f-848f-6446981182db" />

<img width="568" height="62" alt="image" src="https://github.com/user-attachments/assets/0e2da6fe-1c55-4aec-848d-ab9d964360ee" />

#### Trạng thái quyền file và banner sau khi sửa

<img width="562" height="82" alt="image" src="https://github.com/user-attachments/assets/b504d114-24b6-4f58-9a0f-c593682b0e6b" />

<img width="512" height="47" alt="image" src="https://github.com/user-attachments/assets/4723dc37-a219-41e0-bdfe-516304b56631" />

<img width="543" height="55" alt="image" src="https://github.com/user-attachments/assets/7fc6fe5a-170d-43e0-b0ed-1ea4e4c89d45" />

<img width="582" height="55" alt="image" src="https://github.com/user-attachments/assets/e3505543-4e89-493d-803d-6110a2ed84f7" />

#### Mục mình cố ý bỏ qua

Trong thực tế vận hành , việc tuân thủ 100% benchmark không phải lúc nào cũng tối ưu nếu nó làm gián đoạn nghiệp vụ hoặc cản trở khả năng kiểm thử bảo mật. Dưới đây là các tiêu chí được cố ý giữ lại kèm lý do giải trình kỹ thuật.

| **Check ID** | **Nội dung** | **Vì sao không sửa (Justification / Exception)** |
| :--- | :--- | :--- |
| **28652** | Vô hiệu hóa đăng nhập SSH bằng mật khẩu (`PasswordAuthentication no`) | Cần duy trì cơ chế đăng nhập bằng mật khẩu để phục vụ kịch bản mô phỏng tấn công dò mật khẩu (SSH Brute Force attack) ở giai đoạn kiểm thử module Active Response / Log Analysis tiếp theo. |
| **28642** | Cấm đăng nhập trực tiếp bằng tài khoản `root` qua SSH (`PermitRootLogin no`) | Tạm thời duy trì để thuận tiện cho thao tác quản trị, cấu hình nhanh các dịch vụ trong môi trường Lab thử nghiệm; sẽ áp dụng hardening triệt để khi đưa vào môi trường Production. |
| **28580** | Kích hoạt tường lửa UFW và chặn mặc định luồng vào (`ufw enable`) | Tạm hoãn cấu hình để tránh nguy cơ tường lửa làm ngắt quãng luồng Telemetry giữa Wazuh Agent và Wazuh Manager (port `1514`/`1515`) khi chưa phân tích xong toàn bộ luồng traffic. |

## Win-Client1

### Policy: CIS Microsoft Windows 10 Enterprise Benchmark v4.0.0.

Phạm vi ở phần này sẽ nhẹ hơn Ubuntu (3 mục) vì quy trình đã được chứng minh đầy đủ ở Ubuntu phía trên.

| Thông tin | Trước | Sau | Thay đổi |
| :--- | :--- | :--- | :--- |
| **Passed** | `119` | `122` | `+3` |
| **Failed** | `300` | `297` | `-3` |
| **Not applicable** | `5` | `5` | `Không đổi` |
| **Điểm (%)** | `28%` | `29%` | `Tăng 1%` |

#### SCA trước khi khắc phục 

<img width="1907" height="912" alt="image" src="https://github.com/user-attachments/assets/d1d7a163-accd-4597-9a7b-33697a6bc0bf" />

#### SCA sau khi khắc phục 

<img width="1912" height="857" alt="image" src="https://github.com/user-attachments/assets/faa18f1a-2780-4242-8fe2-fd854bdf232d" />


### Các mục đã khắc phục

| Check ID | Dịch vụ | Vì sao an toàn để tắt | Trước | Sau |
| :--- | :--- | :--- | :--- | :--- |
| **15585** | **MSiSCSI (iSCSI Initiator)** | Chỉ cần khi nối ổ đĩa iSCSI, lab không dùng | **Failed** | `Passed` |
| **15607** | **WerSvc (Windows Error Reporting)** | Chỉ gửi báo cáo lỗi về Microsoft | **Failed** | `Passed` |
| **15608** | **Wecsvc (Event Collector)** | Dùng cho event subscription, agent Wazuh đọc trực tiếp các kênh log tại máy nên không phụ thuộc | **Failed** | `Passed` |

#### Trạng thái trước khi sửa

<img width="690" height="120" alt="image" src="https://github.com/user-attachments/assets/12c31265-23d0-44c3-84bf-892c9d84ebc7" />

<img width="807" height="112" alt="image" src="https://github.com/user-attachments/assets/e6679a72-fdba-4f86-9591-d0d73367545a" />

<img width="825" height="120" alt="image" src="https://github.com/user-attachments/assets/6e30cbb3-d895-4b87-8f20-2317813a9630" />

#### Trạng thái sau khi sửa

<img width="717" height="250" alt="image" src="https://github.com/user-attachments/assets/c6e1c9b1-9f95-4909-afb8-6a9b917dd57c" />

<img width="807" height="200" alt="image" src="https://github.com/user-attachments/assets/d291ab69-e3fa-40f3-ab8a-714848fa1bfb" />

<img width="806" height="191" alt="image" src="https://github.com/user-attachments/assets/f392c51a-ebcd-448d-93ba-0215eef539ab" />

### Những mục cố ý bỏ qua

| Check ID | Nội dung | Vì sao không sửa |
| :--- | :--- | :--- |
| **15595** | TermService (Remote Desktop) Disabled | Cần RDP cho kịch bản brute force Windows ở giai đoạn mô phỏng tấn công, và để quản lý máy lab |
| **15596** | UmRdpService Disabled | Đi cặp với TermService, tắt riêng không có ý nghĩa |

Ngoài ra mình đã chủ động tránh các nhóm mục có thể làm hỏng lab: chính sách khóa tài khoản, firewall, Windows Defender và các mục chống mã độc (sẽ cản các bài mô phỏng tấn công), quyền đăng nhập từ xa.

### Nhận xét chung

- Đọc Command thay vì tin tiêu đề. Lý do một mục Failed thường khác điều suy đoán ban đầu (ví dụ mục phân quyền thường là do quyền đọc quá rộng chứ không phải cho phép ghi), nên phải xem SCA kiểm tra bằng lệnh nào.
- Không phải mục nào Failed cũng nên sửa. Một số khuyến nghị CIS xung đột với mục đích lab (tấn công mô phỏng, quản lý từ xa). Quyết định bỏ qua có lý do cũng là một phần của đánh giá rủi ro.

### Trạng thái hiện tại
- SCA Ubuntu: đã sửa 5 mục (28538, 28539, 28626, 28627, 28634) và SCA Windows: đã sửa 3 mục (15585, 15607, 15608)
