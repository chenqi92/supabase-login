#!/bin/bash

# Supabase登录UI - Docker构建工具
# 功能：构建、运行、导出、帮助

# 默认设置
VERSION=${2:-1.0.0}
IMAGE_NAME="supabase-login-ui"
CONTAINER_NAME="supabase-login-ui"
BASE_IMAGE="registry.cn-hangzhou.aliyuncs.com/nodejs-image/node:18-slim"
PORT=3000
SUPABASE_URL="https://database.allbs.cn"
ANON_KEY="your_anon_key"
SITE_URL="https://login.allbs.cn"
GITHUB_ENABLED="true"
GOOGLE_ENABLED="true"

# 命令列表
COMMANDS=("build" "run" "export" "help")

# 显示帮助信息
show_help() {
    echo "使用方法: $0 命令 [参数]"
    echo ""
    echo "可用命令:"
    echo "  build [版本号]    - 构建Docker镜像 (默认版本: 1.0.0)"
    echo "  run [版本号]      - 运行已构建的Docker镜像 (默认版本: 1.0.0)"
    echo "  export [版本号]   - 导出Docker镜像为.tar文件 (默认版本: 1.0.0)"
    echo "  help             - 显示帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 build 1.0.0   - 构建版本1.0.0的镜像"
    echo "  $0 run           - 运行最新构建的镜像"
    echo "  $0 export 1.0.0  - 导出版本1.0.0的镜像"
    echo ""
    echo "环境变量可以通过.env文件设置"
}

# 检查命令是否有效
is_valid_command() {
    for cmd in "${COMMANDS[@]}"; do
        if [[ "$cmd" == "$1" ]]; then
            return 0
        fi
    done
    return 1
}

# 检查Docker守护进程是否运行
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        echo "错误: Docker守护进程未运行，请启动Docker服务"
        exit 1
    fi
}

# 检查网络连接
check_network() {
    echo "检查网络连接..."
    if ! ping -c 1 registry.cn-hangzhou.aliyuncs.com > /dev/null 2>&1; then
        echo "警告: 无法连接到阿里云镜像服务，可能存在网络问题"
        echo "继续尝试构建..."
    fi
}

# 预先拉取基础镜像
pull_base_image() {
    echo "尝试预先拉取基础镜像..."
    if ! docker pull $BASE_IMAGE; then
        echo "警告: 无法拉取基础镜像，将尝试使用本地缓存继续构建"
        # 检查是否有本地缓存
        if ! docker images $BASE_IMAGE | grep -q $BASE_IMAGE; then
            echo "错误: 本地无缓存的基础镜像，构建可能会失败"
            echo "您可以尝试手动设置Docker镜像源后再试"
            echo "是否继续构建? (y/n)"
            read -r continue_build
            if [[ "$continue_build" != "y" && "$continue_build" != "Y" ]]; then
                echo "构建已取消"
                exit 1
            fi
        fi
    fi
}

# 加载环境变量
load_env() {
    if [ -f .env ]; then
        echo "加载.env文件..."
        # 只加载非注释行且非空行
        while IFS= read -r line || [ -n "$line" ]; do
            # 跳过注释行和空行
            if [[ ! "$line" =~ ^# ]] && [[ -n "$line" ]]; then
                export "$line"
            fi
        done < .env
    fi

    # 设置默认值（如果未在.env中设置）
    SUPABASE_URL=${SUPABASE_PUBLIC_URL:-$SUPABASE_URL}
    ANON_KEY=${ANON_KEY:-"your_anon_key"}
    SITE_URL=${SITE_URL:-$SITE_URL}
    GITHUB_ENABLED=${GOTRUE_EXTERNAL_GITHUB_ENABLED:-true}
    GOOGLE_ENABLED=${GOTRUE_EXTERNAL_GOOGLE_ENABLED:-true}
}

# 清理旧容器和镜像
cleanup() {
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
}

# 构建镜像
build_image() {
    echo "=== 开始构建版本: $VERSION ==="
    
    check_docker
    check_network
    pull_base_image
    load_env
    cleanup

    echo "构建Docker镜像..."
    docker build \
      --build-arg NEXT_PUBLIC_SUPABASE_URL=$SUPABASE_URL \
      --build-arg NEXT_PUBLIC_SUPABASE_ANON_KEY=$ANON_KEY \
      --build-arg NEXT_PUBLIC_SITE_URL=$SITE_URL \
      --build-arg NEXT_PUBLIC_AUTH_GITHUB_ENABLED=$GITHUB_ENABLED \
      --build-arg NEXT_PUBLIC_AUTH_GOOGLE_ENABLED=$GOOGLE_ENABLED \
      --build-arg APP_VERSION=$VERSION \
      -t $IMAGE_NAME:latest .

    # 检查构建是否成功
    if [ $? -ne 0 ]; then
        echo "错误: Docker镜像构建失败"
        exit 1
    fi

    echo "为镜像添加版本标签..."
    docker tag $IMAGE_NAME:latest $IMAGE_NAME:$VERSION

    echo "=== 构建完成! ==="
    echo "镜像版本: $VERSION"
    echo "现在可以运行: $0 run $VERSION"
}

# 运行容器
run_container() {
    echo "=== 开始运行版本: $VERSION ==="
    
    check_docker
    load_env

    # 检查镜像是否存在
    if ! docker images $IMAGE_NAME:$VERSION | grep -q $VERSION; then
        echo "错误: 镜像 $IMAGE_NAME:$VERSION 不存在"
        echo "请先运行 $0 build $VERSION 构建镜像"
        exit 1
    fi

    # 检查是否有旧容器运行
    if [ "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
        echo "停止并移除现有容器..."
        docker stop $CONTAINER_NAME
        docker rm $CONTAINER_NAME
    fi

    echo "启动容器..."
    docker run -d \
      --name $CONTAINER_NAME \
      -p ${PORT}:3000 \
      -e NODE_ENV=production \
      -v $(pwd)/logs:/app/logs \
      $IMAGE_NAME:$VERSION

    # 检查容器是否成功启动
    if [ "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
        echo "=== 容器启动成功! ==="
        echo "应用正在运行: http://localhost:$PORT"
        echo "版本信息: $VERSION"

        # 显示容器日志
        echo "容器日志:"
        docker logs $CONTAINER_NAME
    else
        echo "错误: 容器未能成功启动"
        echo "请检查日志获取更多信息:"
        echo "docker logs $CONTAINER_NAME"
        exit 1
    fi
}

# 导出镜像
export_image() {
    echo "=== 开始导出镜像: $IMAGE_NAME:$VERSION ==="
    
    check_docker

    # 检查镜像是否存在
    if ! docker images $IMAGE_NAME:$VERSION | grep -q $VERSION; then
        echo "错误: 镜像 $IMAGE_NAME:$VERSION 不存在"
        echo "请先运行 $0 build $VERSION 构建镜像"
        exit 1
    fi

    OUTPUT_FILE="$IMAGE_NAME-$VERSION.tar"
    
    # 导出镜像
    echo "导出镜像到文件: $OUTPUT_FILE"
    docker save -o $OUTPUT_FILE $IMAGE_NAME:$VERSION

    # 检查导出是否成功
    if [ $? -eq 0 ] && [ -f "$OUTPUT_FILE" ]; then
        # 计算文件大小
        FILE_SIZE=$(du -h $OUTPUT_FILE | cut -f1)
        echo "=== 导出成功! ==="
        echo "文件大小: $FILE_SIZE"
        echo "文件路径: $(pwd)/$OUTPUT_FILE"
        echo ""
        echo "在目标机器上使用以下命令加载镜像:"
        echo "  docker load -i $OUTPUT_FILE"
        echo "  docker run -d --name $CONTAINER_NAME -p 3000:3000 $IMAGE_NAME:$VERSION"
    else
        echo "错误: 导出失败"
        exit 1
    fi
}

# 主函数
main() {
    # 设置权限
    chmod +x *.sh 2>/dev/null || true
    
    # 检查参数
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi

    # 检查命令是否有效
    if ! is_valid_command "$1"; then
        echo "错误: 无效的命令 '$1'"
        show_help
        exit 1
    fi

    # 处理命令
    case "$1" in
        build)
            build_image
            ;;
        run)
            run_container
            ;;
        export)
            export_image
            ;;
        help|*)
            show_help
            ;;
    esac
}

# 运行主函数
main "$@" 