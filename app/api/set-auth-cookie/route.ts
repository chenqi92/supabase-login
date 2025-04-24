import { cookies } from 'next/headers';
import { NextRequest, NextResponse } from 'next/server';

export async function POST(request: NextRequest) {
  try {
    const { token } = await request.json();
    
    if (!token) {
      return NextResponse.json(
        { error: "未提供访问令牌" },
        { status: 400 }
      );
    }
    
    // 设置 HttpOnly Cookie
    const cookieStore = cookies();
    cookieStore.set('sb-access-token', token, {
      path: '/',
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'lax', // 允许OAuth重定向回来时保留Cookie
      maxAge: 60 * 60 * 8, // 8小时
    });
    
    return NextResponse.json({ success: true });
  } catch (err) {
    console.error('设置认证Cookie时发生错误:', err);
    return NextResponse.json(
      { error: "服务器错误" },
      { status: 500 }
    );
  }
} 