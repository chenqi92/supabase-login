# Supabase 登录 UI 构建工具

## 简介

此工具提供了一个完整的Docker构建和部署解决方案，专为国内网络环境优化，包含环境变量映射、镜像源替换和中文支持。

## 快速开始

### 1. 创建环境变量文件

在项目根目录创建 `.env` 文件，参考以下内容：

```
# Supabase 配置
SUPABASE_PUBLIC_URL=https://database.allbs.cn
ANON_KEY=your_anon_key
SITE_URL=https://login.allbs.cn

# OAuth配置
GOTRUE_EXTERNAL_GITHUB_ENABLED=true
GOTRUE_EXTERNAL_GOOGLE_ENABLED=true

# 版本控制
APP_VERSION=1.0.0
```

### 2. 使用构建工具

**Linux/macOS:**
```bash
# 设置执行权限
chmod +x docker-build.sh

# 构建镜像
./docker-build.sh build 1.0.0

# 运行容器
./docker-build.sh run 1.0.0

# 导出镜像
./docker-build.sh export 1.0.0
```

**Windows:**
```cmd
# 构建镜像
docker-build.bat build 1.0.0

# 运行容器
docker-build.bat run 1.0.0

# 导出镜像
docker-build.bat export 1.0.0
```

## 解决的问题

1. **Docker Hub连接问题**
   - 使用阿里云镜像仓库替代Docker Hub
   - 配置国内Debian软件源
   - 提供镜像导出功能用于离线部署

2. **中文显示问题**
   - 批处理脚本自动设置UTF-8编码
   - 安装中文字体包支持
   - 配置正确的区域设置

3. **构建稳定性**
   - 优化网络连接和错误处理
   - 支持环境变量和默认值设置
   - 镜像版本控制和标签管理

## 环境变量说明

| Supabase变量名 | 前端变量名 | 说明 |
|--------------|-----------|------|
| `SUPABASE_PUBLIC_URL` | `NEXT_PUBLIC_SUPABASE_URL` | Supabase API服务地址 |
| `ANON_KEY` | `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Supabase匿名访问密钥 |
| `SITE_URL` | `NEXT_PUBLIC_SITE_URL` | 应用站点URL，用于OAuth回调 |
| `GOTRUE_EXTERNAL_GITHUB_ENABLED` | `NEXT_PUBLIC_AUTH_GITHUB_ENABLED` | 是否启用GitHub登录 |
| `GOTRUE_EXTERNAL_GOOGLE_ENABLED` | `NEXT_PUBLIC_AUTH_GOOGLE_ENABLED` | 是否启用Google登录 |
| `APP_VERSION` | `APP_VERSION` | 应用版本号 |

## 注意事项

- `.env`文件中的注释行需以`#`开头
- 不要在环境变量定义中包含空格，如：`VARIABLE=value` (正确) 而非 `VARIABLE = value` (错误)
- Windows环境下建议使用UTF-8编码创建所有文件，避免中文乱码
- 导出镜像前务必先构建镜像 