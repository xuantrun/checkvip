@echo off
chcp 65001 >nul
title REG MOD Studio - VPS Controller
echo =======================================================
echo    REG MOD PRO STUDIO - FREE FIRE MODDER ^& CONTROLLER
echo    Server VPS : 103.238.234.204:5678
echo    Admin MEONXT : http://103.238.234.204:5678/meonxt (Pass: 222007)
echo =======================================================
echo.
echo Dang khoi dong Web Server tren http://127.0.0.1:5678...
start "" http://127.0.0.1:5678
python app.py
pause
