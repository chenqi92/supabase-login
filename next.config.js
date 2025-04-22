/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone', // 为 Docker 构建优化
  reactStrictMode: true,
  swcMinify: true,
};

module.exports = nextConfig;
