import { NextResponse } from 'next/server';
import { createAdminClient } from '@/lib/supabase/admin';

export async function POST(request: Request) {
  try {
    // 检查环境变量
    if (!process.env.SUPABASE_SERVICE_ROLE_KEY) {
      return NextResponse.json(
        { error: "未配置服务角色密钥，无法创建管理员" },
        { status: 500 }
      );
    }

    // 解析请求体
    const { email, password } = await request.json();

    if (!email || !password) {
      return NextResponse.json(
        { error: "邮箱和密码是必需的" },
        { status: 400 }
      );
    }

    // 创建Supabase管理员客户端
    const supabaseAdmin = createAdminClient();

    // 创建管理员用户
    const { data, error } = await supabaseAdmin.auth.admin.createUser({
      email: email,
      password: password,
      email_confirm: true, // 自动确认邮箱
      user_metadata: {},
      app_metadata: { provider: 'email', roles: ['admin'] } // 添加admin角色
    });

    if (error) {
      console.error('创建管理员用户失败:', error);
      return NextResponse.json(
        { error: error.message },
        { status: 400 }
      );
    }

    // 返回成功响应
    return NextResponse.json({ 
      message: "管理员创建成功",
      user: { 
        id: data.user.id,
        email: data.user.email
      } 
    });
  } catch (err) {
    console.error('创建管理员时发生错误:', err);
    return NextResponse.json(
      { error: "服务器错误" },
      { status: 500 }
    );
  }
} 