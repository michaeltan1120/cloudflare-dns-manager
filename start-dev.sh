#!/bin/bash

# Cloudflare DNS Manager 开发环境启动脚本

set -e

echo "🚀 启动 Cloudflare DNS Manager 开发环境..."

# 检查是否在项目根目录
if [ ! -d "server" ] || [ ! -d "client" ]; then
    echo "❌ 请在项目根目录运行此脚本"
    exit 1
fi

# 检查环境配置
if [ ! -f ".env" ]; then
    echo "⚠️  未找到 .env 文件，正在创建..."
    cp .env.example .env
    echo "📝 请编辑 .env 文件设置您的 Cloudflare API Token:"
    echo "   nano .env"
    echo ""
    read -p "按 Enter 继续，或 Ctrl+C 退出去配置 .env 文件..."
fi

# 检查依赖是否已安装
echo "📦 检查依赖..."

if [ ! -d "server/node_modules" ]; then
    echo "📦 安装后端依赖..."
    cd server
    npm install
    cd ..
fi

if [ ! -d "client/node_modules" ]; then
    echo "📦 安装前端依赖..."
    cd client
    npm install
    cd ..
fi

# 检查端口占用
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo "⚠️  端口 $port 已被占用"
        return 1
    fi
    return 0
}

echo "🔍 检查端口占用..."
if ! check_port 3005; then
    echo "❌ 后端端口 3005 被占用，请停止占用该端口的进程"
    echo "   查看占用进程: lsof -i :3005"
    exit 1
fi

if ! check_port 5173; then
    echo "⚠️  前端端口 5173 被占用，Vite 将自动选择其他端口"
fi

# 创建日志目录
mkdir -p logs

echo "🎯 启动服务..."
echo "📍 后端服务将运行在: http://localhost:3005"
echo "📍 前端服务将运行在: http://localhost:5173 (或其他可用端口)"
echo ""

# 启动后端服务
echo "🔧 启动后端服务..."
cd server
npm start > ../logs/backend.log 2>&1 &
BACKEND_PID=$!
cd ..

# 等待后端启动
echo "⏳ 等待后端服务启动..."
sleep 3

# 检查后端是否启动成功
if ! kill -0 $BACKEND_PID 2>/dev/null; then
    echo "❌ 后端服务启动失败，请检查日志:"
    cat logs/backend.log
    exit 1
fi

# 测试后端连接
if curl -s http://localhost:3005/api/health >/dev/null 2>&1; then
    echo "✅ 后端服务启动成功"
else
    echo "⚠️  后端服务可能未完全启动，请稍后检查"
    echo "   可以手动测试: curl http://localhost:3005/api/health"
fi

# 启动前端服务
echo "🎨 启动前端服务..."
cd client
npm run dev > ../logs/frontend.log 2>&1 &
FRONTEND_PID=$!
cd ..

# 等待前端启动
echo "⏳ 等待前端服务启动..."
sleep 5

# 检查前端是否启动成功
if ! kill -0 $FRONTEND_PID 2>/dev/null; then
    echo "❌ 前端服务启动失败，请检查日志:"
    cat logs/frontend.log
    kill $BACKEND_PID 2>/dev/null
    exit 1
fi

echo "✅ 前端服务启动成功"

# 保存进程ID
echo $BACKEND_PID > logs/backend.pid
echo $FRONTEND_PID > logs/frontend.pid

echo ""
echo "🎉 开发环境启动完成！"
echo ""
echo "📋 服务信息:"
echo "   后端 API: http://localhost:3005"
echo "   前端界面: 请查看上方 Vite 输出的 URL"
echo ""
echo "📝 有用的命令:"
echo "   查看后端日志: tail -f logs/backend.log"
echo "   查看前端日志: tail -f logs/frontend.log"
echo "   停止服务: ./stop-dev.sh"
echo ""
echo "💡 提示: 按 Ctrl+C 不会停止后台服务，请使用 ./stop-dev.sh 停止"
echo ""
echo "🌐 现在可以在浏览器中访问应用了！"