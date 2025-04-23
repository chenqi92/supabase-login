# 依赖阶段 - 安装所有依赖
FROM node:18-alpine AS deps

# 设置工作目录
WORKDIR /app

# 设置国内镜像源（可根据实际情况调整）
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories && \
    apk add --no-cache curl 

# 设置npm国内源
RUN npm config set registry https://registry.npmmirror.com

# 单独复制package文件 - 改进缓存利用率
COPY package.json package-lock.json* ./
RUN npm ci

# 构建阶段 - 编译应用
FROM node:18-alpine AS builder

# 设置工作目录
WORKDIR /app

# 检测CPU架构并设置环境变量
RUN arch=$(uname -m) && \
    if [ "$arch" = "x86_64" ] || [ "$arch" = "aarch64" ]; then \
        echo "Architecture $arch supports SWC compiler"; \
        export NEXT_ARCHITECTURE=supported; \
    else \
        echo "Architecture $arch does not support SWC compiler, using Babel fallback"; \
        export NEXT_ARCHITECTURE=unsupported; \
    fi

# 设置环境变量
ENV NODE_ENV=production \
    NEXT_TELEMETRY_DISABLED=1 \
    SKIP_TYPE_CHECK=true

# 根据架构设置编译器选项
ARG TARGETPLATFORM
RUN echo "Building for $TARGETPLATFORM" && \
    case "$TARGETPLATFORM" in \
        "linux/amd64"|"linux/arm64") \
            echo "Using SWC for $TARGETPLATFORM" && \
            export NEXT_ARCHITECTURE=supported \
            ;; \
        *) \
            echo "Using Babel fallback for $TARGETPLATFORM" && \
            export NEXT_ARCHITECTURE=unsupported \
            ;; \
    esac

# 安装babel相关依赖（仅在需要时使用）
RUN if [ "$NEXT_ARCHITECTURE" = "unsupported" ]; then \
        echo "Installing Babel dependencies for fallback compilation" && \
        npm install --save-dev babel-loader @babel/core @babel/preset-env @babel/preset-react @babel/preset-typescript; \
    fi

# 复制依赖
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# 构建参数
ARG NEXT_PUBLIC_SUPABASE_URL
ARG NEXT_PUBLIC_SITE_URL
ARG NEXT_PUBLIC_SUPABASE_ANON_KEY
ARG NEXT_PUBLIC_AUTH_GITHUB_ENABLED
ARG NEXT_PUBLIC_AUTH_GOOGLE_ENABLED
ARG APP_VERSION=1.0.0

# 设置构建时环境变量
ENV NEXT_PUBLIC_SUPABASE_URL=$NEXT_PUBLIC_SUPABASE_URL \
    NEXT_PUBLIC_SITE_URL=$NEXT_PUBLIC_SITE_URL \
    NEXT_PUBLIC_SUPABASE_ANON_KEY=$NEXT_PUBLIC_SUPABASE_ANON_KEY \
    NEXT_PUBLIC_AUTH_GITHUB_ENABLED=$NEXT_PUBLIC_AUTH_GITHUB_ENABLED \
    NEXT_PUBLIC_AUTH_GOOGLE_ENABLED=$NEXT_PUBLIC_AUTH_GOOGLE_ENABLED \
    APP_VERSION=$APP_VERSION

# 创建版本信息文件
RUN mkdir -p ./public && \
    echo "Version: ${APP_VERSION}" > ./public/version.txt && \
    echo "Build date: $(date)" >> ./public/version.txt && \
    echo "Platform: $(uname -m)" >> ./public/version.txt 

# 构建应用
RUN npm run build

# 运行阶段 - 最终镜像
FROM node:18-alpine AS runner

# 设置工作目录
WORKDIR /app

# 设置环境变量
ENV NODE_ENV=production \
    NEXT_TELEMETRY_DISABLED=1 \
    TZ=Asia/Shanghai \
    PORT=3000 \
    HOSTNAME="0.0.0.0"

# 创建非root用户
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs && \
    mkdir -p /app/logs && \
    chown -R nextjs:nodejs /app

# 复制构建产物
COPY --from=builder --chown=nextjs:nodejs /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

# 切换到非root用户
USER nextjs

# 开放端口
EXPOSE 3000

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 CMD curl -f http://localhost:3000/ || exit 1

# 镜像标签
LABEL maintainer="kkape" \
      org.opencontainers.image.source="https://github.com/kkape/supabase-login-ui" \
      org.opencontainers.image.description="Supabase登录UI多架构镜像"

# 启动应用
CMD ["node", "server.js"]
