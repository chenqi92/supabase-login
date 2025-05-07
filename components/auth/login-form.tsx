"use client";

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { createClientComponentClient } from "@supabase/auth-helpers-nextjs";
import { Auth } from "@supabase/ui";
import Link from "next/link";
import { ShieldIcon } from "lucide-react";

import { useI18n } from "@/components/providers/i18n-provider";
import { LanguageSwitcher } from "@/components/auth/language-switcher";
import { Button } from "@/components/ui/button";

export function LoginForm() {
  const router = useRouter();
  const supabase = createClientComponentClient();
  const { t } = useI18n();
  
  const [error, setError] = useState<string | null>(null);

  // 设置 JWT Cookie 并跳转到 Studio
  const setAuthCookieAndRedirect = async (session: any) => {
    try {
      // 获取访问令牌
      const accessToken = session.access_token;
      
      // 调用设置 Cookie 的 API
      const response = await fetch('/login/api/set-auth-cookie', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ token: accessToken }),
      });
      
      if (!response.ok) {
        throw new Error('设置认证Cookie失败');
      }
      
      // 跳转到 Studio
      window.location.href = '/studio/';
    } catch (err) {
      console.error('设置Cookie时出错:', err);
      setError(err instanceof Error ? err.message : '认证设置失败');
    }
  };

  // 监听认证状态变化
  useEffect(() => {
    const { data: authListener } = supabase.auth.onAuthStateChange(
      async (event, session) => {
        if (event === 'SIGNED_IN' && session) {
          await setAuthCookieAndRedirect(session);
        }
      }
    );

    return () => {
      authListener.subscription.unsubscribe();
    };
  }, []);

  // Auth组件实例视图
  return (
    <div className="mx-auto flex w-full flex-col justify-center space-y-6 sm:w-[350px]">
      <div className="flex flex-col space-y-2 text-center">
        <h1 className="text-2xl font-semibold tracking-tight">
          {t("auth.signin")}
        </h1>
        <p className="text-sm text-muted-foreground">
          {t("auth.welcome_back")}
        </p>
      </div>
      <div className="absolute top-4 right-4">
        <LanguageSwitcher />
      </div>
      {error && (
        <div className="text-sm text-destructive">{error}</div>
      )}
      <div className="grid gap-6">
        <Auth
          supabaseClient={supabase}
          providers={['github', 'google']}
          view="sign_in"
          redirectTo={`${window.location.origin}/login/auth/callback?next=/auth-success`}
          className="supabase-auth-ui"
        />
        
        {/* 超级管理员入口 */}
        <div className="relative mt-6">
          <div className="absolute inset-0 flex items-center">
            <span className="w-full border-t" />
          </div>
          <div className="relative flex justify-center text-xs uppercase">
            <span className="bg-background px-2 text-muted-foreground">
              管理选项
            </span>
          </div>
        </div>
        
        <div className="flex justify-center">
          <Link href="/admin">
            <Button
              variant="outline"
              type="button"
              className="flex gap-2 text-red-600 border-red-200 hover:bg-red-50"
            >
              <ShieldIcon className="h-4 w-4" />
              创建超级管理员
            </Button>
          </Link>
        </div>
      </div>
    </div>
  );
} 