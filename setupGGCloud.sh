#!/bin/bash

set -e  # Dừng script nếu có lỗi

# ===============================
# 🔹 CẤU HÌNH THÔNG TIN VPS & MYSQL
# ===============================
USERNAME="huyenvu_wru"
PROJECT_DIR="/home/$USERNAME/LicenseCheckerAPI"
SERVICE_NAME="licenseapi.service"
MYSQL_ROOT_PASSWORD="Bui1610@hung"
MYSQL_USER="apiuser"
MYSQL_PASSWORD="Bui1610@hung"
MYSQL_DATABASE="license_db"

# ===============================
# 🛑 XÓA TOÀN BỘ CÀI ĐẶT CŨ
# ===============================
echo "❌ Gỡ bỏ MySQL Server..."
sudo systemctl stop mysql || true
sudo apt-get remove --purge -y mysql-server mysql-client mysql-common mysql-server-core-* mysql-client-core-* || true
sudo rm -rf /var/lib/mysql /etc/mysql
sudo apt-get autoremove -y
sudo apt-get autoclean

echo "❌ Gỡ bỏ .NET SDK..."
sudo apt-get remove --purge -y dotnet-sdk-* aspnetcore-* || true
sudo rm -rf /home/$USERNAME/.dotnet
sudo rm -rf /usr/share/dotnet
sudo apt-get autoremove -y
sudo apt-get autoclean

echo "❌ Xóa thư mục API cũ..."
rm -rf $PROJECT_DIR || true

echo "❌ Xóa dịch vụ API cũ..."
sudo systemctl stop $SERVICE_NAME || true
sudo systemctl disable $SERVICE_NAME || true
sudo rm -f /etc/systemd/system/$SERVICE_NAME
sudo systemctl daemon-reload

echo "🚀 Bắt đầu cài đặt server License API trên Google Cloud VPS..."

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
echo "🔹 Cài đặt MySQL Server..."
sudo apt install mysql-server -y
sudo systemctl start mysql
sudo systemctl enable mysql

echo "🔹 Thiết lập mật khẩu root MySQL..."
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$MYSQL_ROOT_PASSWORD'; FLUSH PRIVILEGES;"

echo "🔹 Xóa database cũ nếu tồn tại..."
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "DROP DATABASE IF EXISTS $MYSQL_DATABASE;"

echo "🔹 Tạo database mới..."
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "
CREATE DATABASE $MYSQL_DATABASE CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED WITH mysql_native_password BY '$MYSQL_PASSWORD';
GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'%';
FLUSH PRIVILEGES;"

# Cho phép MySQL truy cập từ xa
echo "🔹 Mở MySQL cho truy cập từ xa..."
sudo sed -i "s/bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf
sudo systemctl restart mysql

# ===============================
# 3️⃣ MỞ CỔNG TƯỜNG LỬA GOOGLE CLOUD
# ===============================
echo "🔹 Mở cổng cần thiết..."
sudo ufw allow 22/tcp
sudo ufw allow 3306/tcp
sudo ufw allow 5000/tcp
echo "y" | sudo ufw enable
sudo ufw reload

# ===============================
# 4️⃣ CÀI ĐẶT .NET 7
# ===============================
echo "🔹 Cài đặt .NET 7..."
wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt update
sudo apt install -y dotnet-sdk-7.0

# ===============================
# 5️⃣ CÀI ĐẶT `dotnet-ef` VÀ FIX LỖI
# ===============================
echo "🔹 Kiểm tra và xử lý lỗi dotnet-ef..."

# Đảm bảo thư mục ~/.dotnet/tools tồn tại
sudo -u $USERNAME mkdir -p /home/$USERNAME/.dotnet/tools
sudo -u $USERNAME chown -R $USERNAME:$USERNAME /home/$USERNAME/.dotnet
sudo -u $USERNAME chmod -R u+rwx /home/$USERNAME/.dotnet

# Kiểm tra nếu dotnet-ef chưa tồn tại
if ! sudo -u $USERNAME which dotnet-ef &> /dev/null; then
    echo "❌ dotnet-ef không tìm thấy, cài đặt lại..."
    sudo -u $USERNAME dotnet tool install --global dotnet-ef --version 7.0.14
fi

# Cập nhật PATH
echo 'export PATH="$HOME/.dotnet/tools:$PATH"' | sudo tee -a /home/$USERNAME/.bashrc
source /home/$USERNAME/.bashrc

# ===============================
# 6️⃣ CLONE CODE TỪ GITHUB
# ===============================
echo "🔹 Tải lại dự án từ GitHub..."
cd /home/$USERNAME
git clone https://github.com/HungHuyen113/LicenseCheckerAPI.git || (echo "❌ Lỗi khi clone GitHub" && exit 1)
cd LicenseCheckerAPI
git pull || (echo "❌ Lỗi khi pull từ GitHub" && exit 1)

# ===============================
# 7️⃣ CHẠY MIGRATION DATABASE
# ===============================
echo "🔹 Kiểm tra và sửa lỗi dotnet-ef nếu cần..."
if ! command -v dotnet-ef &> /dev/null; then
    echo "❌ dotnet-ef không tìm thấy, sửa lỗi..."
    export PATH="/home/$USERNAME/.dotnet/tools:$PATH"
    source ~/.bashrc
fi

echo "🔹 Cấp quyền cho dự án..."
sudo chown -R $USERNAME:$USERNAME $PROJECT_DIR
sudo chmod -R u+rwx $PROJECT_DIR

echo "🔹 Tạo migration mới và update database..."
cd $PROJECT_DIR
rm -rf Migrations
dotnet ef migrations add InitialCreate || true
dotnet ef database update

# ===============================
# 8️⃣ TẠO SERVICE CHẠY API TỰ ĐỘNG
# ===============================
echo "🔹 Tạo service để server tự động chạy khi VPS khởi động..."
sudo tee /etc/systemd/system/licenseapi.service > /dev/null <<EOF
[Unit]
Description=License API Service
After=network.target

[Service]
ExecStart=/usr/bin/dotnet /home/$USERNAME/LicenseCheckerAPI/bin/Debug/net7.0/LicenseCheckerAPI.dll
WorkingDirectory=/home/$USERNAME/LicenseCheckerAPI
Restart=always
User=$USERNAME
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
