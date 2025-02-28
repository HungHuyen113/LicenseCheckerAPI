#!/bin/bash

set -e  # Dừng script nếu có lỗi

# ===============================
# 🔹 CẤU HÌNH THÔNG TIN VPS & MYSQL
# ===============================
USERNAME="root"
PROJECT_DIR="/root/LicenseCheckerAPI"
SERVICE_NAME="licenseapi.service"
MYSQL_ROOT_PASSWORD="Bui1610@hung"
MYSQL_USER="apiuser"
MYSQL_PASSWORD="Bui1610@hung"
MYSQL_DATABASE="license_db"

echo "🚀 Bắt đầu **xóa toàn bộ cài đặt cũ**"

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
rm -rf $PROJECT_DIR || true

echo "❌ Xóa dịch vụ API cũ..."
sudo systemctl stop $SERVICE_NAME || true
sudo systemctl disable $SERVICE_NAME || true
sudo rm -f /etc/systemd/system/$SERVICE_NAME
sudo systemctl daemon-reload

echo "🚀 Bắt đầu cài đặt server License API..."

# ===============================
# 1️⃣ CẬP NHẬT VPS VÀ CÀI ĐẶT GÓI CẦN THIẾT
# ===============================
echo "🔹 Cập nhật hệ thống..."
sudo apt update && sudo apt upgrade -y

echo "🔹 Cài đặt các gói cơ bản..."
sudo apt install -y wget curl git ufw nano || (echo "❌ Lỗi khi cài đặt gói cơ bản" && exit 1)

# ===============================
# 2️⃣ CÀI ĐẶT MYSQL SERVER
# ===============================
echo "🔹 Cài đặt MySQL Server..."
sudo apt install mysql-server -y || (echo "❌ Lỗi khi cài đặt MySQL" && exit 1)
sudo systemctl start mysql
sudo systemctl enable mysql

# Kiểm tra MySQL có chạy không
if ! systemctl is-active --quiet mysql; then
    echo "❌ MySQL chưa khởi động. Đang khởi động lại..."
    sudo systemctl start mysql
fi

echo "🔹 Xóa database cũ nếu tồn tại..."
mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "DROP DATABASE IF EXISTS ${MYSQL_DATABASE};"

echo "🔹 Tạo database mới..."
mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "
CREATE DATABASE ${MYSQL_DATABASE} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;"

# Cho phép MySQL truy cập từ xa
echo "🔹 Mở MySQL cho truy cập từ xa..."
sudo sed -i "s/bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf
sudo systemctl restart mysql

# ===============================
# 3️⃣ MỞ CỔNG TƯỜNG LỬA
# ===============================
echo "🔹 Mở cổng cần thiết..."
for port in 22 3306 5000; do
    if ! sudo ufw status | grep -q "$port/tcp"; then
        sudo ufw allow $port/tcp
    fi
done
echo "y" | sudo ufw enable
sudo ufw reload

# ===============================
# 4️⃣ CÀI ĐẶT .NET 7
# ===============================
echo "🔹 Cài đặt .NET 7..."
wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt update
sudo apt install -y dotnet-sdk-7.0 || (echo "❌ Lỗi khi cài đặt .NET SDK" && exit 1)

# ===============================
# 5️⃣ CLONE CODE TỪ GITHUB
# ===============================
echo "🔹 Tải lại dự án từ GitHub..."
if [ -d "$PROJECT_DIR" ]; then
    echo "🔹 Dự án đã tồn tại. Đang cập nhật..."
    cd $PROJECT_DIR
    git reset --hard
    git pull || (echo "❌ Lỗi khi pull từ GitHub" && exit 1)
else
    git clone https://github.com/HungHuyen113/LicenseCheckerAPI.git $PROJECT_DIR
fi
cd $PROJECT_DIR

# ===============================
# 6️⃣ XÂY DỰNG & CHẠY API
# ===============================
echo "🔹 Xây dựng API..."
dotnet build --configuration Release

# ===============================
# 7️⃣ TẠO SERVICE CHẠY API
# ===============================
echo "🔹 Tạo service để server tự động chạy khi VPS khởi động..."
sudo tee /etc/systemd/system/$SERVICE_NAME > /dev/null <<EOF
[Unit]
Description=License API Service
After=network.target

[Service]
ExecStart=/usr/bin/dotnet $PROJECT_DIR/bin/Release/net7.0/LicenseCheckerAPI.dll
WorkingDirectory=$PROJECT_DIR
Restart=always
User=$USERNAME
Environment=DOTNET_CLI_HOME=/tmp
Environment=DOTNET_NOLOGO=1

[Install]
WantedBy=multi-user.target
EOF

# Kích hoạt service
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME
sudo systemctl restart $SERVICE_NAME

echo "✅ Server License API đã chạy thành công trên cổng 5000!"
