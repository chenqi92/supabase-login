"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { createClientComponentClient } from "@supabase/auth-helpers-nextjs";
import { GithubIcon, ShieldIcon } from "lucide-react";

import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { useI18n } from "@/components/providers/i18n-provider";
import { LanguageSwitcher } from "@/components/auth/language-switcher";
import { isEmailOrUsername, isValidEmail, isValidUsername } from "@/lib/utils";

export function LoginForm() {
  const router = useRouter();
  const supabase = createClientComponentClient();
  const { t } = useI18n();
  
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [identifier, setIdentifier] = useState("");
  const [password, setPassword] = useState("");

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
      setIsLoading(false);
    }
  };

  const handleSignIn = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError(null);

    const idType = isEmailOrUsername(identifier);
    
    // 根据输入内容判断是邮箱还是用户名
    if (idType === 'email') {
      // 验证邮箱格式
      if (!isValidEmail(identifier)) {
        setError(t("auth.invalid_email_format"));
        setIsLoading(false);
        return;
      }

      const { data, error } = await supabase.auth.signInWithPassword({
        email: identifier,
        password,
      });

      if (error) {
        setError(error.message);
        setIsLoading(false);
        return;
      }
      
      // 设置 Cookie 并跳转
      await setAuthCookieAndRedirect(data.session);
    } else {
      // 验证用户名格式
      if (!isValidUsername(identifier)) {
        setError(t("auth.invalid_username_format"));
        setIsLoading(false);
        return;
      }

      // 使用用户名登录
      // Supabase 原生不支持用户名登录，需要先查询用户然后使用邮箱登录
      // 这里假设用户名存储在用户元数据中
      const { data: profileData, error: fetchError } = await supabase
        .from('profiles')
        .select('email')
        .eq('username', identifier)
        .single();

      if (fetchError || !profileData) {
        setError(t("auth.invalid_username"));
        setIsLoading(false);
        return;
      }

      const { data, error } = await supabase.auth.signInWithPassword({
        email: profileData.email,
        password,
      });

      if (error) {
        setError(error.message);
        setIsLoading(false);
        return;
      }
      
      // 设置 Cookie 并跳转
      await setAuthCookieAndRedirect(data.session);
    }
  };

  const handleGithubSignIn = async () => {
    setIsLoading(true);
    setError(null);

    const { data, error } = await supabase.auth.signInWithOAuth({
      provider: 'github',
      options: {
        redirectTo: `${window.location.origin}/login/auth/callback?next=/auth-success`,
      },
    });

    if (error) {
      setError(error.message);
      setIsLoading(false);
    }
  };

  const handleGoogleSignIn = async () => {
    setIsLoading(true);
    setError(null);

    const { data, error } = await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: {
        redirectTo: `${window.location.origin}/login/auth/callback?next=/auth-success`,
      },
    });

    if (error) {
      setError(error.message);
      setIsLoading(false);
    }
  };

  return (
    <div className="mx-auto flex w-full flex-col justify-center space-y-6 sm:w-[350px]">
      <div className="flex flex-col space-y-2 text-center">
        <h1 className="text-2xl font-semibold tracking-tight">
          {t("auth.signin")}
        </h1>
        <p className="text-sm text-muted-foreground">
          {t("auth.no_account")} <Link href="/signup" className="underline underline-offset-4 hover:text-primary">{t("auth.signup")}</Link>
        </p>
      </div>
      <div className="absolute top-4 right-4">
        <LanguageSwitcher />
      </div>
      <div className="grid gap-6">
        <form onSubmit={handleSignIn}>
          <div className="grid gap-4">
            <div className="grid gap-2">
              <Label htmlFor="identifier">{t("auth.username_or_email")}</Label>
              <Input
                id="identifier"
                placeholder="username / name@example.com"
                type="text"
                autoCapitalize="none"
                autoCorrect="off"
                disabled={isLoading}
                value={identifier}
                onChange={(e) => setIdentifier(e.target.value)}
              />
            </div>
            <div className="grid gap-2">
              <div className="flex items-center justify-between">
                <Label htmlFor="password">{t("auth.password")}</Label>
                <Link
                  href="/reset-password"
                  className="text-xs text-muted-foreground hover:text-primary"
                >
                  {t("auth.forgot_password")}
                </Link>
              </div>
              <Input
                id="password"
                type="password"
                autoCapitalize="none"
                autoComplete="current-password"
                disabled={isLoading}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
              />
            </div>
            {error && (
              <div className="text-sm text-destructive">{error}</div>
            )}
            <Button disabled={isLoading} className="bg-supabase hover:bg-supabase/90 text-white">
              {isLoading ? t("common.loading") : t("auth.signin")}
            </Button>
          </div>
        </form>
        <div className="relative">
          <div className="absolute inset-0 flex items-center">
            <span className="w-full border-t" />
          </div>
          <div className="relative flex justify-center text-xs uppercase">
            <span className="bg-background px-2 text-muted-foreground">
              {t("auth.continue_with")}
            </span>
          </div>
        </div>
        <div className="flex flex-col gap-2">
          {process.env.NEXT_PUBLIC_AUTH_GITHUB_ENABLED === 'true' && (
            <Button 
              variant="outline" 
              type="button"
              disabled={isLoading}
              onClick={handleGithubSignIn}
              className="flex gap-2"
            >
              <GithubIcon className="h-4 w-4" />
              {t("auth.github")}
            </Button>
          )}
          {process.env.NEXT_PUBLIC_AUTH_GOOGLE_ENABLED === 'true' && (
            <Button
              variant="outline"
              type="button"
              disabled={isLoading}
              onClick={handleGoogleSignIn}
              className="flex gap-2"
            >
              <svg xmlns="http://www.w3.org/2000/svg" height="16" width="16" viewBox="0 0 488 512">
                <path d="M488 261.8C488 403.3 391.1 504 248 504 110.8 504 0 393.2 0 256S110.8 8 248 8c66.8 0 123 24.5 166.3 64.9l-67.5 64.9C258.5 52.6 94.3 116.6 94.3 256c0 86.5 69.1 156.6 153.7 156.6 98.2 0 135-70.4 140.8-106.9H248v-85.3h236.1c2.3 12.7 3.9 24.9 3.9 41.4z"/>
              </svg>
              {t("auth.google")}
            </Button>
          )}
        </div>
        
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