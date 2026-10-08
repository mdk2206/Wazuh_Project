# Các bước khắc phục SCA đã thực hiện trên win-client01 (policy CIS Windows).
# Trước khi sửa: chụp snapshot và sao lưu trạng thái dịch vụ.

New-Item -Path C:\sca-backup -ItemType Directory -Force
Get-Service | Select-Object Name, Status, StartType | Export-Csv C:\sca-backup\services-before.csv -NoTypeInformation

# --- 15585: MSiSCSI (Microsoft iSCSI Initiator Service) -> Disabled ---
Get-Service MSiSCSI | Select-Object Name, Status, StartType     # trạng thái trước
Stop-Service MSiSCSI -ErrorAction SilentlyContinue
Set-Service -Name MSiSCSI -StartupType Disabled
Get-Service MSiSCSI | Select-Object Name, Status, StartType     # trạng thái sau

# --- 15607: WerSvc (Windows Error Reporting Service) -> Disabled ---
Stop-Service WerSvc -ErrorAction SilentlyContinue
Set-Service -Name WerSvc -StartupType Disabled

# --- 15608: Wecsvc (Windows Event Collector) -> Disabled ---
Stop-Service Wecsvc -ErrorAction SilentlyContinue
Set-Service -Name Wecsvc -StartupType Disabled

# --- Kiểm tra: agent Wazuh vẫn chạy ---
Get-Service MSiSCSI, WerSvc, Wecsvc | Select-Object Name, Status, StartType
Get-Service wazuh | Select-Object Name, Status


# --- Cố ý không sửa ---
# 15595 TermService, 15596 UmRdpService: cần RDP cho kịch bản brute force
# và để quản lý máy lab.
