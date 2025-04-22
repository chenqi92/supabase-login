@echo off
setlocal

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

echo 构建Docker镜像...
docker build ^
  --build-arg NEXT_PUBLIC_SUPABASE_URL=https://database.allbs.cn ^
  --build-arg NEXT_PUBLIC_SUPABASE_ANON_KEY=your_anon_key ^
  --build-arg NEXT_PUBLIC_SITE_URL=https://login.allbs.cn ^
  --build-arg NEXT_PUBLIC_AUTH_GITHUB_ENABLED=true ^
  --build-arg NEXT_PUBLIC_AUTH_GOOGLE_ENABLED=true ^
  --build-arg APP_VERSION=%VERSION% ^
  -t %IMAGE_NAME%:latest .

echo 为镜像添加版本标签...
docker tag %IMAGE_NAME%:latest %IMAGE_NAME%:%VERSION%

echo 启动容器...
docker run -d ^
  --name %CONTAINER_NAME% ^
  -p 3000:3000 ^
  -e NODE_ENV=production ^
  -v %cd%\logs:/app/logs ^
  %IMAGE_NAME%:%VERSION%

echo === 构建完成! ===
echo 应用正在运行: http://localhost:3000
echo 版本信息: %VERSION% 