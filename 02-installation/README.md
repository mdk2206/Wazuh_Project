# 02-installation

## Mục tiêu

Dựng Wazuh server theo mô hình all-in-one (Wazuh server + indexer + dashboard trên cùng một VM), làm nền tảng cho toàn bộ lab SOC. Kết quả cần đạt: dashboard truy cập được, các dịch vụ chạy ổn định, có snapshot sạch để khôi phục.

## Môi trường

| Hạng mục | Giá trị |
| :--- | :--- |
| **Hostname** | `wazuhserver` |
| **Hệ điều hành** | Ubuntu Server 22.04.5 LTS (jammy) |
| **Phiên bản Wazuh** | 4.14.8 |
| **Phương pháp cài** | Installation assistant, chế độ all-in-one (`-a`) |
| **Nền tảng ảo hóa** | `VMWare` |
| **IP mạng lab** | `192.168.56.10` |
| **Ngày cài** | 2026-10-07 |
| **Log cài đặt** | `/var/log/wazuh-install.log` |

## Vì sao chọn All-in-one?

Tài liệu chính thức của Wazuh đưa ra bảng cấu hình khuyến nghị cho triển khai quickstart (server, indexer và dashboard trên cùng một máy): với 1-25 agent là 4 vCPU, 8 GiB RAM, 50 GB lưu trữ cho 90 ngày dữ liệu, và kiểu triển khai này thường đủ cho tới khoảng 100 endpoint. Lab này chỉ có vài máy, nên mình dùng một node là đủ. Triển khai phân tán (distributed) chỉ đáng cân nhắc khi số endpoint lớn hơn nhiều hoặc cần tính sẵn sàng cao.

## Các bước thực hiện

### 1. Chuẩn bị máy ảo

Cài Ubuntu Server 22.04 và cập nhật hệ thống:

<img width="511" height="120" alt="image" src="https://github.com/user-attachments/assets/84998937-7a6e-4b68-90ce-acaac3327050" />


### 2. Kiểm tra và mở rộng dung lượng đĩa

### 3. Cấu hình mạng

Máy chủ Wazuh được thiết lập với 2 Network Adapters riêng biệt nhằm tách bạch luồng traffic internet và mạng nội bộ của lab:

- **Card 1 (`ens33` - NAT):** Nhận IP động qua DHCP để kết nối Internet (dùng để cập nhật OS, tải các gói cài đặt Wazuh và đồng bộ Threat Intelligence).
- **Card 2 (`ens34` - Host-only):** Cấu hình IP tĩnh cố định (`192.168.56.10`) dùng làm mạng nội bộ để giao tiếp, nhận kết nối và thu thập log từ các thiết bị Endpoint Agents.
 
<img width="755" height="100" alt="image" src="https://github.com/user-attachments/assets/6230192b-579c-4ff6-8997-df9dd6e99225" />

### 4. Cài Wazuh bằng installation assistant

Lệnh cài đặt được lấy từ trang Quickstart chính thức của Wazuh:

` curl -sO https://packages.wazuh.com/4.14/wazuh-install.sh && sudo bash ./wazuh-install.sh -a `

<img width="861" height="386" alt="image" src="https://github.com/user-attachments/assets/aee5529c-336a-4364-9a15-398e36b95244" />

** Trích xuất phần tóm tắt cài đặt thành công từ /var/log/wazuh-install.log

### 5. Xác minh cài đặt

#### a. Sau khi hoàn tất quá trình chạy script cài đặt, mình sẽ tiến hành kiểm tra tính toàn vẹn của dịch vụ, các cổng lắng nghe và tài nguyên hệ thống.

Mình sẽ chạy lệnh kiểm tra trạng thái hoạt động của 4 thành phần chính và kiểm tra danh sách cổng đang lắng nghe và mức tiêu thụ tài nguyên bộ nhớ:

<img width="870" height="376" alt="image" src="https://github.com/user-attachments/assets/cbd1b025-b0c7-41ea-ab24-1407088fd9e2" />

#### b. Truy cập và kiểm tra giao diện quản trị Web

Truy cập giao diện quản trị từ trình duyệt máy host thông qua IP card host-only: `https://192.168.56.10`

<img width="1897" height="957" alt="image" src="https://github.com/user-attachments/assets/2d5f3d16-ef08-46c3-a9e8-443c36362200" />


#### 6. Xác minh tổng hợp

- Bốn dịch vụ (wazuh-manager, wazuh-indexer, wazuh-dashboard, filebeat) ở trạng thái active
- Các cổng 443, 1514, 1515, 55000, 9200 đang lắng nghe
- Đăng nhập dashboard thành công
- Agent kết nối thành công và gửi log về (xem 03-log-sources)

##### Tài liệu tham khảo
- Wazuh documentation: Quickstart
