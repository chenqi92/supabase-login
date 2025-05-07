import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
import { createMiddlewareClient } from '@supabase/auth-helpers-nextjs';

export async function middleware(request: NextRequest) {
  const response = NextResponse.next();
  
  // 创建 Supabase 中间件客户端
  const supabase = createMiddlewareClient({ req: request, res: response });
  
  // 刷新会话，如果会话已过期，则会自动清除
  await supabase.auth.getSession();

  // 获取当前路径
  const { pathname } = request.nextUrl;
  
  // 如果访问根路径，根据登录状态重定向
  if (pathname === '/') {
    const { data: { session } } = await supabase.auth.getSession();
    
    if (session) {
      // 用户已登录，重定向到 Studio
      const redirectUrl = new URL('/studio', request.url);
      return NextResponse.redirect(redirectUrl);
    } else {
      // 用户未登录，重定向到登录页
      const redirectUrl = new URL('/login', request.url);
      return NextResponse.redirect(redirectUrl);
    }
  }
  
  return response;
}

// 配置中间件仅在特定路径上运行
export const config = {
  matcher: ['/', '/login', '/studio'],
}; 