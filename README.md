# Supabase Login UI

This repository contains a Docker Compose configuration for deploying the Supabase Login UI, a customizable authentication interface for Supabase.

## Quick Start

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/supabase-login.git
   cd supabase-login
   ```

2. Modify the `docker-compose.yml` file to update your Supabase credentials and other configuration options.

3. Start the container:
   ```bash
   docker-compose up -d
   ```

4. Access the login UI at http://localhost:3110 (or the port you configured)

## Configuration

The `docker-compose.yml` file contains all necessary configuration. Here are the key environment variables you may want to customize:

| Variable | Description | Default |
|----------|-------------|---------|
| NEXT_PUBLIC_SUPABASE_URL | Your Supabase project URL | https://database.example.com |
| NEXT_PUBLIC_SUPABASE_ANON_KEY | Your Supabase anonymous key | example key |
| SUPABASE_SERVICE_ROLE_KEY | Your Supabase service role key | example key |
| NEXT_PUBLIC_SITE_URL | The URL where your login UI is hosted | https://login.example.com |
| PORT | The local port to expose the service | 3110 |
| DOCKER_NAMESPACE | Docker Hub namespace for the image | kkape |

## Authentication Providers

You can enable/disable third-party authentication providers by setting these environment variables:

- NEXT_PUBLIC_AUTH_GITHUB_ENABLED: Set to "true" to enable GitHub authentication
- NEXT_PUBLIC_AUTH_GOOGLE_ENABLED: Set to "true" to enable Google authentication

## Custom Deployment

If you want to use a different version or build your own image, you can modify the image reference in the docker-compose.yml file:

```yaml
image: yourusername/supabase-login-ui:your-tag
```

## Resource Limits

The default configuration includes resource limits that you can adjust based on your server capacity:

```yaml
deploy:
  resources:
    limits:
      cpus: '1'
      memory: 512M
```

## Health Checks

The service includes a health check that verifies the application is running properly:

```yaml
healthcheck:
  test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:3000/"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 5s
```

## Logs

Logs are stored in a volume mounted at `./logs:/app/logs`. 