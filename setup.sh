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

echo "🔹 Xóa sạch .NET cũ..."
sudo apt-get remove --purge -y dotnet-sdk-* aspnetcore-* || true
sudo rm -rf $HOME/.dotnet
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
MYSQL_PASSWORD="Bui1610@hung"  # ⚠️ Thay bằng mật khẩu mạnh hơn!

echo "🔹 Cài đặt MySQL Server..."
sudo apt install mysql-server -y
sudo systemctl start mysql
sudo systemctl enable mysql

# Kiểm tra MySQL có đang chạy không
echo "🔹 Kiểm tra trạng thái MySQL..."
sudo systemctl status mysql --no-pager

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
# 3️⃣ TẠO BẢNG `UpdateInfo` TRONG MYSQL
# ===============================
echo "🔹 Tạo bảng UpdateInfo..."
sudo mysql -u root -e "
USE license_db;
CREATE TABLE IF NOT EXISTS UpdateInfo (
    Id INT AUTO_INCREMENT PRIMARY KEY,
    UpdateAvailable ENUM('yes', 'no') NOT NULL DEFAULT 'no',
    DownloadLink VARCHAR(255) NOT NULL DEFAULT '',
    UpdateMessage TEXT NOT NULL,  -- ❌ Bỏ DEFAULT để tránh lỗi
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
INSERT IGNORE INTO UpdateInfo (Id, UpdateAvailable, DownloadLink, UpdateMessage) 
VALUES (1, 'no', '', 'Không có bản cập nhật nào.');
"

# ===============================
# 4️⃣ MỞ CỔNG TƯỜNG LỬA
# ===============================
echo "🔹 Mở cổng cần thiết..."
sudo ufw allow 22/tcp || echo "Cổng SSH (22) đã mở"
sudo ufw allow 3306/tcp || echo "Cổng MySQL (3306) đã mở"
sudo ufw allow 5000/tcp || echo "Cổng API (5000) đã mở"
echo "y" | sudo ufw enable  # ✅ Tự động xác nhận kích hoạt tường lửa
sudo ufw reload

# ===============================
# 5️⃣ CÀI ĐẶT .NET 7
# ===============================
echo "🔹 Cài đặt .NET 7..."
wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt update
sudo apt install -y dotnet-sdk-7.0

# ===============================
# 6️⃣ CLONE CODE TỪ GITHUB
# ===============================
echo "🔹 Tải lại dự án từ GitHub..."
cd /root
git clone https://github.com/HungHuyen113/LicenseCheckerAPI.git
cd /root/LicenseCheckerAPI

# ===============================
# 7️⃣ CÀI ĐẶT .NET & ENTITY FRAMEWORK CORE
# ===============================
echo "🔹 Cài đặt các package .NET..."
dotnet restore
dotnet tool install --global dotnet-ef --version 7.0.14
export PATH="/root/.dotnet/tools:$PATH"

# ===============================
# 8️⃣ CHẠY DATABASE MIGRATION
# ===============================
echo "🔹 Kiểm tra migration..."
if dotnet ef migrations list | grep -q "No migrations"; then
    echo "⚠️ Chưa có migration, tạo mới..."
    dotnet ef migrations add InitialMigration
fi
dotnet ef database update || (echo "❌ Lỗi khi chạy database migration" && exit 1)

# ===============================
# 9️⃣ CHẠY SERVER API TỰ ĐỘNG
# ===============================
echo "🔹 Tạo service để server tự động chạy khi VPS khởi động..."
sudo systemctl daemon-reload
sudo systemctl enable licenseapi.service
sudo systemctl restart licenseapi.service

echo "✅ Server License API đã chạy thành công trên cổng 5000!"
