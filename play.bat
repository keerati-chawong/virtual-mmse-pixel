@echo off
chcp 65001 >nul
rem เปิดเกม Virtual MMSE (Pixel) ด้วย Godot 4.7 — แก้ path ด้านล่างถ้าย้ายไฟล์ Godot
set GODOT=C:\Users\ASUS\Downloads\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64.exe
start "" "%GODOT%" --path "%~dp0"
