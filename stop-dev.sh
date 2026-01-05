#!/bin/bash

# Cloudflare DNS Manager 开发环境停止脚本

echo "🛑 停止 Cloudflare DNS Manager 开发环境..."

# 检查是否在项目根目录
if [ ! -d "logs" ]; then
    echo "❌ 未找到 logs 目录，请在项目根目录运行此脚本"
    exit 1
fi

# 停止后端服务
if [ -f "logs/backend.pid" ]; then
    BACKEND_PID=$(cat logs/backend.pid)
    if kill -0 $BACKEND_PID 2>/dev/null; then
        echo "🔧 停止后端服务 (PID: $BACKEND_PID)..."
        kill $BACKEND_PID
        sleep 2
        if kill -0 $BACKEND_PID 2>/dev/null; then
            echo "⚠️  强制停止后端服务..."
            kill -9 $BACKEND_PID
        fi
        echo "✅ 后端服务已停止"
    else
        echo "ℹ️  后端服务未运行"
    fi
    rm -f logs/backend.pid
else
    echo "ℹ️  未找到后端服务 PID 文件"
fi

# 停止前端服务
if [ -f "logs/frontend.pid" ]; then
    FRONTEND_PID=$(cat logs/frontend.pid)
    if kill -0 $FRONTEND_PID 2>/dev/null; then
        echo "🎨 停止前端服务 (PID: $FRONTEND_PID)..."
        kill $FRONTEND_PID
        sleep 2
        if kill -0 $FRONTEND_PID 2>/dev/null; then
            echo "⚠️  强制停止前端服务..."
            kill -9 $FRONTEND_PID
        fi
        echo "✅ 前端服务已停止"
    else
        echo "ℹ️  前端服务未运行"
    fi
    rm -f logs/frontend.pid
else
    echo "ℹ️  未找到前端服务 PID 文件"
fi

# 清理可能残留的进程
echo "🧹 清理残留进程..."

# 查找并停止可能的 Node.js 进程
NODE_PIDS=$(pgrep -f "node.*server.js|npm.*start|vite" 2>/dev/null || true)
if [ ! -z "$NODE_PIDS" ]; then
    echo "🔍 发现可能的残留进程，正在清理..."
    for pid in $NODE_PIDS; do
        if kill -0 $pid 2>/dev/null; then
            # 检查进程是否在当前项目目录下
            PROC_CWD=$(pwdx $pid 2>/dev/null | cut -d' ' -f2- || echo "")
            if [[ "$PROC_CWD" == *"$(pwd)"* ]]; then
                echo "  停止进程 $pid (工作目录: $PROC_CWD)"
                kill $pid 2>/dev/null || true
            fi
        fi
    done
    sleep 1
fi

# 检查端口占用
check_port_usage() {
    local port=$1
    local service=$2
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo "⚠️  端口 $port ($service) 仍被占用"
        echo "   查看占用进程: lsof -i :$port"
        return 1
    fi
    return 0
}

echo "🔍 检查端口状态..."
if check_port_usage 3005 "后端"; then
    echo "✅ 端口 3005 已释放"
fi

if check_port_usage 5173 "前端"; then
    echo "✅ 端口 5173 已释放"
fi

echo ""
echo "🎉 开发环境已停止！"
echo ""
echo "📝 有用的信息:"
echo "   日志文件保留在 logs/ 目录中"
echo "   重新启动: ./start-dev.sh"
echo "   查看最近的日志:"
echo "     tail logs/backend.log"
echo "     tail logs/frontend.log"
echo ""