FROM registry.cn-hangzhou.aliyuncs.com/nodejs-image/node:18-slim AS base

# 安装依赖
FROM base AS deps
# 更新软件源并安装依赖
RUN sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list \
    && sed -i 's/security.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list \
    && apt-get update && apt-get install -y --no-install-recommends \
    libc6-compat \
    locales \
    fonts-noto-cjk \
    wget \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    # 设置中文支持
    && sed -i 's/^# *\(zh_CN.UTF-8\)/\1/' /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=zh_CN.UTF-8 LC_ALL=zh_CN.UTF-8

# 设置环境变量
ENV LANG=zh_CN.UTF-8 
ENV LC_ALL=zh_CN.UTF-8
ENV TZ=Asia/Shanghai

WORKDIR /app

# 设置npm使用淘宝镜像
RUN npm config set registry https://registry.npmmirror.com
COPY package.json package-lock.json* ./
RUN npm ci

# 构建应用
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# 设置环境变量，这些变量需要在构建时使用
ARG NEXT_PUBLIC_SUPABASE_URL
ARG NEXT_PUBLIC_SUPABASE_ANON_KEY
ARG NEXT_PUBLIC_SITE_URL
ARG NEXT_PUBLIC_AUTH_GITHUB_ENABLED
ARG NEXT_PUBLIC_AUTH_GOOGLE_ENABLED
ARG APP_VERSION=1.0.0

ENV NEXT_PUBLIC_SUPABASE_URL=$NEXT_PUBLIC_SUPABASE_URL
ENV NEXT_PUBLIC_SUPABASE_ANON_KEY=$NEXT_PUBLIC_SUPABASE_ANON_KEY
ENV NEXT_PUBLIC_SITE_URL=$NEXT_PUBLIC_SITE_URL
ENV NEXT_PUBLIC_AUTH_GITHUB_ENABLED=$NEXT_PUBLIC_AUTH_GITHUB_ENABLED
ENV NEXT_PUBLIC_AUTH_GOOGLE_ENABLED=$NEXT_PUBLIC_AUTH_GOOGLE_ENABLED
ENV APP_VERSION=$APP_VERSION

RUN npm run build

# 生产环境
FROM base AS runner
WORKDIR /app

ENV NODE_ENV production
ENV APP_VERSION=${APP_VERSION:-1.0.0}
ENV LANG=zh_CN.UTF-8 
ENV LC_ALL=zh_CN.UTF-8
ENV TZ=Asia/Shanghai

# 安装运行时所需依赖
RUN sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list \
    && sed -i 's/security.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list \
    && apt-get update && apt-get install -y --no-install-recommends \
    locales \
    fonts-noto-cjk \
    wget \
    && rm -rf /var/lib/apt/lists/* \
    # 设置中文支持
    && sed -i 's/^# *\(zh_CN.UTF-8\)/\1/' /etc/locale.gen \
    && locale-gen

# 创建非root用户
RUN groupadd -g 1001 nodejs
RUN useradd -u 1001 -g nodejs -s /bin/bash -m nextjs

COPY --from=builder /app/public ./public

# 设置正确的权限
RUN mkdir -p .next
RUN chown nextjs:nodejs .next

# 自动利用输出跟踪功能复制到独立的层以提高缓存命中率
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

# 添加版本信息文件
RUN echo "Version: $APP_VERSION" > ./public/version.txt
RUN echo "Build date: $(date)" >> ./public/version.txt

USER nextjs

EXPOSE 3000

ENV PORT 3000
ENV HOSTNAME "0.0.0.0"

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 CMD wget --no-verbose --tries=1 --spider http://localhost:3000/ || exit 1

# 添加标签
LABEL maintainer="ALLBS Team"
LABEL version="${APP_VERSION}"
LABEL description="Supabase登录UI"

# 服务器使用独立的输出配置
CMD ["node", "server.js"] 