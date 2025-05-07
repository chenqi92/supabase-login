"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import { createClientComponentClient } from "@supabase/auth-helpers-nextjs";
import { Auth } from "@supabase/auth-ui-react";
import { ThemeSupa } from "@supabase/auth-ui-shared";
import { useI18n } from "@/components/providers/i18n-provider";
import { Button } from "@/components/ui/button";

export default function ResetPasswordPage() {
  const { t } = useI18n();
  const supabase = createClientComponentClient();
  const [origin, setOrigin] = useState<string>("");

  // 客户端初始化时设置origin
  useEffect(() => {
    setOrigin(window.location.origin);
  }, []);

  return (
    <div className="container flex h-screen w-screen flex-col items-center justify-center">
      <div className="mx-auto flex w-full flex-col justify-center space-y-6 sm:w-[350px]">
        <div className="flex flex-col space-y-2 text-center">
          <h1 className="text-2xl font-semibold tracking-tight">
            {t("auth.reset_password")}
          </h1>
          <p className="text-sm text-muted-foreground">
            {t("auth.reset_password_instructions")}
          </p>
        </div>

        <div className="grid gap-6">
          {origin && (
            <div className="supabase-auth-ui">
              <Auth
                supabaseClient={supabase}
                appearance={{ theme: ThemeSupa }}
                view="forgotten_password"
                redirectTo={`${origin}/login/auth/callback?next=/update-password`}
              />
            </div>
          )}
        </div>

        <Button asChild variant="outline">
          <Link href="/login">{t("auth.back_to_login")}</Link>
        </Button>
      </div>
    </div>
  );
} 