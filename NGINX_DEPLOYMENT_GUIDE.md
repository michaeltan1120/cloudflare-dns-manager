# Cloudflare DNS 管理系统 - Nginx 反向代理部署指南

## 概述

本指南详细说明如何配置 Nginx 反向代理来统一管理前端和后端服务，解决跨域问题并提供更好的用户体验。

### 系统架构

```
用户浏览器
    ↓
Nginx 反向代理 (80/443端口)
    ↓
┌─────────────────┬─────────────────┐
│   前端服务       │   后端API服务    │
│ localhost:5173  │ localhost:3005  │
│   (静态文件)     │   (REST API)    │
└─────────────────┴─────────────────┘
```

### 路由规则

- `http://your-domain.com/` → 前端服务 (localhost:5173)
- `http://your-domain.com/api/*` → 后端API服务 (localhost:3005)

## 部署步骤

### 1. 安装 Nginx

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install nginx

# CentOS/RHEL
sudo yum install nginx
# 或者
sudo dnf install nginx
```

### 2. 配置 Nginx

#### 方法一：使用提供的配置文件

```bash
# 复制配置文件到 Nginx 配置目录
sudo cp /root/cloudflare/nginx-proxy.conf /etc/nginx/sites-available/cloudflare-dns

# 创建软链接启用站点
sudo ln -s /etc/nginx/sites-available/cloudflare-dns /etc/nginx/sites-enabled/

# 删除默认站点（可选）
sudo rm -f /etc/nginx/sites-enabled/default
```

#### 方法二：修改现有配置

如果您已有 Nginx 配置，请将 `nginx-proxy.conf` 中的 server 块内容添加到您的配置文件中。

### 3. 修改域名配置

编辑配置文件，将 `cfdns.023021.xyz` 替换为您的实际域名：

```bash
sudo nano /etc/nginx/sites-available/cloudflare-dns
```

找到这一行：
```nginx
server_name cfdns.023021.xyz;  # 替换为您的域名
```

### 4. 测试配置

```bash
# 测试 Nginx 配置语法
sudo nginx -t

# 如果测试通过，重新加载配置
sudo systemctl reload nginx

# 启动 Nginx 服务
sudo systemctl start nginx
sudo systemctl enable nginx
```

### 5. 更新前端 API 配置

修改前端 API 配置文件以使用反向代理：

```bash
nano /root/cloudflare/client/src/config/api.js
```

将生产环境配置修改为：

```javascript
function getApiBaseUrl() {
  if (process.env.NODE_ENV === 'development') {
    return 'http://localhost:3005/api';
  } else {
    // 生产环境：使用当前域名的反代路径
    const currentProtocol = window.location.protocol;
    const currentHost = window.location.host;
    return `${currentProtocol}//${currentHost}/api`;
  }
}
```

### 6. 重新构建前端

```bash
cd /root/cloudflare/client
npm run build
```

### 7. 重启服务

```bash
# 重启前端服务
sudo systemctl restart cloudflare-dns-frontend

# 重启后端服务
sudo systemctl restart cloudflare-dns-backend

# 重启 Nginx
sudo systemctl restart nginx
```

## 验证部署

### 1. 检查服务状态

```bash
# 检查 Nginx 状态
sudo systemctl status nginx

# 检查前端服务
sudo systemctl status cloudflare-dns-frontend

# 检查后端服务
sudo systemctl status cloudflare-dns-backend

# 检查端口监听
netstat -tlnp | grep -E ':(80|3005|5173)'
```

### 2. 测试 API 连接

```bash
# 测试后端 API
curl -i http://your-domain.com/api/health

# 测试前端页面
curl -i http://your-domain.com/
```

### 3. 浏览器测试

1. 打开浏览器访问 `http://your-domain.com`
2. 打开开发者工具，检查网络请求
3. 确认 API 请求都指向 `/api/*` 路径
4. 确认没有跨域错误

## 故障排除

### 常见问题

#### 1. 502 Bad Gateway

**原因**：后端服务未启动或端口不正确

**解决方案**：
```bash
# 检查后端服务
sudo systemctl status cloudflare-dns-backend
netstat -tlnp | grep 3005

# 重启后端服务
sudo systemctl restart cloudflare-dns-backend
```

#### 2. 404 Not Found (API 请求)

**原因**：API 路径配置错误

**解决方案**：
1. 检查 Nginx 配置中的 `location ^~ /api` 块
2. 确认后端服务的路由配置
3. 检查前端 API 配置是否正确

#### 3. 静态资源加载失败

**原因**：前端服务未启动或配置错误

**解决方案**：
```bash
# 检查前端服务
sudo systemctl status cloudflare-dns-frontend
netstat -tlnp | grep 5173

# 重启前端服务
sudo systemctl restart cloudflare-dns-frontend
```

#### 4. CORS 错误

**原因**：跨域配置不正确

**解决方案**：
1. 确认使用了反向代理配置
2. 检查后端 CORS 设置
3. 确认前端 API 配置使用相对路径

### 日志查看

```bash
# Nginx 访问日志
sudo tail -f /var/log/nginx/cloudflare-dns-access.log

# Nginx 错误日志
sudo tail -f /var/log/nginx/cloudflare-dns-error.log

# 应用日志
tail -f /root/cloudflare/logs/backend.log
tail -f /root/cloudflare/logs/frontend.log
```

## SSL/HTTPS 配置（可选）

### 使用 Let's Encrypt

```bash
# 安装 Certbot
sudo apt install certbot python3-certbot-nginx

# 获取 SSL 证书
sudo certbot --nginx -d your-domain.com

# 自动续期
sudo crontab -e
# 添加以下行：
# 0 12 * * * /usr/bin/certbot renew --quiet
```

### 手动 SSL 配置

如果您有自己的 SSL 证书，请取消注释 `nginx-proxy.conf` 中的 HTTPS 配置部分，并修改证书路径。

## 性能优化

### 1. 启用 Gzip 压缩

在 Nginx 配置中添加：

```nginx
gzip on;
gzip_vary on;
gzip_min_length 1024;
gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
```

### 2. 调整缓存策略

根据需要调整静态资源缓存时间：

```nginx
# 长期缓存
location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

### 3. 启用 HTTP/2

```nginx
listen 443 ssl http2;
```

## 监控和维护

### 定期检查

```bash
#!/bin/bash
# 创建监控脚本 /root/cloudflare/monitor.sh

echo "=== Nginx Status ==="
sudo systemctl status nginx --no-pager

echo "\n=== Frontend Status ==="
sudo systemctl status cloudflare-dns-frontend --no-pager

echo "\n=== Backend Status ==="
sudo systemctl status cloudflare-dns-backend --no-pager

echo "\n=== Port Status ==="
netstat -tlnp | grep -E ':(80|443|3005|5173)'

echo "\n=== Disk Usage ==="
df -h /var/log/nginx/
```

### 日志轮转

确保 Nginx 日志轮转配置正确：

```bash
sudo nano /etc/logrotate.d/nginx
```

## 总结

通过本指南，您应该能够成功配置 Nginx 反向代理，实现：

1. ✅ 统一域名访问前后端服务
2. ✅ 解决跨域问题
3. ✅ 提供更好的安全性和性能
4. ✅ 支持 SSL/HTTPS
5. ✅ 便于维护和监控

如果遇到问题，请参考故障排除部分或查看相关日志文件。