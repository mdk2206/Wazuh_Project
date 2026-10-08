#!/usr/bin/env bash
# Các bước khắc phục SCA đã thực hiện trên UbuntuWeb (policy CIS Ubuntu 22.04).
# Trước khi sửa: chụp snapshot và sao lưu.
 
sudo mkdir -p /root/sca-backup
sudo cp -a /etc/issue /etc/issue.net /etc/crontab /etc/ssh/sshd_config /root/sca-backup/

# --- Ghi trạng thái trước khi sửa ---
sudo stat -c '%a %U:%G %n' /etc/crontab /etc/cron.hourly /etc/ssh/sshd_config
cat /etc/issue /etc/issue.net
 
# --- 28626 /etc/crontab | 28627 /etc/cron.hourly | 28634 /etc/ssh/sshd_config ---
sudo chown root:root /etc/crontab /etc/cron.hourly /etc/ssh/sshd_config
sudo chmod og-rwx /etc/crontab /etc/cron.hourly /etc/ssh/sshd_config
sudo stat -c '%a %U:%G %n' /etc/crontab /etc/cron.hourly /etc/ssh/sshd_config
 
# Kiểm tra SSH vẫn ổn
sudo sshd -t
 
# --- 28538, 28539 Banner cảnh báo đăng nhập ---
# echo "Authorized users only. All activity may be monitored and reported." | sudo tee /etc/issue /etc/issue.net
 
