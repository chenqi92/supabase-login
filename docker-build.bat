@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

REM Supabase登录UI - Docker构建工具
REM 功能：构建、运行、导出、帮助

REM 默认设置
set VERSION=%2
if "%VERSION%"=="" set VERSION=1.0.0
set IMAGE_NAME=supabase-login-ui
set CONTAINER_NAME=supabase-login-ui
set BASE_IMAGE=registry.cn-hangzhou.aliyuncs.com/nodejs-image/node:18-slim
set PORT=3000
set SUPABASE_URL=https://database.allbs.cn
set ANON_KEY=your_anon_key
set SITE_URL=https://login.allbs.cn
set GITHUB_ENABLED=true
set GOOGLE_ENABLED=true

REM 命令处理
if "%1"=="" goto help
if "%1"=="build" goto build
if "%1"=="run" goto run
if "%1"=="export" goto export
if "%1"=="help" goto help
goto invalid_command

:invalid_command
echo 错误: 无效的命令 '%1'
goto help

:help
echo 使用方法: %0 命令 [参数]
echo.
echo 可用命令:
echo   build [版本号]    - 构建Docker镜像 (默认版本: 1.0.0)
echo   run [版本号]      - 运行已构建的Docker镜像 (默认版本: 1.0.0)
echo   export [版本号]   - 导出Docker镜像为.tar文件 (默认版本: 1.0.0)
echo   help             - 显示帮助信息
echo.
echo 示例:
echo   %0 build 1.0.0   - 构建版本1.0.0的镜像
echo   %0 run           - 运行最新构建的镜像
echo   %0 export 1.0.0  - 导出版本1.0.0的镜像
echo.
echo 环境变量可以通过.env文件设置
goto :eof

:check_docker
REM 检查Docker守护进程是否运行
docker info > nul 2>&1
if %errorlevel% neq 0 (
    echo 错误: Docker守护进程未运行，请启动Docker服务
    exit /b 1
)
goto :eof

:check_network
echo 检查网络连接...
ping -n 1 registry.cn-hangzhou.aliyuncs.com > nul 2>&1
if %errorlevel% neq 0 (
    echo 警告: 无法连接到阿里云镜像服务，可能存在网络问题
    echo 继续尝试构建...
)
goto :eof

:pull_base_image
echo 尝试预先拉取基础镜像...
docker pull %BASE_IMAGE% > nul 2>&1
if %errorlevel% neq 0 (
    echo 警告: 无法拉取基础镜像，将尝试使用本地缓存继续构建

    REM 检查是否有本地缓存
    docker images | findstr "%BASE_IMAGE%" > nul
    if %errorlevel% neq 0 (
        echo 错误: 本地无缓存的基础镜像，构建可能会失败
        echo 您可以尝试手动设置Docker镜像源后再试
        set /p continue_build=是否继续构建? (y/n): 
        if /i not "!continue_build!"=="y" (
            echo 构建已取消
            exit /b 1
        )
    )
)
goto :eof

:load_env
if exist .env (
    echo 加载.env文件...
    for /f "usebackq tokens=* eol=#" %%a in (".env") do (
        if not "%%a"=="" set "%%a"
    )
)

REM 设置默认值（如果未在.env中设置）
if defined SUPABASE_PUBLIC_URL set SUPABASE_URL=!SUPABASE_PUBLIC_URL!
if not defined ANON_KEY set ANON_KEY=your_anon_key
if defined SITE_URL set SITE_URL=!SITE_URL!
if not defined GOTRUE_EXTERNAL_GITHUB_ENABLED set GITHUB_ENABLED=true
if defined GOTRUE_EXTERNAL_GITHUB_ENABLED set GITHUB_ENABLED=!GOTRUE_EXTERNAL_GITHUB_ENABLED!
if not defined GOTRUE_EXTERNAL_GOOGLE_ENABLED set GOOGLE_ENABLED=true
if defined GOTRUE_EXTERNAL_GOOGLE_ENABLED set GOOGLE_ENABLED=!GOTRUE_EXTERNAL_GOOGLE_ENABLED!
goto :eof

:cleanup
REM 检查是否有旧容器运行
docker ps -q -f name=%CONTAINER_NAME% > nul 2>&1
if not errorlevel 1 (
    echo 停止并移除现有容器...
    docker stop %CONTAINER_NAME% > nul 2>&1
    docker rm %CONTAINER_NAME% > nul 2>&1
)

REM 检查是否有旧镜像
docker images -q %IMAGE_NAME%:%VERSION% > nul 2>&1
if not errorlevel 1 (
    echo 移除旧版本镜像...
    docker rmi %IMAGE_NAME%:%VERSION% > nul 2>&1
)
goto :eof

:build
echo === 开始构建版本: %VERSION% ===

call :check_docker
call :check_network
call :pull_base_image
call :load_env
call :cleanup

echo 构建Docker镜像...
docker build ^
  --build-arg NEXT_PUBLIC_SUPABASE_URL=%SUPABASE_URL% ^
  --build-arg NEXT_PUBLIC_SUPABASE_ANON_KEY=%ANON_KEY% ^
  --build-arg NEXT_PUBLIC_SITE_URL=%SITE_URL% ^
  --build-arg NEXT_PUBLIC_AUTH_GITHUB_ENABLED=%GITHUB_ENABLED% ^
  --build-arg NEXT_PUBLIC_AUTH_GOOGLE_ENABLED=%GOOGLE_ENABLED% ^
  --build-arg APP_VERSION=%VERSION% ^
  -t %IMAGE_NAME%:latest .

REM 检查构建是否成功
if %errorlevel% neq 0 (
    echo 错误: Docker镜像构建失败
    exit /b 1
)

echo 为镜像添加版本标签...
docker tag %IMAGE_NAME%:latest %IMAGE_NAME%:%VERSION%

echo === 构建完成! ===
echo 镜像版本: %VERSION%
echo 现在可以运行: %0 run %VERSION%
goto :eof

:run
echo === 开始运行版本: %VERSION% ===

call :check_docker
call :load_env

REM 检查镜像是否存在
docker images -q %IMAGE_NAME%:%VERSION% > nul 2>&1
if errorlevel 1 (
    echo 错误: 镜像 %IMAGE_NAME%:%VERSION% 不存在
    echo 请先运行 %0 build %VERSION% 构建镜像
    exit /b 1
)

REM 检查是否有旧容器运行
docker ps -q -f name=%CONTAINER_NAME% > nul 2>&1
if not errorlevel 1 (
    echo 停止并移除现有容器...
    docker stop %CONTAINER_NAME% > nul 2>&1
    docker rm %CONTAINER_NAME% > nul 2>&1
)

echo 启动容器...
docker run -d --name %CONTAINER_NAME% -p %PORT%:3000 -e NODE_ENV=production %IMAGE_NAME%:%VERSION%

REM 检查容器是否成功启动
timeout /t 3 > nul
docker ps -q -f name=%CONTAINER_NAME% > nul 2>&1
if not errorlevel 1 (
    echo === 容器启动成功! ===
    echo 应用正在运行: http://localhost:%PORT%
    echo 版本信息: %VERSION%

    REM 显示容器日志
    echo 容器日志:
    docker logs %CONTAINER_NAME% 2>&1
    goto :eof
)

echo 错误: 容器未能成功启动
echo 请检查日志获取更多信息:
echo docker logs %CONTAINER_NAME%
exit /b 1

:export
echo === 开始导出镜像: %IMAGE_NAME%:%VERSION% ===

call :check_docker

REM 检查镜像是否存在
docker images -q %IMAGE_NAME%:%VERSION% > nul 2>&1
if errorlevel 1 (
    echo 错误: 镜像 %IMAGE_NAME%:%VERSION% 不存在
    echo 请先运行 %0 build %VERSION% 构建镜像
    exit /b 1
)

set OUTPUT_FILE=%IMAGE_NAME%-%VERSION%.tar

REM 导出镜像
echo 导出镜像到文件: %OUTPUT_FILE%
docker save -o %OUTPUT_FILE% %IMAGE_NAME%:%VERSION%

REM 检查导出是否成功
if %errorlevel% equ 0 (
    if exist "%OUTPUT_FILE%" (
        for %%F in (%OUTPUT_FILE%) do set FILE_SIZE=%%~zF
        set /a FILE_SIZE_MB=!FILE_SIZE! / 1048576
        echo === 导出成功! ===
        echo 文件大小: !FILE_SIZE_MB! MB
        echo 文件路径: %cd%\%OUTPUT_FILE%
        echo.
        echo 在目标机器上使用以下命令加载镜像:
        echo   docker load -i %OUTPUT_FILE%
        echo   docker run -d --name %CONTAINER_NAME% -p 3000:3000 %IMAGE_NAME%:%VERSION%
    ) else (
        echo 错误: 导出失败，文件未创建
        exit /b 1
    )
) else (
    echo 错误: 导出失败
    exit /b 1
)
goto :eof 