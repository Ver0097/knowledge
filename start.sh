#!/bin/bash

echo "===================================="
echo "智能知识库问答系统启动脚本"
echo "===================================="
echo ""

# 检查Python是否安装
if ! command -v python3 &> /dev/null; then
    echo "[错误] 未检测到Python，请先安装Python 3.8+"
    exit 1
fi

echo "[1/3] 检查依赖..."
if [ ! -d "venv" ]; then
    echo "创建虚拟环境..."
    python3 -m venv venv
fi

echo "激活虚拟环境..."
source venv/bin/activate

echo "安装依赖包..."
pip install -r requirements.txt -q

echo ""
echo "[2/3] 创建必要目录..."
mkdir -p uploads
mkdir -p static
mkdir -p chroma_db

echo ""
echo "[3/3] 启动服务..."
echo "服务地址: http://localhost:8000"
echo "按 Ctrl+C 停止服务"
echo ""

python app/main.py
