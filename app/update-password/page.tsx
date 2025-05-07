"use client";

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { createClientComponentClient } from "@supabase/auth-helpers-nextjs";
import { Auth } from "@supabase/ui";
import { useI18n } from "@/components/providers/i18n-provider";
import { LanguageSwitcher } from "@/components/auth/language-switcher";

export default function UpdatePasswordPage() {
  const router = useRouter();
  const { t } = useI18n();
  const supabase = createClientComponentClient();
  const [message, setMessage] = useState<string | null>(null);

  // 检查是否通过重置链接访问
  useEffect(() => {
    const checkSession = async () => {
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) {
        router.push("/login");
      }
    };

    checkSession();
  }, [router, supabase.auth]);

  // 监听认证状态变化
  useEffect(() => {
    const { data: authListener } = supabase.auth.onAuthStateChange(
      async (event, session) => {
        if (event === 'PASSWORD_RECOVERY') {
          setMessage(t("auth.password_updated"));
          // 短暂延迟后跳转到登录页
          setTimeout(() => {
            router.push("/login");
          }, 2000);
        }
      }
    );

    return () => {
      authListener.subscription.unsubscribe();
    };
  }, [router, t]);

  return (
    <div className="container flex h-screen w-screen flex-col items-center justify-center">
      <div className="absolute top-4 right-4">
        <LanguageSwitcher />
      </div>
      <div className="mx-auto flex w-full flex-col justify-center space-y-6 sm:w-[350px]">
        <div className="flex flex-col space-y-2 text-center">
          <h1 className="text-2xl font-semibold tracking-tight">
            {t("auth.update_password")}
          </h1>
          <p className="text-sm text-muted-foreground">
            {t("auth.update_password_instructions")}
          </p>
        </div>

        {message ? (
          <div className="rounded-lg border border-supabase/20 bg-supabase/10 p-4 text-center">
            <p className="text-sm">{message}</p>
          </div>
        ) : (
          <div className="grid gap-6">
            <Auth
              supabaseClient={supabase}
              view="update_password"
              className="supabase-auth-ui"
            />
          </div>
        )}
      </div>
    </div>
  );
} 