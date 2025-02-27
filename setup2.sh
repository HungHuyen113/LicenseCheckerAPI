#!/bin/bash

set -e  # Dừng script nếu có lỗi

echo "🚀 Bắt đầu **xóa toàn bộ cài đặt cũ** và cài đặt server License API mới..."

# ===============================
# 🛑  XÓA CÁC CÀI ĐẶT CŨ
# ===============================
echo "❌ Gỡ bỏ MySQL Server..."
sudo systemctl stop mysql || true
sudo apt-get remove --purge -y mysql-server mysql-client mysql-common mysql-server-core-* mysql-client-core-* || true
sudo rm -rf /var/lib/mysql /etc/mysql
sudo apt-get autoremove -y
sudo apt-get autoclean

echo "❌ Gỡ bỏ .NET SDK..."
sudo apt-get remove --purge -y dotnet-sdk-* aspnetcore-* || true
sudo rm -rf /root/.dotnet
sudo rm -rf /usr/share/dotnet
sudo rm -rf /etc/apt/sources.list.d/microsoft-prod.list
sudo apt-get autoremove -y
sudo apt-get autoclean

echo "❌ Xóa thư mục API cũ..."
rm -rf /root/LicenseCheckerAPI || true

echo "❌ Xóa dịch vụ API cũ..."
sudo systemctl stop licenseapi.service || true
sudo systemctl disable licenseapi.service || true
sudo rm -f /etc/systemd/system/licenseapi.service
sudo systemctl daemon-reload

# ===============================
# 1️⃣ CẬP NHẬT VPS VÀ CÀI ĐẶT GÓI CẦN THIẾT
# ===============================
echo "🔹 Cập nhật hệ thống..."
sudo apt update && sudo apt upgrade -y

echo "🔹 Cài đặt các gói cơ bản..."
sudo apt install -y wget curl git ufw nano

# ===============================
# 2️⃣ CÀI ĐẶT MYSQL SERVER
# ===============================
MYSQL_PASSWORD="Bui1610@hung"

echo "🔹 Cài đặt MySQL Server..."
sudo apt install mysql-server -y
sudo systemctl start mysql
sudo systemctl enable mysql

echo "🔹 Cấu hình MySQL..."
sudo mysql -u root -e "
DROP DATABASE IF EXISTS license_db;
CREATE DATABASE license_db;
CREATE USER IF NOT EXISTS 'apiuser'@'%' IDENTIFIED WITH mysql_native_password BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON license_db.* TO 'apiuser'@'%';
FLUSH PRIVILEGES;"

# Cho phép MySQL truy cập từ xa
echo "🔹 Mở MySQL cho truy cập từ xa..."
sudo sed -i "s/bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf
sudo systemctl restart mysql

# ===============================
# 3️⃣ CÀI ĐẶT .NET 7
# ===============================
echo "🔹 Cài đặt .NET 7..."
wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt update
sudo apt install -y dotnet-sdk-7.0 aspnetcore-runtime-7.0 dotnet-runtime-7.0

# Cấu hình lại PATH để nhận diện dotnet
export DOTNET_ROOT=/usr/share/dotnet
export PATH="/root/.dotnet/tools:/usr/share/dotnet:$PATH"

echo 'export DOTNET_ROOT=/usr/share/dotnet' >> /root/.bashrc
echo 'export PATH="/root/.dotnet/tools:/usr/share/dotnet:$PATH"' >> /root/.bashrc
source /root/.bashrc

# Kiểm tra lại .NET
if ! dotnet --info; then
    echo "❌ .NET chưa được nhận diện! Kiểm tra lại cài đặt."
    exit 1
fi

# ===============================
# 4️⃣ CLONE CODE TỪ GITHUB
# ===============================
echo "🔹 Tải lại dự án từ GitHub..."
cd /root
git clone https://github.com/HungHuyen113/LicenseCheckerAPI.git || true
cd /root/LicenseCheckerAPI

echo "🔹 Kiểm tra merge conflict..."
grep -rn "<<<<<<<" . && echo "❌ Phát hiện xung đột merge! Hãy sửa trước khi tiếp tục." && exit 1

# ===============================
# 5️⃣ CÀI ĐẶT .NET & ENTITY FRAMEWORK CORE
# ===============================
echo "🔹 Cài đặt các package .NET..."
dotnet restore
dotnet tool install --global dotnet-ef --version 7.0.14
export PATH="/root/.dotnet/tools:$PATH"

# ===============================
# 6️⃣ CHẠY DATABASE MIGRATION
# ===============================
echo "🔹 Kiểm tra migration..."
if ! dotnet ef migrations list; then
    echo "⚠️ Chưa có migration, tạo mới..."
    dotnet ef migrations add InitialMigration
fi
dotnet ef database update || (echo "❌ Lỗi khi chạy database migration" && exit 1)

# ===============================
# 7️⃣ CHẠY SERVER API TỰ ĐỘNG
# ===============================
echo "🔹 Tạo service để server tự động chạy khi VPS khởi động..."
sudo systemctl daemon-reload
sudo systemctl enable licenseapi.service
sudo systemctl restart licenseapi.service

echo "✅ Server License API đã chạy thành công trên cổng 5000!"
