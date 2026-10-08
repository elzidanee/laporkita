@echo off
set "ANDROID_HOME=%LOCALAPPDATA%\Android\Sdk"
set "ANDROID_SDK_ROOT=%LOCALAPPDATA%\Android\Sdk"
set "PATH=%PATH%;%LOCALAPPDATA%\Android\Sdk\platform-tools;%LOCALAPPDATA%\Android\Sdk\emulator"

echo ========================================
echo   APPIUM SERVER UNTUK LAPORKITA
echo ========================================
echo ANDROID_HOME: %ANDROID_HOME%
echo Menjalankan Appium di http://127.0.0.1:4723...
echo Biarkan jendela ini tetap terbuka selama testing!
echo ----------------------------------------

appium
