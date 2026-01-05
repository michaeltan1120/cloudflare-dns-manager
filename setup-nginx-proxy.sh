#!/bin/bash

# Cloudflare DNS 管理系统 - Nginx 反向代理自动配置脚本
# 使用方法: sudo ./setup-nginx-proxy.sh [your-domain.com]

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否以root权限运行
if [[ $EUID -ne 0 ]]; then
   log_error "此脚本需要root权限运行，请使用 sudo"
   exit 1
fi

# 获取域名参数
DOMAIN=${1:-"cfdns.023021.xyz"}
log_info "配置域名: $DOMAIN"

# 检查nginx是否安装
if ! command -v nginx &> /dev/null; then
    log_warning "Nginx 未安装，正在安装..."
    if command -v apt &> /dev/null; then
        apt update
        apt install -y nginx
    elif command -v yum &> /dev/null; then
        yum install -y nginx
    elif command -v dnf &> /dev/null; then
        dnf install -y nginx
    else
        log_error "无法自动安装nginx，请手动安装"
        exit 1
    fi
    log_success "Nginx 安装完成"
else
    log_info "Nginx 已安装"
fi

# 备份现有配置
if [ -f "/etc/nginx/sites-available/cloudflare-dns" ]; then
    log_warning "发现现有配置，正在备份..."
    cp /etc/nginx/sites-available/cloudflare-dns /etc/nginx/sites-available/cloudflare-dns.backup.$(date +%Y%m%d_%H%M%S)
    log_success "配置已备份"
fi

# 复制配置文件
log_info "复制nginx配置文件..."
cp /root/cloudflare/nginx-proxy.conf /etc/nginx/sites-available/cloudflare-dns

# 替换域名
log_info "更新域名配置为: $DOMAIN"
sed -i "s/cfdns.023021.xyz/$DOMAIN/g" /etc/nginx/sites-available/cloudflare-dns

# 创建软链接
log_info "启用站点配置..."
ln -sf /etc/nginx/sites-available/cloudflare-dns /etc/nginx/sites-enabled/

# 删除默认站点（如果存在）
if [ -f "/etc/nginx/sites-enabled/default" ]; then
    log_info "删除默认站点配置..."
    rm -f /etc/nginx/sites-enabled/default
fi

# 测试nginx配置
log_info "测试nginx配置..."
if nginx -t; then
    log_success "Nginx配置测试通过"
else
    log_error "Nginx配置测试失败，请检查配置文件"
    exit 1
fi

# 检查服务状态
log_info "检查应用服务状态..."

# 检查后端服务
if systemctl is-active --quiet cloudflare-dns-backend; then
    log_success "后端服务运行正常"
else
    log_warning "后端服务未运行，尝试启动..."
    systemctl start cloudflare-dns-backend || log_error "后端服务启动失败"
fi

# 检查前端服务
if systemctl is-active --quiet cloudflare-dns-frontend; then
    log_success "前端服务运行正常"
else
    log_warning "前端服务未运行，尝试启动..."
    systemctl start cloudflare-dns-frontend || log_error "前端服务启动失败"
fi

# 启动并启用nginx
log_info "启动nginx服务..."
systemctl start nginx
systemctl enable nginx

# 重新加载nginx配置
log_info "重新加载nginx配置..."
systemctl reload nginx

log_success "Nginx反向代理配置完成！"

# 显示状态信息
echo
log_info "=== 服务状态 ==="
echo "Nginx: $(systemctl is-active nginx)"
echo "前端服务: $(systemctl is-active cloudflare-dns-frontend 2>/dev/null || echo 'unknown')"
echo "后端服务: $(systemctl is-active cloudflare-dns-backend 2>/dev/null || echo 'unknown')"

echo
log_info "=== 端口监听状态 ==="
netstat -tlnp | grep -E ':(80|443|3005|5173)' || echo "未找到相关端口监听"

echo
log_info "=== 访问地址 ==="
echo "前端页面: http://$DOMAIN"
echo "后端API: http://$DOMAIN/api"

echo
log_info "=== 测试命令 ==="
echo "测试前端: curl -I http://$DOMAIN"
echo "测试API: curl -I http://$DOMAIN/api/health"

echo
log_success "配置完成！请在浏览器中访问 http://$DOMAIN 测试"

# 可选：自动测试
read -p "是否现在进行连接测试？(y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "正在测试连接..."
    
    # 测试前端
    if curl -s -I "http://$DOMAIN" | grep -q "200 OK"; then
        log_success "前端连接测试通过"
    else
        log_error "前端连接测试失败"
    fi
    
    # 测试API
    if curl -s -I "http://$DOMAIN/api/health" | grep -q "200 OK"; then
        log_success "API连接测试通过"
    else
        log_warning "API连接测试失败，请检查后端服务"
    fi
fi

log_info "如需查看详细部署指南，请参考: /root/cloudflare/NGINX_DEPLOYMENT_GUIDE.md"