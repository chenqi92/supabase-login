"use client";

import { useState } from "react";
import Link from "next/link";
import { createClientComponentClient } from "@supabase/auth-helpers-nextjs";
import { useI18n } from "@/components/providers/i18n-provider";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { isValidEmail } from "@/lib/utils";

export default function ResetPasswordPage() {
  const { t } = useI18n();
  const supabase = createClientComponentClient();
  const [email, setEmail] = useState("");
  const [emailError, setEmailError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [isSent, setIsSent] = useState(false);

  const handleResetPassword = async (e: React.FormEvent) => {
    e.preventDefault();
    
    // 验证邮箱
    if (!email) {
      setEmailError(t("auth.required_field"));
      return;
    } else if (!isValidEmail(email)) {
      setEmailError(t("auth.invalid_email"));
      return;
    } else {
      setEmailError(null);
    }

    setIsLoading(true);
    
    const { error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${window.location.origin}/auth/callback?next=/update-password`,
    });
    
    setIsLoading(false);

    if (error) {
      setEmailError(error.message);
    } else {
      setIsSent(true);
    }
  };

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

        {!isSent ? (
          <form onSubmit={handleResetPassword} className="space-y-4">
            <div className="grid gap-2">
              <Label htmlFor="email">{t("auth.email")}</Label>
              <Input
                id="email"
                placeholder="name@example.com"
                type="email"
                autoCapitalize="none"
                autoComplete="email"
                autoCorrect="off"
                disabled={isLoading}
                value={email}
                onChange={(e) => setEmail(e.target.value)}
              />
              {emailError && (
                <p className="text-xs text-destructive">{emailError}</p>
              )}
            </div>
            <Button
              disabled={isLoading}
              type="submit"
              className="w-full bg-supabase hover:bg-supabase/90 text-white"
            >
              {isLoading ? t("common.loading") : t("auth.reset_password")}
            </Button>
          </form>
        ) : (
          <div className="rounded-lg border border-supabase/20 bg-supabase/10 p-4 text-center">
            <p className="text-sm">{t("auth.reset_link_sent")}</p>
          </div>
        )}

        <Button asChild variant="outline">
          <Link href="/login">{t("auth.back_to_login")}</Link>
        </Button>
      </div>
    </div>
  );
} 