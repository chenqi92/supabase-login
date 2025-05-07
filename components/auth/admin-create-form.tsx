"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { useI18n } from "@/components/providers/i18n-provider";
import { isValidEmail, isValidPassword } from "@/lib/utils";
import { ArrowLeft } from "lucide-react";
import Link from "next/link";

export function AdminCreateForm() {
  const { t } = useI18n();
  
  const [isLoading, setIsLoading] = useState(false);
  const [success, setSuccess] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  
  // 表单验证错误
  const [emailError, setEmailError] = useState<string | null>(null);
  const [passwordError, setPasswordError] = useState<string | null>(null);
  const [confirmPasswordError, setConfirmPasswordError] = useState<string | null>(null);
  
  // 验证表单
  const validateForm = () => {
    let isValid = true;
    
    // 验证邮箱
    if (!email) {
      setEmailError(t("admin.email_required"));
      isValid = false;
    } else if (!isValidEmail(email)) {
      setEmailError(t("admin.invalid_email"));
      isValid = false;
    } else {
      setEmailError(null);
    }
    
    // 验证密码
    if (!password) {
      setPasswordError(t("admin.password_required"));
      isValid = false;
    } else if (!isValidPassword(password)) {
      setPasswordError(t("admin.password_too_short"));
      isValid = false;
    } else {
      setPasswordError(null);
    }
    
    // 验证确认密码
    if (password !== confirmPassword) {
      setConfirmPasswordError(t("admin.passwords_not_match"));
      isValid = false;
    } else {
      setConfirmPasswordError(null);
    }
    
    return isValid;
  };

  // 创建管理员处理函数
  const handleCreateAdmin = async (e: React.FormEvent) => {
    e.preventDefault();
    
    // 表单验证
    if (!validateForm()) {
      return;
    }
    
    setIsLoading(true);
    setError(null);
    setSuccess(null);

    try {
      // 调用服务器端API创建管理员
      const response = await fetch('/login/api/admin/create', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          email,
          password,
        }),
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || t("admin.create_failed"));
      }

      // 清空表单
      setEmail("");
      setPassword("");
      setConfirmPassword("");
      setSuccess(t("admin.create_success"));
    } catch (err) {
      setError(err instanceof Error ? err.message : t("admin.unknown_error"));
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="mx-auto flex w-full flex-col justify-center space-y-6 sm:w-[350px]">
      {/* 返回按钮 */}
      <div className="absolute top-4 left-4">
        <Link href="/login">
          <Button variant="ghost" size="icon" className="h-8 w-8" aria-label={t("common.back")}>
            <ArrowLeft className="h-4 w-4" />
          </Button>
        </Link>
      </div>
      
      <div className="flex flex-col space-y-2 text-center">
        <h1 className="text-2xl font-semibold tracking-tight">
          {t("admin.create_title")}
        </h1>
        <p className="text-sm text-muted-foreground">
          {t("admin.create_description")}
        </p>
      </div>
      
      <div className="grid gap-6">
        <form onSubmit={handleCreateAdmin}>
          <div className="grid gap-4">
            <div className="grid gap-2">
              <Label htmlFor="admin-email">{t("admin.email_label")}</Label>
              <Input
                id="admin-email"
                placeholder="admin@example.com"
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
            
            <div className="grid gap-2">
              <Label htmlFor="admin-password">{t("admin.password_label")}</Label>
              <Input
                id="admin-password"
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
              <Label htmlFor="admin-confirm-password">{t("admin.confirm_password")}</Label>
              <Input
                id="admin-confirm-password"
                type="password"
                autoCapitalize="none"
                autoComplete="new-password"
                disabled={isLoading}
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
              />
              {confirmPasswordError && (
                <p className="text-xs text-destructive">{confirmPasswordError}</p>
              )}
            </div>
            
            {error && (
              <div className="text-sm text-destructive">{error}</div>
            )}
            
            {success && (
              <div className="text-sm text-green-600">{success}</div>
            )}
            
            <div className="flex gap-4">
              <Button 
                disabled={isLoading} 
                className="bg-red-600 hover:bg-red-700 text-white flex-1"
                type="submit"
              >
                {isLoading ? t("common.processing") : t("admin.create_button")}
              </Button>
              
              <Link href="/login" className="flex-1">
                <Button 
                  variant="outline" 
                  className="w-full"
                  type="button"
                  disabled={isLoading}
                >
                  {t("common.back_to_login")}
                </Button>
              </Link>
            </div>
          </div>
        </form>
      </div>
    </div>
  );
} 