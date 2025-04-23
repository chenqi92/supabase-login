#!/bin/bash

# 设置错误时退出
set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 无颜色

# 默认值设置
DEFAULT_REGISTRY="docker.io"
DEFAULT_USERNAME="kkape"
DEFAULT_VERSION="latest"
DEFAULT_REPOSITORY="supabase-login-ui"
DEFAULT_PLATFORMS="linux/amd64,linux/arm64"

# 所有可用的平台列表
ALL_PLATFORMS="linux/amd64,linux/arm64,linux/arm/v7,linux/ppc64le,linux/s390x"

# 解析命令参数
COMMAND=$1
VERSION=$2

if [ -z "$VERSION" ]; then
    VERSION="latest"
fi

# 显示帮助信息
show_help() {
    echo -e "${BLUE}Supabase 登录 UI Docker 构建工具${NC}"
    echo "用法: $0 [命令] [版本号]"
    echo ""
    echo "命令:"
    echo "  build [版本号]      构建Docker镜像"
    echo "  buildlatest         构建并标记为latest版本镜像"
    echo "  buildmulti [版本]   构建多架构镜像并推送到仓库(仅支持SWC兼容平台)"
    echo "  buildall [版本]     构建全部架构镜像并推送(包含不兼容平台，较慢)"
    echo "  run [版本号]        运行Docker容器"
    echo "  export [版本号]     导出Docker镜像为tar文件"
    echo "  login [仓库地址]    登录到Docker镜像仓库"
    echo "  push [版本号]       推送镜像到仓库"
    echo "  pull [版本号]       从仓库拉取镜像"
    echo "  help               显示此帮助信息"
    echo ""
    echo "注意:"
    echo "  - buildmulti 仅构建支持Next.js SWC编译器的平台: amd64, arm64"
    echo "  - buildall 构建所有平台，但对于不支持SWC的平台会使用Babel，构建较慢"
    echo ""
    echo "示例:"
    echo "  $0 build 1.0.0     构建版本1.0.0的镜像"
    echo "  $0 buildlatest   构建并标记为latest版本镜像"
    echo "  $0 buildmulti 1.0.0 构建多架构镜像并推送(仅amd64, arm64)"
    echo "  $0 buildall 1.0.0  构建全部架构镜像并推送"
    echo "  $0 run 1.0.0       运行版本1.0.0的容器"
    echo "  $0 export 1.0.0    导出版本1.0.0的镜像"
    echo "  $0 login docker.io  登录到Docker Hub官方仓库"
    echo "  $0 push 1.0.0       推送1.0.0版本镜像到仓库"
    echo "  $0 pull 1.0.0       从仓库拉取1.0.0版本镜像"
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
DOCKER_REGISTRY=$DEFAULT_REGISTRY
DOCKER_NAMESPACE=$DEFAULT_USERNAME
DOCKER_REPOSITORY=$DEFAULT_REPOSITORY

# 多平台支持
DOCKER_PLATFORMS=$DEFAULT_PLATFORMS

# SWC兼容平台
SWC_COMPATIBLE_PLATFORMS=$DEFAULT_PLATFORMS

# 全部平台(包括SWC不兼容的平台)
ALL_PLATFORMS=$ALL_PLATFORMS
EOF
        echo -e "${GREEN}已创建 .env 文件，请编辑其中的配置再继续${NC}"
        exit 1
    fi
}

# 加载环境变量
load_env() {
    if [ -f .env ]; then
        export $(grep -v '^#' .env | xargs)
    fi
}

# 构建Docker镜像
build_image() {
    echo -e "${BLUE}开始构建 supabase-login-ui:$VERSION 镜像...${NC}"
    check_env_file
    
    # 加载环境变量
    load_env
    
    # 设置默认平台，如果没有设置
    if [ -z "$DOCKER_PLATFORMS" ]; then
        DOCKER_PLATFORMS="$DEFAULT_PLATFORMS"
        echo -e "${YELLOW}警告: 未设置DOCKER_PLATFORMS，使用默认值: ${DOCKER_PLATFORMS}${NC}"
    fi
    
    # 创建buildx构建器（如果不存在）
    echo -e "${BLUE}设置多架构构建环境...${NC}"
    docker buildx create --use --name multiarch-builder 2>/dev/null || true
    
    # 构建镜像
    echo -e "${BLUE}正在构建镜像(仅当前平台)...${NC}"
    echo -e "${YELLOW}注意: 本地构建仅包含当前平台架构${NC}"
    
    # 使用普通 docker build 命令构建单一架构镜像
    docker build \
        --build-arg NEXT_PUBLIC_SUPABASE_URL=$SUPABASE_PUBLIC_URL \
        --build-arg NEXT_PUBLIC_SITE_URL=$SITE_URL \
        --build-arg APP_VERSION=$VERSION \
        --build-arg NEXT_PUBLIC_SUPABASE_ANON_KEY=$ANON_KEY \
        --build-arg NEXT_PUBLIC_AUTH_GITHUB_ENABLED=$GOTRUE_EXTERNAL_GITHUB_ENABLED \
        --build-arg NEXT_PUBLIC_AUTH_GOOGLE_ENABLED=$GOTRUE_EXTERNAL_GOOGLE_ENABLED \
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
    load_env
    
    # 确保APP_VERSION有值
    if [ -z "$APP_VERSION" ]; then
        APP_VERSION="1.0.0"
        echo -e "${YELLOW}警告: APP_VERSION 未设置，使用默认值 ${APP_VERSION}${NC}"
    fi
    
    # 生成带时间戳的版本号
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    CURRENT_VERSION="${APP_VERSION}.${TIMESTAMP}"
    
    # 输出版本信息
    echo -e "${BLUE}使用版本号: ${CURRENT_VERSION}${NC}"
    
    # 创建buildx构建器（如果不存在）
    echo -e "${BLUE}设置多架构构建环境...${NC}"
    docker buildx create --use --name multiarch-builder 2>/dev/null || true
    
    # 构建镜像 - 同时标记为特定版本和latest
    echo -e "${BLUE}正在构建镜像(仅当前平台)...${NC}"
    echo -e "${YELLOW}注意: 本地构建仅包含当前平台架构${NC}"
    
    # 使用普通 docker build 命令构建单一架构镜像
    docker build \
        --build-arg NEXT_PUBLIC_SUPABASE_URL=$SUPABASE_PUBLIC_URL \
        --build-arg NEXT_PUBLIC_SITE_URL=$SITE_URL \
        --build-arg APP_VERSION=$CURRENT_VERSION \
        --build-arg NEXT_PUBLIC_SUPABASE_ANON_KEY=$ANON_KEY \
        --build-arg NEXT_PUBLIC_AUTH_GITHUB_ENABLED=$GOTRUE_EXTERNAL_GITHUB_ENABLED \
        --build-arg NEXT_PUBLIC_AUTH_GOOGLE_ENABLED=$GOTRUE_EXTERNAL_GOOGLE_ENABLED \
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
        
        echo -e "${BLUE}是否要推送多架构镜像到仓库? [y/N]${NC}"
        read -r push_answer
        if [[ "$push_answer" =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}正在推送多架构镜像...${NC}"
            # 重新构建并直接推送到仓库
            docker buildx build \
                --platform linux/amd64,linux/arm64,linux/arm/v7,linux/ppc64le,linux/s390x \
                --build-arg NEXT_PUBLIC_SUPABASE_URL=$SUPABASE_PUBLIC_URL \
                --build-arg NEXT_PUBLIC_SITE_URL=$SITE_URL \
                --build-arg APP_VERSION=$CURRENT_VERSION \
                --build-arg NEXT_PUBLIC_SUPABASE_ANON_KEY=$ANON_KEY \
                --build-arg NEXT_PUBLIC_AUTH_GITHUB_ENABLED=$GOTRUE_EXTERNAL_GITHUB_ENABLED \
                --build-arg NEXT_PUBLIC_AUTH_GOOGLE_ENABLED=$GOTRUE_EXTERNAL_GOOGLE_ENABLED \
                -t $REMOTE_TAG_SPECIFIC \
                -t $REMOTE_TAG_LATEST \
                --push .
            
            if [ $? -ne 0 ]; then
                echo -e "${RED}多架构镜像推送失败!${NC}"
                exit 1
            fi
            
            echo -e "${GREEN}多架构镜像已成功推送到仓库!${NC}"
        else
            echo -e "${YELLOW}提示: 使用以下命令推送镜像到仓库:${NC}"
            echo -e "${BLUE}docker push $REMOTE_TAG_SPECIFIC${NC}"
            echo -e "${BLUE}docker push $REMOTE_TAG_LATEST${NC}"
        fi
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
    load_env
    
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

# 检查是否已登录Docker
check_docker_login() {
    REGISTRY=${1:-docker.io}
    
    # 检查凭据文件是否存在
    if [ -f ~/.docker/config.json ]; then
        # 如果使用凭据存储，则假定已登录
        if grep -q "credsStore" ~/.docker/config.json; then
            # 尝试获取用户名作为额外验证
            CURRENT_USER=$(docker info 2>/dev/null | grep Username | awk '{print $2}')
            if [ -n "$CURRENT_USER" ]; then
                echo -e "${GREEN}已使用用户 $CURRENT_USER 登录到Docker${NC}"
                return 0
            fi
        fi
        
        # 检查配置文件中是否包含指定的仓库
        if [ "$REGISTRY" = "docker.io" ]; then
            if grep -q "index.docker.io/v1" ~/.docker/config.json; then
                echo -e "${GREEN}已登录到Docker Hub${NC}"
                return 0
            fi
        elif grep -q "$REGISTRY" ~/.docker/config.json; then
            echo -e "${GREEN}已登录到 $REGISTRY${NC}"
            return 0
        fi
    fi
    
    echo -e "${YELLOW}未登录到Docker仓库${NC}"
    return 1
}

# 获取Docker用户名（改进版）
get_docker_username() {
    # 先尝试从docker info获取
    CURRENT_USER=$(docker info 2>/dev/null | grep Username | awk '{print $2}')
    
    # 如果上面的方法获取失败，询问用户输入或使用默认值
    if [ -z "$CURRENT_USER" ]; then
        # 尝试使用环境变量中的用户名
        if [ -n "$DOCKER_USERNAME" ] && [ "$DOCKER_USERNAME" != "your-username" ]; then
            CURRENT_USER="$DOCKER_USERNAME"
            echo -e "${YELLOW}使用环境变量中的用户名: $CURRENT_USER${NC}" >&2
        else
            # 使用默认用户名
            CURRENT_USER="$DEFAULT_USERNAME"
            echo -e "${YELLOW}使用默认用户名: $CURRENT_USER${NC}" >&2
        fi
    fi
    
    echo "$CURRENT_USER"
    return 0
}

# 登录到Docker镜像仓库
login_registry() {
    check_env_file
    
    # 从.env文件加载变量
    load_env
    
    # 如果提供了仓库地址参数，则使用参数值
    REGISTRY=${1:-${DOCKER_REGISTRY:-$DEFAULT_REGISTRY}}
    
    if [ -z "$REGISTRY" ]; then
        echo -e "${YELLOW}未指定仓库地址，将使用默认的Docker Hub${NC}"
        REGISTRY="docker.io"
    fi
    
    # 检查是否已登录
    if check_docker_login $REGISTRY; then
        return 0
    fi
    
    echo -e "${BLUE}正在登录到Docker镜像仓库: $REGISTRY${NC}"
    echo -e "${YELLOW}请输入Docker Hub用户名和密码${NC}"
    
    # 始终使用交互式登录，不使用环境变量中的凭据
    docker login $REGISTRY
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}登录失败!${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}登录成功${NC}"
}

# 推送镜像到仓库
push_image() {
    check_env_file
    
    # 加载环境变量
    load_env
    
    # 检查必要的环境变量
    if [ -z "$DOCKER_REPOSITORY" ]; then
        echo -e "${YELLOW}未设置DOCKER_REPOSITORY，将使用默认值: $DEFAULT_REPOSITORY${NC}"
        DOCKER_REPOSITORY="$DEFAULT_REPOSITORY"
    fi
    
    # 检查镜像是否存在
    if ! docker images | grep "supabase-login-ui" | grep "$VERSION" > /dev/null; then
        echo -e "${RED}错误: 镜像 supabase-login-ui:$VERSION 不存在，请先构建镜像${NC}"
        exit 1
    fi
    
    # 确保已登录
    REGISTRY=${DOCKER_REGISTRY:-docker.io}
    login_registry $REGISTRY
    
    # 获取当前登录的Docker用户名
    CURRENT_USER=$(get_docker_username)
    if [ $? -ne 0 ]; then
        exit 1
    fi
    
    echo -e "${BLUE}准备推送镜像，使用用户: $CURRENT_USER${NC}"
    
    # 使用Docker Hub的命名格式
    if [ "$REGISTRY" = "docker.io" ]; then
        REMOTE_TAG="$CURRENT_USER/$DOCKER_REPOSITORY:$VERSION"
    else
        REMOTE_TAG="$REGISTRY/$DOCKER_NAMESPACE/$DOCKER_REPOSITORY:$VERSION"
    fi
    
    # 确认要推送的镜像
    echo -e "${YELLOW}确认要推送多架构镜像吗? ${NC}"
    echo -e "  本地镜像: ${GREEN}supabase-login-ui:$VERSION${NC}"
    echo -e "  远程镜像: ${GREEN}$REMOTE_TAG${NC}"
    echo -e "${YELLOW}是否继续? [Y/n]${NC}"
    read -r confirm
    
    if [[ "$confirm" =~ ^[Nn]$ ]]; then
        echo -e "${YELLOW}已取消推送操作${NC}"
        return 0
    fi
    
    echo -e "${BLUE}正在重新构建并推送多架构镜像到仓库...${NC}"
    # 创建buildx构建器（如果不存在）
    docker buildx create --use --name multiarch-builder 2>/dev/null || true
    
    # 直接构建并推送
    docker buildx build \
        --platform linux/amd64,linux/arm64,linux/arm/v7,linux/ppc64le,linux/s390x \
        --build-arg NEXT_PUBLIC_SUPABASE_URL=$SUPABASE_PUBLIC_URL \
        --build-arg NEXT_PUBLIC_SITE_URL=$SITE_URL \
        --build-arg APP_VERSION=$VERSION \
        --build-arg NEXT_PUBLIC_SUPABASE_ANON_KEY=$ANON_KEY \
        --build-arg NEXT_PUBLIC_AUTH_GITHUB_ENABLED=$GOTRUE_EXTERNAL_GITHUB_ENABLED \
        --build-arg NEXT_PUBLIC_AUTH_GOOGLE_ENABLED=$GOTRUE_EXTERNAL_GOOGLE_ENABLED \
        -t $REMOTE_TAG \
        --push .
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}推送失败! 可能的原因:${NC}"
        echo -e "  1. ${YELLOW}您没有权限推送到 $REMOTE_TAG${NC}"
        echo -e "  2. ${YELLOW}仓库 $CURRENT_USER/$DOCKER_REPOSITORY 不存在，请先在Docker Hub创建${NC}"
        echo -e "  3. ${YELLOW}网络连接问题${NC}"
        echo -e "  4. ${YELLOW}Docker Hub账号凭据已过期${NC}"
        
        echo -e "${BLUE}解决方案:${NC}"
        echo -e "  - 在Docker Hub创建仓库: $DOCKER_REPOSITORY"
        echo -e "  - 重新登录Docker: docker login"
        echo -e "  - 检查网络连接"
        exit 1
    fi
    
    echo -e "${GREEN}成功推送多架构镜像: $REMOTE_TAG${NC}"
    
    # 如果版本是latest，同时也推送特定版本
    if [ "$VERSION" = "latest" ]; then
        TIMESTAMP=$(date +%Y%m%d-%H%M%S)
        CURRENT_VERSION="${APP_VERSION}.${TIMESTAMP}"
        
        if [ "$REGISTRY" = "docker.io" ]; then
            REMOTE_TAG_SPECIFIC="$CURRENT_USER/$DOCKER_REPOSITORY:$CURRENT_VERSION"
        else
            REMOTE_TAG_SPECIFIC="$REGISTRY/$DOCKER_NAMESPACE/$DOCKER_REPOSITORY:$CURRENT_VERSION"
        fi
        
        echo -e "${BLUE}同时推送时间戳版本多架构镜像: $REMOTE_TAG_SPECIFIC${NC}"
        
        docker buildx build \
            --platform linux/amd64,linux/arm64,linux/arm/v7,linux/ppc64le,linux/s390x \
            --build-arg NEXT_PUBLIC_SUPABASE_URL=$SUPABASE_PUBLIC_URL \
            --build-arg NEXT_PUBLIC_SITE_URL=$SITE_URL \
            --build-arg APP_VERSION=$CURRENT_VERSION \
            --build-arg NEXT_PUBLIC_SUPABASE_ANON_KEY=$ANON_KEY \
            --build-arg NEXT_PUBLIC_AUTH_GITHUB_ENABLED=$GOTRUE_EXTERNAL_GITHUB_ENABLED \
            --build-arg NEXT_PUBLIC_AUTH_GOOGLE_ENABLED=$GOTRUE_EXTERNAL_GOOGLE_ENABLED \
            -t $REMOTE_TAG_SPECIFIC \
            --push .
        
        if [ $? -ne 0 ]; then
            echo -e "${RED}推送特定版本失败!${NC}"
        else
            echo -e "${GREEN}成功推送时间戳版本多架构镜像: $REMOTE_TAG_SPECIFIC${NC}"
        fi
    fi
    
    echo -e "${GREEN}多架构镜像推送完成!${NC}"
}

# 构建多架构镜像 (仅SWC兼容平台)
build_multiarch() {
    echo -e "${BLUE}开始构建 supabase-login-ui:$VERSION 多架构镜像 (仅SWC兼容平台)...${NC}"
    check_env_file || return 1
    load_env

    # 使用SWC兼容平台列表
    platforms=${SWC_COMPATIBLE_PLATFORMS:-$DEFAULT_PLATFORMS}
    echo -e "${BLUE}使用平台: $platforms${NC}"
    
    # 设置多架构构建环境
    echo -e "${BLUE}设置多架构构建环境...${NC}"
    docker buildx create --name multiarch-builder --use 2>/dev/null || echo "构建器已存在"
    docker buildx inspect --bootstrap

    # 构建镜像
    echo -e "${BLUE}开始多架构构建($platforms)...${NC}"
    
    docker buildx build \
        --platform $platforms \
        --build-arg NEXT_PUBLIC_SUPABASE_URL=${SUPABASE_PUBLIC_URL} \
        --build-arg NEXT_PUBLIC_SUPABASE_ANON_KEY=${ANON_KEY} \
        --build-arg NEXT_PUBLIC_SITE_URL=${SITE_URL} \
        --build-arg NEXT_PUBLIC_AUTH_GITHUB_ENABLED=${GOTRUE_EXTERNAL_GITHUB_ENABLED} \
        --build-arg NEXT_PUBLIC_AUTH_GOOGLE_ENABLED=${GOTRUE_EXTERNAL_GOOGLE_ENABLED} \
        --build-arg APP_VERSION=${VERSION} \
        -t supabase-login-ui:${VERSION} \
        --output "type=image,push=false" .

    if [ $? -ne 0 ]; then
        echo -e "${RED}构建失败!${NC}"
        echo -e "${YELLOW}错误排查建议:${NC}"
        echo "1. 检查Docker buildx是否正确安装"
        echo "2. 尝试使用更少的目标平台架构"
        echo "3. 检查网络连接情况"
        return 1
    fi

    echo -e "${GREEN}多架构镜像构建完成: supabase-login-ui:$VERSION${NC}"
}

# 构建全部架构镜像 (包含SWC不兼容平台)
build_all_arch() {
    echo -e "${BLUE}开始构建 supabase-login-ui:$VERSION 全部架构镜像...${NC}"
    echo -e "${YELLOW}警告: 这将包括不支持Next.js SWC编译器的平台，构建将较慢${NC}"
    check_env_file || return 1
    load_env
    
    # 使用全部平台列表
    platforms=${ALL_PLATFORMS}
    echo -e "${BLUE}使用所有平台: $platforms${NC}"
    
    # 设置多架构构建环境
    echo -e "${BLUE}设置多架构构建环境...${NC}"
    docker buildx create --name multiarch-builder --use 2>/dev/null || echo "构建器已存在"
    docker buildx inspect --bootstrap
    
    # 清理可能的缓存
    docker buildx prune -f
    
    echo -e "${YELLOW}确认要构建所有架构(包括不支持SWC的架构)吗? [Y/n]${NC}"
    read -r confirm
    
    if [[ "$confirm" =~ ^[Nn]$ ]]; then
        echo -e "${YELLOW}已取消构建${NC}"
        return 0
    fi
    
    # 登录到Docker仓库
    if [ -n "$DOCKER_USERNAME" ] && [ -n "$DOCKER_PASSWORD" ]; then
        echo -e "${BLUE}登录到Docker仓库...${NC}"
        echo "$DOCKER_PASSWORD" | docker login "$DOCKER_REGISTRY" -u "$DOCKER_USERNAME" --password-stdin
    else
        echo -e "${YELLOW}未提供Docker登录凭据，如需推送请先登录${NC}"
        docker login "$DOCKER_REGISTRY"
    fi
    
    # 构建并推送
    echo -e "${BLUE}开始构建所有架构...${NC}"
    
    # 构建仓库标签
    if [ -n "$DOCKER_REGISTRY" ] && [ -n "$DOCKER_NAMESPACE" ] && [ -n "$DOCKER_REPOSITORY" ]; then
        REMOTE_TAG_SPECIFIC="${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/${DOCKER_REPOSITORY}:${VERSION}"
        REMOTE_TAG_LATEST="${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/${DOCKER_REPOSITORY}:latest"
    else
        echo -e "${RED}错误: 镜像仓库配置不完整，请检查.env文件${NC}"
        return 1
    fi
    
    docker buildx build \
        --platform $platforms \
        --build-arg NEXT_PUBLIC_SUPABASE_URL=${SUPABASE_PUBLIC_URL} \
        --build-arg NEXT_PUBLIC_SUPABASE_ANON_KEY=${ANON_KEY} \
        --build-arg NEXT_PUBLIC_SITE_URL=${SITE_URL} \
        --build-arg NEXT_PUBLIC_AUTH_GITHUB_ENABLED=${GOTRUE_EXTERNAL_GITHUB_ENABLED} \
        --build-arg NEXT_PUBLIC_AUTH_GOOGLE_ENABLED=${GOTRUE_EXTERNAL_GOOGLE_ENABLED} \
        --build-arg APP_VERSION=${VERSION} \
        -t ${REMOTE_TAG_SPECIFIC} \
        -t ${REMOTE_TAG_LATEST} \
        --push .
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}构建并推送失败!${NC}"
        return 1
    fi
    
    echo -e "${GREEN}全部架构镜像构建并推送完成:${NC}"
    echo -e "${GREEN}- ${REMOTE_TAG_SPECIFIC}${NC}"
    echo -e "${GREEN}- ${REMOTE_TAG_LATEST}${NC}"
}

# 构建并推送多架构镜像 (仅SWC兼容平台)
build_and_push_multiarch() {
    echo -e "${BLUE}开始构建并推送多架构镜像 (仅SWC兼容平台)...${NC}"
    check_env_file || return 1
    load_env
    
    # 确保版本号正确
    CURRENT_VERSION=${VERSION}
    if [ "$CURRENT_VERSION" == "latest" ]; then
        if [ -n "$APP_VERSION" ]; then
            CURRENT_VERSION="$APP_VERSION"
        else
            CURRENT_VERSION="1.0.0"
        fi
        echo -e "${YELLOW}使用版本号: $CURRENT_VERSION${NC}"
    fi
    
    # 设置镜像标签
    if [ -n "$DOCKER_REGISTRY" ] && [ -n "$DOCKER_NAMESPACE" ] && [ -n "$DOCKER_REPOSITORY" ]; then
        REMOTE_TAG_SPECIFIC="${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/${DOCKER_REPOSITORY}:${CURRENT_VERSION}"
        REMOTE_TAG_LATEST="${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/${DOCKER_REPOSITORY}:latest"
    else
        echo -e "${RED}错误: 镜像仓库配置不完整，请检查.env文件${NC}"
        return 1
    fi
    
    # 设置多架构构建环境
    echo -e "${BLUE}设置多架构构建环境...${NC}"
    docker buildx create --name multiarch-builder --use 2>/dev/null || echo "构建器已存在"
    docker buildx inspect --bootstrap
    
    # 清理可能的缓存
    docker buildx prune -f
    
    # 使用SWC兼容平台列表
    platforms=${SWC_COMPATIBLE_PLATFORMS:-$DEFAULT_PLATFORMS}
    echo -e "${BLUE}使用SWC兼容平台: $platforms${NC}"
    echo -e "${YELLOW}目标仓库: ${REMOTE_TAG_SPECIFIC}${NC}"
    
    # 登录到Docker仓库
    if [ -n "$DOCKER_USERNAME" ] && [ -n "$DOCKER_PASSWORD" ]; then
        echo -e "${BLUE}登录到Docker仓库...${NC}"
        echo "$DOCKER_PASSWORD" | docker login "$DOCKER_REGISTRY" -u "$DOCKER_USERNAME" --password-stdin
    else
        echo -e "${YELLOW}未提供Docker登录凭据，如需推送请先登录${NC}"
        docker login "$DOCKER_REGISTRY"
    fi
    
    # 构建并推送
    docker buildx build \
        --platform $platforms \
        --build-arg NEXT_PUBLIC_SUPABASE_URL=${SUPABASE_PUBLIC_URL} \
        --build-arg NEXT_PUBLIC_SUPABASE_ANON_KEY=${ANON_KEY} \
        --build-arg NEXT_PUBLIC_SITE_URL=${SITE_URL} \
        --build-arg NEXT_PUBLIC_AUTH_GITHUB_ENABLED=${GOTRUE_EXTERNAL_GITHUB_ENABLED} \
        --build-arg NEXT_PUBLIC_AUTH_GOOGLE_ENABLED=${GOTRUE_EXTERNAL_GOOGLE_ENABLED} \
        --build-arg APP_VERSION=${CURRENT_VERSION} \
        -t ${REMOTE_TAG_SPECIFIC} \
        -t ${REMOTE_TAG_LATEST} \
        --push .
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}构建并推送失败!${NC}"
        return 1
    fi
    
    echo -e "${GREEN}多架构镜像构建并推送完成:${NC}"
    echo -e "${GREEN}- ${REMOTE_TAG_SPECIFIC}${NC}"
    echo -e "${GREEN}- ${REMOTE_TAG_LATEST}${NC}"
}

# 从仓库拉取镜像
pull_image() {
    check_env_file
    
    # 加载环境变量
    load_env
    
    # 检查并设置必要的环境变量
    if [ -z "$DOCKER_REGISTRY" ]; then
        echo -e "${YELLOW}未设置DOCKER_REGISTRY，将使用默认值: docker.io${NC}"
        DOCKER_REGISTRY="docker.io"
    fi
    
    if [ -z "$DOCKER_NAMESPACE" ]; then
        # 获取当前登录的Docker用户名
        DOCKER_USERNAME=$(docker info 2>&1 | grep Username | cut -d':' -f2 | tr -d ' ')
        
        if [ -z "$DOCKER_USERNAME" ]; then
            echo -e "${YELLOW}无法自动获取Docker用户名，请手动输入您的Docker Hub用户名:${NC}"
            read DOCKER_USERNAME
        fi
        
        echo -e "${YELLOW}未设置DOCKER_NAMESPACE，将使用当前登录的用户名: $DOCKER_USERNAME${NC}"
        DOCKER_NAMESPACE=$DOCKER_USERNAME
    fi
    
    if [ -z "$DOCKER_REPOSITORY" ]; then
        echo -e "${YELLOW}未设置DOCKER_REPOSITORY，将使用默认值: supabase-login-ui${NC}"
        DOCKER_REPOSITORY="supabase-login-ui"
    fi
    
    # 构建远程镜像标签
    if [ "$DOCKER_REGISTRY" == "docker.io" ]; then
        REMOTE_TAG="${DOCKER_NAMESPACE}/${DOCKER_REPOSITORY}:${VERSION}"
    else
        REMOTE_TAG="${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/${DOCKER_REPOSITORY}:${VERSION}"
    fi
    
    echo -e "${BLUE}正在从仓库拉取镜像: $REMOTE_TAG${NC}"
    echo -e "${BLUE}此操作将自动选择适合当前系统架构的镜像版本${NC}"
    docker pull $REMOTE_TAG
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}拉取失败!${NC}"
        return 1
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
    VERSION=${1:-$DEFAULT_VERSION}
    
    case $COMMAND in
        build)
            build_multiarch
            ;;
        buildlatest)
            VERSION="latest"
            build_multiarch
            ;;
        buildmulti)
            build_and_push_multiarch
            ;;
        buildall)
            build_all_arch
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
            build_and_push_multiarch
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