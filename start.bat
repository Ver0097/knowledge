@echo off
chcp 65001 >nul
echo ====================================
echo 智能知识库问答系统启动脚本
echo ====================================
echo.

REM 检查Python是否安装
python --version >nul 2>&1
if errorlevel 1 (
    echo [错误] 未检测到Python，请先安装Python 3.8+
    pause
    exit /b 1
)

echo [1/3] 检查依赖...
if not exist "venv" (
    echo 创建虚拟环境...
    python -m venv venv
)

echo 激活虚拟环境...
call venv\Scripts\activate.bat

echo 安装依赖包...
chcp 65001 >nul
pip install -r requirements.txt
if errorlevel 1 (
    echo.
    echo [错误] 依赖安装失败，请检查网络连接或手动安装
    echo 手动安装命令: pip install -r requirements.txt
    pause
    exit /b 1
)

echo.
echo [2/3] 创建必要目录...
if not exist "uploads" mkdir uploads
if not exist "static" mkdir static
if not exist "chroma_db" mkdir chroma_db

echo.
echo [3/3] 启动服务...
echo 服务地址: http://127.0.0.1:8000 或 http://localhost:8000
echo 按 Ctrl+C 停止服务
echo.
echo 提示: 如果无法访问，请检查防火墙设置
echo.

python -m app.main
if errorlevel 1 (
    echo.
    echo [错误] 服务启动失败
    echo 请检查依赖是否安装完整: pip install -r requirements.txt
    pause
    exit /b 1
)

pause
