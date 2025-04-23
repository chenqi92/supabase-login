# Supabase 登录 UI 多架构 Docker 构建工具

这个项目提供了一个完整的 Supabase 登录界面，可以构建为支持多种 CPU 架构的 Docker 镜像。

## 特性

- 支持多种处理器架构 (AMD64, ARM64, ARMv7, PPC64le, s390x)
- 优化的多阶段构建，减小镜像体积
- 国内环境友好，内置了国内镜像源配置
- 跨平台构建脚本 (Linux/macOS/Windows)
- 完整的环境变量映射与说明

## 快速开始

### 1. 克隆仓库

```bash
git clone https://github.com/yourusername/supabase-login.git
cd supabase-login
```

### 2. 创建环境变量配置

首次运行脚本会自动创建一个示例 `.env` 文件，您需要编辑以下关键配置：

```
# Supabase 配置
SUPABASE_PUBLIC_URL=https://your-supabase-url.com
ANON_KEY=your-anon-key
SITE_URL=https://your-site-url.com

# Docker镜像仓库配置
DOCKER_REGISTRY=registry.cn-hangzhou.aliyuncs.com
DOCKER_NAMESPACE=your-namespace
DOCKER_REPOSITORY=supabase-login-ui
```

### 3. 构建多架构镜像

#### Linux/macOS 用户

```bash
# 添加执行权限
chmod +x docker-build.sh

# 构建主流架构镜像并推送到仓库 (amd64, arm64)
./docker-build.sh buildmulti 1.0.0

# 构建所有架构镜像 (包括不兼容平台)
./docker-build.sh buildall 1.0.0

# 或者仅在本地构建
./docker-build.sh build 1.0.0
```

#### Windows 用户

```batch
# 构建主流架构镜像并推送到仓库 (amd64, arm64)
docker-build.bat buildmulti 1.0.0

# 构建所有架构镜像 (包括不兼容平台)
docker-build.bat buildall 1.0.0

# 或者仅在本地构建
docker-build.bat build 1.0.0
```

### 4. 运行容器

```bash
# Linux/macOS
./docker-build.sh run 1.0.0

# Windows
docker-build.bat run 1.0.0
```

或使用 docker-compose:

```bash
docker-compose up -d
```

## 多架构支持说明

本项目使用 Docker BuildX 构建支持多种 CPU 架构的容器镜像，但各架构有不同的编译支持级别：

### 完全支持的架构（推荐用于生产环境）
- **linux/amd64**: 适用于大多数桌面电脑、服务器和云实例
- **linux/arm64**: 适用于基于 ARM64 的设备，如树莓派 4、AWS Graviton、Apple Silicon Mac

### 有限支持的架构（需要使用Babel替代SWC）
- **linux/arm/v7**: 适用于老款树莓派等 ARMv7 设备
- **linux/ppc64le**: 适用于基于 POWER8+ 的服务器
- **linux/s390x**: 适用于 IBM Z 系列大型机

> **注意**：Next.js 的 SWC 编译器不支持某些架构（如 ppc64le 和 s390x）。对于这些架构，我们提供了使用 Babel 的备选方案，但构建速度会较慢。

### 自定义支持的架构

您可以在 `.env` 文件中修改支持的架构：

```
# SWC兼容平台 (推荐)
SWC_COMPATIBLE_PLATFORMS=linux/amd64,linux/arm64

# 全部平台 (包括SWC不兼容平台)
ALL_PLATFORMS=linux/amd64,linux/arm64,linux/arm/v7,linux/ppc64le,linux/s390x
```

## 命令参考

### Linux/macOS

```bash
./docker-build.sh build [版本号]      # 构建多架构镜像
./docker-build.sh buildlatest         # 构建latest版本镜像 
./docker-build.sh buildmulti [版本]   # 构建并推送多架构镜像 (仅兼容平台)
./docker-build.sh buildall [版本]     # 构建并推送所有架构镜像 (包括不兼容平台)
./docker-build.sh run [版本号]        # 运行容器
./docker-build.sh export [版本号]     # 导出镜像为tar文件
./docker-build.sh login [仓库地址]    # 登录到Docker仓库
./docker-build.sh push [版本号]       # 推送镜像到仓库
./docker-build.sh pull [版本号]       # 拉取镜像
```

### Windows

```batch
docker-build.bat build [版本号]       # 构建多架构镜像
docker-build.bat buildlatest          # 构建latest版本镜像
docker-build.bat buildmulti [版本]    # 构建并推送多架构镜像 (仅兼容平台)
docker-build.bat buildall [版本]      # 构建并推送所有架构镜像 (包括不兼容平台)
docker-build.bat run [版本号]         # 运行容器
docker-build.bat export [版本号]      # 导出镜像为tar文件
docker-build.bat login [仓库地址]     # 登录到Docker仓库
docker-build.bat push [版本号]        # 推送镜像到仓库
docker-build.bat pull [版本号]        # 拉取镜像
```

## 故障排除

### 1. 构建失败

如果构建多架构镜像时出现错误：

```bash
# 尝试清理Docker构建缓存
docker buildx prune -f

# 检查Docker Buildx是否正确安装
docker buildx version

# 尝试减少支持的架构数量
# 编辑.env文件中的DOCKER_PLATFORMS变量
```

### 2. 镜像拉取问题

国内用户可能遇到网络问题，尝试以下方法：

```bash
# 配置国内Docker镜像源
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": [
    "https://registry.docker-cn.com",
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com"
  ]
}
EOF
sudo systemctl restart docker

# 或使用导出/导入方式部署
./docker-build.sh export 1.0.0
# 将导出的tar文件复制到目标服务器
docker load -i docker-exports/supabase-login-ui-1.0.0.tar
```

### 3. 运行时架构不匹配

确保您拉取的是多架构镜像：

```bash
# 检查镜像支持的架构
docker manifest inspect ${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/${DOCKER_REPOSITORY}:${VERSION}
```

### 4. TypeScript构建错误

如果遇到 TypeScript 类型错误导致构建失败：

```
Failed to compile.
Type error: Type 'ForwardedRef<HTMLButtonElement>' is not assignable to type...
```

可以尝试以下解决方案：

1. **方案1**: 跳过类型检查（已在Dockerfile中配置）
   - 使用 `SKIP_TYPE_CHECK=true` 环境变量，已在Dockerfile中设置

2. **方案2**: 修复组件库类型问题
   - button.tsx中使用了 `asChild` 属性，需要导入和使用 `@radix-ui/react-slot` 组件
   - 已在组件库中修复相关问题

### 5. SWC编译器错误

在某些架构下可能出现以下错误：

```
⚠ Trying to load next-swc for unsupported platforms
⨯ Failed to load SWC binary for linux/ppc64, see more info here
```

解决方案：

1. 使用 `buildmulti` 命令代替 `buildall`，只构建SWC兼容的平台
2. 或者在使用所有平台时，可以通过修改 `.env` 中的 `ALL_PLATFORMS` 来移除不兼容的平台

## 环境变量映射

| Supabase变量名 | 前端变量名 | 说明 |
|--------------|-----------|------|
| `SUPABASE_PUBLIC_URL` | `NEXT_PUBLIC_SUPABASE_URL` | Supabase API服务地址 |
| `ANON_KEY` | `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Supabase匿名访问密钥 |
| `SITE_URL` | `NEXT_PUBLIC_SITE_URL` | 应用站点URL，用于OAuth回调 |
| `GOTRUE_EXTERNAL_GITHUB_ENABLED` | `NEXT_PUBLIC_AUTH_GITHUB_ENABLED` | 是否启用GitHub登录 |
| `GOTRUE_EXTERNAL_GOOGLE_ENABLED` | `NEXT_PUBLIC_AUTH_GOOGLE_ENABLED` | 是否启用Google登录 |

## 性能优化与最佳实践

1. **减小镜像体积**：使用多阶段构建，只包含必要文件
2. **安全性**：最终镜像使用非root用户运行
3. **缓存优化**：依赖安装和构建分离，提高构建速度
4. **健康检查**：内置健康检查确保容器正常运行
5. **资源限制**：通过docker-compose配置CPU和内存限制
6. **架构兼容**：自动检测和适配不同的CPU架构 