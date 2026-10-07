# Chạy trong PowerShell mở bằng quyền Administrator trên win-client01.

# 1. Ghi nhật ký đăng nhập thành công và thất bại
auditpol /set /subcategory:"Logon" /success:enable /failure:enable

# 2. Ghi nhật ký tạo tiến trình
auditpol /set /subcategory:"Process Creation" /success:enable

# 3. Đưa cả dòng lệnh (command line) vào Event tạo tiến trình
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Audit" /v ProcessCreationIncludeCmdLine_Enabled /t REG_DWORD /d 1 /f

# 4. Bật PowerShell Script Block Logging 
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" /v EnableScriptBlockLogging /t REG_DWORD /d 1 /f
