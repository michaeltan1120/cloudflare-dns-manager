const express = require('express');
const cors = require('cors');
const axios = require('axios');
const fs = require('fs');
const path = require('path');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
require('dotenv').config({ path: '../.env' });

const app = express();
const PORT = process.env.PORT || 3005;

// 账号数据存储文件路径
const ACCOUNTS_FILE = path.join(__dirname, 'accounts.json');
const AUTH_FILE = path.join(__dirname, 'auth.json');

// CORS配置，支持多个来源,这里需要修改成你前端实际访问的网址
const allowedOrigins = [
  'http://localhost:5173',
  'http://127.0.0.1:5173',
  'http://www.abc.com',
  'https://www.abc.com',
  process.env.CLIENT_URL
].filter(Boolean);

app.use(cors({ 
  origin: function (origin, callback) {
    // 允许没有origin的请求（如移动应用）
    if (!origin) return callback(null, true);
    
    if (allowedOrigins.indexOf(origin) !== -1) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true
}));
app.use(express.json());

// 认证管理类
class AuthManager {
  constructor() {
    this.authConfig = this.loadAuthConfig();
  }

  loadAuthConfig() {
    try {
      if (fs.existsSync(AUTH_FILE)) {
        const data = fs.readFileSync(AUTH_FILE, 'utf8');
        return JSON.parse(data);
      }
    } catch (error) {
      console.error('Error loading auth config:', error);
    }
    return { users: [], settings: { jwt_secret: 'default-secret', token_expiry: '24h' } };
  }

  async validateUser(username, password) {
    const user = this.authConfig.users.find(u => u.username === username);
    if (!user) return null;
    
    // 直接比较密码（生产环境应该使用bcrypt）
    if (user.password === password) {
      return { username: user.username, role: user.role };
    }
    return null;
  }

  generateToken(user) {
    return jwt.sign(
      { username: user.username, role: user.role },
      this.authConfig.settings.jwt_secret,
      { expiresIn: this.authConfig.settings.token_expiry }
    );
  }

  verifyToken(token) {
    try {
      return jwt.verify(token, this.authConfig.settings.jwt_secret);
    } catch (error) {
      return null;
    }
  }
}

const authManager = new AuthManager();

// JWT认证中间件
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  const user = authManager.verifyToken(token);
  if (!user) {
    return res.status(403).json({ error: 'Invalid or expired token' });
  }

  req.user = user;
  next();
};

// 账号管理类
class AccountManager {
  constructor() {
    this.accounts = this.loadAccounts();
  }

  loadAccounts() {
    try {
      if (fs.existsSync(ACCOUNTS_FILE)) {
        const data = fs.readFileSync(ACCOUNTS_FILE, 'utf8');
        return JSON.parse(data);
      }
    } catch (error) {
      console.error('Error loading accounts:', error);
    }
    return {};
  }

  saveAccounts() {
    try {
      fs.writeFileSync(ACCOUNTS_FILE, JSON.stringify(this.accounts, null, 2));
    } catch (error) {
      console.error('Error saving accounts:', error);
      throw error;
    }
  }

  addAccount(id, name, token) {
    this.accounts[id] = {
      id,
      name,
      token,
      createdAt: new Date().toISOString()
    };
    this.saveAccounts();
    return this.accounts[id];
  }

  removeAccount(id) {
    if (this.accounts[id]) {
      delete this.accounts[id];
      this.saveAccounts();
      return true;
    }
    return false;
  }

  getAccount(id) {
    return this.accounts[id];
  }

  getAllAccounts() {
    // 返回账号列表但不包含token（安全考虑）
    return Object.values(this.accounts).map(account => ({
      id: account.id,
      name: account.name,
      createdAt: account.createdAt
    }));
  }

  createCloudflareAPI(accountId) {
    const account = this.accounts[accountId];
    if (!account) {
      throw new Error(`Account ${accountId} not found`);
    }

    return axios.create({
      baseURL: 'https://api.cloudflare.com/client/v4',
      headers: {
        'Authorization': `Bearer ${account.token}`,
        'Content-Type': 'application/json'
      }
    });
  }
}

const accountManager = new AccountManager();

// 全局错误处理函数
const handleCloudflareError = (error, res) => {
  console.error('Cloudflare API Error:', error.response?.data || error.message);
  
  if (error.response) {
    // 格式化错误信息，确保返回字符串而不是对象
    let errorMessage = 'Cloudflare API error';
    let detailMessage = 'Unknown error';
    
    if (error.response.data.errors) {
      if (Array.isArray(error.response.data.errors)) {
        errorMessage = error.response.data.errors.map(err => 
          typeof err === 'object' ? err.message || JSON.stringify(err) : err
        ).join('; ');
      } else if (typeof error.response.data.errors === 'object') {
        errorMessage = error.response.data.errors.message || JSON.stringify(error.response.data.errors);
      } else {
        errorMessage = error.response.data.errors;
      }
    }
    
    if (error.response.data.messages) {
      if (Array.isArray(error.response.data.messages)) {
        detailMessage = error.response.data.messages.map(msg => 
          typeof msg === 'object' ? msg.message || JSON.stringify(msg) : msg
        ).join('; ');
      } else if (typeof error.response.data.messages === 'object') {
        detailMessage = error.response.data.messages.message || JSON.stringify(error.response.data.messages);
      } else {
        detailMessage = error.response.data.messages;
      }
    }
    
    return res.status(error.response.status).json({
      success: false,
      error: errorMessage,
      message: detailMessage
    });
  }
  
  return res.status(500).json({
    success: false,
    error: 'Internal server error',
    message: error.message
  });
};

// API端点

// 账号管理API

// 登录API
app.post('/api/auth/login', async (req, res) => {
  try {
    const { username, password } = req.body;
    
    if (!username || !password) {
      return res.status(400).json({ error: 'Username and password are required' });
    }

    const user = await authManager.validateUser(username, password);
    if (!user) {
      return res.status(401).json({ error: 'Invalid username or password' });
    }

    const token = authManager.generateToken(user);
    res.json({ 
      token, 
      user: { username: user.username, role: user.role },
      message: 'Login successful' 
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Login failed' });
  }
});

// 验证token API
app.get('/api/auth/verify', authenticateToken, (req, res) => {
  res.json({ 
    valid: true, 
    user: { username: req.user.username, role: req.user.role } 
  });
});

// 获取所有账号 - 需要认证
app.get('/api/accounts', authenticateToken, (req, res) => {
  try {
    const accounts = accountManager.getAllAccounts();
    res.json({ success: true, data: accounts });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// 添加账号 - 需要认证
app.post('/api/accounts', authenticateToken, async (req, res) => {
  try {
    const { id, name, token } = req.body;
    
    if (!id || !name || !token) {
      return res.status(400).json({ 
        success: false, 
        error: 'Missing required fields: id, name, token' 
      });
    }

    // 验证token是否有效
    const testAPI = axios.create({
      baseURL: 'https://api.cloudflare.com/client/v4',
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });

    const verifyResponse = await testAPI.get('/user/tokens/verify');
    
    const account = accountManager.addAccount(id, name, token);
    res.json({ 
      success: true, 
      data: { id: account.id, name: account.name, createdAt: account.createdAt } 
    });
  } catch (error) {
    console.error('API Token验证错误:', error.response?.data || error.message);
    if (error.response?.status === 401 || error.response?.status === 403) {
      res.status(400).json({ success: false, error: 'API Token无效或权限不足，请检查Token是否正确以及是否具有Zone:Read和DNS:Edit权限' });
    } else if (error.response?.status === 400) {
      res.status(400).json({ success: false, error: 'API Token格式错误，请确保使用的是Custom API Token而不是Global API Key' });
    } else {
      res.status(500).json({ success: false, error: `验证API Token时发生错误: ${error.message}` });
    }
  }
});

// 删除账号 - 需要认证
app.delete('/api/accounts/:accountId', authenticateToken, (req, res) => {
  try {
    const { accountId } = req.params;
    const success = accountManager.removeAccount(accountId);
    
    if (success) {
      res.json({ success: true, message: 'Account deleted successfully' });
    } else {
      res.status(404).json({ success: false, error: 'Account not found' });
    }
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// DNS管理API（支持多账号）

// 获取指定账号的所有域名 - 需要认证
app.get('/api/accounts/:accountId/zones', authenticateToken, async (req, res) => {
  try {
    const { accountId } = req.params;
    const cloudflareAPI = accountManager.createCloudflareAPI(accountId);
    const response = await cloudflareAPI.get('/zones');
    res.json({ success: true, data: response.data.result });
  } catch (error) {
    if (error.message.includes('not found')) {
      res.status(404).json({ success: false, error: 'Account not found' });
    } else {
      handleCloudflareError(error, res);
    }
  }
});

// 兼容旧版API（使用第一个账号或返回错误）- 需要认证
app.get('/api/zones', authenticateToken, async (req, res) => {
  try {
    const accounts = accountManager.getAllAccounts();
    if (accounts.length === 0) {
      return res.status(400).json({ 
        success: false, 
        error: 'No Cloudflare accounts configured. Please add an account first.' 
      });
    }
    
    const firstAccountId = accounts[0].id;
    const cloudflareAPI = accountManager.createCloudflareAPI(firstAccountId);
    const response = await cloudflareAPI.get('/zones');
    res.json({ success: true, data: response.data.result });
  } catch (error) {
    handleCloudflareError(error, res);
  }
});

// 获取指定账号的DNS记录 - 需要认证
app.get('/api/accounts/:accountId/zones/:zoneId/dns_records', authenticateToken, async (req, res) => {
  try {
    const { accountId, zoneId } = req.params;
    const cloudflareAPI = accountManager.createCloudflareAPI(accountId);
    const response = await cloudflareAPI.get(`/zones/${zoneId}/dns_records`);
    res.json({ success: true, data: response.data.result });
  } catch (error) {
    if (error.message.includes('not found')) {
      res.status(404).json({ success: false, error: 'Account not found' });
    } else {
      handleCloudflareError(error, res);
    }
  }
});

// 创建指定账号的DNS记录 - 需要认证
app.post('/api/accounts/:accountId/zones/:zoneId/dns_records', authenticateToken, async (req, res) => {
  try {
    const { accountId, zoneId } = req.params;
    const cloudflareAPI = accountManager.createCloudflareAPI(accountId);
    const response = await cloudflareAPI.post(`/zones/${zoneId}/dns_records`, req.body);
    res.json({ success: true, data: response.data.result });
  } catch (error) {
    if (error.message.includes('not found')) {
      res.status(404).json({ success: false, error: 'Account not found' });
    } else {
      handleCloudflareError(error, res);
    }
  }
});

// 更新指定账号的DNS记录 - 需要认证
app.put('/api/accounts/:accountId/zones/:zoneId/dns_records/:recordId', authenticateToken, async (req, res) => {
  try {
    const { accountId, zoneId, recordId } = req.params;
    const cloudflareAPI = accountManager.createCloudflareAPI(accountId);
    const response = await cloudflareAPI.put(`/zones/${zoneId}/dns_records/${recordId}`, req.body);
    res.json({ success: true, data: response.data.result });
  } catch (error) {
    if (error.message.includes('not found')) {
      res.status(404).json({ success: false, error: 'Account not found' });
    } else {
      handleCloudflareError(error, res);
    }
  }
});

// 删除指定账号的DNS记录 - 需要认证
app.delete('/api/accounts/:accountId/zones/:zoneId/dns_records/:recordId', authenticateToken, async (req, res) => {
  try {
    const { accountId, zoneId, recordId } = req.params;
    const cloudflareAPI = accountManager.createCloudflareAPI(accountId);
    const response = await cloudflareAPI.delete(`/zones/${zoneId}/dns_records/${recordId}`);
    res.json({ success: true, data: response.data.result });
  } catch (error) {
    if (error.message.includes('not found')) {
      res.status(404).json({ success: false, error: 'Account not found' });
    } else {
      handleCloudflareError(error, res);
    }
  }
});

// 兼容旧版DNS API（使用第一个账号）

// 获取DNS记录 - 需要认证
app.get('/api/zones/:zoneId/dns_records', authenticateToken, async (req, res) => {
  try {
    const accounts = accountManager.getAllAccounts();
    if (accounts.length === 0) {
      return res.status(400).json({ 
        success: false, 
        error: 'No Cloudflare accounts configured. Please add an account first.' 
      });
    }
    
    const firstAccountId = accounts[0].id;
    const cloudflareAPI = accountManager.createCloudflareAPI(firstAccountId);
    const response = await cloudflareAPI.get(`/zones/${req.params.zoneId}/dns_records`);
    res.json({ success: true, data: response.data.result });
  } catch (error) {
    handleCloudflareError(error, res);
  }
});

// 创建DNS记录 - 需要认证
app.post('/api/zones/:zoneId/dns_records', authenticateToken, async (req, res) => {
  try {
    const accounts = accountManager.getAllAccounts();
    if (accounts.length === 0) {
      return res.status(400).json({ 
        success: false, 
        error: 'No Cloudflare accounts configured. Please add an account first.' 
      });
    }
    
    const firstAccountId = accounts[0].id;
    const cloudflareAPI = accountManager.createCloudflareAPI(firstAccountId);
    const response = await cloudflareAPI.post(`/zones/${req.params.zoneId}/dns_records`, req.body);
    res.json({ success: true, data: response.data.result });
  } catch (error) {
    handleCloudflareError(error, res);
  }
});

// 更新DNS记录 - 需要认证
app.put('/api/zones/:zoneId/dns_records/:recordId', authenticateToken, async (req, res) => {
  try {
    const accounts = accountManager.getAllAccounts();
    if (accounts.length === 0) {
      return res.status(400).json({ 
        success: false, 
        error: 'No Cloudflare accounts configured. Please add an account first.' 
      });
    }
    
    const firstAccountId = accounts[0].id;
    const cloudflareAPI = accountManager.createCloudflareAPI(firstAccountId);
    const response = await cloudflareAPI.put(`/zones/${req.params.zoneId}/dns_records/${req.params.recordId}`, req.body);
    res.json({ success: true, data: response.data.result });
  } catch (error) {
    handleCloudflareError(error, res);
  }
});

// 删除DNS记录 - 需要认证
app.delete('/api/zones/:zoneId/dns_records/:recordId', authenticateToken, async (req, res) => {
  try {
    const accounts = accountManager.getAllAccounts();
    if (accounts.length === 0) {
      return res.status(400).json({ 
        success: false, 
        error: 'No Cloudflare accounts configured. Please add an account first.' 
      });
    }
    
    const firstAccountId = accounts[0].id;
    const cloudflareAPI = accountManager.createCloudflareAPI(firstAccountId);
    const response = await cloudflareAPI.delete(`/zones/${req.params.zoneId}/dns_records/${req.params.recordId}`);
    res.json({ success: true, data: response.data.result });
  } catch (error) {
    handleCloudflareError(error, res);
  }
});

// 健康检查端点
app.get('/api/health', (req, res) => {
  res.json({
    success: true,
    message: 'Cloudflare DNS Server is running',
    timestamp: new Date().toISOString()
  });
});

// 全局错误处理中间件
app.use((error, req, res, next) => {
  console.error('Unhandled error:', error);
  res.status(500).json({
    success: false,
    error: 'Internal server error',
    message: error.message
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Cloudflare DNS Server is running on 0.0.0.0:${PORT}`);
  console.log(`📡 CORS enabled for: ${process.env.CLIENT_URL || 'http://localhost:5173'}`);
  
  const accounts = accountManager.getAllAccounts();
  console.log(`📋 Configured accounts: ${accounts.length}`);
  
  if (accounts.length === 0) {
    console.warn('⚠️  No Cloudflare accounts configured. Add accounts via /api/accounts endpoint.');
  } else {
    console.log('✅ Multi-account management enabled');
    accounts.forEach(account => {
      console.log(`   - ${account.name} (${account.id})`);
    });
  }
});
