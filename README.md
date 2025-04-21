# Supabase 风格登录系统

一个现代化的、符合 Supabase 设计风格的认证系统，包含：

- 用户注册和登录（支持用户名或邮箱登录）
- GitHub 和 Google 第三方登录
- 中英文国际化支持
- 响应式设计，支持多种设备

## 技术栈

- Next.js 14 (App Router)
- TypeScript
- Supabase (认证和数据库)
- Tailwind CSS (样式)
- Shadcn UI (组件库)
- i18next (国际化)
- Docker (容器化)

## 快速开始

### 开发环境

```bash
# 安装依赖
npm install

# 运行开发服务器
npm run dev
```

开发服务器启动后，访问 http://localhost:3000

### Supabase 配置

1. 在 [Supabase](https://supabase.com) 创建一个新项目
2. 在 SQL 编辑器中运行以下 SQL 语句，创建用户资料表：

```sql
-- 创建 profiles 表，用于存储用户名和邮箱的关联
CREATE TABLE profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  email TEXT UNIQUE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE
);

-- 启用 RLS（行级安全）
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- 创建政策允许用户读取自己的资料
CREATE POLICY "Users can view own profile" 
  ON profiles FOR SELECT 
  USING (auth.uid() = id);

-- 创建政策允许用户更新自己的资料
CREATE POLICY "Users can update own profile" 
  ON profiles FOR UPDATE 
  USING (auth.uid() = id);

-- 创建政策允许通过用户名查询邮箱（用于用户名登录）
CREATE POLICY "Anyone can query profile by username" 
  ON profiles FOR SELECT 
  USING (true);

-- 创建索引加速查询
CREATE INDEX profiles_username_idx ON profiles (username);
CREATE INDEX profiles_email_idx ON profiles (email);
```

3. 在认证设置中配置允许的回调 URL
4. 如需第三方登录，配置 GitHub 和 Google OAuth 提供商

## 环境变量

请创建 `.env.local` 文件并添加以下变量：

```
NEXT_PUBLIC_SUPABASE_URL=你的Supabase项目URL
NEXT_PUBLIC_SUPABASE_ANON_KEY=你的Supabase匿名密钥
NEXT_PUBLIC_SITE_URL=你的网站URL
```

## Docker 部署

### 本地构建和运行

```bash
# 构建 Docker 镜像
docker build -t supabase-login .

# 运行 Docker 容器
docker run -p 3000:3000 \
  -e NEXT_PUBLIC_SUPABASE_URL=你的Supabase项目URL \
  -e NEXT_PUBLIC_SUPABASE_ANON_KEY=你的Supabase匿名密钥 \
  -e NEXT_PUBLIC_SITE_URL=你的网站URL \
  supabase-login
```

或者使用 docker-compose：

```bash
# 确保已在 .env 文件中设置所需的环境变量
docker-compose up -d
```

### 推送到 Docker Hub

```bash
# 登录到 Docker Hub
docker login

# 为镜像添加标签（替换 yourusername 为您的 Docker Hub 用户名）
docker tag supabase-login yourusername/supabase-login:latest

# 推送镜像到 Docker Hub
docker push yourusername/supabase-login:latest
```

### 推送到 GitHub Container Registry

```bash
# 登录到 GitHub Container Registry
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# 为镜像添加标签
docker tag supabase-login ghcr.io/yourusername/supabase-login:latest

# 推送镜像
docker push ghcr.io/yourusername/supabase-login:latest
```

### 从远程仓库拉取并运行

```bash
# 从 Docker Hub 拉取
docker pull yourusername/supabase-login:latest

# 运行容器
docker run -p 3000:3000 \
  -e NEXT_PUBLIC_SUPABASE_URL=你的Supabase项目URL \
  -e NEXT_PUBLIC_SUPABASE_ANON_KEY=你的Supabase匿名密钥 \
  -e NEXT_PUBLIC_SITE_URL=你的网站URL \
  yourusername/supabase-login:latest

# 或从 GitHub Container Registry 拉取
docker pull ghcr.io/yourusername/supabase-login:latest

# 运行容器
docker run -p 3000:3000 \
  -e NEXT_PUBLIC_SUPABASE_URL=你的Supabase项目URL \
  -e NEXT_PUBLIC_SUPABASE_ANON_KEY=你的Supabase匿名密钥 \
  -e NEXT_PUBLIC_SITE_URL=你的网站URL \
  ghcr.io/yourusername/supabase-login:latest
```

## 自定义和扩展

- 添加更多验证和安全功能
- 实现用户个人资料页面
- 添加更多第三方登录提供商
- 自定义 UI 主题和样式 