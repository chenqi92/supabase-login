"use client";

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { createClientComponentClient } from "@supabase/auth-helpers-nextjs";
import { useI18n } from "@/components/providers/i18n-provider";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { isValidPassword } from "@/lib/utils";
import { LanguageSwitcher } from "@/components/auth/language-switcher";

export default function UpdatePasswordPage() {
  const router = useRouter();
  const { t } = useI18n();
  const supabase = createClientComponentClient();
  const [password, setPassword] = useState("");
  const [passwordConfirm, setPasswordConfirm] = useState("");
  const [passwordError, setPasswordError] = useState<string | null>(null);
  const [confirmError, setConfirmError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);
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

  const handleUpdatePassword = async (e: React.FormEvent) => {
    e.preventDefault();
    
    // 验证密码
    let isValid = true;
    
    if (!password) {
      setPasswordError(t("auth.required_field"));
      isValid = false;
    } else if (!isValidPassword(password)) {
      setPasswordError(t("auth.password_requirements"));
      isValid = false;
    } else {
      setPasswordError(null);
    }

    if (password !== passwordConfirm) {
      setConfirmError(t("auth.password_mismatch"));
      isValid = false;
    } else {
      setConfirmError(null);
    }

    if (!isValid) return;

    setIsLoading(true);
    
    const { error } = await supabase.auth.updateUser({
      password: password
    });
    
    setIsLoading(false);

    if (error) {
      setMessage(error.message);
    } else {
      setMessage(t("common.success"));
      // 短暂延迟后跳转到登录页
      setTimeout(() => {
        router.push("/login");
      }, 2000);
    }
  };

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
          <div className={`rounded-lg border p-4 text-center ${
            message === t("common.success") 
              ? "border-supabase/20 bg-supabase/10" 
              : "border-destructive/20 bg-destructive/10"
          }`}>
            <p className="text-sm">{message}</p>
          </div>
        ) : (
          <form onSubmit={handleUpdatePassword} className="space-y-4">
            <div className="grid gap-2">
              <Label htmlFor="password">{t("auth.password")}</Label>
              <Input
                id="password"
                type="password"
                autoCapitalize="none"
                autoComplete="new-password"
                disabled={isLoading}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
              />
              {passwordError && (
                <p className="text-xs text-destructive">{passwordError}</p>
              )}
            </div>
            <div className="grid gap-2">
              <Label htmlFor="password-confirm">{t("auth.confirm_password")}</Label>
              <Input
                id="password-confirm"
                type="password"
                autoCapitalize="none"
                autoComplete="new-password"
                disabled={isLoading}
                value={passwordConfirm}
                onChange={(e) => setPasswordConfirm(e.target.value)}
              />
              {confirmError && (
                <p className="text-xs text-destructive">{confirmError}</p>
              )}
            </div>
            <Button
              disabled={isLoading}
              type="submit"
              className="w-full bg-supabase hover:bg-supabase/90 text-white"
            >
              {isLoading ? t("common.loading") : t("common.submit")}
            </Button>
          </form>
        )}
      </div>
    </div>
  );
} 