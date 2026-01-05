# 项目结构说明

```
cloudflare-dns-manager/
├── 📁 server/                    # 后端服务
│   ├── 📄 server.js              # 主服务器文件
│   ├── 📄 package.json           # 后端依赖配置
│   └── 📄 package-lock.json      # 依赖锁定文件
│
├── 📁 client/                    # 前端应用
│   ├── 📁 src/                   # 源代码目录
│   │   ├── 📄 main.jsx           # 应用入口
│   │   ├── 📄 App.jsx            # 主应用组件
│   │   ├── 📄 AccountManager.jsx # 账号管理组件
│   │   ├── 📄 RecordForm.jsx     # DNS记录表单组件
│   │   ├── 📄 index.css          # 全局样式
│   │   └── 📄 App.css            # 应用样式
│   ├── 📁 public/                # 静态资源
│   ├── 📁 dist/                  # 构建输出目录
│   ├── 📄 index.html             # HTML模板
│   ├── 📄 package.json           # 前端依赖配置
│   ├── 📄 vite.config.js         # Vite构建配置
│   ├── 📄 tailwind.config.js     # Tailwind CSS配置
│   └── 📄 postcss.config.js      # PostCSS配置
│
├── 📁 logs/                      # 日志目录（运行时创建）
│   ├── 📄 backend.log            # 后端日志
│   ├── 📄 frontend.log           # 前端日志
│   ├── 📄 backend.pid            # 后端进程ID
│   └── 📄 frontend.pid           # 前端进程ID
│
├── 📄 .env                       # 环境变量配置（需要创建）
├── 📄 .env.example               # 环境变量模板
├── 📄 .gitignore                 # Git忽略文件
├── 📄 README.md                  # 项目说明文档
├── 📄 DEPLOYMENT_CHECKLIST.md    # 部署检查清单
├── 📄 PROJECT_STRUCTURE.md       # 项目结构说明（本文件）
│
├── 🚀 deploy.sh                  # 一键部署脚本
├── 🚀 start-dev.sh               # 开发环境启动脚本
└── 🚀 stop-dev.sh                # 开发环境停止脚本
```

## 核心文件说明

### 后端文件

**server/server.js**
- Express.js 服务器主文件
- 提供 Cloudflare API 代理服务
- 处理账号管理和 DNS 记录操作
- 支持多账号管理功能

**server/package.json**
- 后端依赖管理
- 主要依赖：express, cors, axios
- 启动脚本：`npm start`

### 前端文件

**client/src/App.jsx**
- 主应用组件
- DNS 记录管理界面
- 账号切换功能

**client/src/AccountManager.jsx**
- 账号管理组件
- 添加、删除、编辑 Cloudflare 账号
- 账号列表显示

**client/src/RecordForm.jsx**
- DNS 记录表单组件
- 添加和编辑 DNS 记录
- 表单验证和提交

**client/package.json**
- 前端依赖管理
- 主要依赖：react, vite, tailwindcss, axios
- 构建脚本：`npm run build`
- 开发脚本：`npm run dev`

### 配置文件

**.env**
- 环境变量配置文件
- 包含 Cloudflare API Token
- 服务器端口和 CORS 配置
- **注意：此文件包含敏感信息，不应提交到版本控制**

**client/vite.config.js**
- Vite 构建工具配置
- 开发服务器配置
- 插件配置

**client/tailwind.config.js**
- Tailwind CSS 配置
- 样式扫描路径
- 主题自定义

### 脚本文件

**deploy.sh**
- 一键部署脚本
- 自动安装依赖
- 环境检查和配置
- 可选的 systemd 服务创建

**start-dev.sh**
- 开发环境启动脚本
- 自动检查依赖和端口
- 后台启动前后端服务
- 生成日志文件

**stop-dev.sh**
- 开发环境停止脚本
- 优雅停止所有服务
- 清理进程和释放端口

## 数据存储

### 账号数据
- 存储在 `server/accounts.json`（运行时创建）
- JSON 格式存储账号信息
- 包含账号名称和加密的 API Token

### 日志文件
- `logs/backend.log` - 后端服务日志
- `logs/frontend.log` - 前端构建和运行日志
- `logs/*.pid` - 进程ID文件，用于服务管理

## 端口使用

- **3001** - 后端 API 服务
- **5173** - 前端开发服务器（Vite默认）
- **5174, 5175...** - 前端备用端口（如果5173被占用）

## 开发工作流

1. **初始化**：运行 `./deploy.sh` 或手动安装依赖
2. **配置**：编辑 `.env` 文件设置 API Token
3. **开发**：运行 `./start-dev.sh` 启动开发环境
4. **调试**：查看 `logs/` 目录中的日志文件
5. **停止**：运行 `./stop-dev.sh` 停止服务
6. **部署**：运行 `npm run build` 构建生产版本

## 注意事项

- `.env` 文件包含敏感信息，不要提交到版本控制
- `logs/` 和 `client/dist/` 目录在运行时创建
- `node_modules/` 目录通过 npm install 创建
- 确保防火墙开放必要端口
- 定期备份 `server/accounts.json` 文件