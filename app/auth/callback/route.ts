import { createRouteHandlerClient } from '@supabase/auth-helpers-nextjs';
import { cookies } from 'next/headers';
import { NextRequest, NextResponse } from 'next/server';

export async function GET(request: NextRequest) {
  const requestUrl = new URL(request.url);
  const code = requestUrl.searchParams.get('code');
  const next = requestUrl.searchParams.get('next') || '/';

  if (code) {
    const cookieStore = cookies();
    const supabase = createRouteHandlerClient({ cookies: () => cookieStore });
    await supabase.auth.exchangeCodeForSession(code);
  }

  // 构建重定向URL
  let redirectUrl: string;
  
  // 如果是要认证成功页面，使用完整路径
  if (next === '/auth-success') {
    redirectUrl = `${requestUrl.origin}/login/auth-success`;
  } else {
    // 否则，确保baseUrl包含/login前缀
    const baseUrl = `${requestUrl.origin}/login`;
    redirectUrl = next === '/' ? baseUrl : `${baseUrl}${next}`;
  }
  
  // URL to redirect to after sign in process completes
  return NextResponse.redirect(redirectUrl);
} 