import React, { useState, useEffect } from 'react';
import { useAuth } from './AuthContext';
import { getApiBaseUrl } from './config/api';

const API_BASE_URL = getApiBaseUrl();

const AccountManager = ({ onAccountChange }) => {
  const { authenticatedFetch } = useAuth();
  const [accounts, setAccounts] = useState([]);
  const [showAddForm, setShowAddForm] = useState(false);
  const [formData, setFormData] = useState({
    id: '',
    name: '',
    token: ''
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);
  const [accountToDelete, setAccountToDelete] = useState(null);

  // 获取账号列表
  const fetchAccounts = async () => {
    try {
      const response = await authenticatedFetch(`${API_BASE_URL}/accounts`);
      const data = await response.json();
      if (data.success) {
        setAccounts(data.data);
      }
    } catch (error) {
      console.error('Error fetching accounts:', error);
      setError('获取账号列表失败');
    }
  };

  useEffect(() => {
    fetchAccounts();
  }, []);

  // 添加账号
  const handleAddAccount = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    setSuccess('');

    try {
      const response = await authenticatedFetch(`${API_BASE_URL}/accounts`, {
        method: 'POST',
        body: JSON.stringify(formData)
      });
      const data = await response.json();
      if (data.success) {
        setError(''); // 清除之前的错误消息
        setSuccess('账号添加成功！');
        setFormData({ id: '', name: '', token: '' });
        setShowAddForm(false);
        await fetchAccounts();
        if (onAccountChange) {
          onAccountChange();
        }
        // 3秒后自动清除成功消息
        setTimeout(() => {
          setSuccess('');
        }, 3000);
      }
    } catch (error) {
      setError('添加账号失败');
    } finally {
      setLoading(false);
    }
  };

  // 显示删除确认对话框
  const showDeleteConfirmDialog = (accountId, accountName) => {
    setAccountToDelete({ id: accountId, name: accountName });
    setShowDeleteConfirm(true);
  };

  // 取消删除
  const cancelDelete = () => {
    setShowDeleteConfirm(false);
    setAccountToDelete(null);
  };

  // 确认删除账号
  const confirmDeleteAccount = async () => {
    if (!accountToDelete) return;

    try {
      const response = await authenticatedFetch(`${API_BASE_URL}/accounts/${accountToDelete.id}`, {
        method: 'DELETE'
      });
      const data = await response.json();
      if (data.success) {
        setSuccess('账号删除成功！');
        await fetchAccounts();
        if (onAccountChange) {
          onAccountChange();
        }
      }
    } catch (error) {
      setError('删除账号失败');
    } finally {
      setShowDeleteConfirm(false);
      setAccountToDelete(null);
    }
  };

  // 清除消息
  const clearMessages = () => {
    setError('');
    setSuccess('');
  };

  return (
    <div className="bg-white rounded-lg shadow">
      <div className="px-6 py-4 border-b border-gray-200">
        <div className="flex justify-between items-center">
          <h2 className="text-lg font-medium text-gray-900">Cloudflare 账号管理</h2>
          <button
            onClick={() => {
              setShowAddForm(!showAddForm);
              clearMessages();
            }}
            className={`px-4 py-2 rounded-md font-medium ${
              showAddForm
                ? 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                : 'bg-blue-600 text-white hover:bg-blue-700'
            } transition-colors`}
          >
            {showAddForm ? '取消' : '添加账号'}
          </button>
        </div>
      </div>

      {/* 消息提示 */}
      {error && (
        <div className="px-6 py-4">
          <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded">
            {error}
          </div>
        </div>
      )}
      {success && (
        <div className="px-6 py-4">
          <div className="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded">
            {success}
          </div>
        </div>
      )}

      {/* 添加账号表单 */}
      {showAddForm && (
        <div className="px-6 py-4 border-b border-gray-200">
          <h3 className="text-lg font-medium text-gray-900 mb-4">添加新账号</h3>
          <form onSubmit={handleAddAccount} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                账号ID *
              </label>
              <input
                type="text"
                value={formData.id}
                onChange={(e) => setFormData({ ...formData, id: e.target.value })}
                className="block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                placeholder="例如: main-account"
                required
              />
              <p className="text-xs text-gray-500 mt-1">用于内部识别的唯一标识符</p>
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                账号名称 *
              </label>
              <input
                type="text"
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                className="block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                placeholder="例如: 主账号"
                required
              />
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                API Token *
              </label>
              <textarea
                value={formData.token}
                onChange={(e) => setFormData({ ...formData, token: e.target.value })}
                className="block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                placeholder="粘贴您的 Cloudflare API Token"
                rows={3}
                required
              />
              <p className="text-xs text-gray-500 mt-1">
                在 Cloudflare Dashboard → My Profile → API Tokens 中获取
              </p>
            </div>
            
            <div className="flex space-x-3">
              <button
                type="submit"
                disabled={loading}
                className="bg-blue-600 hover:bg-blue-700 disabled:bg-gray-400 text-white px-4 py-2 rounded-md font-medium transition-colors"
              >
                {loading ? '验证中...' : '添加账号'}
              </button>
              <button
                type="button"
                onClick={() => {
                  setShowAddForm(false);
                  setFormData({ id: '', name: '', token: '' });
                  clearMessages();
                }}
                className="bg-gray-100 hover:bg-gray-200 text-gray-700 px-4 py-2 rounded-md font-medium transition-colors"
              >
                取消
              </button>
            </div>
          </form>
        </div>
      )}

      {/* 账号列表 */}
      <div className="px-6 py-4">
        <h3 className="text-lg font-medium text-gray-900 mb-4">已配置账号 ({accounts.length})</h3>
        {accounts.length === 0 ? (
          <div className="text-center py-8 text-gray-500">
            <div className="inline-block w-16 h-16 mb-4">
              <svg className="w-full h-full text-gray-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1} d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z" />
              </svg>
            </div>
            <p className="text-gray-500">暂无配置的账号</p>
            <p className="text-sm mt-1 text-gray-400">点击上方"添加账号"按钮开始配置</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    账号信息
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    创建时间
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    操作
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {accounts.map((account) => (
                  <tr key={account.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div>
                        <div className="text-sm font-medium text-gray-900">{account.name}</div>
                        <div className="text-sm text-gray-500">ID: {account.id}</div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {new Date(account.createdAt).toLocaleString()}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                      <button
                        onClick={() => showDeleteConfirmDialog(account.id, account.name)}
                        className="text-red-600 hover:text-red-900"
                      >
                        删除
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* 删除确认对话框 */}
      {showDeleteConfirm && (
        <div className="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
          <div className="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white">
            <div className="mt-3 text-center">
              <div className="mx-auto flex items-center justify-center h-12 w-12 rounded-full bg-red-100">
                <svg className="h-6 w-6 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.732-.833-2.5 0L4.268 16.5c-.77.833.192 2.5 1.732 2.5z" />
                </svg>
              </div>
              <h3 className="text-lg leading-6 font-medium text-gray-900 mt-4">确认删除账号</h3>
              <div className="mt-2 px-7 py-3">
                <p className="text-sm text-gray-500">
                  您确定要删除账号 <span className="font-medium text-gray-900">"{accountToDelete?.name}"</span> 吗？
                </p>
                <p className="text-sm text-red-600 mt-2">
                  此操作不可撤销，删除后将无法恢复该账号的配置信息。
                </p>
              </div>
              <div className="items-center px-4 py-3">
                <div className="flex space-x-3">
                  <button
                    onClick={cancelDelete}
                    className="px-4 py-2 bg-gray-100 text-gray-700 text-base font-medium rounded-md w-full shadow-sm hover:bg-gray-200 focus:outline-none focus:ring-2 focus:ring-gray-300"
                  >
                    取消
                  </button>
                  <button
                    onClick={confirmDeleteAccount}
                    className="px-4 py-2 bg-red-600 text-white text-base font-medium rounded-md w-full shadow-sm hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500"
                  >
                    确认删除
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default AccountManager;