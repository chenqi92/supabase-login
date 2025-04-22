@echo off
setlocal enabledelayedexpansion

REM 设置变量
set VERSION=%1
if "%VERSION%"=="" set VERSION=1.0.0
set IMAGE_NAME=supabase-login-ui
set CONTAINER_NAME=supabase-login-ui

echo === 开始构建版本: %VERSION% ===

REM 检查是否有旧容器运行
docker ps -q -f name=%CONTAINER_NAME% > nul
if %ERRORLEVEL% == 0 (
    echo 停止并移除现有容器...
    docker stop %CONTAINER_NAME%
    docker rm %CONTAINER_NAME%
)

REM 检查是否有旧镜像
docker images -q %IMAGE_NAME%:%VERSION% > nul
if %ERRORLEVEL% == 0 (
    echo 移除旧版本镜像...
    docker rmi %IMAGE_NAME%:%VERSION%
)

REM 设置环境变量
set APP_VERSION=%VERSION%
set PORT=3000

REM 从.env文件加载变量（如果存在）
if exist .env (
    echo 加载.env文件...
    for /f "tokens=*" %%a in (.env) do (
        set %%a
    )
)

REM 设置默认值（如果未在.env中设置）
if not defined SUPABASE_PUBLIC_URL set SUPABASE_PUBLIC_URL=https://database.allbs.cn
if not defined ANON_KEY set ANON_KEY=your_anon_key
if not defined SITE_URL set SITE_URL=https://login.allbs.cn
if not defined GOTRUE_EXTERNAL_GITHUB_ENABLED set GOTRUE_EXTERNAL_GITHUB_ENABLED=true
if not defined GOTRUE_EXTERNAL_GOOGLE_ENABLED set GOTRUE_EXTERNAL_GOOGLE_ENABLED=true

echo 构建Docker镜像...
docker-compose build

echo 为镜像添加版本标签...
docker tag %IMAGE_NAME%:latest %IMAGE_NAME%:%VERSION%

echo 启动容器...
docker-compose up -d

echo === 构建完成! ===
echo 应用正在运行: http://localhost:%PORT%
echo 版本信息: %VERSION% 