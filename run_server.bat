@echo off
chcp 65001 >nul
title REG MOD STUDIO SERVER - MEONXT CONTROLLER [Port 5678]
color 0B

echo ===============================================================================
echo            ⚡ REG MOD PRO STUDIO - SERVER CONTROLLER & FLASK BACKEND ⚡
echo                           Tác giả: CheatiOS Vip
echo ===============================================================================
echo.
echo  [*] Địa chỉ lắng nghe: 0.0.0.0:5678
echo  [*] VPS IP           : http://103.238.234.204:5678
echo  [*] Localhost        : http://127.0.0.1:5678
echo  [*] Trang Quản Trị   : http://103.238.234.204:5678/meonxt
echo  [*] Mật khẩu Admin   : 222007
echo  [*] Trạng thái Quyền : Role 0 = Free (Cache) ^| Role 1 = VIP (Shader)
echo.
echo ===============================================================================
echo  [+] Đang khởi động hệ thống Backend Flask Server...
echo.

python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] LỖI: Không tìm thấy Python trên máy tính. Vui lòng cài đặt Python và thử lại!
    echo.
    pause
    exit /b 1
)

python app.py

if %errorlevel% neq 0 (
    echo.
    echo [!] Server đã dừng hoặc gặp sự cố.
)

echo.
echo Nhấn phím bất kỳ để thoát...
pause >nul
