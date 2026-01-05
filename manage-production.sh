#!/bin/bash

# Cloudflare DNS Manager 生产环境管理脚本
# 用于管理 systemd 服务

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 服务名称
BACKEND_SERVICE="cloudflare-dns-backend"
FRONTEND_SERVICE="cloudflare-dns-frontend"

# 检查是否为root用户或有sudo权限
check_sudo() {
    if ! sudo -n true 2>/dev/null; then
        echo -e "${RED}❌ 此脚本需要sudo权限来管理systemd服务${NC}"
        exit 1
    fi
}

# 检查服务是否存在
check_service_exists() {
    local service=$1
    if ! systemctl list-unit-files | grep -q "^$service.service"; then
        echo -e "${RED}❌ 服务 $service 不存在${NC}"
        echo -e "${YELLOW}💡 请先运行 ./deploy.sh 并选择生产环境模式${NC}"
        return 1
    fi
    return 0
}

# 获取服务状态
get_service_status() {
    local service=$1
    if systemctl is-active --quiet $service; then
        echo -e "${GREEN}🟢 运行中${NC}"
    elif systemctl is-enabled --quiet $service; then
        echo -e "${YELLOW}🟡 已启用但未运行${NC}"
    else
        echo -e "${RED}🔴 已停止${NC}"
    fi
}

# 显示服务状态
show_status() {
    echo -e "${BLUE}📊 服务状态:${NC}"
    echo ""
    
    if check_service_exists $BACKEND_SERVICE; then
        echo -n "后端服务 ($BACKEND_SERVICE): "
        get_service_status $BACKEND_SERVICE
    fi
    
    if check_service_exists $FRONTEND_SERVICE; then
        echo -n "前端服务 ($FRONTEND_SERVICE): "
        get_service_status $FRONTEND_SERVICE
    fi
    
    echo ""
    echo -e "${BLUE}🌐 访问地址:${NC}"
    echo "前端: http://localhost:5173"
    echo "后端: http://localhost:3005"
}

# 启动服务
start_services() {
    echo -e "${BLUE}🚀 启动生产环境服务...${NC}"
    
    if check_service_exists $BACKEND_SERVICE; then
        sudo systemctl start $BACKEND_SERVICE
        echo -e "${GREEN}✅ 后端服务已启动${NC}"
    fi
    
    if check_service_exists $FRONTEND_SERVICE; then
        sudo systemctl start $FRONTEND_SERVICE
        echo -e "${GREEN}✅ 前端服务已启动${NC}"
    fi
    
    sleep 2
    show_status
}

# 停止服务
stop_services() {
    echo -e "${BLUE}⏹️  停止生产环境服务...${NC}"
    
    if check_service_exists $BACKEND_SERVICE; then
        sudo systemctl stop $BACKEND_SERVICE
        echo -e "${GREEN}✅ 后端服务已停止${NC}"
    fi
    
    if check_service_exists $FRONTEND_SERVICE; then
        sudo systemctl stop $FRONTEND_SERVICE
        echo -e "${GREEN}✅ 前端服务已停止${NC}"
    fi
}

# 重启服务
restart_services() {
    echo -e "${BLUE}🔄 重启生产环境服务...${NC}"
    
    if check_service_exists $BACKEND_SERVICE; then
        sudo systemctl restart $BACKEND_SERVICE
        echo -e "${GREEN}✅ 后端服务已重启${NC}"
    fi
    
    if check_service_exists $FRONTEND_SERVICE; then
        sudo systemctl restart $FRONTEND_SERVICE
        echo -e "${GREEN}✅ 前端服务已重启${NC}"
    fi
    
    sleep 2
    show_status
}

# 查看日志
show_logs() {
    echo -e "${BLUE}📋 选择要查看的日志:${NC}"
    echo "1) 后端服务日志"
    echo "2) 前端服务日志"
    echo "3) 后端系统日志"
    echo "4) 前端系统日志"
    echo "5) 应用日志文件"
    read -p "请选择 (1-5): " log_choice
    
    case $log_choice in
        1)
            if check_service_exists $BACKEND_SERVICE; then
                echo -e "${BLUE}📋 后端服务日志 (按 Ctrl+C 退出):${NC}"
                sudo journalctl -u $BACKEND_SERVICE -f
            fi
            ;;
        2)
            if check_service_exists $FRONTEND_SERVICE; then
                echo -e "${BLUE}📋 前端服务日志 (按 Ctrl+C 退出):${NC}"
                sudo journalctl -u $FRONTEND_SERVICE -f
            fi
            ;;
        3)
            if check_service_exists $BACKEND_SERVICE; then
                echo -e "${BLUE}📋 后端系统日志 (最近50行):${NC}"
                sudo journalctl -u $BACKEND_SERVICE -n 50
            fi
            ;;
        4)
            if check_service_exists $FRONTEND_SERVICE; then
                echo -e "${BLUE}📋 前端系统日志 (最近50行):${NC}"
                sudo journalctl -u $FRONTEND_SERVICE -n 50
            fi
            ;;
        5)
            echo -e "${BLUE}📋 应用日志文件:${NC}"
            if [ -f "logs/backend.log" ]; then
                echo "后端日志 (最近20行):"
                tail -n 20 logs/backend.log
                echo ""
            fi
            if [ -f "logs/frontend.log" ]; then
                echo "前端日志 (最近20行):"
                tail -n 20 logs/frontend.log
            fi
            ;;
        *)
            echo -e "${RED}❌ 无效选择${NC}"
            ;;
    esac
}

# 启用/禁用开机自启
manage_autostart() {
    echo -e "${BLUE}🤖 开机自启管理:${NC}"
    echo "1) 启用开机自启"
    echo "2) 禁用开机自启"
    echo "3) 查看自启状态"
    read -p "请选择 (1-3): " autostart_choice
    
    case $autostart_choice in
        1)
            if check_service_exists $BACKEND_SERVICE; then
                sudo systemctl enable $BACKEND_SERVICE
                echo -e "${GREEN}✅ 后端服务开机自启已启用${NC}"
            fi
            if check_service_exists $FRONTEND_SERVICE; then
                sudo systemctl enable $FRONTEND_SERVICE
                echo -e "${GREEN}✅ 前端服务开机自启已启用${NC}"
            fi
            ;;
        2)
            if check_service_exists $BACKEND_SERVICE; then
                sudo systemctl disable $BACKEND_SERVICE
                echo -e "${GREEN}✅ 后端服务开机自启已禁用${NC}"
            fi
            if check_service_exists $FRONTEND_SERVICE; then
                sudo systemctl disable $FRONTEND_SERVICE
                echo -e "${GREEN}✅ 前端服务开机自启已禁用${NC}"
            fi
            ;;
        3)
            if check_service_exists $BACKEND_SERVICE; then
                echo -n "后端服务开机自启: "
                if systemctl is-enabled --quiet $BACKEND_SERVICE; then
                    echo -e "${GREEN}已启用${NC}"
                else
                    echo -e "${RED}已禁用${NC}"
                fi
            fi
            if check_service_exists $FRONTEND_SERVICE; then
                echo -n "前端服务开机自启: "
                if systemctl is-enabled --quiet $FRONTEND_SERVICE; then
                    echo -e "${GREEN}已启用${NC}"
                else
                    echo -e "${RED}已禁用${NC}"
                fi
            fi
            ;;
        *)
            echo -e "${RED}❌ 无效选择${NC}"
            ;;
    esac
}

# 显示帮助信息
show_help() {
    echo -e "${BLUE}📚 Cloudflare DNS Manager 生产环境管理脚本${NC}"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  status    显示服务状态"
    echo "  start     启动所有服务"
    echo "  stop      停止所有服务"
    echo "  restart   重启所有服务"
    echo "  logs      查看服务日志"
    echo "  autostart 管理开机自启"
    echo "  help      显示此帮助信息"
    echo ""
    echo "如果不提供参数，将显示交互式菜单。"
}

# 交互式菜单
show_menu() {
    while true; do
        echo ""
        echo -e "${BLUE}🏭 Cloudflare DNS Manager 生产环境管理${NC}"
        echo "================================="
        echo "1) 查看服务状态"
        echo "2) 启动服务"
        echo "3) 停止服务"
        echo "4) 重启服务"
        echo "5) 查看日志"
        echo "6) 管理开机自启"
        echo "7) 退出"
        echo ""
        read -p "请选择操作 (1-7): " choice
        
        case $choice in
            1) show_status ;;
            2) start_services ;;
            3) stop_services ;;
            4) restart_services ;;
            5) show_logs ;;
            6) manage_autostart ;;
            7) echo -e "${GREEN}👋 再见！${NC}"; exit 0 ;;
            *) echo -e "${RED}❌ 无效选择，请输入 1-7${NC}" ;;
        esac
    done
}

# 主函数
main() {
    # 检查是否在项目根目录
    if [ ! -f "deploy.sh" ] || [ ! -d "server" ] || [ ! -d "client" ]; then
        echo -e "${RED}❌ 请在项目根目录运行此脚本${NC}"
        exit 1
    fi
    
    # 检查sudo权限
    check_sudo
    
    # 根据参数执行相应操作
    case "${1:-}" in
        status) show_status ;;
        start) start_services ;;
        stop) stop_services ;;
        restart) restart_services ;;
        logs) show_logs ;;
        autostart) manage_autostart ;;
        help) show_help ;;
        "") show_menu ;;  # 无参数时显示菜单
        *) echo -e "${RED}❌ 未知选项: $1${NC}"; show_help; exit 1 ;;
    esac
}

# 运行主函数
main "$@"