@echo off
chcp 65001 >nul
:: Set UTF-8 encoding

:: Color definitions
set RED=[91m
set GREEN=[92m
set YELLOW=[93m
set BLUE=[94m
set NC=[0m

:: 默认的平台支持列表
set DEFAULT_PLATFORMS=linux/amd64,linux/arm64,linux/arm/v7,linux/ppc64le,linux/s390x

:: Parse command parameters
set COMMAND=%1
set VERSION=%2

if "%VERSION%"=="" (
    set VERSION=latest
)

:: Display help information
if "%COMMAND%"=="" goto :help
if /i "%COMMAND%"=="help" goto :help

:: Execute corresponding command
if /i "%COMMAND%"=="build" goto :build
if /i "%COMMAND%"=="run" goto :run
if /i "%COMMAND%"=="export" goto :export
if /i "%COMMAND%"=="login" goto :login
if /i "%COMMAND%"=="push" goto :push
if /i "%COMMAND%"=="pull" goto :pull
if /i "%COMMAND%"=="buildlatest" goto :buildlatest
if /i "%COMMAND%"=="buildmulti" goto :buildmulti

echo %RED%Error: Unknown command '%COMMAND%'%NC%
goto :help

:help
echo %BLUE%Supabase 登录 UI Docker 构建工具%NC%
echo 用法: %0 [命令] [版本号]
echo.
echo 命令:
echo   build [版本号]    构建Docker镜像
echo   buildlatest       构建并标记为latest版本镜像
echo   buildmulti [版本] 构建多架构镜像并推送到仓库(适用于所有平台)
echo   run [版本号]      运行Docker容器
echo   export [版本号]   导出Docker镜像为tar文件
echo   login [仓库地址]  登录到Docker镜像仓库
echo   push [版本号]     推送镜像到仓库
echo   pull [版本号]     从仓库拉取镜像
echo   help             显示此帮助信息
echo.
echo 示例:
echo   %0 build 1.0.0   构建版本1.0.0的镜像
echo   %0 buildlatest   构建并标记为latest版本镜像
echo   %0 buildmulti    构建多架构镜像并推送(适用于所有平台)
echo   %0 run 1.0.0     运行版本1.0.0的容器
echo   %0 export 1.0.0  导出版本1.0.0的镜像
echo   %0 login docker.io  登录到Docker Hub官方仓库
echo   %0 push 1.0.0    推送1.0.0版本镜像到仓库
echo   %0 pull 1.0.0    从仓库拉取1.0.0版本镜像
echo.
goto :eof

:check_env_file
if not exist .env (
    echo %YELLOW%警告: .env 文件不存在，将创建示例环境变量文件%NC%
    (
        echo # Supabase 配置
        echo SUPABASE_PUBLIC_URL=https://database.allbs.cn
        echo ANON_KEY=your_anon_key
        echo SITE_URL=https://login.allbs.cn
        echo.
        echo # OAuth配置
        echo GOTRUE_EXTERNAL_GITHUB_ENABLED=true
        echo GOTRUE_EXTERNAL_GOOGLE_ENABLED=true
        echo.
        echo # 版本控制
        echo APP_VERSION=%VERSION%
        echo.
        echo # Docker镜像仓库配置
        echo DOCKER_REGISTRY=registry.cn-hangzhou.aliyuncs.com
        echo DOCKER_NAMESPACE=your-namespace
        echo DOCKER_REPOSITORY=supabase-login-ui
        echo DOCKER_USERNAME=your-username
        echo DOCKER_PASSWORD=your-password
        echo.
        echo # 多平台支持
        echo DOCKER_PLATFORMS=%DEFAULT_PLATFORMS%
    ) > .env
    echo %GREEN%已创建 .env 文件，请编辑其中的配置再继续%NC%
    exit /b 1
)
exit /b 0

:build
echo %BLUE%开始构建 supabase-login-ui:%VERSION% 镜像...%NC%
call :check_env_file
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:: 从.env文件加载变量
for /f "tokens=1,* delims==" %%a in (.env) do (
    if not "%%a"=="" (
        if not "%%a:~0,1%"=="#" (
            set "%%a=%%b"
        )
    )
)

:: 创建buildx构建器（如果不存在）
echo %BLUE%设置多架构构建环境...%NC%
docker buildx create --use --name multiarch-builder 2>nul || echo 构建器已存在

:: 构建镜像
echo %BLUE%开始多架构构建(linux/amd64,linux/arm64,linux/arm/v7,linux/ppc64le,linux/s390x)...%NC%
docker buildx build ^
    --platform linux/amd64,linux/arm64,linux/arm/v7,linux/ppc64le,linux/s390x ^
    --build-arg NEXT_PUBLIC_SUPABASE_URL=%SUPABASE_PUBLIC_URL% ^
    --build-arg NEXT_PUBLIC_SUPABASE_ANON_KEY=%ANON_KEY% ^
    --build-arg SUPABASE_SERVICE_ROLE_KEY=%SERVICE_ROLE_KEY% ^
    --build-arg NEXT_PUBLIC_SITE_URL=%SITE_URL% ^
    --build-arg NEXT_PUBLIC_AUTH_GITHUB_ENABLED=%GOTRUE_EXTERNAL_GITHUB_ENABLED% ^
    --build-arg NEXT_PUBLIC_AUTH_GOOGLE_ENABLED=%GOTRUE_EXTERNAL_GOOGLE_ENABLED% ^
    --build-arg APP_VERSION=%VERSION% ^
    -t supabase-login-ui:%VERSION% ^
    --load .

if %ERRORLEVEL% neq 0 (
    echo %RED%构建失败!%NC%
    exit /b 1
)

echo %GREEN%多架构镜像构建完成: supabase-login-ui:%VERSION%%NC%
goto :eof

:buildlatest
echo %BLUE%开始构建 latest 版本镜像...%NC%
call :check_env_file
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:: 从.env文件加载变量
for /f "tokens=1,* delims==" %%a in (.env) do (
    if not "%%a"=="" (
        if not "%%a:~0,1%"=="#" (
            set "%%a=%%b"
        )
    )
)

:: 确保APP_VERSION有值
if "%APP_VERSION%"=="" (
    set "APP_VERSION=1.0.0"
)

:: 获取当前日期时间作为版本号
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "TIMESTAMP=%dt:~0,8%-%dt:~8,6%"
set "CURRENT_VERSION=%APP_VERSION%.%TIMESTAMP%"

:: 检查版本号是否有效
echo %BLUE%使用版本号: %CURRENT_VERSION%%NC%

:: 创建buildx构建器（如果不存在）
echo %BLUE%设置多架构构建环境...%NC%
docker buildx create --use --name multiarch-builder 2>nul || echo 构建器已存在

:: 构建镜像 - 同时标记为特定版本和latest
echo %BLUE%正在构建镜像(仅当前平台)...%NC%
echo %YELLOW%注意: 本地构建仅包含当前平台架构%NC%

:: 使用普通 docker build 命令构建单一架构镜像
docker build ^
    --build-arg NEXT_PUBLIC_SUPABASE_URL=%SUPABASE_PUBLIC_URL% ^
    --build-arg NEXT_PUBLIC_SUPABASE_ANON_KEY=%ANON_KEY% ^
    --build-arg SUPABASE_SERVICE_ROLE_KEY=%SERVICE_ROLE_KEY% ^
    --build-arg NEXT_PUBLIC_SITE_URL=%SITE_URL% ^
    --build-arg NEXT_PUBLIC_AUTH_GITHUB_ENABLED=%GOTRUE_EXTERNAL_GITHUB_ENABLED% ^
    --build-arg NEXT_PUBLIC_AUTH_GOOGLE_ENABLED=%GOTRUE_EXTERNAL_GOOGLE_ENABLED% ^
    --build-arg APP_VERSION=%CURRENT_VERSION% ^
    -t supabase-login-ui:%CURRENT_VERSION% ^
    -t supabase-login-ui:latest .

if %ERRORLEVEL% neq 0 (
    echo %RED%构建失败!%NC%
    exit /b 1
)

:: 如果配置了仓库信息，同时标记为远程镜像
if defined DOCKER_REGISTRY if defined DOCKER_NAMESPACE if defined DOCKER_REPOSITORY (
    set REMOTE_TAG_SPECIFIC=%DOCKER_REGISTRY%/%DOCKER_NAMESPACE%/%DOCKER_REPOSITORY%:%CURRENT_VERSION%
    set REMOTE_TAG_LATEST=%DOCKER_REGISTRY%/%DOCKER_NAMESPACE%/%DOCKER_REPOSITORY%:latest
    
    echo %BLUE%正在标记远程镜像...%NC%
    docker tag supabase-login-ui:%CURRENT_VERSION% %REMOTE_TAG_SPECIFIC%
    docker tag supabase-login-ui:latest %REMOTE_TAG_LATEST%
    
    echo %GREEN%已标记远程镜像: %NC%
    echo %GREEN%- %REMOTE_TAG_SPECIFIC%%NC%
    echo %GREEN%- %REMOTE_TAG_LATEST%%NC%
    
    echo %YELLOW%是否要推送多架构镜像到仓库? [y/N]%NC%
    set /p push_answer=
    if /i "%push_answer%"=="y" (
        echo %BLUE%正在推送多架构镜像...%NC%
        :: 重新构建并直接推送到仓库
        docker buildx build ^
            --platform linux/amd64,linux/arm64,linux/arm/v7,linux/ppc64le,linux/s390x ^
            --build-arg NEXT_PUBLIC_SUPABASE_URL=%SUPABASE_PUBLIC_URL% ^
            --build-arg NEXT_PUBLIC_SUPABASE_ANON_KEY=%ANON_KEY% ^
            --build-arg SUPABASE_SERVICE_ROLE_KEY=%SERVICE_ROLE_KEY% ^
            --build-arg NEXT_PUBLIC_SITE_URL=%SITE_URL% ^
            --build-arg NEXT_PUBLIC_AUTH_GITHUB_ENABLED=%GOTRUE_EXTERNAL_GITHUB_ENABLED% ^
            --build-arg NEXT_PUBLIC_AUTH_GOOGLE_ENABLED=%GOTRUE_EXTERNAL_GOOGLE_ENABLED% ^
            --build-arg APP_VERSION=%CURRENT_VERSION% ^
            -t %REMOTE_TAG_SPECIFIC% ^
            -t %REMOTE_TAG_LATEST% ^
            --push .
        
        if %ERRORLEVEL% neq 0 (
            echo %RED%多架构镜像推送失败!%NC%
            exit /b 1
        )
        
        echo %GREEN%多架构镜像已成功推送到仓库!%NC%
    ) else (
        echo %YELLOW%提示: 使用以下命令推送镜像到仓库:%NC%
        echo %BLUE%docker push %REMOTE_TAG_SPECIFIC%%NC%
        echo %BLUE%docker push %REMOTE_TAG_LATEST%%NC%
    )
)

echo %GREEN%镜像构建完成: %NC%
echo %GREEN%- supabase-login-ui:%CURRENT_VERSION%%NC%
echo %GREEN%- supabase-login-ui:latest%NC%
goto :eof

:run
echo %BLUE%开始运行 supabase-login-ui:%VERSION% 容器...%NC%
call :check_env_file
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:: 从.env文件加载变量
for /f "tokens=1,* delims==" %%a in (.env) do (
    if not "%%a"=="" (
        if not "%%a:~0,1%"=="#" (
            set "%%a=%%b"
        )
    )
)

:: 检查端口变量，如果未设置则使用默认值3000
if "%PORT%"=="" set PORT=3000

:: 停止并移除已存在的容器
docker ps -a | findstr "supabase-login-ui" >nul
if %ERRORLEVEL% equ 0 (
    echo %YELLOW%发现已存在的容器，正在停止并移除...%NC%
    docker stop supabase-login-ui 2>nul || echo 容器未运行
    docker rm supabase-login-ui 2>nul || echo 容器不存在
)

:: 检查网络是否存在
docker network ls | findstr "supabase-network" >nul
if %ERRORLEVEL% neq 0 (
    echo 创建 Docker 网络: supabase-network
    docker network create supabase-network
)

:: 运行容器
echo %BLUE%启动容器...%NC%
docker run -d ^
    --name supabase-login-ui ^
    --restart always ^
    --network supabase-network ^
    -p %PORT%:3000 ^
    -e NEXT_PUBLIC_SUPABASE_URL=%SUPABASE_PUBLIC_URL% ^
    -e NEXT_PUBLIC_SUPABASE_ANON_KEY=%ANON_KEY% ^
    -e NEXT_PUBLIC_SITE_URL=%SITE_URL% ^
    -e NEXT_PUBLIC_AUTH_GITHUB_ENABLED=%GOTRUE_EXTERNAL_GITHUB_ENABLED% ^
    -e NEXT_PUBLIC_AUTH_GOOGLE_ENABLED=%GOTRUE_EXTERNAL_GOOGLE_ENABLED% ^
    -e APP_VERSION=%VERSION% ^
    -v %cd%\logs:/app/logs ^
    supabase-login-ui:%VERSION%

if %ERRORLEVEL% neq 0 (
    echo %RED%容器启动失败!%NC%
    exit /b 1
)

echo %GREEN%容器已启动: supabase-login-ui%NC%
echo 访问地址: %BLUE%http://localhost:%PORT%%NC%
goto :eof

:export
echo %BLUE%开始导出 supabase-login-ui:%VERSION% 镜像...%NC%

:: 检查镜像是否存在
docker images | findstr "supabase-login-ui" | findstr "%VERSION%" >nul
if %ERRORLEVEL% neq 0 (
    echo %RED%错误: 镜像 supabase-login-ui:%VERSION% 不存在，请先构建镜像%NC%
    exit /b 1
)

:: 创建导出目录
set EXPORT_DIR=docker-exports
if not exist %EXPORT_DIR% mkdir %EXPORT_DIR%

:: 导出镜像
set EXPORT_FILE=%EXPORT_DIR%\supabase-login-ui-%VERSION%.tar
echo %BLUE%正在导出到 %EXPORT_FILE% ...%NC%
docker save supabase-login-ui:%VERSION% -o %EXPORT_FILE%

if %ERRORLEVEL% neq 0 (
    echo %RED%导出失败!%NC%
    exit /b 1
)

echo %GREEN%镜像已成功导出: %EXPORT_FILE%%NC%
echo %YELLOW%提示: 在目标服务器上使用以下命令加载镜像:%NC%
echo %BLUE%docker load -i %EXPORT_FILE%%NC%
goto :eof

:login
call :check_env_file
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:: 从.env文件加载变量
for /f "tokens=1,* delims==" %%a in (.env) do (
    if not "%%a"=="" (
        if not "%%a:~0,1%"=="#" (
            set "%%a=%%b"
        )
    )
)

:: 如果提供了仓库地址参数，则使用参数值
set REGISTRY=%2
if "%REGISTRY%"=="" set REGISTRY=%DOCKER_REGISTRY%

if "%REGISTRY%"=="" (
    echo %YELLOW%未指定仓库地址，将使用默认的Docker Hub%NC%
    set REGISTRY=docker.io
)

echo %BLUE%正在登录到Docker镜像仓库: %REGISTRY%%NC%

:: 检查凭据是否在环境变量中存在
if defined DOCKER_USERNAME if defined DOCKER_PASSWORD (
    echo %BLUE%使用环境变量中的凭据登录%NC%
    echo %DOCKER_PASSWORD% | docker login %REGISTRY% -u "%DOCKER_USERNAME%" --password-stdin
) else (
    echo %YELLOW%环境变量中未找到Docker凭据，将进入交互式登录%NC%
    docker login %REGISTRY%
)

if %ERRORLEVEL% neq 0 (
    echo %RED%登录失败!%NC%
    exit /b 1
)

echo %GREEN%登录成功%NC%
goto :eof

:push
call :check_env_file
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:: 从.env文件加载变量
for /f "tokens=1,* delims==" %%a in (.env) do (
    if not "%%a"=="" (
        if not "%%a:~0,1%"=="#" (
            set "%%a=%%b"
        )
    )
)

:: 检查必要的环境变量
if "%DOCKER_REGISTRY%"=="" goto :missing_registry_config
if "%DOCKER_NAMESPACE%"=="" goto :missing_registry_config
if "%DOCKER_REPOSITORY%"=="" goto :missing_registry_config

:: 检查镜像是否存在
docker images | findstr "supabase-login-ui" | findstr "%VERSION%" >nul
if %ERRORLEVEL% neq 0 (
    echo %RED%错误: 镜像 supabase-login-ui:%VERSION% 不存在，请先构建镜像%NC%
    exit /b 1
)

:: 构建远程镜像标签
set REMOTE_TAG=%DOCKER_REGISTRY%/%DOCKER_NAMESPACE%/%DOCKER_REPOSITORY%:%VERSION%

echo %YELLOW%确认要推送多架构镜像吗? [Y/n]%NC%
set /p confirm=

if /i "%confirm%"=="n" (
    echo %YELLOW%已取消推送操作%NC%
    goto :eof
)

:: 创建buildx构建器（如果不存在）
echo %BLUE%设置多架构构建环境...%NC%
docker buildx create --use --name multiarch-builder 2>nul || echo 构建器已存在

echo %BLUE%正在重新构建并推送多架构镜像到仓库...%NC%
docker buildx build ^
    --platform linux/amd64,linux/arm64,linux/arm/v7,linux/ppc64le,linux/s390x ^
    --build-arg NEXT_PUBLIC_SUPABASE_URL=%SUPABASE_PUBLIC_URL% ^
    --build-arg NEXT_PUBLIC_SUPABASE_ANON_KEY=%ANON_KEY% ^
    --build-arg SUPABASE_SERVICE_ROLE_KEY=%SERVICE_ROLE_KEY% ^
    --build-arg NEXT_PUBLIC_SITE_URL=%SITE_URL% ^
    --build-arg NEXT_PUBLIC_AUTH_GITHUB_ENABLED=%GOTRUE_EXTERNAL_GITHUB_ENABLED% ^
    --build-arg NEXT_PUBLIC_AUTH_GOOGLE_ENABLED=%GOTRUE_EXTERNAL_GOOGLE_ENABLED% ^
    --build-arg APP_VERSION=%VERSION% ^
    -t %REMOTE_TAG% ^
    --push .

if %ERRORLEVEL% neq 0 (
    echo %RED%推送失败!%NC%
    exit /b 1
)

:: 如果版本是latest，同时也推送特定版本
if "%VERSION%"=="latest" (
    for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
    set "TIMESTAMP=%dt:~0,8%-%dt:~8,6%"
    set "CURRENT_VERSION=%APP_VERSION%.%TIMESTAMP%"
    set REMOTE_TAG_SPECIFIC=%DOCKER_REGISTRY%/%DOCKER_NAMESPACE%/%DOCKER_REPOSITORY%:%CURRENT_VERSION%
    
    echo %BLUE%同时推送时间戳版本多架构镜像: %REMOTE_TAG_SPECIFIC%%NC%
    docker buildx build ^
        --platform linux/amd64,linux/arm64,linux/arm/v7,linux/ppc64le,linux/s390x ^
        --build-arg NEXT_PUBLIC_SUPABASE_URL=%SUPABASE_PUBLIC_URL% ^
        --build-arg NEXT_PUBLIC_SUPABASE_ANON_KEY=%ANON_KEY% ^
        --build-arg SUPABASE_SERVICE_ROLE_KEY=%SERVICE_ROLE_KEY% ^
        --build-arg NEXT_PUBLIC_SITE_URL=%SITE_URL% ^
        --build-arg NEXT_PUBLIC_AUTH_GITHUB_ENABLED=%GOTRUE_EXTERNAL_GITHUB_ENABLED% ^
        --build-arg NEXT_PUBLIC_AUTH_GOOGLE_ENABLED=%GOTRUE_EXTERNAL_GOOGLE_ENABLED% ^
        --build-arg APP_VERSION=%CURRENT_VERSION% ^
        -t %REMOTE_TAG_SPECIFIC% ^
        --push .
)

echo %GREEN%多架构镜像推送完成!%NC%
goto :eof

:pull
call :check_env_file
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:: 从.env文件加载变量
for /f "tokens=1,* delims==" %%a in (.env) do (
    if not "%%a"=="" (
        if not "%%a:~0,1%"=="#" (
            set "%%a=%%b"
        )
    )
)

:: 检查并设置必要的环境变量
:: Docker仓库地址
if "%DOCKER_REGISTRY%"=="" (
    echo %YELLOW%未设置DOCKER_REGISTRY，将使用默认值: docker.io%NC%
    set "DOCKER_REGISTRY=docker.io"
)

:: 获取当前登录的Docker用户名作为命名空间
if "%DOCKER_NAMESPACE%"=="" (
    for /f "tokens=*" %%a in ('docker info 2^>^&1 ^| findstr Username') do (
        set "DOCKER_USERNAME=%%a"
    )
    set "DOCKER_USERNAME=%DOCKER_USERNAME:*: =%"
    
    if "%DOCKER_USERNAME%"=="" (
        echo %YELLOW%无法自动获取Docker用户名，请手动输入您的Docker Hub用户名:%NC%
        set /p DOCKER_USERNAME=
    )
    
    echo %YELLOW%未设置DOCKER_NAMESPACE，将使用当前登录的用户名: %DOCKER_USERNAME%%NC%
    set "DOCKER_NAMESPACE=%DOCKER_USERNAME%"
)

:: 设置仓库名称
if "%DOCKER_REPOSITORY%"=="" (
    echo %YELLOW%未设置DOCKER_REPOSITORY，将使用默认值: supabase-login-ui%NC%
    set "DOCKER_REPOSITORY=supabase-login-ui"
)

:: 构建远程镜像标签
if "%DOCKER_REGISTRY%"=="docker.io" (
    set "REMOTE_TAG=%DOCKER_NAMESPACE%/%DOCKER_REPOSITORY%:%VERSION%"
) else (
    set "REMOTE_TAG=%DOCKER_REGISTRY%/%DOCKER_NAMESPACE%/%DOCKER_REPOSITORY%:%VERSION%"
)

echo %BLUE%正在从仓库拉取镜像: %REMOTE_TAG%%NC%
echo %BLUE%此操作将自动选择适合当前系统架构的镜像版本%NC%
docker pull %REMOTE_TAG%

if %ERRORLEVEL% neq 0 (
    echo %RED%拉取失败!%NC%
    exit /b 1
)

echo %BLUE%正在标记镜像为本地标签: supabase-login-ui:%VERSION%%NC%
docker tag %REMOTE_TAG% supabase-login-ui:%VERSION%

echo %GREEN%镜像已成功拉取: supabase-login-ui:%VERSION%%NC%
goto :eof

:missing_registry_config
echo %RED%错误: 缺少镜像仓库配置，请检查.env文件%NC%
echo %YELLOW%需要设置: DOCKER_REGISTRY, DOCKER_NAMESPACE, DOCKER_REPOSITORY%NC%
exit /b 1

:buildmulti
echo %BLUE%Starting to build and push multi-architecture images...%NC%
call :check_env_file
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:: Load variables from .env file
for /f "tokens=1,* delims==" %%a in (.env) do (
    if not "%%a"=="" (
        if not "%%a:~0,1%"=="#" (
            set "%%a=%%b"
        )
    )
)

:: 获取平台配置，如果没有则使用默认值
if "%DOCKER_PLATFORMS%"=="" (
    set "DOCKER_PLATFORMS=%DEFAULT_PLATFORMS%"
    echo %YELLOW%警告: 未设置DOCKER_PLATFORMS，使用默认值: %DOCKER_PLATFORMS%%NC%
)

:: Set version increment
if "%APP_VERSION%"=="" (
    :: Default to next version 1.0.3, as user indicated current cloud version is 1.0.2
    echo %BLUE%Checking cloud version...%NC%
    set "CURRENT_VERSION=1.0.3"
    echo %YELLOW%APP_VERSION not set, using incremented version: %CURRENT_VERSION%%NC%
) else (
    :: Parse current version number
    for /f "tokens=1,2,3 delims=." %%a in ("%APP_VERSION%") do (
        set "MAJOR=%%a"
        set "MINOR=%%b"
        set "PATCH=%%c"
    )
    
    :: If PATCH is empty, set to 0
    if "%PATCH%"=="" set "PATCH=0"
    
    :: Increment patch number
    set /a PATCH=%PATCH%+1
    set "CURRENT_VERSION=%MAJOR%.%MINOR%.%PATCH%"
    echo %BLUE%Version increment: %APP_VERSION% -^> %CURRENT_VERSION%%NC%
)

:: Set default repository to docker.io
if "%DOCKER_REGISTRY%"=="" (
    echo %YELLOW%DOCKER_REGISTRY not set, using default: docker.io%NC%
    set "DOCKER_REGISTRY=docker.io"
)

:: Check if already logged in to Docker
echo %BLUE%Checking Docker login status...%NC%
docker info 2>&1 | findstr /C:"Username:" > nul
set "DOCKER_LOGGED_IN=%ERRORLEVEL%"

if %DOCKER_LOGGED_IN% == 0 (
    echo %GREEN%Docker login detected%NC%
    
    :: Get current logged-in Docker username
    for /f "tokens=*" %%a in ('docker info 2^>^&1 ^| findstr Username') do (
        set "DOCKER_USERNAME=%%a"
    )
    set "DOCKER_USERNAME=%DOCKER_USERNAME:*: =%"
    echo %GREEN%Currently logged in as: %DOCKER_USERNAME%%NC%
    
    :: If namespace not set, use current logged-in username
    if "%DOCKER_NAMESPACE%"=="" (
        set "DOCKER_NAMESPACE=%DOCKER_USERNAME%"
        echo %YELLOW%Using current username as namespace: %DOCKER_NAMESPACE%%NC%
    )
) else (
    echo %YELLOW%No Docker login detected, logging in...%NC%
    call :login
    if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%
    
    :: Get username after login
    for /f "tokens=*" %%a in ('docker info 2^>^&1 ^| findstr Username') do (
        set "DOCKER_USERNAME=%%a"
    )
    set "DOCKER_USERNAME=%DOCKER_USERNAME:*: =%"
    
    :: If namespace not set, and login successful and username obtained
    if "%DOCKER_NAMESPACE%"=="" if not "%DOCKER_USERNAME%"=="" (
        set "DOCKER_NAMESPACE=%DOCKER_USERNAME%"
        echo %YELLOW%Using current username as namespace: %DOCKER_NAMESPACE%%NC%
    )
)

:: Check if namespace is set
if "%DOCKER_NAMESPACE%"=="" (
    echo %YELLOW%Namespace not set, please enter Docker Hub username:%NC%
    set /p DOCKER_NAMESPACE=
)

:: Validate namespace is not empty
if "%DOCKER_NAMESPACE%"=="" (
    echo %RED%Error: Must provide namespace or username%NC%
    exit /b 1
)

:: Clean invalid characters from namespace
set "DOCKER_NAMESPACE=%DOCKER_NAMESPACE:/=%"
set "DOCKER_NAMESPACE=%DOCKER_NAMESPACE:\=%"
set "DOCKER_NAMESPACE=%DOCKER_NAMESPACE:~=%"
set "DOCKER_NAMESPACE=%DOCKER_NAMESPACE:==%"

:: Set repository name
if "%DOCKER_REPOSITORY%"=="" (
    echo %YELLOW%DOCKER_REPOSITORY not set, using default: supabase-login-ui%NC%
    set "DOCKER_REPOSITORY=supabase-login-ui"
)

:: Build image tags
if "%DOCKER_REGISTRY%"=="docker.io" (
    set "REMOTE_TAG_SPECIFIC=%DOCKER_NAMESPACE%/%DOCKER_REPOSITORY%:%CURRENT_VERSION%"
    set "REMOTE_TAG_LATEST=%DOCKER_NAMESPACE%/%DOCKER_REPOSITORY%:latest"
) else (
    set "REMOTE_TAG_SPECIFIC=%DOCKER_REGISTRY%/%DOCKER_NAMESPACE%/%DOCKER_REPOSITORY%:%CURRENT_VERSION%"
    set "REMOTE_TAG_LATEST=%DOCKER_REGISTRY%/%DOCKER_NAMESPACE%/%DOCKER_REPOSITORY%:latest"
)

:: 检查buildx是否已安装并启用
docker buildx version >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo %RED%错误: Docker buildx 未安装或未启用。请确保您使用的是Docker 20.10.0或更高版本。%NC%
    echo %BLUE%提示: 可以通过执行以下命令启用buildx:%NC%
    echo docker buildx create --name mybuilder --use
    exit /b 1
)

:: Create buildx builder (if it doesn't exist)
echo %BLUE%Setting up multi-architecture build environment...%NC%
docker buildx create --use --name multiarch-builder 2>nul || echo Builder already exists

:: 清理可能的缓存以避免构建错误
docker buildx prune -f

:: Description
echo %YELLOW%This command will directly build and push multi-architecture images to the remote repository.%NC%
echo %YELLOW%This is necessary because Docker doesn't support loading multi-architecture images locally.%NC%
echo %YELLOW%After completion, use the pull command to get the pushed multi-architecture image:%NC%
echo %YELLOW%  %0 pull %CURRENT_VERSION%%NC%

echo %BLUE%Will use the following configuration to build and push multi-architecture images:%NC%
echo %BLUE%- Registry: %DOCKER_REGISTRY%%NC%
echo %BLUE%- Namespace: %DOCKER_NAMESPACE%%NC%
echo %BLUE%- Repository: %DOCKER_REPOSITORY%%NC%
echo %BLUE%- Image version: %CURRENT_VERSION%%NC%
echo %BLUE%- Complete image tag: %REMOTE_TAG_SPECIFIC%%NC%
echo %BLUE%- Platforms: %DOCKER_PLATFORMS%%NC%

echo %BLUE%Confirm building and pushing multi-architecture images? [Y/n]%NC%
set /p confirm=

if /i "%confirm%"=="n" (
    echo %YELLOW%Operation canceled%NC%
    goto :eof
)

:: Directly build and push multi-architecture images
echo %BLUE%Building and pushing multi-architecture images (supporting %DOCKER_PLATFORMS%)...%NC%
docker buildx build ^
    --platform %DOCKER_PLATFORMS% ^
    --build-arg NEXT_PUBLIC_SUPABASE_URL=%SUPABASE_PUBLIC_URL% ^
    --build-arg NEXT_PUBLIC_SUPABASE_ANON_KEY=%ANON_KEY% ^
    --build-arg SUPABASE_SERVICE_ROLE_KEY=%SERVICE_ROLE_KEY% ^
    --build-arg NEXT_PUBLIC_SITE_URL=%SITE_URL% ^
    --build-arg NEXT_PUBLIC_AUTH_GITHUB_ENABLED=%GOTRUE_EXTERNAL_GITHUB_ENABLED% ^
    --build-arg NEXT_PUBLIC_AUTH_GOOGLE_ENABLED=%GOTRUE_EXTERNAL_GOOGLE_ENABLED% ^
    --build-arg APP_VERSION=%CURRENT_VERSION% ^
    -t %REMOTE_TAG_SPECIFIC% ^
    -t %REMOTE_TAG_LATEST% ^
    --push .

if %ERRORLEVEL% neq 0 (
    echo %RED%Multi-architecture image build and push failed!%NC%
    echo %YELLOW%Possible issues:%NC%
    echo %YELLOW%1. Docker buildx not set up correctly%NC%
    echo %YELLOW%2. Network connectivity issues%NC%
    echo %YELLOW%3. Not enough system resources%NC%
    echo %YELLOW%4. Docker Hub rate limits (for free accounts)%NC%
    
    echo %BLUE%Try with fewer platforms:%NC%
    echo %YELLOW%Edit .env file and change DOCKER_PLATFORMS to include fewer platforms%NC%
    echo %YELLOW%For example: DOCKER_PLATFORMS=linux/amd64,linux/arm64%NC%
    exit /b 1
)

:: Update APP_VERSION in .env file
findstr /C:"APP_VERSION=" .env >nul
if %ERRORLEVEL% == 0 (
    :: If exists, replace
    :: Create temporary file
    type .env | findstr /v /C:"APP_VERSION=" > .env.tmp
    echo APP_VERSION=%CURRENT_VERSION% >> .env.tmp
    move /y .env.tmp .env > nul
) else (
    :: If not exists, add
    echo APP_VERSION=%CURRENT_VERSION% >> .env
)
echo %GREEN%Updated version number in .env file: APP_VERSION=%CURRENT_VERSION%%NC%

echo %GREEN%Successfully built and pushed multi-architecture images: %NC%
echo %GREEN%- %REMOTE_TAG_SPECIFIC%%NC%
echo %GREEN%- %REMOTE_TAG_LATEST%%NC%

echo %YELLOW%Tip: Use the following commands to pull and use the multi-architecture image:%NC%
echo %BLUE%%0 pull %CURRENT_VERSION%%NC%
echo %BLUE%%0 run %CURRENT_VERSION%%NC%

goto :eof