# Cloudflare DNS 管理面板

一个基于 Node.js/Express + React 的前后端分离项目，用于管理 Cloudflare DNS 解析记录。

## 项目结构

```
cloudflare-dns-manager/
├── server/           # 后端 Node.js/Express 服务
│   ├── server.js
│   ├── package.json
│   └── package-lock.json
├── client/           # 前端 React 应用
│   ├── src/
│   ├── public/
│   ├── package.json
│   └── ...
├── deploy.sh         # 一键部署脚本
├── .env.example      # 环境变量模板
└── README.md
```

## 功能特性

- 🌐 查看域名 DNS 记录
- ➕ 添加新的 DNS 记录
- ✏️ 编辑现有 DNS 记录
- 🗑️ 删除 DNS 记录
- 👥 多账号管理支持
- 🔄 账号切换功能
- 📱 响应式设计
- 🎨 现代化 UI 界面

## 技术栈

### 后端
- Node.js
- Express.js
- Cloudflare API

### 前端
- React 19
- Tailwind CSS 3
- Vite 构建工具
- 现代化 UI 组件
- 响应式设计

## 快速开始

## 快速开始

### 方法一：一键部署（推荐）
```bash
# 克隆或下载项目
git clone https://github.com/michaeltan1120/cloudflare-dns.git
cd cloudflare-dns-manager

# 给部署脚本执行权限
chmod +x deploy.sh

# 运行部署脚本
./deploy.sh
```

部署脚本会自动：
- 检测操作系统并安装 Node.js
- 安装项目依赖
- 创建环境配置文件
- 提供启动指令

### 方法二：手动部署

#### 1. 环境要求
- Node.js 18+ 
- npm 或 yarn
- Linux/macOS/Windows

#### 2. 安装依赖
```bash
# 后端依赖
cd server
npm install

# 前端依赖
cd ../client
npm install
cd ..
```

#### 3. 环境配置
```bash
# 复制环境变量模板
cp .env.example .env

# 编辑环境变量
nano .env
```

#### 4. 启动服务

**开发环境：**
```bash
# 启动后端服务（端口 3001）
cd server
npm start &

# 启动前端服务（端口 5173）
cd ../client
npm run dev
```

**生产环境：**
```bash
# 构建前端
cd client
npm run build

# 安装静态文件服务器
npm install -g serve

# 启动服务
cd ../server
npm start &
cd ../client
serve -s dist -l 5173
```

## 环境配置

在 `.env` 文件中配置以下变量：

```env
# Cloudflare API Token
CLOUDFLARE_API_TOKEN=your_api_token_here

# 服务器配置
PORT=3001
NODE_ENV=production

# CORS 配置
CORS_ORIGIN=http://localhost:5173
```

### 获取 Cloudflare API Token
1. 登录 [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. 进入 "My Profile" > "API Tokens"
3. 点击 "Create Token"
4. 选择 "Custom token" 模板
5. 设置权限：
   - **Zone:Zone:Read** (读取域名信息)
   - **Zone:DNS:Edit** (编辑 DNS 记录)
6. 选择要管理的域名（建议选择所有域名）
7. 复制生成的 Token 到 `.env` 文件

## 使用说明

### 多账号管理
1. **添加账号**：在账号管理页面点击"添加账号"，输入账号名称和 API Token
2. **切换账号**：在 DNS 管理页面顶部选择要管理的账号
3. **删除账号**：在账号管理页面点击删除按钮

### DNS 记录管理
1. **查看记录**：选择账号后自动加载该账号下的所有域名和 DNS 记录
2. **添加记录**：点击"添加记录"按钮，填写记录信息
3. **编辑记录**：点击记录行的编辑按钮
4. **删除记录**：点击记录行的删除按钮

## 故障排除

### 常见问题

**1. API Token 无效**
- 检查 Token 是否正确复制
- 确认 Token 权限包含 Zone:Read 和 DNS:Edit
- 检查 Token 是否已过期

**2. 无法访问应用**
- 检查防火墙是否开放 3001 和 5173 端口
- 确认服务是否正常启动
- 检查 CORS 配置是否正确

**3. 前端白屏**
- 检查浏览器控制台错误信息
- 确认后端服务是否正常运行
- 清除浏览器缓存重试

### 日志查看
```bash
# 查看后端日志
cd server
npm start

# 查看 systemd 服务日志
sudo journalctl -u cloudflare-dns-backend -f
sudo journalctl -u cloudflare-dns-frontend -f
```

## 🔧 其他有用脚本

- `start-dev.sh` - 一键启动开发环境
- `stop-dev.sh` - 停止开发环境
- `deploy.sh` - 自动化部署脚本
- `manage-production.sh` - 生产环境管理脚本

### 生产环境管理

使用 `manage-production.sh` 脚本可以方便地管理生产环境的 systemd 服务：

```bash
# 交互式菜单
./manage-production.sh

# 直接命令
./manage-production.sh status    # 查看服务状态
./manage-production.sh start     # 启动服务
./manage-production.sh stop      # 停止服务
./manage-production.sh restart   # 重启服务
./manage-production.sh logs      # 查看日志
./manage-production.sh autostart # 管理开机自启
```

**功能特性：**
- 🔍 实时服务状态监控
- 🚀 一键启动/停止/重启服务
- 📋 多种日志查看方式（系统日志、应用日志）
- 🤖 开机自启管理
- 🎨 彩色输出，用户友好

## 迁移指南

### 迁移到新服务器
1. **备份数据**：复制整个项目目录
2. **环境准备**：在新服务器上安装 Node.js
3. **部署应用**：运行 `./deploy.sh` 脚本
4. **恢复配置**：复制 `.env` 文件和账号数据
5. **启动服务**：按照部署说明启动服务

### 数据备份
```bash
# 备份账号数据（如果使用文件存储）
cp server/accounts.json /backup/

# 备份环境配置
cp .env /backup/
```
