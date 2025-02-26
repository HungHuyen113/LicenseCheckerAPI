#!/bin/bash

set -e  # Dừng script nếu có lỗi

echo "🚀 Bắt đầu cài đặt server License API..."

# ===============================
# 1️⃣ CẬP NHẬT VPS VÀ CÀI ĐẶT GÓI CẦN THIẾT
# ===============================
echo "🔹 Cập nhật hệ thống..."
sudo apt update && sudo apt upgrade -y

echo "🔹 Cài đặt các gói cơ bản..."
sudo apt install -y wget curl git ufw nano mysql-server dotnet-sdk-7.0

# ===============================
# 2️⃣ CÀI ĐẶT MYSQL SERVER
# ===============================
MYSQL_PASSWORD="Bui1610@hung"

echo "🔹 Cấu hình MySQL..."
sudo systemctl start mysql
sudo systemctl enable mysql

sudo mysql -u root -e "
CREATE DATABASE IF NOT EXISTS license_db;
CREATE USER IF NOT EXISTS 'apiuser'@'%' IDENTIFIED WITH mysql_native_password BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON license_db.* TO 'apiuser'@'%';
FLUSH PRIVILEGES;"

# Cho phép MySQL truy cập từ xa
echo "🔹 Mở MySQL cho truy cập từ xa..."
sudo sed -i "s/bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf
sudo systemctl restart mysql

# ===============================
# 3️⃣ MỞ CỔNG TƯỜNG LỬA
# ===============================
echo "🔹 Mở cổng cần thiết..."
sudo ufw allow 22/tcp || echo "Cổng SSH (22) đã mở"
sudo ufw allow 3306/tcp || echo "Cổng MySQL (3306) đã mở"
sudo ufw allow 5000/tcp || echo "Cổng API (5000) đã mở"
sudo ufw reload
sudo ufw enable


# ===============================
# 4️⃣ CÀI ĐẶT .NET 7
# ===============================
echo "🔹 Cài đặt .NET 7..."
wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt update
sudo apt install -y dotnet-sdk-7.0

# ===============================
# 5️⃣ CLONE CODE TỪ GITHUB
# ===============================
echo "🔹 Tải lại dự án từ GitHub..."
cd /root

if [ ! -d "/root/LicenseCheckerAPI" ]; then
  git clone https://github.com/HungHuyen113/LicenseCheckerAPI.git || (echo "❌ Lỗi khi clone GitHub" && exit 1)
else
  cd /root/LicenseCheckerAPI
  git pull || (echo "❌ Lỗi khi pull từ GitHub" && exit 1)
fi

cd /root/LicenseCheckerAPI

# ===============================
# 6️⃣ CÀI ĐẶT .NET & ENTITY FRAMEWORK CORE
# ===============================
echo "🔹 Cài đặt các package .NET..."
dotnet restore
dotnet tool install --global dotnet-ef --version 7.0.14
export PATH="/root/.dotnet/tools:$PATH"

# ===============================
# 7️⃣ CHẠY DATABASE MIGRATION
# ===============================
echo "🔹 Chạy database migration..."
dotnet ef database update || (echo "❌ Lỗi khi chạy database migration" && exit 1)

# ===============================
# 8️⃣ CHẠY SERVER API TỰ ĐỘNG
# ===============================
echo "🔹 Tạo service để server tự động chạy khi VPS khởi động..."
sudo tee /etc/systemd/system/licenseapi.service > /dev/null <<EOF
[Unit]
Description=License API Service
After=network.target

[Service]
ExecStart=/usr/bin/dotnet /root/LicenseCheckerAPI/bin/Debug/net7.0/LicenseCheckerAPI.dll
WorkingDirectory=/root/LicenseCheckerAPI
Restart=always
User=root
Environment=DOTNET_CLI_HOME=/tmp
Environment=DOTNET_NOLOGO=1

[Install]
WantedBy=multi-user.target
EOF

# Kích hoạt service
sudo systemctl daemon-reload
sudo systemctl enable licenseapi.service
sudo systemctl restart licenseapi.service

echo "✅ Server License API đã chạy thành công trên cổng 5000!"
