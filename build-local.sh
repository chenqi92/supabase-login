#!/bin/bash

# 设置变量
VERSION=${1:-1.0.0}
IMAGE_NAME="supabase-login-ui"
CONTAINER_NAME="supabase-login-ui"

echo "=== 开始构建版本: $VERSION ==="

# 检查是否有旧容器运行
if [ "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
    echo "停止并移除现有容器..."
    docker stop $CONTAINER_NAME
    docker rm $CONTAINER_NAME
fi

# 检查是否有旧镜像
if [ "$(docker images -q $IMAGE_NAME:$VERSION)" ]; then
    echo "移除旧版本镜像..."
    docker rmi $IMAGE_NAME:$VERSION
fi

# 设置环境变量
export APP_VERSION=$VERSION
export PORT=3000

# 从.env文件加载变量（如果存在）
if [ -f .env ]; then
    echo "加载.env文件..."
    source .env
fi

# 设置默认值（如果未在.env中设置）
export SUPABASE_PUBLIC_URL=${SUPABASE_PUBLIC_URL:-https://database.allbs.cn}
export ANON_KEY=${ANON_KEY:-your_anon_key}
export SITE_URL=${SITE_URL:-https://login.allbs.cn}
export GOTRUE_EXTERNAL_GITHUB_ENABLED=${GOTRUE_EXTERNAL_GITHUB_ENABLED:-true}
export GOTRUE_EXTERNAL_GOOGLE_ENABLED=${GOTRUE_EXTERNAL_GOOGLE_ENABLED:-true}

echo "构建Docker镜像..."
docker-compose build

echo "为镜像添加版本标签..."
docker tag $IMAGE_NAME:latest $IMAGE_NAME:$VERSION

echo "启动容器..."
docker-compose up -d

echo "=== 构建完成! ==="
echo "应用正在运行: http://localhost:$PORT"
echo "版本信息: $VERSION" 