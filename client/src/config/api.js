// 统一的API配置
export const getApiBaseUrl = () => {
  // 在开发环境下使用localhost
  if (process.env.NODE_ENV === 'development') {
    return 'http://localhost:3005/api';
  }
  
  // 生产环境：使用当前域名的反代路径
  const currentProtocol = window.location.protocol;
  const currentHost = window.location.host;
  return `${currentProtocol}//${currentHost}/api`;
};

export const API_BASE_URL = getApiBaseUrl();