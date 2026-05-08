# AI Token API 中转站 - 项目规范

## 1. 项目概述

### 1.1 项目名称
**AI Token Gateway** - 个人开发者友好的 AI API 中转服务

### 1.2 核心功能
一个统一的 AI API 网关服务，允许用户通过一个 API Key 访问多个 AI 提供商（OpenAI、Claude、Gemini 等），支持用量统计、计费管理和简单的用户管理功能。

### 1.3 目标用户
个人开发者、小型项目团队，需要便捷访问多种 AI 模型的用户。

---

## 2. 技术选型

### 2.1 技术栈

| 层级 | 技术选型 | 说明 |
|------|----------|------|
| **后端框架** | Node.js + Express | 高性能、易扩展、丰富的生态系统 |
| **数据库** | PostgreSQL + Prisma ORM | 关系型数据库，适合复杂查询，Prisma 提供类型安全 |
| **缓存层** | Redis | 用于会话管理、限流计数、热点数据缓存 |
| **部署** | Docker + 手动部署 | 简单高效，成本可控 |
| **前端** | React + Ant Design | 企业级 UI 组件，快速开发 |

### 2.2 架构设计

```
┌─────────────┐
│   用户请求   │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Nginx/网关  │ ← 负载均衡、SSL
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Express    │ ← API 网关、鉴权、限流
│  Gateway    │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ Redis Cache │ ← 限流、缓存
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ AI Providers│ ← OpenAI/Claude/Gemini
└─────────────┘
```

### 2.3 支持的 AI 提供商

| 提供商 | 模型 | 优先级 | 支持状态 |
|--------|------|--------|----------|
| OpenAI | GPT-4o, GPT-4-turbo, GPT-3.5-turbo | P0 | ✅ |
| Anthropic | Claude-3.5-Sonnet, Claude-3-Opus | P0 | ✅ |
| Google | Gemini-1.5-Pro, Gemini-1.5-Flash | P1 | ✅ |

---

## 3. 功能模块

### 3.1 用户管理模块

**功能列表：**
- 用户注册（邮箱 + 密码）
- 用户登录（JWT Token）
- 密码重置
- 用户信息查看/修改

**API 端点：**
```
POST   /api/auth/register    - 用户注册
POST   /api/auth/login       - 用户登录
POST   /api/auth/logout      - 用户登出
GET    /api/auth/profile     - 获取用户信息
PUT    /api/auth/profile     - 更新用户信息
POST   /api/auth/reset-password - 重置密码
```

### 3.2 API Key 管理模块

**功能列表：**
- 创建 API Key（可设置名称、权限）
- 查看 API Key 列表
- 删除 API Key
- API Key 启用/禁用

**API 端点：**
```
POST   /api/keys              - 创建新 API Key
GET    /api/keys              - 获取用户所有 Key
DELETE /api/keys/:id           - 删除指定 Key
PUT    /api/keys/:id/status   - 启用/禁用 Key
```

### 3.3 代理转发模块

**功能列表：**
- 统一 OpenAI 兼容 API 格式
- 请求转发到对应 AI 提供商
- 响应数据格式化
- 错误处理和日志记录

**API 端点：**
```
POST   /v1/chat/completions    - OpenAI 兼容接口
POST   /v1/completions        - OpenAI 兼容接口
POST   /v1/embeddings         - OpenAI 兼容接口
GET    /v1/models             - 获取可用模型列表
```

### 3.4 计费与用量模块

**功能列表：**
- Token 用量实时统计
- 余额管理（充值系统）
- 用量明细查询
- 套餐管理

**API 端点：**
```
GET    /api/usage/summary     - 用量概览
GET    /api/usage/details     - 用量明细
GET    /api/balance           - 查询余额
POST   /api/recharge          - 充值
```

### 3.5 管理后台模块

**功能列表：**
- 用户管理
- API Key 管理
- 充值记录管理
- 系统配置
- 日志查看

---

## 4. 数据模型

### 4.1 用户表 (User)

```sql
CREATE TABLE users (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email         VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  nickname      VARCHAR(100),
  balance       DECIMAL(10,2) DEFAULT 0.00,
  is_admin      BOOLEAN DEFAULT FALSE,
  is_active     BOOLEAN DEFAULT TRUE,
  created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 4.2 API Key 表 (ApiKey)

```sql
CREATE TABLE api_keys (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID REFERENCES users(id) ON DELETE CASCADE,
  key_hash     VARCHAR(255) UNIQUE NOT NULL,
  key_prefix   VARCHAR(10) NOT NULL,          -- sk-xxx 前缀
  name         VARCHAR(100),
  is_active    BOOLEAN DEFAULT TRUE,
  last_used_at TIMESTAMP,
  created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 4.3 用量记录表 (UsageLog)

```sql
CREATE TABLE usage_logs (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  api_key_id    UUID REFERENCES api_keys(id) ON DELETE CASCADE,
  user_id       UUID REFERENCES users(id) ON DELETE CASCADE,
  model         VARCHAR(50) NOT NULL,
  provider      VARCHAR(20) NOT NULL,          -- openai, anthropic, google
  input_tokens  INTEGER DEFAULT 0,
  output_tokens INTEGER DEFAULT 0,
  cost          DECIMAL(10,4) DEFAULT 0.0000,
  created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 4.4 充值记录表 (RechargeLog)

```sql
CREATE TABLE recharge_logs (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID REFERENCES users(id) ON DELETE CASCADE,
  amount      DECIMAL(10,2) NOT NULL,
  status      VARCHAR(20) DEFAULT 'pending',  -- pending, completed, failed
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 4.5 模型定价表 (ModelPricing)

```sql
CREATE TABLE model_pricing (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider        VARCHAR(20) NOT NULL,
  model           VARCHAR(50) NOT NULL,
  input_price_per_1k DECIMAL(10,6) DEFAULT 0,  -- 每1K token 价格
  output_price_per_1k DECIMAL(10,6) DEFAULT 0,
  is_active       BOOLEAN DEFAULT TRUE,
  UNIQUE(provider, model)
);
```

---

## 5. 安全策略

### 5.1 认证与授权

- **API Key 认证**：使用 `Authorization: Bearer sk-xxx` 头部
- **JWT Token**：用于管理后台登录
- **Key 哈希存储**：使用 bcrypt 哈希存储

### 5.2 限流策略

| 用户等级 | 速率限制 | 每日用量限制 |
|----------|----------|--------------|
| 普通用户 | 60 RPM | 100,000 tokens |
| 付费用户 | 300 RPM | 无限制 |

### 5.3 安全措施

- 请求参数验证
- SQL 注入防护（使用 Prisma ORM）
- XSS 防护
- CORS 配置
- 请求日志审计

---

## 6. 部署方案

### 6.1 服务器要求

**最低配置（个人项目）：**
- CPU: 2 核
- 内存: 4 GB
- 磁盘: 40 GB SSD
- 月费用: ~100-200 元（阿里云/腾讯云）

### 6.2 部署架构

```
单个服务器部署：
├── Nginx (反向代理、SSL)
├── Docker Container
│   ├── API Gateway (Node.js)
│   ├── PostgreSQL
│   └── Redis
└── 备份策略（每日数据库备份）
```

### 6.3 成本估算（月度）

| 项目 | 费用 |
|------|------|
| 服务器 | 100-200 元 |
| 域名 | 30-50 元 |
| SSL 证书 | 免费（Let's Encrypt） |
| **总计** | **130-250 元/月** |

---

## 7. 开发计划

### Phase 1: 基础框架搭建
- [ ] 项目初始化（Node.js + Express）
- [ ] 数据库连接（Prisma + PostgreSQL）
- [ ] 基础目录结构
- [ ] 工具函数库

### Phase 2: 用户管理
- [ ] 用户注册/登录 API
- [ ] JWT 认证中间件
- [ ] 用户信息管理

### Phase 3: API Key 管理
- [ ] Key 生成（安全的随机字符串）
- [ ] Key 存储（哈希存储）
- [ ] Key 管理 API

### Phase 4: 代理转发
- [ ] OpenAI 兼容接口实现
- [ ] 请求转发逻辑
- [ ] 错误处理
- [ ] 多提供商适配

### Phase 5: 计费系统
- [ ] Token 计数
- [ ] 费用计算
- [ ] 用量记录
- [ ] 余额管理

### Phase 6: 前端 Dashboard
- [ ] React 项目初始化
- [ ] 用户注册/登录页面
- [ ] Dashboard 主页面
- [ ] API Key 管理界面
- [ ] 用量统计页面

### Phase 7: 安全加固
- [ ] 限流实现
- [ ] 请求验证
- [ ] 日志审计

### Phase 8: 部署上线
- [ ] Docker 化
- [ ] 生产环境配置
- [ ] 监控告警

---

## 8. 验收标准

### 8.1 功能验收

✅ 用户可以注册和登录
✅ 用户可以创建、查看、删除 API Key
✅ 用户可以使用 API Key 调用 AI 接口
✅ 系统正确统计 Token 用量
✅ 系统正确计算费用并扣除余额
✅ 用户可以查看用量明细
✅ 管理后台可以管理用户和配置

### 8.2 性能验收

✅ API 响应时间 < 500ms（不含 AI 响应）
✅ 支持 50+ 并发用户
✅ 系统可用性 > 99%

### 8.3 安全验收

✅ API Key 安全存储
✅ 敏感数据加密
✅ 限流正常工作
✅ 无 SQL 注入风险
✅ 无 XSS 风险

---

## 9. 后续扩展方向

- **套餐系统**：预设套餐，自动扣费
- **邀请奖励**：邀请注册赠送余额
- **更多模型**：支持更多 AI 提供商
- **插件系统**：支持自定义处理器
- **分布式部署**：多节点集群

---

*文档版本：v1.0*
*创建时间：2026-05-08*
