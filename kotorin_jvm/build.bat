@echo off
setlocal

REM --- 出力 ---
set OUT=out
set JAR=kotorin_jvm.jar

if not exist %OUT% (
    mkdir %OUT%
)

echo [BUILD] Kotlin compile (with runtime)...

kotlinc src\Main.kt -include-runtime -d %JAR%

if errorlevel 1 (
    echo [ERROR] Compile failed
    exit /b 1
)

echo [OK] Build success: %JAR%
endlocal
