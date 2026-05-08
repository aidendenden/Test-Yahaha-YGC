import React, { useState, useEffect } from 'react';
import {
  Layout, Menu, Card, Row, Col, Statistic, Button, Table, Modal,
  Form, Input, message, Popconfirm, Typography, Space, Tag, Select,
  DatePicker, Drawer, Descriptions, Alert
} from 'antd';
import {
  DashboardOutlined, KeyOutlined, LineChartOutlined, WalletOutlined,
  LogoutOutlined, PlusOutlined, DeleteOutlined, CopyOutlined,
  ReloadOutlined, ThunderboltOutlined, UserOutlined, SettingOutlined
} from '@ant-design/icons';
import { useNavigate } from 'react-router-dom';
import { authAPI, apiKeysAPI, usageAPI } from '../api';
import dayjs from 'dayjs';
import './Dashboard.css';

const { Header, Sider, Content } = Layout;
const { Title, Text } = Typography;

const Dashboard = () => {
  const [collapsed, setCollapsed] = useState(false);
  const [user, setUser] = useState(null);
  const [apiKeys, setApiKeys] = useState([]);
  const [usageSummary, setUsageSummary] = useState(null);
  const [balance, setBalance] = useState(0);
  const [loading, setLoading] = useState(false);
  const [createKeyModalVisible, setCreateKeyModalVisible] = useState(false);
  const [createKeyData, setCreateKeyData] = useState(null);
  const [selectedMenu, setSelectedMenu] = useState('dashboard');
  const [form] = Form.useForm();
  const navigate = useNavigate();

  useEffect(() => {
    loadUserData();
  }, []);

  const loadUserData = async () => {
    try {
      const [profileRes, keysRes, usageRes, balanceRes] = await Promise.all([
        authAPI.getProfile(),
        apiKeysAPI.list(),
        usageAPI.getSummary(),
        usageAPI.getBalance()
      ]);
      setUser(profileRes.data.user);
      setApiKeys(keysRes.data.apiKeys);
      setUsageSummary(usageRes.data.summary);
      setBalance(balanceRes.data.balance);
    } catch (error) {
      message.error('加载数据失败');
    }
  };

  const handleCreateApiKey = async (values) => {
    setLoading(true);
    try {
      const response = await apiKeysAPI.create(values);
      setCreateKeyData(response.data);
      setCreateKeyModalVisible(true);
      message.success('API Key 创建成功！');
      loadUserData();
    } catch (error) {
      message.error(error.response?.data?.message || '创建失败');
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteKey = async (id) => {
    try {
      await apiKeysAPI.delete(id);
      message.success('API Key 已删除');
      loadUserData();
    } catch (error) {
      message.error('删除失败');
    }
  };

  const handleToggleKeyStatus = async (id, currentStatus) => {
    try {
      await apiKeysAPI.updateStatus(id, { isActive: !currentStatus });
      message.success(currentStatus ? 'API Key 已禁用' : 'API Key 已启用');
      loadUserData();
    } catch (error) {
      message.error('操作失败');
    }
  };

  const handleLogout = () => {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    navigate('/login');
  };

  const copyToClipboard = (text) => {
    navigator.clipboard.writeText(text);
    message.success('已复制到剪贴板');
  };

  const menuItems = [
    { key: 'dashboard', icon: <DashboardOutlined />, label: '概览' },
    { key: 'apikeys', icon: <KeyOutlined />, label: 'API Keys' },
    { key: 'usage', icon: <LineChartOutlined />, label: '用量统计' },
    { key: 'balance', icon: <WalletOutlined />, label: '余额管理' },
    { key: 'settings', icon: <SettingOutlined />, label: '设置' }
  ];

  const renderContent = () => {
    switch (selectedMenu) {
      case 'dashboard':
        return (
          <div className="dashboard-content">
            <Title level={3} className="section-title">
              <ThunderboltOutlined /> 数据概览
            </Title>
            <Row gutter={[24, 24]}>
              <Col xs={24} sm={12} lg={6}>
                <Card className="stat-card stat-card-primary">
                  <Statistic
                    title={<span className="stat-title">账户余额</span>}
                    value={balance}
                    precision={2}
                    prefix="¥"
                    valueStyle={{ color: '#667eea' }}
                  />
                </Card>
              </Col>
              <Col xs={24} sm={12} lg={6}>
                <Card className="stat-card stat-card-success">
                  <Statistic
                    title={<span className="stat-title">API Keys</span>}
                    value={apiKeys.length}
                    prefix={<KeyOutlined />}
                  />
                </Card>
              </Col>
              <Col xs={24} sm={12} lg={6}>
                <Card className="stat-card stat-card-info">
                  <Statistic
                    title={<span className="stat-title">总请求数</span>}
                    value={usageSummary?.totalRequests || 0}
                    prefix={<LineChartOutlined />}
                  />
                </Card>
              </Col>
              <Col xs={24} sm={12} lg={6}>
                <Card className="stat-card stat-card-warning">
                  <Statistic
                    title={<span className="stat-title">总费用</span>}
                    value={usageSummary?.totalCost || 0}
                    precision={4}
                    prefix="¥"
                  />
                </Card>
              </Col>
            </Row>

            <Title level={3} className="section-title" style={{ marginTop: 48 }}>
              最近使用情况
            </Title>
            <Row gutter={[24, 24]}>
              <Col xs={24} lg={12}>
                <Card className="usage-card">
                  <div className="usage-stat">
                    <Text className="usage-label">输入 Tokens</Text>
                    <Title level={2} className="usage-value">
                      {(usageSummary?.totalInputTokens || 0).toLocaleString()}
                    </Title>
                  </div>
                  <div className="usage-chart-placeholder">
                    <div className="chart-bar" style={{ height: '60%' }}></div>
                    <div className="chart-bar" style={{ height: '80%' }}></div>
                    <div className="chart-bar" style={{ height: '45%' }}></div>
                    <div className="chart-bar" style={{ height: '90%' }}></div>
                    <div className="chart-bar" style={{ height: '70%' }}></div>
                  </div>
                </Card>
              </Col>
              <Col xs={24} lg={12}>
                <Card className="usage-card">
                  <div className="usage-stat">
                    <Text className="usage-label">输出 Tokens</Text>
                    <Title level={2} className="usage-value">
                      {(usageSummary?.totalOutputTokens || 0).toLocaleString()}
                    </Title>
                  </div>
                  <div className="usage-chart-placeholder">
                    <div className="chart-bar" style={{ height: '75%' }}></div>
                    <div className="chart-bar" style={{ height: '55%' }}></div>
                    <div className="chart-bar" style={{ height: '85%' }}></div>
                    <div className="chart-bar" style={{ height: '65%' }}></div>
                    <div className="chart-bar" style={{ height: '95%' }}></div>
                  </div>
                </Card>
              </Col>
            </Row>

            {usageSummary?.byProvider && Object.keys(usageSummary.byProvider).length > 0 && (
              <>
                <Title level={3} className="section-title" style={{ marginTop: 48 }}>
                  按提供商统计
                </Title>
                <Row gutter={[24, 24]}>
                  {Object.entries(usageSummary.byProvider).map(([provider, data]) => (
                    <Col xs={24} sm={12} lg={8} key={provider}>
                      <Card className="provider-card">
                        <Tag color={provider === 'openai' ? 'green' : provider === 'anthropic' ? 'blue' : 'orange'}>
                          {provider.toUpperCase()}
                        </Tag>
                        <div className="provider-stats">
                          <Statistic title="请求数" value={data.requests} />
                          <Statistic title="费用" value={data.cost} precision={4} prefix="¥" />
                        </div>
                      </Card>
                    </Col>
                  ))}
                </Row>
              </>
            )}
          </div>
        );

      case 'apikeys':
        return (
          <div className="dashboard-content">
            <div className="content-header">
              <Title level={3} className="section-title">
                <KeyOutlined /> API Keys 管理
              </Title>
              <Button type="primary" icon={<PlusOutlined />} onClick={() => form.submit()}>
                创建新 Key
              </Button>
            </div>

            <Form form={form} onFinish={handleCreateApiKey} layout="inline" className="create-key-form">
              <Form.Item name="name" label="Key 名称">
                <Input placeholder="例如：开发环境" style={{ width: 200 }} />
              </Form.Item>
            </Form>

            <Table
              dataSource={apiKeys}
              rowKey="id"
              className="api-keys-table"
              pagination={false}
              columns={[
                {
                  title: '名称',
                  dataIndex: 'name',
                  key: 'name',
                  render: (text, record) => (
                    <Space>
                      <KeyOutlined />
                      <Text strong>{text || '未命名'}</Text>
                    </Space>
                  )
                },
                {
                  title: 'Key',
                  dataIndex: 'keyPrefix',
                  key: 'keyPrefix',
                  render: (text) => <Text code>{text}</Text>
                },
                {
                  title: '状态',
                  dataIndex: 'isActive',
                  key: 'isActive',
                  render: (isActive) => (
                    <Tag color={isActive ? 'success' : 'default'}>
                      {isActive ? '启用' : '禁用'}
                    </Tag>
                  )
                },
                {
                  title: '最后使用',
                  dataIndex: 'lastUsedAt',
                  key: 'lastUsedAt',
                  render: (date) => date ? dayjs(date).format('YYYY-MM-DD HH:mm') : '从未使用'
                },
                {
                  title: '创建时间',
                  dataIndex: 'createdAt',
                  key: 'createdAt',
                  render: (date) => dayjs(date).format('YYYY-MM-DD HH:mm')
                },
                {
                  title: '操作',
                  key: 'actions',
                  render: (_, record) => (
                    <Space>
                      <Button
                        type="text"
                        onClick={() => handleToggleKeyStatus(record.id, record.isActive)}
                      >
                        {record.isActive ? '禁用' : '启用'}
                      </Button>
                      <Popconfirm
                        title="确认删除？"
                        onConfirm={() => handleDeleteKey(record.id)}
                      >
                        <Button type="text" danger icon={<DeleteOutlined />} />
                      </Popconfirm>
                    </Space>
                  )
                }
              ]}
            />

            <Alert
              type="warning"
              showIcon
              message="安全提示"
              description="API Key 只会在创建时显示一次，请妥善保管。如果遗失，请删除并重新创建。"
              style={{ marginTop: 24 }}
            />
          </div>
        );

      case 'usage':
        return (
          <div className="dashboard-content">
            <Title level={3} className="section-title">
              <LineChartOutlined /> 用量统计
            </Title>
            <Row gutter={[24, 24]}>
              <Col xs={24} lg={16}>
                <Card title="详细统计" className="usage-detail-card">
                  <Descriptions column={2}>
                    <Descriptions.Item label="总请求数">
                      {usageSummary?.totalRequests || 0}
                    </Descriptions.Item>
                    <Descriptions.Item label="总费用">
                      ¥{usageSummary?.totalCost?.toFixed(4) || '0.0000'}
                    </Descriptions.Item>
                    <Descriptions.Item label="输入 Tokens">
                      {(usageSummary?.totalInputTokens || 0).toLocaleString()}
                    </Descriptions.Item>
                    <Descriptions.Item label="输出 Tokens">
                      {(usageSummary?.totalOutputTokens || 0).toLocaleString()}
                    </Descriptions.Item>
                  </Descriptions>
                </Card>
              </Col>
              <Col xs={24} lg={8}>
                <Card title="余额" className="balance-card">
                  <Statistic
                    title="当前余额"
                    value={balance}
                    precision={2}
                    prefix="¥"
                    valueStyle={{ color: '#667eea', fontSize: 32 }}
                  />
                  <Button type="primary" block style={{ marginTop: 16 }}>
                    充值
                  </Button>
                </Card>
              </Col>
            </Row>
          </div>
        );

      case 'balance':
        return (
          <div className="dashboard-content">
            <Title level={3} className="section-title">
              <WalletOutlined /> 余额管理
            </Title>
            <Card className="balance-management-card">
              <Row gutter={24}>
                <Col span={12}>
                  <Statistic
                    title="账户余额"
                    value={balance}
                    precision={2}
                    prefix="¥"
                    valueStyle={{ fontSize: 48, color: '#667eea' }}
                  />
                </Col>
                <Col span={12}>
                  <Title level={4}>快速充值</Title>
                  <Space wrap>
                    {[10, 50, 100, 500].map(amount => (
                      <Button key={amount} size="large" onClick={() => message.info(`充值 ${amount} 元功能开发中`)}>
                        ¥{amount}
                      </Button>
                    ))}
                  </Space>
                </Col>
              </Row>
            </Card>
          </div>
        );

      case 'settings':
        return (
          <div className="dashboard-content">
            <Title level={3} className="section-title">
              <SettingOutlined /> 账户设置
            </Title>
            <Card>
              <Descriptions column={1} bordered>
                <Descriptions.Item label="邮箱">{user?.email}</Descriptions.Item>
                <Descriptions.Item label="昵称">{user?.nickname || '未设置'}</Descriptions.Item>
                <Descriptions.Item label="用户 ID">{user?.id}</Descriptions.Item>
                <Descriptions.Item label="注册时间">
                  {user?.createdAt ? dayjs(user.createdAt).format('YYYY-MM-DD HH:mm:ss') : '-'}
                </Descriptions.Item>
              </Descriptions>
            </Card>
          </div>
        );

      default:
        return null;
    }
  };

  return (
    <Layout className="dashboard-layout">
      <Sider
        collapsible
        collapsed={collapsed}
        onCollapse={setCollapsed}
        className="dashboard-sider"
        width={240}
      >
        <div className="logo-container">
          <div className="logo-icon">⚡</div>
          {!collapsed && <span className="logo-text">AI Gateway</span>}
        </div>
        <Menu
          theme="dark"
          mode="inline"
          selectedKeys={[selectedMenu]}
          items={menuItems}
          onClick={({ key }) => setSelectedMenu(key)}
          className="dashboard-menu"
        />
        <div className="user-info">
          <UserOutlined />
          {!collapsed && (
            <Space direction="vertical" size={0}>
              <Text className="user-name">{user?.nickname || user?.email}</Text>
              <Text className="user-balance">¥{balance.toFixed(2)}</Text>
            </Space>
          )}
        </div>
      </Sider>
      <Layout>
        <Header className="dashboard-header">
          <div className="header-content">
            <Title level={4} style={{ margin: 0, color: '#fff' }}>
              {menuItems.find(item => item.key === selectedMenu)?.label}
            </Title>
            <Space>
              <Button icon={<ReloadOutlined />} onClick={loadUserData}>
                刷新
              </Button>
              <Button icon={<LogoutOutlined />} onClick={handleLogout}>
                退出
              </Button>
            </Space>
          </div>
        </Header>
        <Content className="dashboard-main-content">
          {renderContent()}
        </Content>
      </Layout>

      <Modal
        title="🎉 API Key 创建成功"
        open={createKeyModalVisible}
        onCancel={() => {
          setCreateKeyModalVisible(false);
          setCreateKeyData(null);
        }}
        footer={[
          <Button key="close" type="primary" onClick={() => setCreateKeyModalVisible(false)}>
            我已保存
          </Button>
        ]}
        width={600}
      >
        {createKeyData && (
          <div>
            <Alert
              type="warning"
              showIcon
              message="重要提示"
              description="此 API Key 只显示这一次，请立即复制并妥善保管！"
              style={{ marginBottom: 24 }}
            />
            <Form layout="vertical">
              <Form.Item label="API Key">
                <Input.Password
                  value={createKeyData.apiKey?.key || createKeyData.key}
                  readOnly
                  addonAfter={
                    <CopyOutlined
                      onClick={() => copyToClipboard(createKeyData.apiKey?.key || createKeyData.key)}
                      style={{ cursor: 'pointer' }}
                    />
                  }
                />
              </Form.Item>
              <Form.Item label="Key 前缀">
                <Input value={createKeyData.apiKey?.prefix || createKeyData.prefix} readOnly />
              </Form.Item>
              <Form.Item label="名称">
                <Input value={createKeyData.apiKey?.name || createKeyData.name} readOnly />
              </Form.Item>
            </Form>
          </div>
        )}
      </Modal>
    </Layout>
  );
};

export default Dashboard;
