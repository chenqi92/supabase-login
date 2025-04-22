# 使用轻量级Alpine镜像 
FROM node:18-alpine

# 设置工作目录
WORKDIR /app

# 设置国内镜像源
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories && \
    apk add --no-cache curl

# 设置npm国内源并仅复制package.json文件
COPY package*.json ./
RUN npm config set registry https://registry.npmmirror.com && \
    npm install

# 复制源代码
COPY . .

# 设置构建参数
ARG NEXT_PUBLIC_SUPABASE_URL
ARG NEXT_PUBLIC_SITE_URL
ARG APP_VERSION=1.0.0

# 环境变量配置
ENV NEXT_PUBLIC_SUPABASE_URL=${NEXT_PUBLIC_SUPABASE_URL} \
    NEXT_PUBLIC_SITE_URL=${NEXT_PUBLIC_SITE_URL} \
    APP_VERSION=${APP_VERSION} \
    NODE_ENV=production \
    TZ=Asia/Shanghai \
    PORT=3000 \
    HOSTNAME="0.0.0.0"

# 添加版本信息
RUN mkdir -p ./public && \
    echo "Version: ${APP_VERSION}" > ./public/version.txt && \
    echo "Build date: $(date)" >> ./public/version.txt

# 开放3000端口
EXPOSE 3000

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 CMD curl -f http://localhost:3000/ || exit 1

# 镜像标签
LABEL maintainer="ALLBS Team" \
      version="${APP_VERSION}" \
      description="Supabase登录UI"

# 直接使用开发模式启动应用，绕过构建步骤
CMD ["npm", "run", "dev"]
