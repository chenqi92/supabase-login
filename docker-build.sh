#!/bin/bash

# Supabase登录UI - Docker简易构建工具

# 默认配置
APP_NAME="supabase-login-ui"
APP_VERSION="1.0.0"
PORT=3000

# 帮助函数
show_help() {
  echo "Supabase登录UI - Docker简易构建工具"
  echo ""
  echo "用法: ./$(basename $0) <命令> [选项]"
  echo ""
  echo "命令:"
  echo "  build [版本]    构建Docker镜像 (默认版本: 1.0.0)"
  echo "  run [端口]      运行Docker容器 (默认端口: 3000)"
  echo "  stop           停止并删除运行中的容器"
  echo "  status         查看容器状态"
  echo "  help           显示帮助信息"
  echo ""
  echo "示例:"
  echo "  ./$(basename $0) build 2.0.0    构建版本2.0.0的镜像"
  echo "  ./$(basename $0) run 8080       在8080端口运行容器"
  echo ""
}

# 环境变量处理
setup_env() {
  # 如果.env文件存在，则读取
  if [ -f .env ]; then
    echo "📋 加载环境变量..."
    export $(grep -v '^#' .env | xargs)
  fi
  
  # 设置构建参数
  SUPABASE_URL=${NEXT_PUBLIC_SUPABASE_URL:-"https://database.allbs.cn"}
  ANON_KEY=${NEXT_PUBLIC_SUPABASE_ANON_KEY:-"your_anon_key"}
  SITE_URL=${NEXT_PUBLIC_SITE_URL:-"https://login.allbs.cn"}
  GITHUB_ENABLED=${NEXT_PUBLIC_AUTH_GITHUB_ENABLED:-"true"}
  GOOGLE_ENABLED=${NEXT_PUBLIC_AUTH_GOOGLE_ENABLED:-"true"}
}

# 构建镜像
build_image() {
  local version=${1:-$APP_VERSION}
  
  echo "🔨 开始构建 $APP_NAME:$version"
  setup_env
  
  # 构建Docker镜像
  docker build \
    --build-arg NEXT_PUBLIC_SUPABASE_URL=$SUPABASE_URL \
    --build-arg NEXT_PUBLIC_SUPABASE_ANON_KEY=$ANON_KEY \
    --build-arg NEXT_PUBLIC_SITE_URL=$SITE_URL \
    --build-arg NEXT_PUBLIC_AUTH_GITHUB_ENABLED=$GITHUB_ENABLED \
    --build-arg NEXT_PUBLIC_AUTH_GOOGLE_ENABLED=$GOOGLE_ENABLED \
    --build-arg APP_VERSION=$version \
    -t $APP_NAME:$version \
    -t $APP_NAME:latest .
  
  if [ $? -eq 0 ]; then
    echo "✅ 镜像构建成功: $APP_NAME:$version"
  else
    echo "❌ 镜像构建失败"
    exit 1
  fi
}

# 运行容器
run_container() {
  local port=${1:-$PORT}
  
  # 确保存在latest镜像
  if ! docker image inspect $APP_NAME:latest >/dev/null 2>&1; then
    echo "❌ 未找到镜像 $APP_NAME:latest"
    echo "请先运行: ./$(basename $0) build"
    exit 1
  fi
  
  # 停止旧容器
  stop_container > /dev/null
  
  echo "🚀 启动容器 $APP_NAME (端口: $port)..."
  docker run -d \
    --name $APP_NAME \
    -p $port:3000 \
    -e NODE_ENV=production \
    $APP_NAME:latest
  
  if [ $? -eq 0 ]; then
    echo "✅ 容器启动成功!"
    echo "🌐 访问地址: http://localhost:$port"
  else
    echo "❌ 容器启动失败"
    exit 1
  fi
}

# 停止容器
stop_container() {
  if docker ps -q -f name=$APP_NAME >/dev/null; then
    echo "🛑 停止容器 $APP_NAME..."
    docker stop $APP_NAME >/dev/null
    docker rm $APP_NAME >/dev/null
    echo "✅ 容器已停止并删除"
  else
    echo "ℹ️ 没有运行中的 $APP_NAME 容器"
  fi
}

# 查看状态
show_status() {
  echo "📊 $APP_NAME 状态:"
  
  # 检查镜像
  echo "镜像:"
  docker images $APP_NAME --format "  {{.Tag}}\t({{.CreatedAt}})"
  
  # 检查容器
  echo "容器:"
  if docker ps -a -f name=$APP_NAME --format "{{.Names}}" | grep -q $APP_NAME; then
    docker ps -a -f name=$APP_NAME --format "  {{.Names}}\t{{.Status}}\t{{.Ports}}"
  else
    echo "  没有相关容器"
  fi
}

# 主函数
main() {
  case "$1" in
    build)
      build_image "$2"
      ;;
    run)
      run_container "$2"
      ;;
    stop)
      stop_container
      ;;
    status)
      show_status
      ;;
    help|*)
      show_help
      ;;
  esac
}

# 执行主函数
main "$@" 