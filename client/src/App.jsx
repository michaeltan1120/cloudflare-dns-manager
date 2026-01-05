import { useState, useEffect } from 'react'
import axios from 'axios'
import RecordForm from './RecordForm'
import AccountManager from './AccountManager'
import Login from './Login'
import { AuthProvider, useAuth } from './AuthContext'
import { getApiBaseUrl } from './config/api'

function AppContent() {
  // 状态管理
  const [accounts, setAccounts] = useState([])
  const [selectedAccount, setSelectedAccount] = useState(null)
  const [zones, setZones] = useState([])
  const [selectedZone, setSelectedZone] = useState(null)
  const [dnsRecords, setDnsRecords] = useState([])
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')
  const [isFormOpen, setIsFormOpen] = useState(false)
  const [editingRecord, setEditingRecord] = useState(null)
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [currentView, setCurrentView] = useState('dns') // 'dns' or 'accounts'
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false)
  const [recordToDelete, setRecordToDelete] = useState(null)

  const API_BASE_URL = getApiBaseUrl()

  const { user, isAuthenticated, authenticatedFetch, logout } = useAuth()

  // 获取账号列表
  useEffect(() => {
    const fetchAccounts = async () => {
      if (!isAuthenticated()) return
      
      try {
        const response = await authenticatedFetch(`${API_BASE_URL}/accounts`)
        const data = await response.json()
        const accountList = data.success ? data.data : []
        setAccounts(accountList)
        // 如果有账号，默认选择第一个
        if (accountList.length > 0 && !selectedAccount) {
          setSelectedAccount(accountList[0])
        }
      } catch (err) {
        console.error('获取账号列表失败:', err)
        setError('获取账号列表失败')
      }
    }

    fetchAccounts()
  }, [isAuthenticated])

  // 获取域名列表
  useEffect(() => {
    if (!selectedAccount) {
      setZones([])
      return
    }

    const fetchZones = async () => {
      setIsLoading(true)
      setError('')
      try {
        const response = await authenticatedFetch(`${API_BASE_URL}/accounts/${selectedAccount.id}/zones`)
        const data = await response.json()
        setZones(data.data || [])
      } catch (err) {
        setError('获取域名列表失败: ' + err.message)
      } finally {
        setIsLoading(false)
      }
    }

    fetchZones()
  }, [selectedAccount])

  // 当选中域名变化时，获取DNS记录
  useEffect(() => {
    if (!selectedZone) {
      setDnsRecords([])
      return
    }

    const fetchDnsRecords = async () => {
        setIsLoading(true)
        setError('')
        try {
          const response = await authenticatedFetch(`${API_BASE_URL}/accounts/${selectedAccount.id}/zones/${selectedZone.id}/dns_records`)
          const data = await response.json()
          setDnsRecords(data.data || [])
        } catch (err) {
          setError('获取DNS记录失败: ' + err.message)
        } finally {
          setIsLoading(false)
        }
      }

    fetchDnsRecords()
  }, [selectedZone])

  // 处理账号选择
  const handleAccountChange = (e) => {
    const accountId = e.target.value
    const account = accounts.find(a => a.id === accountId)
    setSelectedAccount(account || null)
    setSelectedZone(null) // 重置选中的域名
    setDnsRecords([]) // 清空DNS记录
  }

  // 处理域名选择
  const handleZoneChange = (e) => {
    const zoneId = e.target.value
    const zone = zones.find(z => z.id === zoneId)
    setSelectedZone(zone || null)
  }

  // 处理视图切换
  const handleViewChange = (view) => {
    setCurrentView(view)
    setError('') // 清除错误信息
    setSuccess('') // 清除成功信息
    // 切换到DNS管理时刷新账号列表
    if (view === 'dns') {
      refreshAccounts()
    }
  }

  // 刷新账号列表
  const refreshAccounts = async () => {
    try {
      const response = await authenticatedFetch(`${API_BASE_URL}/accounts`)
      const data = await response.json()
      const accountList = data.success ? data.data : []
      setAccounts(accountList)
      // 如果当前选中的账号被删除了，重置选择
      if (selectedAccount && !accountList.find(a => a.id === selectedAccount.id)) {
        setSelectedAccount(accountList.length > 0 ? accountList[0] : null)
      }
    } catch (err) {
      console.error('刷新账号列表失败:', err)
    }
  }

  // 显示删除确认对话框
  const showDeleteConfirmDialog = (record) => {
    setRecordToDelete(record)
    setShowDeleteConfirm(true)
  }

  // 取消删除
  const cancelDelete = () => {
    setShowDeleteConfirm(false)
    setRecordToDelete(null)
  }

  // 确认删除DNS记录
  const confirmDeleteRecord = async () => {
    if (!recordToDelete) return
    
    setIsLoading(true)
    setError('')
    setSuccess('')
    
    try {
      await authenticatedFetch(`${API_BASE_URL}/accounts/${selectedAccount.id}/zones/${selectedZone.id}/dns_records/${recordToDelete.id}`, {
        method: 'DELETE'
      })
      // 重新获取DNS记录
      const response = await authenticatedFetch(`${API_BASE_URL}/accounts/${selectedAccount.id}/zones/${selectedZone.id}/dns_records`)
      const data = await response.json()
      setDnsRecords(data.data || [])
      setSuccess('DNS记录删除成功！')
      
      // 3秒后自动清除成功消息
      setTimeout(() => {
        setSuccess('')
      }, 3000)
    } catch (err) {
      setError('删除DNS记录失败: ' + err.message)
    } finally {
      setIsLoading(false)
      setShowDeleteConfirm(false)
      setRecordToDelete(null)
    }
  }

  // 打开添加记录表单
  const handleAddRecord = () => {
    setEditingRecord(null)
    setIsFormOpen(true)
  }

  // 打开编辑记录表单
  const handleEditRecord = (record) => {
    setEditingRecord(record)
    setIsFormOpen(true)
  }

  // 关闭表单
  const handleCloseForm = () => {
    setIsFormOpen(false)
    setEditingRecord(null)
  }

  // 提交表单
  const handleSubmitForm = async (formData) => {
    setIsSubmitting(true)
    setError('')
    setSuccess('')
    
    try {
      if (editingRecord) {
        // 更新记录
        await authenticatedFetch(`${API_BASE_URL}/accounts/${selectedAccount.id}/zones/${selectedZone.id}/dns_records/${editingRecord.id}`, {
          method: 'PUT',
          body: JSON.stringify(formData)
        })
        setSuccess('DNS记录更新成功！')
      } else {
        // 添加新记录
        await authenticatedFetch(`${API_BASE_URL}/accounts/${selectedAccount.id}/zones/${selectedZone.id}/dns_records`, {
          method: 'POST',
          body: JSON.stringify(formData)
        })
        setSuccess('DNS记录添加成功！')
      }
      
      // 重新获取DNS记录
      const response = await authenticatedFetch(`${API_BASE_URL}/accounts/${selectedAccount.id}/zones/${selectedZone.id}/dns_records`)
      const data = await response.json()
      setDnsRecords(data.data || [])
      
      // 关闭表单
      handleCloseForm()
      
      // 3秒后自动清除成功消息
      setTimeout(() => {
        setSuccess('')
      }, 3000)
    } catch (err) {
      setError((editingRecord ? '更新' : '添加') + 'DNS记录失败: ' + err.message)
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="max-w-6xl mx-auto px-4">
        <h1 className="text-3xl font-bold text-gray-900 mb-8">Cloudflare DNS 管理</h1>
        
        {/* 导航栏 */}
        <div className="bg-white rounded-lg shadow mb-6">
          <div className="px-6 py-4">
            <div className="flex justify-between items-center">
              <div className="flex items-center space-x-4">
                <span className="text-sm text-gray-600">欢迎, {user?.username}</span>
                <span className="text-xs bg-blue-100 text-blue-800 px-2 py-1 rounded">{user?.role}</span>
              </div>
              <div className="flex space-x-4">
                <button
                  onClick={() => handleViewChange('dns')}
                  className={`px-4 py-2 rounded-md font-medium ${
                    currentView === 'dns'
                      ? 'bg-blue-600 text-white'
                      : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                  }`}
                >
                  DNS 管理
                </button>
                <button
                  onClick={() => handleViewChange('accounts')}
                  className={`px-4 py-2 rounded-md font-medium ${
                    currentView === 'accounts'
                      ? 'bg-blue-600 text-white'
                      : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                  }`}
                >
                  账号管理
                </button>
                <button
                  onClick={logout}
                  className="px-4 py-2 rounded-md font-medium bg-red-600 text-white hover:bg-red-700"
                >
                  登出
                </button>
              </div>
            </div>
          </div>
        </div>
        
        {/* 错误提示 */}
        {error && (
          <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-6">
            {error}
          </div>
        )}
        
        {/* 成功提示 */}
        {success && (
          <div className="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded mb-6">
            {success}
          </div>
        )}

        {/* 账号管理视图 */}
        {currentView === 'accounts' && (
          <AccountManager onAccountChange={refreshAccounts} />
        )}

        {/* DNS管理视图 */}
        {currentView === 'dns' && (
          <>
            {/* 账号选择器 */}
            <div className="bg-white rounded-lg shadow p-6 mb-6">
              <label htmlFor="account-select" className="block text-sm font-medium text-gray-700 mb-2">
                选择账号
              </label>
              <select
                id="account-select"
                value={selectedAccount?.id || ''}
                onChange={handleAccountChange}
                className="block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 mb-4"
                disabled={isLoading}
              >
                <option value="">请选择账号...</option>
                {accounts.map(account => (
                  <option key={account.id} value={account.id}>
                    {account.name} ({account.id})
                  </option>
                ))}
              </select>
              
              {/* 域名选择器 */}
              {selectedAccount && (
                <>
                  <label htmlFor="zone-select" className="block text-sm font-medium text-gray-700 mb-2">
                    选择域名
                  </label>
                  <select
                    id="zone-select"
                    value={selectedZone?.id || ''}
                    onChange={handleZoneChange}
                    className="block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                    disabled={isLoading}
                  >
                    <option value="">请选择域名...</option>
                    {zones.map(zone => (
                      <option key={zone.id} value={zone.id}>
                        {zone.name}
                      </option>
                    ))}
                  </select>
                </>
              )}
            </div>

            {/* DNS记录表格 */}
            {selectedZone && (
              <div className="bg-white rounded-lg shadow">
                <div className="px-6 py-4 border-b border-gray-200">
                  <h2 className="text-lg font-medium text-gray-900">
                    {selectedZone.name} 的DNS记录
                  </h2>
                </div>
                 
                 {isLoading ? (
                   <div className="px-6 py-8 text-center">
                     <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
                     <p className="mt-2 text-gray-600">加载中...</p>
                   </div>
                 ) : dnsRecords.length === 0 ? (
                   <div className="px-6 py-8 text-center text-gray-500">
                     暂无DNS记录
                   </div>
                 ) : (
                   <div className="overflow-x-auto">
                      <table className="min-w-full divide-y divide-gray-200">
                        <thead className="bg-gray-50">
                          <tr>
                            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                              类型
                            </th>
                            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                              名称
                            </th>
                            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                              内容
                            </th>
                            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                              代理状态
                            </th>
                            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                              操作
                            </th>
                          </tr>
                        </thead>
                         <tbody className="bg-white divide-y divide-gray-200">
                           {dnsRecords.map(record => (
                             <tr key={record.id} className="hover:bg-gray-50">
                               <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                                 {record.type}
                               </td>
                               <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                                 {record.name}
                               </td>
                               <td className="px-6 py-4 text-sm text-gray-900 max-w-xs truncate">
                                 {record.content}
                               </td>
                               <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                                 <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${
                                   record.proxied 
                                     ? 'bg-orange-100 text-orange-800' 
                                     : 'bg-gray-100 text-gray-800'
                                 }`}>
                                   {record.proxied ? '已代理' : '仅DNS'}
                                 </span>
                               </td>
                               <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                                 <button
                                   onClick={() => handleEditRecord(record)}
                                   className="text-blue-600 hover:text-blue-900 mr-4"
                                   disabled={isLoading}
                                 >
                                   修改
                                 </button>
                                 <button
                                   onClick={() => showDeleteConfirmDialog(record)}
                                   className="text-red-600 hover:text-red-900"
                                   disabled={isLoading}
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
               )}
               
               {/* 添加记录按钮 */}
               {selectedZone && (
                 <div className="mt-6">
                   <button
                     onClick={handleAddRecord}
                     className="bg-blue-600 hover:bg-blue-700 text-white font-medium py-2 px-4 rounded-md"
                     disabled={isLoading}
                   >
                     添加DNS记录
                   </button>
                 </div>
               )}
           </>
         )}
         
         {/* DNS记录表单 */}
         <RecordForm
           isOpen={isFormOpen}
           record={editingRecord}
           onSubmit={handleSubmitForm}
           onClose={handleCloseForm}
           isLoading={isSubmitting}
         />
         
         {/* 删除确认对话框 */}
         {showDeleteConfirm && (
           <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
             <div className="bg-white rounded-lg shadow-xl max-w-md w-full mx-4">
               <div className="px-6 py-4 border-b border-gray-200">
                 <h3 className="text-lg font-medium text-gray-900 flex items-center">
                   <svg className="w-6 h-6 text-red-600 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                     <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L4.082 16.5c-.77.833.192 2.5 1.732 2.5z" />
                   </svg>
                   确认删除
                 </h3>
               </div>
               <div className="px-6 py-4">
                 <p className="text-gray-700 mb-4">
                   确定要删除DNS记录 <strong>{recordToDelete?.name}</strong> ({recordToDelete?.type}) 吗？
                 </p>
                 <p className="text-red-600 text-sm">
                   此操作不可撤销！
                 </p>
               </div>
               <div className="px-6 py-4 border-t border-gray-200 flex justify-end space-x-3">
                 <button
                   onClick={cancelDelete}
                   className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                   disabled={isLoading}
                 >
                   取消
                 </button>
                 <button
                   onClick={confirmDeleteRecord}
                   className="px-4 py-2 text-sm font-medium text-white bg-red-600 border border-transparent rounded-md shadow-sm hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 disabled:opacity-50"
                   disabled={isLoading}
                 >
                   {isLoading ? '删除中...' : '确认删除'}
                 </button>
               </div>
             </div>
           </div>
         )}
       </div>
     </div>
   )
}

// 主App组件，包含认证逻辑
function App() {
  return (
    <AuthProvider>
      <AppWrapper />
    </AuthProvider>
  )
}

// App包装组件，处理登录状态
function AppWrapper() {
  const { user, isAuthenticated, loading, login } = useAuth()

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-lg">加载中...</div>
      </div>
    )
  }

  if (!isAuthenticated()) {
    return <Login onLogin={login} />
  }

  return (
    <div>
      <AppContent />
    </div>
  )
}

export default App
