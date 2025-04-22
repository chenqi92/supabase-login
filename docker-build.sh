#!/bin/bash

# 设置错误时退出
set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 无颜色

# 显示帮助信息
show_help() {
    echo -e "${BLUE}Supabase 登录 UI Docker 构建工具${NC}"
    echo "用法: $0 [命令] [版本号]"
    echo ""
    echo "命令:"
    echo "  build [版本号]    构建Docker镜像"
    echo "  buildlatest       构建并标记为latest版本镜像"
    echo "  run [版本号]      运行Docker容器"
    echo "  export [版本号]   导出Docker镜像为tar文件"
    echo "  login [仓库地址]  登录到Docker镜像仓库"
    echo "  push [版本号]     推送镜像到仓库"
    echo "  pull [版本号]     从仓库拉取镜像"
    echo "  help             显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 build 1.0.0   构建版本1.0.0的镜像"
    echo "  $0 buildlatest   构建并标记为latest版本镜像"
    echo "  $0 run 1.0.0     运行版本1.0.0的容器"
    echo "  $0 export 1.0.0  导出版本1.0.0的镜像"
    echo "  $0 login docker.io  登录到Docker Hub官方仓库"
    echo "  $0 push 1.0.0    推送1.0.0版本镜像到仓库"
    echo "  $0 pull 1.0.0    从仓库拉取1.0.0版本镜像"
    echo ""
}

# 检查环境变量文件
check_env_file() {
    if [ ! -f .env ]; then
        echo -e "${YELLOW}警告: .env 文件不存在，将创建示例环境变量文件${NC}"
        cat > .env << EOF
# Supabase 配置
SUPABASE_PUBLIC_URL=https://database.allbs.cn
ANON_KEY=your_anon_key
SITE_URL=https://login.allbs.cn

# OAuth配置
GOTRUE_EXTERNAL_GITHUB_ENABLED=true
GOTRUE_EXTERNAL_GOOGLE_ENABLED=true

# 版本控制
APP_VERSION=$VERSION

# Docker镜像仓库配置
DOCKER_REGISTRY=docker.io
DOCKER_NAMESPACE=your-namespace
DOCKER_REPOSITORY=supabase-login-ui
DOCKER_USERNAME=your-username
DOCKER_PASSWORD=your-password
EOF
        echo -e "${GREEN}已创建 .env 文件，请编辑其中的配置再继续${NC}"
        exit 1
    fi
}

# 构建Docker镜像
build_image() {
    echo -e "${BLUE}开始构建 supabase-login-ui:$VERSION 镜像...${NC}"
    check_env_file
    
    # 加载环境变量
    export $(grep -v '^#' .env | xargs)
    
    # 构建镜像
    docker build \
        --build-arg NEXT_PUBLIC_SUPABASE_URL=$SUPABASE_PUBLIC_URL \
        --build-arg NEXT_PUBLIC_SITE_URL=$SITE_URL \
        --build-arg APP_VERSION=$VERSION \
        -t supabase-login-ui:$VERSION .
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}构建失败!${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}镜像构建完成: supabase-login-ui:$VERSION${NC}"
}

# 构建latest版本镜像
build_latest() {
    echo -e "${BLUE}开始构建 latest 版本镜像...${NC}"
    check_env_file
    
    # 加载环境变量
    export $(grep -v '^#' .env | xargs)
    
    # 生成带时间戳的版本号
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    CURRENT_VERSION="${APP_VERSION}.${TIMESTAMP}"
    
    # 构建镜像 - 同时标记为特定版本和latest
    echo -e "${BLUE}正在构建并标记镜像...${NC}"
    docker build \
        --build-arg NEXT_PUBLIC_SUPABASE_URL=$SUPABASE_PUBLIC_URL \
        --build-arg NEXT_PUBLIC_SITE_URL=$SITE_URL \
        --build-arg APP_VERSION=$CURRENT_VERSION \
        -t supabase-login-ui:$CURRENT_VERSION \
        -t supabase-login-ui:latest .
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}构建失败!${NC}"
        exit 1
    fi
    
    # 询问是否要标记远程镜像
    echo -e "${YELLOW}是否要为镜像添加远程标记?（准备推送）[y/N]${NC}"
    read -r answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        # 先尝试登录
        echo -e "${BLUE}请先登录到Docker仓库${NC}"
        login_registry ${DOCKER_REGISTRY:-docker.io}
        
        # 获取当前登录的Docker用户名
        CURRENT_USER=$(get_docker_username)
        if [ $? -ne 0 ]; then
            exit 1
        fi
        
        # 检查必要的环境变量
        if [ -z "$DOCKER_REPOSITORY" ]; then
            echo -e "${RED}错误: 缺少仓库名称配置，请检查.env文件${NC}"
            echo -e "${YELLOW}需要设置: DOCKER_REPOSITORY${NC}"
            exit 1
        fi
        
        # 使用Docker Hub的命名格式
        REGISTRY=${DOCKER_REGISTRY:-docker.io}
        if [ "$REGISTRY" = "docker.io" ]; then
            REMOTE_TAG_SPECIFIC="$CURRENT_USER/$DOCKER_REPOSITORY:$CURRENT_VERSION"
            REMOTE_TAG_LATEST="$CURRENT_USER/$DOCKER_REPOSITORY:latest"
        else
            REMOTE_TAG_SPECIFIC="$REGISTRY/$DOCKER_NAMESPACE/$DOCKER_REPOSITORY:$CURRENT_VERSION"
            REMOTE_TAG_LATEST="$REGISTRY/$DOCKER_NAMESPACE/$DOCKER_REPOSITORY:latest"
        fi
        
        echo -e "${BLUE}正在标记远程镜像...${NC}"
        docker tag supabase-login-ui:$CURRENT_VERSION $REMOTE_TAG_SPECIFIC
        docker tag supabase-login-ui:latest $REMOTE_TAG_LATEST
        
        echo -e "${GREEN}已标记远程镜像: ${NC}"
        echo -e "${GREEN}- $REMOTE_TAG_SPECIFIC${NC}"
        echo -e "${GREEN}- $REMOTE_TAG_LATEST${NC}"
        
        echo -e "${YELLOW}提示: 使用以下命令推送镜像到仓库:${NC}"
        echo -e "${BLUE}docker push $REMOTE_TAG_SPECIFIC${NC}"
        echo -e "${BLUE}docker push $REMOTE_TAG_LATEST${NC}"
    fi
    
    echo -e "${GREEN}镜像构建完成: ${NC}"
    echo -e "${GREEN}- supabase-login-ui:$CURRENT_VERSION${NC}"
    echo -e "${GREEN}- supabase-login-ui:latest${NC}"
}

# 运行Docker容器
run_container() {
    echo -e "${BLUE}开始运行 supabase-login-ui:$VERSION 容器...${NC}"
    check_env_file
    
    # 加载环境变量
    export $(grep -v '^#' .env | xargs)
    
    # 停止并移除已存在的容器
    if docker ps -a | grep -q supabase-login-ui; then
        echo -e "${YELLOW}发现已存在的容器，正在停止并移除...${NC}"
        docker stop supabase-login-ui || true
        docker rm supabase-login-ui || true
    fi
    
    # 创建网络(如果不存在)
    if ! docker network ls | grep -q supabase-network; then
        echo "创建 Docker 网络: supabase-network"
        docker network create supabase-network
    fi
    
    # 运行容器
    echo -e "${BLUE}启动容器...${NC}"
    docker run -d \
        --name supabase-login-ui \
        --restart always \
        --network supabase-network \
        -p ${PORT:-3000}:3000 \
        -e NEXT_PUBLIC_SUPABASE_URL=$SUPABASE_PUBLIC_URL \
        -e NEXT_PUBLIC_SUPABASE_ANON_KEY=$ANON_KEY \
        -e NEXT_PUBLIC_SITE_URL=$SITE_URL \
        -e NEXT_PUBLIC_AUTH_GITHUB_ENABLED=$GOTRUE_EXTERNAL_GITHUB_ENABLED \
        -e NEXT_PUBLIC_AUTH_GOOGLE_ENABLED=$GOTRUE_EXTERNAL_GOOGLE_ENABLED \
        -e APP_VERSION=$VERSION \
        -v ./logs:/app/logs \
        supabase-login-ui:$VERSION
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}容器启动失败!${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}容器已启动: supabase-login-ui${NC}"
    echo -e "访问地址: ${BLUE}http://localhost:${PORT:-3000}${NC}"
}

# 导出Docker镜像
export_image() {
    echo -e "${BLUE}开始导出 supabase-login-ui:$VERSION 镜像...${NC}"
    
    # 检查镜像是否存在
    if ! docker images | grep -q "supabase-login-ui" | grep -q "$VERSION"; then
        echo -e "${RED}错误: 镜像 supabase-login-ui:$VERSION 不存在，请先构建镜像${NC}"
        exit 1
    fi
    
    # 创建导出目录
    EXPORT_DIR="./docker-exports"
    mkdir -p $EXPORT_DIR
    
    # 导出镜像
    EXPORT_FILE="$EXPORT_DIR/supabase-login-ui-$VERSION.tar"
    echo -e "${BLUE}正在导出到 $EXPORT_FILE ...${NC}"
    docker save supabase-login-ui:$VERSION -o $EXPORT_FILE
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}导出失败!${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}镜像已成功导出: $EXPORT_FILE${NC}"
    echo -e "${YELLOW}提示: 在目标服务器上使用以下命令加载镜像:${NC}"
    echo -e "${BLUE}docker load -i $EXPORT_FILE${NC}"
}

# 登录到Docker镜像仓库
login_registry() {
    check_env_file
    
    # 加载环境变量
    export $(grep -v '^#' .env | xargs)
    
    # 如果提供了仓库地址参数，则使用参数值
    REGISTRY=${1:-$DOCKER_REGISTRY}
    
    if [ -z "$REGISTRY" ]; then
        echo -e "${YELLOW}未指定仓库地址，将使用默认的Docker Hub${NC}"
        REGISTRY="docker.io"
    fi
    
    echo -e "${BLUE}正在登录到Docker镜像仓库: $REGISTRY${NC}"
    echo -e "${YELLOW}请输入Docker Hub用户名和密码${NC}"
    
    # 始终使用交互式登录
    docker login $REGISTRY
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}登录失败!${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}登录成功${NC}"
}

# 获取Docker用户名
get_docker_username() {
    # 先尝试从docker info获取
    CURRENT_USER=$(docker info 2>/dev/null | grep Username | awk '{print $2}')
    
    # 如果获取失败，则提示用户输入
    if [ -z "$CURRENT_USER" ]; then
        echo -e "${YELLOW}未能自动获取Docker用户名，请手动输入:${NC}"
        read -r CURRENT_USER
        
        if [ -z "$CURRENT_USER" ]; then
            echo -e "${RED}错误: 未提供Docker用户名${NC}"
            return 1
        fi
    fi
    
    echo "$CURRENT_USER"
    return 0
}

# 推送镜像到仓库
push_image() {
    check_env_file
    
    # 加载环境变量
    export $(grep -v '^#' .env | xargs)
    
    # 检查必要的环境变量
    if [ -z "$DOCKER_REPOSITORY" ]; then
        echo -e "${RED}错误: 缺少仓库名称配置，请检查.env文件${NC}"
        echo -e "${YELLOW}需要设置: DOCKER_REPOSITORY${NC}"
        exit 1
    fi
    
    # 检查镜像是否存在
    if ! docker images supabase-login-ui:$VERSION > /dev/null 2>&1; then
        echo -e "${RED}错误: 镜像 supabase-login-ui:$VERSION 不存在，请先构建镜像${NC}"
        exit 1
    fi
    
    # 先尝试登录
    echo -e "${BLUE}请先登录到Docker仓库${NC}"
    login_registry ${DOCKER_REGISTRY:-docker.io}
    
    # 获取当前登录的Docker用户名
    CURRENT_USER=$(get_docker_username)
    if [ $? -ne 0 ]; then
        exit 1
    fi
    
    # 使用Docker Hub的命名格式
    REGISTRY=${DOCKER_REGISTRY:-docker.io}
    if [ "$REGISTRY" = "docker.io" ]; then
        REMOTE_TAG="$CURRENT_USER/$DOCKER_REPOSITORY:$VERSION"
    else
        REMOTE_TAG="$REGISTRY/$DOCKER_NAMESPACE/$DOCKER_REPOSITORY:$VERSION"
    fi
    
    echo -e "${BLUE}正在标记镜像: $REMOTE_TAG${NC}"
    docker tag supabase-login-ui:$VERSION $REMOTE_TAG
    
    echo -e "${BLUE}正在推送镜像到仓库...${NC}"
    docker push $REMOTE_TAG
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}推送失败!${NC}"
        exit 1
    fi
    
    # 如果版本是latest，同时也推送特定版本
    if [ "$VERSION" = "latest" ]; then
        TIMESTAMP=$(date +%Y%m%d-%H%M%S)
        CURRENT_VERSION="${APP_VERSION}.${TIMESTAMP}"
        
        if [ "$REGISTRY" = "docker.io" ]; then
            REMOTE_TAG_SPECIFIC="$CURRENT_USER/$DOCKER_REPOSITORY:$CURRENT_VERSION"
        else
            REMOTE_TAG_SPECIFIC="$REGISTRY/$DOCKER_NAMESPACE/$DOCKER_REPOSITORY:$CURRENT_VERSION"
        fi
        
        echo -e "${BLUE}同时推送时间戳版本: $REMOTE_TAG_SPECIFIC${NC}"
        docker tag supabase-login-ui:latest $REMOTE_TAG_SPECIFIC
        docker push $REMOTE_TAG_SPECIFIC
    fi
    
    echo -e "${GREEN}镜像已成功推送: $REMOTE_TAG${NC}"
}

# 从仓库拉取镜像
pull_image() {
    check_env_file
    
    # 加载环境变量
    export $(grep -v '^#' .env | xargs)
    
    # 检查必要的环境变量
    if [ -z "$DOCKER_REPOSITORY" ]; then
        echo -e "${RED}错误: 缺少仓库名称配置，请检查.env文件${NC}"
        echo -e "${YELLOW}需要设置: DOCKER_REPOSITORY${NC}"
        exit 1
    fi
    
    # 先尝试登录
    echo -e "${BLUE}请先登录到Docker仓库${NC}"
    login_registry ${DOCKER_REGISTRY:-docker.io}
    
    # 获取当前登录的Docker用户名
    CURRENT_USER=$(get_docker_username)
    if [ $? -ne 0 ]; then
        exit 1
    fi
    
    # 使用Docker Hub的命名格式
    REGISTRY=${DOCKER_REGISTRY:-docker.io}
    if [ "$REGISTRY" = "docker.io" ]; then
        REMOTE_TAG="$CURRENT_USER/$DOCKER_REPOSITORY:$VERSION"
    else
        REMOTE_TAG="$REGISTRY/$DOCKER_NAMESPACE/$DOCKER_REPOSITORY:$VERSION"
    fi
    
    echo -e "${BLUE}正在从仓库拉取镜像: $REMOTE_TAG${NC}"
    docker pull $REMOTE_TAG
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}拉取失败!${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}正在标记镜像为本地标签: supabase-login-ui:$VERSION${NC}"
    docker tag $REMOTE_TAG supabase-login-ui:$VERSION
    
    echo -e "${GREEN}镜像已成功拉取: supabase-login-ui:$VERSION${NC}"
}

# 主函数
main() {
    # 检查命令参数
    if [ $# -lt 1 ]; then
        show_help
        exit 1
    fi
    
    COMMAND=$1
    shift
    VERSION=${1:-latest}
    
    case $COMMAND in
        build)
            build_image
            ;;
        buildlatest)
            build_latest
            ;;
        run)
            run_container
            ;;
        export)
            export_image
            ;;
        login)
            login_registry $1
            ;;
        push)
            push_image
            ;;
        pull)
            pull_image
            ;;
        help)
            show_help
            ;;
        *)
            echo -e "${RED}错误: 未知命令 '$COMMAND'${NC}"
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@" 