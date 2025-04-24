0/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone', // 为 Docker 构建优化
  reactStrictMode: true,
  basePath: '/login', // 设置应用基础路径为/login
  swcMinify: process.env.NEXT_ARCHITECTURE === 'unsupported' ? false : true, // 在不支持的架构上禁用swc
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
  // 为不支持的架构提供备选方案
  webpack: (config, { isServer, nextRuntime }) => {
    // 对于不支持SWC的架构，使用Babel转译
    if (process.env.NEXT_ARCHITECTURE === 'unsupported') {
      console.log('⚠️ 使用Babel编译代替SWC (架构不支持SWC)');
      
      // 对JS/TS文件使用babel-loader
      const nextBabelLoader = config.module.rules.find(
        (rule) => rule.use && rule.use.loader === 'next-babel-loader'
      );

      if (nextBabelLoader) {
        // 确保使用babel-loader
        nextBabelLoader.use = {
          loader: 'babel-loader',
          options: {
            presets: ['next/babel'],
            cacheDirectory: true,
          },
        };
      }
    }
    
    return config;
  },
};

module.exports = nextConfig;
