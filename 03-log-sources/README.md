# 03-log-sources
## Mục tiêu
Đưa log từ các máy trong lab về Wazuh server để phân tích. Mỗi nguồn log phải trả lời được ba câu hỏi: thu thập bằng cách nào, dùng để phát hiện hành vi gì, và đã xác minh log về tới dashboard chưa.

## Các Endpoint

| Máy | Hệ điều hành | Tên Agent trên Dashboard | Phiên bản Agent | Trạng thái |
| :--- | :--- | :--- | :--- | :--- |
| **Linux Web Server** | Ubuntu 22.04 | `UbuntuWeb` | `4.14.8` | **Active** |
| **Windows Client** | `Windowns10` | `Win-client1` | `4.14.8` | **Active** |

## Bảng nguồn log

| Nguồn | Máy | Cấu hình | Dùng để phát hiện | Đã xác minh |
| :--- | :--- | :--- | :--- | :--- |
| **SSH (`auth.log`)** | `linux-web01` | Không cần thêm | Brute force, đăng nhập bất thường | **Có** |
| **Apache access/error** | `linux-web01` | `<localfile>`, format `apache` | Quét đường dẫn, SQLi, XSS | **Có** |
| **auditd** | `linux-web01` | `<localfile>`, format `audit` | Sửa file nhạy cảm, lệnh root, tạo user | **Có** |
| **Sysmon** | `win-client01` | `eventchannel` | PowerShell độc hại, persistence | **Có** |
| **Windows Security** | `win-client01` | Mặc định của Agent | Brute force, tạo tài khoản | **Có** |
| **PowerShell Operational** | `win-client01` | `eventchannel` | Script độc hại (Event 4104) | **Có** |


## A. Linux web server (UbuntuWeb)

### A1. Cài Wazuh agent

Mình dùng wizard Agents → Deploy new agent trên dashboard (DEB amd64, server 192.168.56.10, tên agent UbuntuWeb). Wizard sinh sẵn lệnh cài khớp với phiên bản server. Sau khi chạy lệnh, khởi tạo dịch vụ:

<img width="587" height="132" alt="image" src="https://github.com/user-attachments/assets/f3b677ac-6fa8-45aa-b7bb-8460a855d4e2" />

Kiểm tra agent đã kết nối:

<img width="837" height="405" alt="image" src="https://github.com/user-attachments/assets/11b1710a-31e9-46ec-9f6c-5d1777c3b716" />

### A2. SSH

Log SSH nằm trong /var/log/auth.log và nằm sẵn trong cấu hình mặc định của agent, nên không cần thêm gì.

- Sự kiện thử: Từ một máy khác trong mạng lab, mình sẽ SSH vào web server với mật khẩu sai vài lần.

### A3. Apache

Mình sẽ cài đặt Apache, sao lưu cấu hình gốc rồi thêm hai khối ` <localfile>` (xem ossec-localfile.xml):

- Sự kiện thử: Từ máy host mình sẽ truy cập một URL không tồn tại, ví dụ http://192.168.56.30/abc để tạo mã lỗi 404.

### A4. auditd

Mình sẽ dùng auditd để ghi lại thứ mà auth.log và log Apache không có: ai chạy lệnh gì, ai sửa file nhạy cảm.

Cài đặt dịch vụ và kích hoạt khởi động cùng hệ thống:

` sudo apt install -y auditd audispd-plugins `
`sudo systemctl enable --now auditd`

Tạo file cấu hình quy tắc giám sát /etc/audit/rules.d/wazuh.rule (xem ở phần audit-wazuh.rules)

Sau đó mình nạp rule vào kernel và kiểm tra danh sách rules đang hoạt động:

<img width="490" height="515" alt="image" src="https://github.com/user-attachments/assets/99537afa-7053-4c53-8da3-b2485e1ab33e" />

<img width="587" height="138" alt="image" src="https://github.com/user-attachments/assets/8e4ccc4a-c9f8-475b-af2f-9a4e4f2622e0" />

#### Mục đích của từng rule auditd

| Rule | Mục đích | Hành vi tấn công liên quan |
| :--- | :--- | :--- |
| **Theo dõi `/etc/passwd`, `/etc/shadow`** | Phát hiện thêm hoặc thay đổi tài khoản | Tạo tài khoản backdoor, đổi mật khẩu |
| **Theo dõi `/etc/sudoers`** | Phát hiện thay đổi quyền sudo | Cấp quyền sudo trái phép |
| **Theo dõi `/etc/ssh/sshd_config`** | Phát hiện thay đổi cấu hình SSH | Mở lại đăng nhập root, mở đường backdoor |
| **Bắt `execve` của `euid=0`** | Ghi lại các lệnh chạy với quyền root | Post-exploitation |


- Tạo sự kiện để test: sudo useradd testuser01, sudo whoami, sudo userdel testuser01

### A5. Xác minh trên dashboard

Mình sẽ vào Threat intelligence → Threat Hunting → Events để xác minh những sự kiện đã test

| Nguồn | Alert quan sát được |
| :--- | :--- |
| **SSH đăng nhập thất bại** | Rule `2502`, Level `10` |
| **Apache 404** | Rule `31101`, Level `5` |
| **auditd - file nhạy cảm** | Rule `80781`, Level `3` |
| **auditd - lệnh root** | Rule `80792`, Level `3` |


## B. Windows client

### B1. Cài Wazuh agent

Trên dashboard mình vào Agents -> Deploy new agent -> Windows, nhập địa chỉ Wazuh server và tên agent. Wizard sinh lệnh PowerShell, chạy trong PowerShell mở bằng quyền Administrator, rồi khởi động dịch vụ. 

<img width="417" height="138" alt="image" src="https://github.com/user-attachments/assets/1cb06c07-272b-4215-bfed-34896032d032" />

### B2. Cài Sysmon

Sysmon sẽ giúp ghi lại chi tiết hoạt động hệ thống: tạo tiến trình, kết nối mạng, thay đổi registry. Đây là nguồn dữ liệu cốt lõi cho nhiều rule phát hiện.

- Cấu hình: ` sysmonconfig.xml `
- Phiên bản Sysmon: ` v15.15 `

<img width="436" height="150" alt="image" src="https://github.com/user-attachments/assets/bebaafb8-827f-486c-9578-952fb8bdc8f5" />

### B3. Bật audit policy và PowerShell logging

Mặc định, Windows không ghi log chi tiết các dòng lệnh command line được thực thi hay nội dung mã script PowerShell. Để thu thập đủ dữ liệu phục vụ điều tra, chúng ta cần kích hoạt các Policy này thông qua Command Prompt hoặc PowerShell quyền Administrator.

| Thiết lập | Dùng để phát hiện |
| :--- | :--- |
| **Audit Logon** (thành công & thất bại) | Brute force, đăng nhập hệ thống bất thường |
| **Audit Process Creation** | Chuỗi tiến trình đáng ngờ được sinh ra |
| **ProcessCreationIncludeCmdLine_Enabled** | Biết chính xác lệnh nào đã chạy, không chỉ xem tên file `.exe` |
| **PowerShell Script Block Logging** | Script PowerShell độc hại, tải payload, lệnh mã hóa |

#### Các bước thực hiện

- Bật audit policy cho Logon và Process Creation:

<img width="702" height="81" alt="image" src="https://github.com/user-attachments/assets/57e722d2-b78b-441c-9a21-c5a2282a1063" />

- Ghi lại dòng lệnh command line trong event tạo tiến trình và bật PowerShell Script Block Logging:

<img width="856" height="120" alt="image" src="https://github.com/user-attachments/assets/50553345-5936-4ba4-8c80-cdfd48ffcc65" />

- Xác minh cấu hình

<img width="632" height="128" alt="image" src="https://github.com/user-attachments/assets/d2734d0c-ebaa-4c19-947e-6399fedae4f9" />

### B5. Cho agent đọc log Sysmon và PowerShell

Mình sẽ thêm hai khối <localfile> vào bên trong thẻ <ossec_config>. Kênh Security đã nằm trong cấu hình mặc định của agent Windows nên không cần thêm. Sau đó khởi động lại agent:

### B6. Xác minh trên dashboard

| Hành động trên Windows | Alert quan sát được |
| :--- | :--- |
| **Đăng nhập sai mật khẩu vài lần** | Rule `60122`, Level `5` |
| **Mở `cmd.exe `, gõ `net user` (sysmon)** | Rule `92031`, Level `3` |
| **Mở `cmd.exe`, gõ `net user` (Security)** | Rule `67027` Level `3` |
| **Mở PowerShell, chạy `Get-Process`** | Rule `91815` level `4` |

## Cách Wazuh xử lý một dòng log

Phần này chứng minh luồng xử lý của hệ thống: từ một dòng bản ghi thô trên máy trạm , Wazuh Agent gửi về Wazuh Server để bóc tách thành các trường dữ liệu có cấu trúc (decode/parsing) và đối chiếu với bộ luật để sinh cảnh báo tương ứng.

#### 7.1 Log thô (Raw log trên endpoint)

Dòng log thực tế được thu thập qua `journald` từ dịch vụ `sshd` trên máy `UbuntuWeb`:

<img width="1457" height="55" alt="image" src="https://github.com/user-attachments/assets/9e12668c-2e15-4b6d-a5a9-e90c8860f251" />

#### 7.2 Dữ liệu sau khi Wazuh Decode và sinh Alert

<img width="947" height="746" alt="image" src="https://github.com/user-attachments/assets/f463baf1-9e51-42c1-ae31-efa431428be0" />

<img width="947" height="606" alt="image" src="https://github.com/user-attachments/assets/0bd4a9f0-d3db-4fe0-a565-1b1390f663b1" />

| Field (Trường dữ liệu) | Giá trị hiển thị | Ý nghĩa kỹ thuật |
| :--- | :--- | :--- |
| **`agent.name`** | `UbuntuWeb` | Tên endpoint phát sinh sự kiện |
| **`agent.ip`** | `192.168.56.30` | Địa chỉ IP của máy trạm |
| **`decoder.name`** | `sshd` | Bộ giải mã phân tích cú pháp log |
| **`data.srcip`** | `192.168.1.1` | Địa chỉ IP của client thực hiện kết nối SSH |
| **`data.dstuser`** | `khangg` | Tài khoản đích bị nhập sai mật khẩu |
| **`rule.id`** | `2502` | Mã luật: Người dùng nhập sai mật khẩu nhiều hơn 1 lần |
| **`rule.level`** | `10` | Mức độ cảnh báo cao (Multiple authentication failures) |
| **`rule.description`** | `syslog: User missed the password more than one time` | Nội dung mô tả hành vi cảnh báo |
| **`rule.mitre.id`** | `T1110` | Kỹ thuật tấn công theo MITRE ATT&CK (Brute Force) |
| **`rule.mitre.tactic`** | `Credential Access` | Chiến thuật tấn công theo khung MITRE |
| **`rule.groups`** | `syslog, access_control, authentication_failed` | Nhóm phân loại sự kiện trong Wazuh |

### Lưu ý khi đọc log trên dashboard

- Chỉ thấy event đã thành alert: dashboard hiển thị các event khớp rule có level đủ cao. Event khớp rule level 0 vẫn được xử lý nhưng mặc định không hiện. Vì vậy một sự kiện hợp lệ có thể "không thấy" trên dashboard dù log đã về
- Khoảng thời gian: luôn chỉnh time range ở góc trên bên phải, mặc định thường quá rộng hoặc lệch. 
