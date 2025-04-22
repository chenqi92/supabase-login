/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone', // 为 Docker 构建优化
  reactStrictMode: true,
  swcMinify: true,
  typescript: {
    // !! 警告 !!
    // 仅在生产环境构建时禁用类型检查
    // 开发时应保持开启类型检查
    ignoreBuildErrors: process.env.SKIP_TYPE_CHECK === 'true',
  },
  eslint: {
    // 在生产环境构建时禁用ESLint，提高构建速度
    ignoreDuringBuilds: process.env.NODE_ENV === 'production',
  },
};

module.exports = nextConfig;
