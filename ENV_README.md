# 环境变量映射说明

本项目使用的环境变量与Supabase自部署环境变量有对应关系。为了保持前端代码的一致性，我们在Docker构建和运行时进行了映射。

## 环境变量对应关系

| Supabase变量名 | 前端变量名 | 说明 |
|--------------|-----------|------|
| `SUPABASE_PUBLIC_URL` | `NEXT_PUBLIC_SUPABASE_URL` | Supabase API服务地址 |
| `ANON_KEY` | `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Supabase匿名访问密钥 |
| `SITE_URL` | `NEXT_PUBLIC_SITE_URL` | 应用站点URL，用于OAuth回调 |
| `GOTRUE_EXTERNAL_GITHUB_ENABLED` | `NEXT_PUBLIC_AUTH_GITHUB_ENABLED` | 是否启用GitHub登录 |
| `GOTRUE_EXTERNAL_GOOGLE_ENABLED` | `NEXT_PUBLIC_AUTH_GOOGLE_ENABLED` | 是否启用Google登录 |

## 如何使用

1. 在项目根目录创建一个`.env`文件，包含以下内容：

```
# Supabase URL
NEXT_PUBLIC_SUPABASE_URL=https://database.allbs.cn
SUPABASE_PUBLIC_URL=https://database.allbs.cn

# 匿名密钥
NEXT_PUBLIC_SUPABASE_ANON_KEY=你的ANON_KEY
ANON_KEY=你的ANON_KEY

# 站点URL
NEXT_PUBLIC_SITE_URL=https://login.allbs.cn
SITE_URL=https://login.allbs.cn

# OAuth配置
NEXT_PUBLIC_AUTH_GITHUB_ENABLED=true
GOTRUE_EXTERNAL_GITHUB_ENABLED=true

NEXT_PUBLIC_AUTH_GOOGLE_ENABLED=true
GOTRUE_EXTERNAL_GOOGLE_ENABLED=true
```

2. 使用Docker Compose构建和运行：

```bash
docker-compose up -d
```

## 注意事项

- 前端代码中使用`NEXT_PUBLIC_`前缀的变量
- Docker构建时会从对应的Supabase变量中获取值
- 如果直接在本地开发，需要手动设置这些变量 