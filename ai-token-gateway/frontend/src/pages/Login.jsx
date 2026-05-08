import React, { useState } from 'react';
import { Form, Input, Button, Card, message, Typography, Space } from 'antd';
import { UserOutlined, LockOutlined, MailOutlined } from '@ant-design/icons';
import { useNavigate } from 'react-router-dom';
import { authAPI } from '../api';
import './Login.css';

const { Title, Text } = Typography;

const Login = () => {
  const [loading, setLoading] = useState(false);
  const [isRegister, setIsRegister] = useState(false);
  const navigate = useNavigate();

  const onFinish = async (values) => {
    setLoading(true);
    try {
      const response = isRegister
        ? await authAPI.register(values)
        : await authAPI.login(values);

      const { token, user } = response.data;
      localStorage.setItem('token', token);
      localStorage.setItem('user', JSON.stringify(user));

      message.success(isRegister ? '注册成功！' : '登录成功！');
      navigate('/dashboard');
    } catch (error) {
      message.error(error.response?.data?.message || (isRegister ? '注册失败' : '登录失败'));
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="login-container">
      <div className="login-background">
        <div className="floating-shapes">
          <div className="shape shape-1"></div>
          <div className="shape shape-2"></div>
          <div className="shape shape-3"></div>
          <div className="shape shape-4"></div>
        </div>
      </div>
      
      <Card className="login-card" bordered={false}>
        <div className="login-header">
          <div className="logo-container">
            <div className="logo-icon">⚡</div>
            <Title level={2} className="logo-text">AI Token Gateway</Title>
          </div>
          <Text className="login-subtitle">
            {isRegister ? '创建你的账户' : '欢迎回来'}
          </Text>
        </div>

        <Form
          name="auth_form"
          onFinish={onFinish}
          size="large"
          className="auth-form"
        >
          <Form.Item
            name="email"
            rules={[
              { required: true, message: '请输入邮箱地址！' },
              { type: 'email', message: '请输入有效的邮箱地址！' }
            ]}
          >
            <Input 
              prefix={<MailOutlined className="input-icon" />}
              placeholder="邮箱地址"
              className="auth-input"
            />
          </Form.Item>

          {isRegister && (
            <Form.Item
              name="nickname"
            >
              <Input 
                prefix={<UserOutlined className="input-icon" />}
                placeholder="昵称（可选）"
                className="auth-input"
              />
            </Form.Item>
          )}

          <Form.Item
            name="password"
            rules={[
              { required: true, message: '请输入密码！' },
              ...(isRegister ? [{ min: 6, message: '密码至少6个字符！' }] : [])
            ]}
          >
            <Input.Password 
              prefix={<LockOutlined className="input-icon" />}
              placeholder="密码"
              className="auth-input"
            />
          </Form.Item>

          <Form.Item>
            <Button 
              type="primary" 
              htmlType="submit" 
              loading={loading}
              block
              className="auth-button"
            >
              {isRegister ? '注册' : '登录'}
            </Button>
          </Form.Item>

          <div className="auth-switch">
            <Text>
              {isRegister ? '已有账户？' : '还没有账户？'}
            </Text>
            <Button type="link" onClick={() => setIsRegister(!isRegister)}>
              {isRegister ? '立即登录' : '立即注册'}
            </Button>
          </div>
        </Form>
      </Card>
    </div>
  );
};

export default Login;
