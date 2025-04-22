# 环境变量映射说明

本项目使用的环境变量与Supabase自部署环境变量有对应关系。为了保持前端代码的一致性，我们在Docker构建和运行时进行了映射。

## 环境变量对应关系

| Supabase变量名 | 前端变量名 | 说明 |
|--------------|-----------|------|
| `SUPABASE_PUBLIC_URL` | `NEXT_PUBLIC_SUPABASE_URL` | Supabase API服务地址 |
| `ANON_KEY` | `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Supabase匿名访问密钥 |
| `SITE_URL` | `NEXT_PUBLIC_SITE_URL` | 应用站点URL，用于OAuth回调 |
| `GOTRUE_EXTERNAL_GITHUB_ENABLED` | `NEXT_PUBLIC_AUTH_GITHUB_ENABLED` | 是否启用GitHub登录 |
| `GOTRUE_EXTERNAL_GOOGLE_ENABLED` | `NEXT_PUBLIC_AUTH_GOOGLE_ENABLED` | 是否启用Google登录 |
| `APP_VERSION` | `APP_VERSION` | 应用版本号 |

## 如何使用

### 1. 简化版构建脚本 (推荐)

不依赖docker-compose，直接使用docker命令构建：

```bash
# Linux/macOS
chmod +x local-build.sh
./local-build.sh 1.0.0

# Windows
local-build.bat 1.0.0
```

### 2. 完整版构建脚本

如果需要使用docker-compose：

```bash
# Linux/macOS
chmod +x build-local.sh
./build-local.sh 1.0.0

# Windows
build-local.bat 1.0.0
```

## Docker 构建说明

### 基础镜像

本项目使用官方slim版本的Node.js镜像，并解决了软件源问题：

```
FROM node:18-slim AS base
```

### 修复问题

#### 1. Debian软件源404问题

Debian Stretch (Debian 9)已经过了支持期，我们使用了更新的`slim`镜像，并确保正确安装所需软件包。

#### 2. 控制台中文乱码问题

已在Dockerfile中添加了中文支持：

```dockerfile
# 安装中文支持
RUN apt-get update && apt-get install -y --no-install-recommends \
    locales \
    fonts-noto-cjk \
    && rm -rf /var/lib/apt/lists/* \
    && sed -i 's/^# *\(zh_CN.UTF-8\)/\1/' /etc/locale.gen \
    && locale-gen

# 设置环境变量
ENV LANG=zh_CN.UTF-8 
ENV LC_ALL=zh_CN.UTF-8
ENV TZ=Asia/Shanghai
```

如果仍有乱码问题，可以尝试以下解决方案：

1. 确保宿主机终端支持UTF-8
2. 在Windows中，可以在PowerShell中执行`chcp 65001`切换到UTF-8编码
3. 在容器内部运行前设置`PYTHONIOENCODING=utf8`环境变量

### 版本控制

镜像构建时支持版本标签，方便管理不同版本：

```bash
# 指定版本号构建
docker build -t supabase-login-ui:1.0.0 --build-arg APP_VERSION=1.0.0 .

# 或者通过脚本构建
./local-build.sh 1.0.1
```

## 常见问题排查

### 1. 如果仍然遇到镜像拉取问题

可以尝试以下解决方案：

1. 配置Docker使用国内镜像源

编辑或创建 `/etc/docker/daemon.json` (Linux) 或 `%programdata%\docker\config\daemon.json` (Windows)：

```json
{
  "registry-mirrors": [
    "https://registry.docker-cn.com",
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com"
  ]
}
```

然后重启Docker服务。

### 2. 构建过程中显示中文乱码

检查系统区域设置和Docker环境变量，确保支持UTF-8：

```bash
# 检查当前区域设置
locale

# 在Windows中切换到UTF-8
chcp 65001

# 在Linux中设置UTF-8
export LANG=zh_CN.UTF-8
```

## 注意事项

- 前端代码中使用`NEXT_PUBLIC_`前缀的变量
- Docker构建时会从对应的Supabase变量中获取值
- 如果直接在本地开发，需要手动设置这些变量
- 生产环境建议使用固定版本号，而不是latest标签
- 构建脚本会自动处理版本标签和容器管理
- 推荐使用简化版构建脚本(local-build.sh/bat)以减少依赖 