#!/bin/bash

# Cloudflare DNS Manager 一键部署脚本
# 适用于 Ubuntu/Debian 和 CentOS/RHEL 系统
# 版本: 2.0
# 更新: 增强迁移支持、自动依赖检查、错误处理

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 显示帮助信息
show_help() {
    echo -e "${BLUE}Cloudflare DNS Manager 部署脚本 v2.0${NC}"
    echo ""
    echo -e "${YELLOW}用法:${NC}"
    echo "  ./deploy.sh [选项]"
    echo ""
    echo -e "${YELLOW}选项:${NC}"
    echo "  -h, --help         显示此帮助信息"
    echo "  -v, --version      显示版本信息"
    echo "  --clean            清理环境（停止服务、删除依赖）"
    echo "  --fix-permissions  修复文件和目录权限"
    echo ""
    echo -e "${YELLOW}功能:${NC}"
    echo "  • 自动检测操作系统和依赖"
    echo "  • 安装 Node.js 和项目依赖"
    echo "  • 配置环境变量和 API Token"
    echo "  • 创建 systemd 服务"
    echo "  • 支持生产和开发环境部署"
    echo "  • 自动设置正确的文件权限"
    echo ""
    echo -e "${YELLOW}示例:${NC}"
    echo "  ./deploy.sh                # 开始部署"
    echo "  ./deploy.sh --clean        # 清理环境"
    echo "  ./deploy.sh --fix-permissions  # 仅修复权限"
}

# 清理环境
clean_environment() {
    log_info "开始清理环境..."
    
    # 停止服务
    if systemctl is-active --quiet cloudflare-dns-backend 2>/dev/null; then
        log_info "停止后端服务..."
        sudo systemctl stop cloudflare-dns-backend
    fi
    
    if systemctl is-active --quiet cloudflare-dns-frontend 2>/dev/null; then
        log_info "停止前端服务..."
        sudo systemctl stop cloudflare-dns-frontend
    fi
    
    # 禁用服务
    sudo systemctl disable cloudflare-dns-backend cloudflare-dns-frontend 2>/dev/null || true
    
    # 删除服务文件
    sudo rm -f /etc/systemd/system/cloudflare-dns-backend.service
    sudo rm -f /etc/systemd/system/cloudflare-dns-frontend.service
    sudo systemctl daemon-reload
    
    # 清理依赖
    if [ -d "server/node_modules" ]; then
        log_info "清理后端依赖..."
        rm -rf server/node_modules server/package-lock.json
    fi
    
    if [ -d "client/node_modules" ]; then
        log_info "清理前端依赖..."
        rm -rf client/node_modules client/package-lock.json client/dist
    fi
    
    # 清理日志
    if [ -d "logs" ]; then
        log_info "清理日志文件..."
        rm -rf logs
    fi
    
    log_success "环境清理完成"
}

# 设置系统权限
setup_permissions() {
    log_info "设置系统文件和目录权限..."
    
    # 检查项目结构
    if [ ! -d "server" ] || [ ! -d "client" ]; then
        log_error "项目结构不完整，请确保在正确的项目根目录运行此脚本"
        exit 1
    fi
    
    # 创建必要的目录
    mkdir -p logs server/data 2>/dev/null || true
    
    # 设置脚本执行权限
    log_info "设置脚本执行权限..."
    chmod +x deploy.sh 2>/dev/null || true
    chmod +x start-dev.sh 2>/dev/null || true
    chmod +x stop-dev.sh 2>/dev/null || true
    chmod +x manage-production.sh 2>/dev/null || true
    
    # 设置配置文件权限（敏感文件）
    log_info "设置配置文件权限..."
    chmod 600 .env 2>/dev/null || true
    chmod 600 .env.example 2>/dev/null || true
    chmod 600 server/accounts.json 2>/dev/null || true
    
    # 设置目录权限
    log_info "设置目录权限..."
    chmod 755 . 2>/dev/null || true
    chmod 755 server 2>/dev/null || true
    chmod 755 client 2>/dev/null || true
    chmod 755 logs 2>/dev/null || true
    chmod 755 server/data 2>/dev/null || true
    chmod 755 client/src 2>/dev/null || true
    chmod 755 client/public 2>/dev/null || true
    chmod 755 client/dist 2>/dev/null || true
    
    # 设置源代码文件权限
    log_info "设置源代码文件权限..."
    find . -name "*.js" -type f -exec chmod 644 {} \; 2>/dev/null || true
    find . -name "*.jsx" -type f -exec chmod 644 {} \; 2>/dev/null || true
    find . -name "*.ts" -type f -exec chmod 644 {} \; 2>/dev/null || true
    find . -name "*.tsx" -type f -exec chmod 644 {} \; 2>/dev/null || true
    find . -name "*.json" -type f -not -path "./server/accounts.json" -exec chmod 644 {} \; 2>/dev/null || true
    find . -name "*.md" -type f -exec chmod 644 {} \; 2>/dev/null || true
    find . -name "*.html" -type f -exec chmod 644 {} \; 2>/dev/null || true
    find . -name "*.css" -type f -exec chmod 644 {} \; 2>/dev/null || true
    find . -name "*.svg" -type f -exec chmod 644 {} \; 2>/dev/null || true
    find . -name "*.png" -type f -exec chmod 644 {} \; 2>/dev/null || true
    find . -name "*.jpg" -type f -exec chmod 644 {} \; 2>/dev/null || true
    find . -name "*.jpeg" -type f -exec chmod 644 {} \; 2>/dev/null || true
    find . -name "*.gif" -type f -exec chmod 644 {} \; 2>/dev/null || true
    
    # 设置配置文件权限
    log_info "设置配置文件权限..."
    find . -name "*.config.js" -type f -exec chmod 644 {} \; 2>/dev/null || true
    find . -name "*.config.ts" -type f -exec chmod 644 {} \; 2>/dev/null || true
    find . -name ".gitignore" -type f -exec chmod 644 {} \; 2>/dev/null || true
    find . -name "package.json" -type f -exec chmod 644 {} \; 2>/dev/null || true
    find . -name "package-lock.json" -type f -exec chmod 644 {} \; 2>/dev/null || true
    
    # 确保日志文件权限
    log_info "设置日志文件权限..."
    touch logs/backend.log logs/frontend.log logs/backend-error.log logs/frontend-error.log 2>/dev/null || true
    chmod 644 logs/*.log 2>/dev/null || true
    
    # 设置node_modules权限（如果存在）
    if [ -d "server/node_modules" ]; then
        log_info "设置后端node_modules权限..."
        find server/node_modules -type d -exec chmod 755 {} \; 2>/dev/null || true
        find server/node_modules -type f -exec chmod 644 {} \; 2>/dev/null || true
        find server/node_modules -name "*.sh" -type f -exec chmod 755 {} \; 2>/dev/null || true
        find server/node_modules/.bin -type f -exec chmod 755 {} \; 2>/dev/null || true
    fi
    
    if [ -d "client/node_modules" ]; then
        log_info "设置前端node_modules权限..."
        find client/node_modules -type d -exec chmod 755 {} \; 2>/dev/null || true
        find client/node_modules -type f -exec chmod 644 {} \; 2>/dev/null || true
        find client/node_modules -name "*.sh" -type f -exec chmod 755 {} \; 2>/dev/null || true
        find client/node_modules/.bin -type f -exec chmod 755 {} \; 2>/dev/null || true
    fi
    
    # 设置构建文件权限（如果存在）
    if [ -d "client/dist" ]; then
        log_info "设置构建文件权限..."
        find client/dist -type d -exec chmod 755 {} \; 2>/dev/null || true
        find client/dist -type f -exec chmod 644 {} \; 2>/dev/null || true
    fi
    
    log_success "系统权限设置完成"
    
    # 显示权限设置摘要
    echo ""
    log_info "权限设置摘要:"
    echo "   📁 目录权限: 755 (rwxr-xr-x)"
    echo "   📄 普通文件: 644 (rw-r--r--)"
    echo "   🔐 敏感文件: 600 (rw-------)"
    echo "   🚀 可执行脚本: 755 (rwxr-xr-x)"
    echo ""
}

# 命令行参数处理
case "$1" in
    --help|-h)
        show_help
        exit 0
        ;;
    --clean)
        clean_environment
        exit 0
        ;;
    --fix-permissions)
        setup_permissions
        exit 0
        ;;
    --version|-v)
        echo "Cloudflare DNS Manager Deploy Script v2.0"
        exit 0
        ;;
    "")
        # 无参数，继续执行部署
        ;;
    *)
        log_error "未知参数: $1"
        echo "使用 --help 查看帮助信息"
        exit 1
        ;;
esac

# 错误处理函数
handle_error() {
    log_error "部署过程中发生错误，退出码: $?"
    log_error "请检查上述错误信息并重新运行脚本"
    exit 1
}

# 设置错误处理
trap handle_error ERR

echo "🚀 开始部署 Cloudflare DNS Manager v2.0..."

# 系统要求检查
check_system_requirements() {
    log_info "检查系统要求..."
    
    # 检查是否为root用户或有sudo权限
    if [[ $EUID -eq 0 ]]; then
        log_warning "检测到root用户，建议使用普通用户运行此脚本"
        SUDO_CMD=""
    elif sudo -n true 2>/dev/null; then
        log_success "检测到sudo权限"
        SUDO_CMD="sudo"
    else
        log_error "需要sudo权限来安装系统依赖"
        exit 1
    fi
    
    # 检查磁盘空间（至少需要1GB）
    AVAILABLE_SPACE=$(df . | tail -1 | awk '{print $4}')
    if [ $AVAILABLE_SPACE -lt 1048576 ]; then
        log_error "磁盘空间不足，至少需要1GB可用空间"
        exit 1
    fi
    
    # 检查内存（建议至少512MB）
    TOTAL_MEM=$(free -m | awk 'NR==2{print $2}')
    if [ $TOTAL_MEM -lt 512 ]; then
        log_warning "系统内存较少($TOTAL_MEM MB)，建议至少512MB"
    fi
    
    log_success "系统要求检查通过"
}

# 检测操作系统
detect_os() {
    log_info "检测操作系统..."
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
        OS_ID=$ID
    else
        log_error "无法检测操作系统"
        exit 1
    fi
    
    log_success "检测到操作系统: $OS $VER"
    
    # 检查支持的操作系统
    case $OS_ID in
        ubuntu|debian)
            PACKAGE_MANAGER="apt"
            UPDATE_CMD="$SUDO_CMD apt update"
            INSTALL_CMD="$SUDO_CMD apt install -y"
            ;;
        centos|rhel|fedora)
            if command -v dnf &> /dev/null; then
                PACKAGE_MANAGER="dnf"
                INSTALL_CMD="$SUDO_CMD dnf install -y"
            else
                PACKAGE_MANAGER="yum"
                INSTALL_CMD="$SUDO_CMD yum install -y"
            fi
            ;;
        *)
            log_error "不支持的操作系统: $OS"
            log_info "支持的系统: Ubuntu, Debian, CentOS, RHEL, Fedora"
            exit 1
            ;;
    esac
    
    log_success "包管理器: $PACKAGE_MANAGER"
}

# 移除这里的直接调用，所有逻辑都在main函数中处理

# 检查Node.js版本
check_node_version() {
    local required_major=18
    local current_version=$(node --version 2>/dev/null | sed 's/v//' | cut -d. -f1)
    
    if [ -z "$current_version" ]; then
        return 1
    fi
    
    if [ "$current_version" -ge "$required_major" ]; then
        return 0
    else
        return 1
    fi
}

# 安装系统依赖
install_system_dependencies() {
    log_info "安装系统依赖..."
    
    case $PACKAGE_MANAGER in
        apt)
            $UPDATE_CMD
            $INSTALL_CMD curl wget gnupg2 software-properties-common build-essential
            ;;
        dnf|yum)
            $INSTALL_CMD curl wget gnupg2 gcc-c++ make
            ;;
    esac
    
    log_success "系统依赖安装完成"
}

# 安装 Node.js 和 npm
install_nodejs() {
    log_info "安装 Node.js 和 npm..."
    
    # 安装系统依赖
    install_system_dependencies
    
    case $PACKAGE_MANAGER in
        apt)
            # Ubuntu/Debian
            if [ -n "$SUDO_CMD" ]; then
                curl -fsSL https://deb.nodesource.com/setup_18.x | $SUDO_CMD -E bash -
            else
                curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
            fi
            $INSTALL_CMD nodejs
            ;;
        dnf)
            # Fedora
            if [ -n "$SUDO_CMD" ]; then
                curl -fsSL https://rpm.nodesource.com/setup_18.x | $SUDO_CMD bash -
            else
                curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
            fi
            $INSTALL_CMD nodejs
            ;;
        yum)
            # CentOS/RHEL
            if [ -n "$SUDO_CMD" ]; then
                curl -fsSL https://rpm.nodesource.com/setup_18.x | $SUDO_CMD bash -
            else
                curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
            fi
            $INSTALL_CMD nodejs
            ;;
    esac
    
    # 验证安装
    if ! command -v node &> /dev/null || ! command -v npm &> /dev/null; then
        log_error "Node.js 或 npm 安装失败"
        exit 1
    fi
    
    log_success "Node.js 和 npm 安装完成"
}

# 检查和安装 Node.js
log_info "检查 Node.js 环境..."
if ! command -v node &> /dev/null; then
    log_warning "Node.js 未安装"
    install_nodejs
elif ! check_node_version; then
    NODE_VERSION=$(node --version)
    log_warning "Node.js 版本过低: $NODE_VERSION (需要 >= 18.x)"
    read -p "是否升级 Node.js？(y/n): " upgrade_node
    if [[ $upgrade_node == "y" || $upgrade_node == "Y" ]]; then
        install_nodejs
    else
        log_error "Node.js 版本不兼容，请手动升级"
        exit 1
    fi
else
    NODE_VERSION=$(node --version)
    log_success "Node.js 已安装: $NODE_VERSION"
fi

# 检查 npm
if ! command -v npm &> /dev/null; then
    log_error "npm 未安装"
    exit 1
else
    NPM_VERSION=$(npm --version)
    log_success "npm 已安装: $NPM_VERSION"
    
    # 检查npm版本兼容性
    log_info "检查 npm 版本兼容性..."
    NODE_MAJOR=$(node --version | sed 's/v//' | cut -d. -f1)
    if [ "$NODE_MAJOR" -ge 20 ]; then
        log_info "更新 npm 到最新版本..."
        npm install -g npm@latest
        log_success "npm 更新完成"
    else
        log_info "Node.js v$NODE_MAJOR 使用当前 npm 版本: $NPM_VERSION"
        log_warning "跳过 npm 更新以避免兼容性问题"
    fi
fi

# 安装项目依赖
install_project_dependencies() {
    log_info "安装项目依赖..."
    
    # 检查项目结构
    if [ ! -d "server" ] || [ ! -d "client" ]; then
        log_error "项目结构不完整，请确保在正确的项目根目录运行此脚本"
        exit 1
    fi
    
    # 安装后端依赖
    log_info "安装后端依赖..."
    cd server
    
    if [ ! -f "package.json" ]; then
        log_error "server/package.json 不存在"
        exit 1
    fi
    
    # 清理可能的缓存问题
    if [ -d "node_modules" ]; then
        log_info "清理旧的后端依赖..."
        rm -rf node_modules package-lock.json
    fi
    
    npm install --production=false
    if [ $? -ne 0 ]; then
        log_error "后端依赖安装失败"
        exit 1
    fi
    log_success "后端依赖安装完成"
    
    cd ..
    
    # 安装前端依赖
    log_info "安装前端依赖..."
    cd client
    
    if [ ! -f "package.json" ]; then
        log_error "client/package.json 不存在"
        exit 1
    fi
    
    # 清理可能的缓存问题
    if [ -d "node_modules" ]; then
        log_info "清理旧的前端依赖..."
        rm -rf node_modules package-lock.json
    fi
    
    npm install
    if [ $? -ne 0 ]; then
        log_error "前端依赖安装失败"
        exit 1
    fi
    log_success "前端依赖安装完成"
    
    cd ..
    log_success "所有项目依赖安装完成"
}

# 安装全局依赖
install_global_dependencies() {
    log_info "安装全局依赖..."
    
    # 安装 serve（用于生产环境静态文件服务）
    if ! command -v serve &> /dev/null; then
        log_info "安装 serve..."
        npm install -g serve
        log_success "serve 安装完成"
    else
        log_success "serve 已安装"
    fi
    
    # 安装 pm2（可选的进程管理器）
    if ! command -v pm2 &> /dev/null; then
        read -p "是否安装 PM2 进程管理器？(推荐) (y/n): " install_pm2
        if [[ $install_pm2 == "y" || $install_pm2 == "Y" ]]; then
            log_info "安装 PM2..."
            npm install -g pm2
            log_success "PM2 安装完成"
        fi
    else
        log_success "PM2 已安装"
    fi
}



# 环境配置管理
setup_environment() {
    log_info "配置环境变量..."
    
    # 检查 .env.example 是否存在
    if [ ! -f ".env.example" ]; then
        log_error ".env.example 文件不存在"
        exit 1
    fi
    
    # 创建或更新 .env 文件
    if [ ! -f ".env" ]; then
        log_info "创建环境配置文件..."
        cp .env.example .env
        log_success "环境配置文件已创建"
    else
        log_warning "环境配置文件已存在"
        read -p "是否备份现有配置并重新创建？(y/n): " recreate_env
        if [[ $recreate_env == "y" || $recreate_env == "Y" ]]; then
            # 备份现有配置
            cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
            cp .env.example .env
            log_success "已备份旧配置并创建新的环境文件"
        fi
    fi
    
    # 检查关键配置项
    if grep -q "your_api_token_here" .env; then
        log_warning "检测到默认的 API Token，需要配置"
        
        echo ""
        log_info "🔑 获取 Cloudflare API Token 的步骤:"
        echo "   1. 访问 https://dash.cloudflare.com/profile/api-tokens"
        echo "   2. 点击 'Create Token'"
        echo "   3. 选择 'Custom token' 模板"
        echo "   4. 设置权限: Zone:Zone:Read, Zone:DNS:Edit"
        echo "   5. 选择要管理的域名（或选择所有域名）"
        echo "   6. 点击 'Continue to summary' -> 'Create Token'"
        echo "   7. 复制生成的 Token"
        echo ""
        
        read -p "是否现在配置 API Token？(y/n): " config_token
        if [[ $config_token == "y" || $config_token == "Y" ]]; then
            read -p "请输入您的 Cloudflare API Token: " api_token
            if [ ! -z "$api_token" ]; then
                # 使用 sed 替换 API Token
                if [[ "$OSTYPE" == "darwin"* ]]; then
                    # macOS
                    sed -i '' "s/your_api_token_here/$api_token/g" .env
                else
                    # Linux
                    sed -i "s/your_api_token_here/$api_token/g" .env
                fi
                log_success "API Token 配置完成"
            else
                log_warning "未输入 API Token，请稍后手动配置"
            fi
        else
            log_warning "请稍后手动编辑 .env 文件配置 API Token"
        fi
    else
        log_success "API Token 已配置"
    fi
    
    # 设置合适的文件权限
    chmod 600 .env
    log_success "环境配置完成"
}

# 部署模式选择
choose_deploy_mode() {
    log_info "选择部署模式"
    echo ""
    echo -e "${BLUE}1) 生产环境 (推荐)${NC}"
    echo "   - 构建优化的前端代码"
    echo "   - 使用 systemd 服务管理"
    echo "   - 自动启动和重启"
    echo "   - 适合服务器部署"
    echo ""
    echo -e "${YELLOW}2) 开发环境${NC}"
    echo "   - 热重载开发服务器"
    echo "   - 实时代码更新"
    echo "   - 适合开发调试"
    echo ""
    
    while true; do
        read -p "请选择部署模式 (1-2): " deploy_mode
        case $deploy_mode in
            1)
                PRODUCTION_MODE=true
                log_success "选择了生产环境部署"
                break
                ;;
            2)
                PRODUCTION_MODE=false
                log_success "选择了开发环境部署"
                break
                ;;
            *)
                log_error "无效选择，请输入 1 或 2"
                ;;
        esac
    done
}

# 创建 systemd 服务文件
create_systemd_services() {
    local create_service="n"
    
    if [[ $PRODUCTION_MODE == true ]]; then
        log_info "生产环境将自动创建 systemd 服务"
        create_service="y"
    else
        read -p "是否创建 systemd 服务以便开机自启？(y/n): " create_service
    fi
    
    if [[ $create_service == "y" || $create_service == "Y" ]]; then
        log_info "创建 systemd 服务文件..."
        
        local current_dir=$(pwd)
        local node_path=$(which node)
        local npm_path=$(which npm)
        
        # 检查路径
        if [ -z "$node_path" ] || [ -z "$npm_path" ]; then
            log_error "无法找到 Node.js 或 npm 路径"
            exit 1
        fi
        
        # 创建日志目录
        mkdir -p logs
        log_info "创建日志目录: ${current_dir}/logs"
        
        # 检查并停止现有后端服务
        if systemctl is-active --quiet cloudflare-dns-backend 2>/dev/null; then
            log_info "检测到后端服务正在运行，停止服务..."
            sudo systemctl stop cloudflare-dns-backend
        fi
        
        if [ -f "/etc/systemd/system/cloudflare-dns-backend.service" ]; then
            log_info "发现现有后端服务文件，将覆盖更新"
        else
            log_info "创建后端服务文件..."
        fi
            sudo tee /etc/systemd/system/cloudflare-dns-backend.service > /dev/null <<EOF
[Unit]
Description=Cloudflare DNS Manager Backend
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=${current_dir}/server
Environment=NODE_ENV=$([ "$PRODUCTION_MODE" = true ] && echo "production" || echo "development")
EnvironmentFile=${current_dir}/.env
ExecStart=${node_path} server.js
Restart=always
RestartSec=10
KillMode=mixed
KillSignal=SIGTERM
TimeoutStopSec=30

# 日志配置
StandardOutput=append:${current_dir}/logs/backend.log
StandardError=append:${current_dir}/logs/backend-error.log
SyslogIdentifier=cloudflare-dns-backend

# 安全配置
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

        if [[ $PRODUCTION_MODE == true ]]; then
            # 生产环境：构建前端并使用静态文件服务
            log_info "构建前端应用..."
            cd client
            
            # 清理旧的构建文件
            if [ -d "dist" ]; then
                rm -rf dist
            fi
            
            npm run build
            if [ $? -ne 0 ]; then
                log_error "前端构建失败"
                exit 1
            fi
            log_success "前端构建完成"
            cd ..
            
            # 检查 serve 命令
            local serve_path=$(which serve)
            if [ -z "$serve_path" ]; then
                log_error "serve 命令未找到，请确保已安装"
                exit 1
            fi
            
            # 检查并停止现有前端服务
            if systemctl is-active --quiet cloudflare-dns-frontend 2>/dev/null; then
                log_info "检测到前端服务正在运行，停止服务..."
                sudo systemctl stop cloudflare-dns-frontend
            fi
            
            if [ -f "/etc/systemd/system/cloudflare-dns-frontend.service" ]; then
                log_info "发现现有前端服务文件，将覆盖更新（生产环境）"
            else
                log_info "创建前端服务文件（生产环境）..."
            fi
                sudo tee /etc/systemd/system/cloudflare-dns-frontend.service > /dev/null <<EOF
[Unit]
Description=Cloudflare DNS Manager Frontend
After=network.target cloudflare-dns-backend.service
Wants=network.target
Requires=cloudflare-dns-backend.service

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=${current_dir}/client
ExecStart=${serve_path} -s dist -l 5173 --no-clipboard
Restart=always
RestartSec=10
KillMode=mixed
KillSignal=SIGTERM
TimeoutStopSec=15

# 日志配置
StandardOutput=append:${current_dir}/logs/frontend.log
StandardError=append:${current_dir}/logs/frontend-error.log
SyslogIdentifier=cloudflare-dns-frontend

# 安全配置
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF
        
        else
            # 检查并停止现有前端服务
            if systemctl is-active --quiet cloudflare-dns-frontend 2>/dev/null; then
                log_info "检测到前端服务正在运行，停止服务..."
                sudo systemctl stop cloudflare-dns-frontend
            fi
            
            if [ -f "/etc/systemd/system/cloudflare-dns-frontend.service" ]; then
                log_info "发现现有前端服务文件，将覆盖更新（开发环境）"
            else
                log_info "创建前端服务文件（开发环境）..."
            fi
                sudo tee /etc/systemd/system/cloudflare-dns-frontend.service > /dev/null <<EOF
[Unit]
Description=Cloudflare DNS Manager Frontend (Development)
After=network.target cloudflare-dns-backend.service
Wants=network.target
Requires=cloudflare-dns-backend.service

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=${current_dir}/client
ExecStart=${npm_path} run dev -- --host 0.0.0.0
Restart=always
RestartSec=10
KillMode=mixed
KillSignal=SIGTERM
TimeoutStopSec=15

# 日志配置
StandardOutput=append:${current_dir}/logs/frontend-dev.log
StandardError=append:${current_dir}/logs/frontend-dev-error.log
SyslogIdentifier=cloudflare-dns-frontend-dev

# 安全配置
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF
        
        fi

        # 重新加载 systemd
        log_info "重新加载 systemd 配置..."
        sudo systemctl daemon-reload
        
        # 启用服务
        log_info "启用服务自启动..."
        sudo systemctl enable cloudflare-dns-backend cloudflare-dns-frontend
        
        if [[ $PRODUCTION_MODE == true ]]; then
            log_info "启动生产环境服务..."
            
            # 启动后端服务
            sudo systemctl start cloudflare-dns-backend
            sleep 2
            
            # 检查后端服务状态
            if systemctl is-active --quiet cloudflare-dns-backend; then
                log_success "后端服务启动成功"
            else
                log_error "后端服务启动失败"
                echo "请检查日志: sudo journalctl -u cloudflare-dns-backend -f"
            fi
            
            # 启动前端服务
            sudo systemctl start cloudflare-dns-frontend
            sleep 3
            
            # 检查前端服务状态
            if systemctl is-active --quiet cloudflare-dns-frontend; then
                log_success "前端服务启动成功"
            else
                log_error "前端服务启动失败"
                echo "请检查日志: sudo journalctl -u cloudflare-dns-frontend -f"
            fi
            
            # 检查整体状态
            if systemctl is-active --quiet cloudflare-dns-backend && systemctl is-active --quiet cloudflare-dns-frontend; then
                log_success "生产环境服务全部启动成功"
            else
                log_warning "请检查服务状态"
            fi
        else
            log_success "systemd 服务已创建并启用（开发模式）"
            log_info "使用以下命令管理服务:"
            echo "   启动: sudo systemctl start cloudflare-dns-backend cloudflare-dns-frontend"
            echo "   停止: sudo systemctl stop cloudflare-dns-backend cloudflare-dns-frontend"
        fi
        
        log_success "systemd 服务配置完成"
    else
        log_info "跳过 systemd 服务创建"
    fi
}

# 防火墙配置和最终设置
final_setup() {
    log_info "最终配置检查..."
    
    # 防火墙配置提醒
    echo ""
    log_warning "防火墙配置提醒:"
    echo "   请确保以下端口已开放:"
    echo "   - 3005 (后端 API)"
    if [[ $PRODUCTION_MODE == true ]]; then
        echo "   - 5173 (前端服务 - 生产环境)"
    else
        echo "   - 5173 (前端服务 - 开发环境)"
    fi
    echo ""
    
    # 根据操作系统提供防火墙命令
    case $OS in
        "ubuntu"|"debian")
            echo "   ${BLUE}Ubuntu/Debian:${NC}"
            echo "   sudo ufw allow 3005 && sudo ufw allow 5173"
            ;;
        "centos"|"rhel"|"fedora")
            echo "   ${BLUE}CentOS/RHEL/Fedora:${NC}"
            echo "   sudo firewall-cmd --permanent --add-port=3005/tcp"
            echo "   sudo firewall-cmd --permanent --add-port=5173/tcp"
            echo "   sudo firewall-cmd --reload"
            ;;
    esac
    
    # 基本权限设置（详细权限设置已在setup_permissions函数中完成）
    log_info "确保基本文件权限..."
    chmod +x deploy.sh 2>/dev/null || true
    chmod 600 .env 2>/dev/null || true
    
    log_success "基本权限检查完成"
    
    echo ""
    log_success "🎉 Cloudflare DNS Manager v2.0 部署完成！"
    echo ""
}

# 显示部署完成信息
# 主部署流程
main() {
    log_info "开始 Cloudflare DNS Manager v2.0 部署流程"
    
    # 环境清理选项
    read -p "🧹 是否清理现有环境？这将删除 node_modules 和构建文件 (y/n): " clean_env
    
    if [[ $clean_env == "y" || $clean_env == "Y" ]]; then
        echo "🧹 清理现有环境..."
        
        # 停止可能运行的服务
        echo "⏹️  停止现有服务..."
        pkill -f "node.*server.js" 2>/dev/null || true
        pkill -f "npm.*dev" 2>/dev/null || true
        pkill -f "vite" 2>/dev/null || true
        
        # 清理依赖和构建文件
        echo "🗑️  删除依赖和构建文件..."
        rm -rf server/node_modules
        rm -rf client/node_modules
        rm -rf client/dist
        rm -rf logs
        rm -f server/package-lock.json
        rm -f client/package-lock.json
        
        # 清理可能的数据文件（保留配置）
        if [ -f "server/accounts.json" ]; then
            read -p "📊 发现账号数据文件，是否备份？(y/n): " backup_data
            if [[ $backup_data == "y" || $backup_data == "Y" ]]; then
                cp server/accounts.json server/accounts.json.backup.$(date +%Y%m%d_%H%M%S)
                echo "✅ 账号数据已备份"
            fi
        fi
        
        echo "✅ 环境清理完成"
    fi
    
    # 系统检查
    check_system_requirements
    detect_os
    
    # Node.js 环境
    check_node_version
    install_nodejs
    
    # 项目依赖
    install_global_dependencies
    install_project_dependencies
    
    # 环境配置
    setup_environment
    
    # 数据文件初始化和迁移
    init_data_files
    migrate_data
    
    # 部署模式选择
    choose_deploy_mode
    
    # 服务配置
    create_systemd_services
    
    # 设置系统权限
    setup_permissions
    
    # 最终设置
    final_setup
    
    # 显示完成信息
    show_completion_info
    
    log_success "部署流程完成！"
}

# 显示部署完成信息
show_completion_info() {
    local server_ip=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "your-server-ip")
    
    if [[ $PRODUCTION_MODE == true ]]; then
        echo -e "${GREEN}🏭 生产环境部署完成${NC}"
        echo ""
        echo -e "${BLUE}📋 下一步操作:${NC}"
        echo -e "${YELLOW}1.${NC} 配置 API Token (如果还未配置):"
        echo "   nano .env"
        echo ""
        echo -e "${YELLOW}2.${NC} 访问应用:"
        echo -e "   🌐 前端: ${BLUE}http://localhost:5173${NC} 或 ${BLUE}http://${server_ip}:5173${NC}"
        echo -e "   🔧 后端: ${BLUE}http://localhost:3005${NC} 或 ${BLUE}http://${server_ip}:3005${NC}"
        echo ""
        echo -e "${YELLOW}3.${NC} 管理服务:"
        echo -e "   查看状态: ${CYAN}sudo systemctl status cloudflare-dns-backend cloudflare-dns-frontend${NC}"
        echo -e "   重启服务: ${CYAN}sudo systemctl restart cloudflare-dns-backend cloudflare-dns-frontend${NC}"
        echo -e "   停止服务: ${CYAN}sudo systemctl stop cloudflare-dns-backend cloudflare-dns-frontend${NC}"
        echo ""
        echo -e "${YELLOW}4.${NC} 查看日志:"
        echo -e "   应用日志: ${CYAN}tail -f logs/backend.log${NC} | ${CYAN}tail -f logs/frontend.log${NC}"
        echo -e "   系统日志: ${CYAN}sudo journalctl -u cloudflare-dns-backend -f${NC}"
        echo ""
        echo -e "${YELLOW}5.${NC} 服务管理:"
        echo "   服务会在系统重启后自动启动"
        echo "   日志文件位置: $(pwd)/logs/"
    else
        echo -e "${GREEN}🛠️  开发环境部署完成${NC}"
        echo ""
        echo -e "${BLUE}📝 下一步操作:${NC}"
        echo -e "${YELLOW}1.${NC} 配置 API Token:"
        echo "   nano .env"
        echo ""
        echo -e "${YELLOW}2.${NC} 启动开发环境 (选择一种方式):"
        echo -e "   ${CYAN}方式A - 手动启动:${NC}"
        echo "     后端: cd server && npm start"
        echo "     前端: cd client && npm run dev -- --host"
        echo ""
        echo -e "   ${CYAN}方式B - 使用 systemd 服务:${NC}"
        echo "     sudo systemctl start cloudflare-dns-backend cloudflare-dns-frontend"
        echo ""
        echo -e "${YELLOW}3.${NC} 访问应用:"
        echo -e "   🌐 前端: ${BLUE}http://localhost:5173${NC} 或 ${BLUE}http://${server_ip}:5173${NC}"
        echo -e "   🔧 后端: ${BLUE}http://localhost:3005${NC} 或 ${BLUE}http://${server_ip}:3005${NC}"
        echo ""
        echo -e "${YELLOW}4.${NC} 查看日志:"
        echo -e "   应用日志: ${CYAN}tail -f logs/backend.log${NC} | ${CYAN}tail -f logs/frontend-dev.log${NC}"
        echo -e "   实时日志: ${CYAN}sudo journalctl -u cloudflare-dns-backend -f${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}🔧 其他有用命令:${NC}"
    echo -e "   重新部署: ${CYAN}./deploy.sh${NC}"
    echo -e "   清理环境: ${CYAN}./deploy.sh --clean${NC}"
    echo -e "   查看服务状态: ${CYAN}sudo systemctl status cloudflare-dns-*${NC}"
    echo -e "   查看端口占用: ${CYAN}netstat -tlnp | grep -E ':(3005|5173)'${NC}"
    echo ""
    echo -e "${BLUE}📚 获取帮助:${NC}"
    echo -e "   项目文档: ${CYAN}cat README.md${NC}"
    echo -e "   API 文档: ${BLUE}http://${server_ip}:3005/api${NC}"
    echo ""
    echo -e "${GREEN}✨ 享受使用 Cloudflare DNS Manager！${NC}"
}

# 数据文件初始化和备份
init_data_files() {
    log_info "初始化数据文件..."
    
    # 创建数据目录
    mkdir -p server/data
    
    # 检查accounts.json文件
    if [ ! -f "server/accounts.json" ]; then
        log_info "创建初始账号数据文件..."
        cat > server/accounts.json << 'EOF'
{
}
EOF
        log_success "账号数据文件已创建"
    else
        log_info "发现现有账号数据文件"
        
        # 备份现有数据
        backup_file="server/data/accounts_backup_$(date +%Y%m%d_%H%M%S).json"
        cp server/accounts.json "$backup_file"
        log_success "账号数据已备份到: $backup_file"
    fi
    
    # 设置文件权限
    chmod 600 server/accounts.json
    
    # 创建日志目录
    mkdir -p logs
    
    # 创建配置文件模板（如果不存在）
    if [ ! -f ".env" ]; then
        log_info "创建环境配置模板..."
        cat > .env << 'EOF'
# Cloudflare API配置
CLOUDFLARE_API_TOKEN=your_api_token_here

# 服务器配置
PORT=3005
NODE_ENV=production

# CORS配置
CORS_ORIGIN=http://localhost:5173

# 获取Cloudflare API Token的步骤：
# 1. 登录 https://dash.cloudflare.com/
# 2. 点击右上角头像 -> "My Profile"
# 3. 选择 "API Tokens" 标签
# 4. 点击 "Create Token"
# 5. 选择 "Custom token" 模板
# 6. 设置权限：
#    - Zone:Zone:Read
#    - Zone:DNS:Edit
# 7. 选择要管理的域名（可选择所有域名）
# 8. 点击 "Continue to summary" -> "Create Token"
# 9. 复制生成的Token并替换上面的 your_api_token_here
EOF
        log_success "环境配置模板已创建"
    fi
    
    log_success "数据文件初始化完成"
}

# 数据迁移和升级
migrate_data() {
    log_info "检查数据迁移需求..."
    
    # 检查旧版本数据格式
    if [ -f "server/accounts.json" ]; then
        # 验证JSON格式
        if ! python3 -m json.tool server/accounts.json > /dev/null 2>&1; then
            log_warning "检测到损坏的账号数据文件，尝试修复..."
            
            # 备份损坏的文件
            mv server/accounts.json "server/data/accounts_corrupted_$(date +%Y%m%d_%H%M%S).json"
            
            # 创建新的空文件
            echo '{}' > server/accounts.json
            chmod 600 server/accounts.json
            
            log_warning "已创建新的账号数据文件，请重新添加账号"
        else
            log_success "账号数据文件格式正常"
        fi
    fi
    
    # 检查并创建必要的目录结构
    mkdir -p server/data logs
    
    log_success "数据迁移检查完成"
}

# 执行主函数
main