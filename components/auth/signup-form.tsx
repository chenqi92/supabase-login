"use client";

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { createClientComponentClient } from "@supabase/auth-helpers-nextjs";
import { Auth } from "@supabase/ui";

import { useI18n } from "@/components/providers/i18n-provider";
import { LanguageSwitcher } from "@/components/auth/language-switcher";

export function SignupForm() {
  const router = useRouter();
  const supabase = createClientComponentClient();
  const { t } = useI18n();
  
  const [error, setError] = useState<string | null>(null);

  // 监听认证状态变化
  useEffect(() => {
    const { data: authListener } = supabase.auth.onAuthStateChange(
      async (event, session) => {
        // 处理注册成功事件
        if (event === 'SIGNED_IN' && session) {
          router.push("/verify-email");
        }
      }
    );

    return () => {
      authListener.subscription.unsubscribe();
    };
  }, [router]);

  // Auth组件实例视图
  return (
    <div className="mx-auto flex w-full flex-col justify-center space-y-6 sm:w-[350px]">
      <div className="flex flex-col space-y-2 text-center">
        <h1 className="text-2xl font-semibold tracking-tight">
          {t("auth.signup")}
        </h1>
        <p className="text-sm text-muted-foreground">
          {t("auth.create_account")}
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
          view="sign_up"
          redirectTo={`${window.location.origin}/login/auth/callback?next=/verify-email`}
          className="supabase-auth-ui"
        />
      </div>
    </div>
  );
} 