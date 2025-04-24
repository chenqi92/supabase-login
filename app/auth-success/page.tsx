"use client";

import { useEffect, useState } from "react";
import { createClientComponentClient } from "@supabase/auth-helpers-nextjs";
import { useI18n } from "@/components/providers/i18n-provider";

export default function AuthSuccessPage() {
  const { t } = useI18n();
  const [message, setMessage] = useState<string>(t("auth.authenticating"));
  const [error, setError] = useState<string | null>(null);
  
  useEffect(() => {
    const setupAuthAndRedirect = async () => {
      try {
        const supabase = createClientComponentClient();
        
        // 获取当前会话
        const { data: { session }, error: sessionError } = await supabase.auth.getSession();
        
        if (sessionError || !session) {
          throw new Error(sessionError?.message || t("auth.no_session_found"));
        }
        
        // 设置 JWT Cookie
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
          throw new Error(t("auth.cookie_setup_failed"));
        }
        
        // 短暂延迟后跳转到 Studio
        setMessage(t("auth.redirecting"));
        setTimeout(() => {
          window.location.href = '/studio/';
        }, 1000);
      } catch (err) {
        console.error('认证处理错误:', err);
        setError(err instanceof Error ? err.message : String(err));
      }
    };
    
    setupAuthAndRedirect();
  }, [t]);
  
  return (
    <div className="flex h-screen w-full flex-col items-center justify-center">
      <div className="w-[350px] space-y-6 text-center">
        {!error ? (
          <>
            <h1 className="text-2xl font-semibold tracking-tight">
              {t("auth.authentication_successful")}
            </h1>
            <p className="text-sm text-muted-foreground">{message}</p>
            <div className="mt-4 flex items-center justify-center">
              <div className="animate-spin h-8 w-8 border-t-2 border-supabase rounded-full" />
            </div>
          </>
        ) : (
          <>
            <h1 className="text-2xl font-semibold tracking-tight text-destructive">
              {t("auth.authentication_error")}
            </h1>
            <p className="text-sm text-destructive">{error}</p>
          </>
        )}
      </div>
    </div>
  );
} 