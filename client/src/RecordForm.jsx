import { useState, useEffect } from 'react'

/**
 * DNS记录表单组件
 * 支持添加和修改DNS记录
 */
const RecordForm = ({ isOpen, onClose, onSubmit, record, isLoading }) => {
  const [formData, setFormData] = useState({
    type: 'A',
    name: '',
    content: '',
    ttl: 1,
    proxied: false
  })

  const [errors, setErrors] = useState({})

  // DNS记录类型选项
  const recordTypes = [
    'A', 'AAAA', 'CNAME', 'MX', 'TXT', 'SRV', 'NS', 'PTR'
  ]

  // TTL选项
  const ttlOptions = [
    { value: 1, label: '自动' },
    { value: 120, label: '2分钟' },
    { value: 300, label: '5分钟' },
    { value: 600, label: '10分钟' },
    { value: 900, label: '15分钟' },
    { value: 1800, label: '30分钟' },
    { value: 3600, label: '1小时' },
    { value: 7200, label: '2小时' },
    { value: 18000, label: '5小时' },
    { value: 43200, label: '12小时' },
    { value: 86400, label: '1天' }
  ]

  // 当record变化时，更新表单数据
  useEffect(() => {
    if (record) {
      setFormData({
        type: record.type || 'A',
        name: record.name || '',
        content: record.content || '',
        ttl: record.ttl || 1,
        proxied: record.proxied || false
      })
    } else {
      setFormData({
        type: 'A',
        name: '',
        content: '',
        ttl: 1,
        proxied: false
      })
    }
    setErrors({})
  }, [record, isOpen])

  // 处理输入变化
  const handleChange = (e) => {
    const { name, value, type, checked } = e.target
    setFormData(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value
    }))
    // 清除对应字段的错误
    if (errors[name]) {
      setErrors(prev => ({ ...prev, [name]: '' }))
    }
  }

  // 表单验证
  const validateForm = () => {
    const newErrors = {}

    if (!formData.name.trim()) {
      newErrors.name = '名称不能为空'
    }

    if (!formData.content.trim()) {
      newErrors.content = '内容不能为空'
    }

    // 根据记录类型进行特定验证
    if (formData.type === 'A') {
      const ipv4Regex = /^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/
      if (formData.content && !ipv4Regex.test(formData.content)) {
        newErrors.content = '请输入有效的IPv4地址'
      }
    } else if (formData.type === 'AAAA') {
      const ipv6Regex = /^(?:[0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$/
      if (formData.content && !ipv6Regex.test(formData.content)) {
        newErrors.content = '请输入有效的IPv6地址'
      }
    }

    setErrors(newErrors)
    return Object.keys(newErrors).length === 0
  }

  // 处理表单提交
  const handleSubmit = (e) => {
    e.preventDefault()
    if (validateForm()) {
      onSubmit(formData)
    }
  }

  if (!isOpen) return null

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg shadow-xl max-w-md w-full mx-4 max-h-[90vh] overflow-y-auto">
        <div className="px-6 py-4 border-b border-gray-200">
          <h3 className="text-lg font-medium text-gray-900">
            {record ? '修改DNS记录' : '添加DNS记录'}
          </h3>
        </div>

        <form onSubmit={handleSubmit} className="px-6 py-4 space-y-4">
          {/* 记录类型 */}
          <div>
            <label htmlFor="type" className="block text-sm font-medium text-gray-700 mb-1">
              记录类型
            </label>
            <select
              id="type"
              name="type"
              value={formData.type}
              onChange={handleChange}
              className="block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
              disabled={isLoading}
            >
              {recordTypes.map(type => (
                <option key={type} value={type}>{type}</option>
              ))}
            </select>
          </div>

          {/* 名称 */}
          <div>
            <label htmlFor="name" className="block text-sm font-medium text-gray-700 mb-1">
              名称
            </label>
            <input
              type="text"
              id="name"
              name="name"
              value={formData.name}
              onChange={handleChange}
              className={`block w-full px-3 py-2 border rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 ${
                errors.name ? 'border-red-300' : 'border-gray-300'
              }`}
              placeholder="例如: www 或 @ (根域名)"
              disabled={isLoading}
            />
            {errors.name && (
              <p className="mt-1 text-sm text-red-600">{errors.name}</p>
            )}
          </div>

          {/* 内容 */}
          <div>
            <label htmlFor="content" className="block text-sm font-medium text-gray-700 mb-1">
              内容
            </label>
            <input
              type="text"
              id="content"
              name="content"
              value={formData.content}
              onChange={handleChange}
              className={`block w-full px-3 py-2 border rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 ${
                errors.content ? 'border-red-300' : 'border-gray-300'
              }`}
              placeholder={formData.type === 'A' ? '例如: 192.168.1.1' : '记录内容'}
              disabled={isLoading}
            />
            {errors.content && (
              <p className="mt-1 text-sm text-red-600">{errors.content}</p>
            )}
          </div>

          {/* TTL */}
          <div>
            <label htmlFor="ttl" className="block text-sm font-medium text-gray-700 mb-1">
              TTL (生存时间)
            </label>
            <select
              id="ttl"
              name="ttl"
              value={formData.ttl}
              onChange={handleChange}
              className="block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
              disabled={isLoading}
            >
              {ttlOptions.map(option => (
                <option key={option.value} value={option.value}>
                  {option.label}
                </option>
              ))}
            </select>
          </div>

          {/* 代理状态 */}
          <div className="flex items-center">
            <input
              type="checkbox"
              id="proxied"
              name="proxied"
              checked={formData.proxied}
              onChange={handleChange}
              className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
              disabled={isLoading}
            />
            <label htmlFor="proxied" className="ml-2 block text-sm text-gray-900">
              启用Cloudflare代理 (橙色云朵)
            </label>
          </div>

          {/* 按钮 */}
          <div className="flex justify-end space-x-3 pt-4">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
              disabled={isLoading}
            >
              取消
            </button>
            <button
              type="submit"
              className="px-4 py-2 text-sm font-medium text-white bg-blue-600 border border-transparent rounded-md shadow-sm hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50"
              disabled={isLoading}
            >
              {isLoading ? '处理中...' : (record ? '更新' : '添加')}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

export default RecordForm