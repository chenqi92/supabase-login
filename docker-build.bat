@echo off
chcp 65001 >nul
:: 设置UTF-8编码，解决中文显示问题
:: 设置控制台字体为支持中文的字体
reg add "HKEY_CURRENT_USER\Console" /v "FaceName" /t REG_SZ /d "NSimSun" /f > nul 2>&1

:: 颜色定义
set RED=[91m
set GREEN=[92m
set YELLOW=[93m
set BLUE=[94m
set NC=[0m

:: 解析命令参数
set COMMAND=%1
set VERSION=%2

if "%VERSION%"=="" (
    set VERSION=latest
)

:: 显示帮助信息
if "%COMMAND%"=="" goto :help
if /i "%COMMAND%"=="help" goto :help

:: 执行对应的命令
if /i "%COMMAND%"=="build" goto :build
if /i "%COMMAND%"=="run" goto :run
if /i "%COMMAND%"=="export" goto :export
if /i "%COMMAND%"=="login" goto :login
if /i "%COMMAND%"=="push" goto :push
if /i "%COMMAND%"=="pull" goto :pull
if /i "%COMMAND%"=="buildlatest" goto :buildlatest

echo %RED%错误: 未知命令 '%COMMAND%'%NC%
goto :help

:help
echo %BLUE%Supabase 登录 UI Docker 构建工具%NC%
echo 用法: %0 [命令] [版本号]
echo.
echo 命令:
echo   build [版本号]    构建Docker镜像
echo   buildlatest       构建并标记为latest版本镜像
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
echo   %0 run 1.0.0     运行版本1.0.0的容器
echo   %0 export 1.0.0  导出版本1.0.0的镜像
echo   %0 login registry.cn-hangzhou.aliyuncs.com  登录到阿里云镜像仓库
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

:: 构建镜像
docker build ^
    --build-arg NEXT_PUBLIC_SUPABASE_URL=%SUPABASE_PUBLIC_URL% ^
    --build-arg NEXT_PUBLIC_SUPABASE_ANON_KEY=%ANON_KEY% ^
    --build-arg NEXT_PUBLIC_SITE_URL=%SITE_URL% ^
    --build-arg NEXT_PUBLIC_AUTH_GITHUB_ENABLED=%GOTRUE_EXTERNAL_GITHUB_ENABLED% ^
    --build-arg NEXT_PUBLIC_AUTH_GOOGLE_ENABLED=%GOTRUE_EXTERNAL_GOOGLE_ENABLED% ^
    --build-arg APP_VERSION=%VERSION% ^
    -t supabase-login-ui:%VERSION% .

if %ERRORLEVEL% neq 0 (
    echo %RED%构建失败!%NC%
    exit /b 1
)

echo %GREEN%镜像构建完成: supabase-login-ui:%VERSION%%NC%
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

:: 获取当前日期时间作为版本号
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "TIMESTAMP=%dt:~0,8%-%dt:~8,6%"
set "CURRENT_VERSION=%APP_VERSION%.%TIMESTAMP%"

:: 构建镜像 - 同时标记为特定版本和latest
echo %BLUE%正在构建并标记镜像...%NC%
docker build ^
    --build-arg NEXT_PUBLIC_SUPABASE_URL=%SUPABASE_PUBLIC_URL% ^
    --build-arg NEXT_PUBLIC_SUPABASE_ANON_KEY=%ANON_KEY% ^
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
    
    echo %YELLOW%提示: 使用以下命令推送镜像到仓库:%NC%
    echo %BLUE%docker push %REMOTE_TAG_SPECIFIC%%NC%
    echo %BLUE%docker push %REMOTE_TAG_LATEST%%NC%
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

echo %BLUE%正在标记镜像: %REMOTE_TAG%%NC%
docker tag supabase-login-ui:%VERSION% %REMOTE_TAG%

echo %BLUE%正在推送镜像到仓库...%NC%
docker push %REMOTE_TAG%

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
    
    echo %BLUE%同时推送时间戳版本: %REMOTE_TAG_SPECIFIC%%NC%
    docker tag supabase-login-ui:latest %REMOTE_TAG_SPECIFIC%
    docker push %REMOTE_TAG_SPECIFIC%
)

echo %GREEN%镜像已成功推送: %REMOTE_TAG%%NC%
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

:: 检查必要的环境变量
if "%DOCKER_REGISTRY%"=="" goto :missing_registry_config
if "%DOCKER_NAMESPACE%"=="" goto :missing_registry_config
if "%DOCKER_REPOSITORY%"=="" goto :missing_registry_config

:: 构建远程镜像标签
set REMOTE_TAG=%DOCKER_REGISTRY%/%DOCKER_NAMESPACE%/%DOCKER_REPOSITORY%:%VERSION%

echo %BLUE%正在从仓库拉取镜像: %REMOTE_TAG%%NC%
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