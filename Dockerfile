FROM node:18-slim

WORKDIR /app

COPY package*.json ./

# 安装依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    && rm -rf /var/lib/apt/lists/* \
    && npm config set registry https://registry.npmmirror.com \
    && npm install

# 复制源代码
COPY . .

# 设置构建参数（非敏感信息）
ARG NEXT_PUBLIC_SUPABASE_URL
ARG NEXT_PUBLIC_SITE_URL
ARG APP_VERSION=1.0.0

# 设置环境变量（非敏感信息）
ENV NEXT_PUBLIC_SUPABASE_URL=${NEXT_PUBLIC_SUPABASE_URL}
ENV NEXT_PUBLIC_SITE_URL=${NEXT_PUBLIC_SITE_URL}
ENV APP_VERSION=${APP_VERSION}
ENV NODE_ENV=production
ENV TZ=Asia/Shanghai
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

# 添加版本信息文件
RUN mkdir -p ./public && \
    echo "Version: ${APP_VERSION}" > ./public/version.txt && \
    echo "Build date: $(date)" >> ./public/version.txt

EXPOSE 3000

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 CMD wget --no-verbose --tries=1 --spider http://localhost:3000/ || exit 1

# 添加标签
LABEL maintainer="ALLBS Team"
LABEL version="${APP_VERSION}"
LABEL description="Supabase登录UI"

# 启动开发服务器，绕过构建过程
CMD ["npm", "run", "dev"]
