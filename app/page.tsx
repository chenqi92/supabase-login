import { redirect } from "next/navigation";
import { createServerComponentClient } from "@supabase/auth-helpers-nextjs";
import { cookies } from "next/headers";

export default async function Home() {
  // 创建服务端 Supabase 客户端
  const supabase = createServerComponentClient({ cookies });
  
  // 获取用户会话
  const { data: { session } } = await supabase.auth.getSession();
  
  // 根据登录状态重定向
  if (session) {
    // 已登录，重定向到 Studio
    redirect("/studio");
  } else {
    // 未登录，重定向到登录页
    redirect("/login");
  }
  
  return null;
} 