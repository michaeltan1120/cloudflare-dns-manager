# 部署检查清单

## 部署前检查

### 系统要求
- [ ] Node.js 18+ 已安装
- [ ] npm 已安装
- [ ] 防火墙端口 3001 和 5173 已开放
- [ ] 有足够的磁盘空间（至少 500MB）

### 网络要求
- [ ] 服务器可以访问互联网
- [ ] 可以访问 Cloudflare API (api.cloudflare.com)
- [ ] 如果使用代理，已正确配置

## 📋 部署步骤检查

### 1. 项目准备
- [ ] 项目文件已下载/克隆
- [ ] 进入项目目录
- [ ] 给 deploy.sh 执行权限：`chmod +x deploy.sh`

### 2. 部署脚本执行
- [ ] 运行部署脚本: `./deploy.sh`
- [ ] 选择环境清理选项 (如需要)
- [ ] 选择部署模式:
  - [ ] 开发环境 (使用 npm run dev)
  - [ ] 生产环境 (构建并配置 systemd)
- [ ] 选择合适的包管理器 (npm/yarn)
- [ ] 依赖安装成功
- [ ] 环境配置文件创建: `.env`
- [ ] systemd 服务创建和配置
- [ ] 防火墙端口开放提醒

### 3. 环境配置
- [ ] 复制 .env.example 到 .env
- [ ] 设置 CLOUDFLARE_API_TOKEN
- [ ] 检查 PORT 配置（默认 3001）
- [ ] 检查 CORS_ORIGIN 配置（默认 http://localhost:5173）

### 4. 依赖安装
- [ ] 后端依赖安装成功：`cd server && npm install`
- [ ] 前端依赖安装成功：`cd client && npm install`
- [ ] 无错误或警告信息

### 5. 服务启动
- [ ] 后端服务启动成功：`cd server && npm start`
- [ ] 前端服务启动成功：`cd client && npm run dev`
- [ ] 服务运行在正确端口

## 部署后验证

### 功能测试
- [ ] 访问 http://your-server-ip:5173 正常显示页面
- [ ] 账号管理功能正常
- [ ] 可以添加 Cloudflare 账号
- [ ] 可以查看 DNS 记录
- [ ] 可以添加/编辑/删除 DNS 记录

### 性能检查
- [ ] 页面加载速度正常（< 3秒）
- [ ] API 响应速度正常（< 2秒）
- [ ] 无内存泄漏或异常占用

### 安全检查
- [ ] API Token 未在日志中泄露
- [ ] 敏感信息已正确配置在 .env 文件
- [ ] 防火墙规则已正确设置

## 🔍 生产环境额外检查

### systemd 服务管理
- [ ] systemd 服务已创建并启用
- [ ] 服务状态正常: `./manage-production.sh status`
- [ ] 开机自启已配置: `./manage-production.sh autostart`
- [ ] 日志输出正常: `./manage-production.sh logs`

### 生产环境配置
- [ ] 前端已构建: `client/dist` 目录存在
- [ ] 静态文件服务正常 (端口 5000)
- [ ] 后端 API 服务正常 (端口 3001)
- [ ] 防火墙配置正确
- [ ] SSL/TLS 证书配置 (如使用 HTTPS)
- [ ] 反向代理配置 (如使用 Nginx)

### 运维配置
- [ ] 日志轮转配置
- [ ] 监控和告警设置
- [ ] 备份策略制定
- [ ] 性能监控配置

### 监控和日志
- [ ] 日志文件可正常访问
- [ ] 错误日志监控已设置
- [ ] 服务状态监控已配置

### 备份策略
- [ ] 账号数据备份计划已制定
- [ ] 配置文件备份已完成
- [ ] 恢复流程已测试

## 故障排除

### 常见问题检查
- [ ] 检查 Node.js 版本兼容性
- [ ] 检查端口占用情况：`netstat -tlnp | grep :3001`
- [ ] 检查防火墙状态：`sudo ufw status`
- [ ] 检查服务日志：`sudo journalctl -u cloudflare-dns-*`

### 网络问题
- [ ] 测试 Cloudflare API 连接：`curl -H "Authorization: Bearer YOUR_TOKEN" https://api.cloudflare.com/client/v4/user/tokens/verify`
- [ ] 检查 DNS 解析
- [ ] 检查代理配置

## 迁移检查清单

### 迁移前准备
- [ ] 备份当前服务器数据
- [ ] 记录当前配置信息
- [ ] 准备新服务器环境

### 迁移过程
- [ ] 在新服务器上部署应用
- [ ] 恢复配置文件
- [ ] 恢复账号数据
- [ ] 测试所有功能

### 迁移后验证
- [ ] 所有账号数据完整
- [ ] DNS 记录显示正常
- [ ] 功能测试通过
- [ ] 性能测试通过

---

**注意**：请逐项检查以上清单，确保每一项都已完成并测试通过。如遇问题，请参考 README.md 中的故障排除部分。