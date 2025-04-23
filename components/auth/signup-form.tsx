"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { createClientComponentClient } from "@supabase/auth-helpers-nextjs";
import { GithubIcon } from "lucide-react";

import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { useI18n } from "@/components/providers/i18n-provider";
import { LanguageSwitcher } from "@/components/auth/language-switcher";
import { isValidEmail, isValidPassword, isValidUsername } from "@/lib/utils";

export function SignupForm() {
  const router = useRouter();
  const supabase = createClientComponentClient();
  const { t } = useI18n();
  
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [email, setEmail] = useState("");
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  
  // 验证错误
  const [emailError, setEmailError] = useState<string | null>(null);
  const [usernameError, setUsernameError] = useState<string | null>(null);
  const [passwordError, setPasswordError] = useState<string | null>(null);
  const [confirmPasswordError, setConfirmPasswordError] = useState<string | null>(null);
  
  const validateForm = () => {
    let isValid = true;
    
    // 验证邮箱
    if (!email) {
      setEmailError(t("auth.required_field"));
      isValid = false;
    } else if (!isValidEmail(email)) {
      setEmailError(t("auth.invalid_email"));
      isValid = false;
    } else {
      setEmailError(null);
    }
    
    // 验证用户名
    if (!username) {
      setUsernameError(t("auth.required_field"));
      isValid = false;
    } else if (!isValidUsername(username)) {
      setUsernameError(t("auth.invalid_username"));
      isValid = false;
    } else {
      setUsernameError(null);
    }
    
    // 验证密码
    if (!password) {
      setPasswordError(t("auth.required_field"));
      isValid = false;
    } else if (!isValidPassword(password)) {
      setPasswordError(t("auth.password_requirements"));
      isValid = false;
    } else {
      setPasswordError(null);
    }
    
    // 验证确认密码
    if (password !== confirmPassword) {
      setConfirmPasswordError(t("auth.password_mismatch"));
      isValid = false;
    } else {
      setConfirmPasswordError(null);
    }
    
    return isValid;
  };

  const handleSignUp = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!validateForm()) {
      return;
    }
    
    setIsLoading(true);
    setError(null);

    // 1. 注册用户
    const { data: authData, error: authError } = await supabase.auth.signUp({
      email,
      password,
      options: {
        emailRedirectTo: `https://database.allbs.cn/login/auth/v1/callback`,
        data: {
          username, // 将用户名存储在用户元数据中
        }
      },
    });

    if (authError) {
      setError(authError.message);
      setIsLoading(false);
      return;
    }

    // 2. 创建用户资料，将用户名与邮箱关联存储
    if (authData?.user) {
      const { error: profileError } = await supabase
        .from('profiles')
        .insert([
          { 
            id: authData.user.id,
            email,
            username,
            created_at: new Date().toISOString()
          }
        ]);

      if (profileError) {
        // 虽然验证邮件已发送，但存储用户名失败
        setError(profileError.message);
        setIsLoading(false);
        return;
      }
    }

    router.push("/verify-email");
  };

  const handleGithubSignUp = async () => {
    setIsLoading(true);
    setError(null);

    const { error } = await supabase.auth.signInWithOAuth({
      provider: 'github',
      options: {
        redirectTo: `https://database.allbs.cn/login/auth/v1/callback`,
      },
    });

    if (error) {
      setError(error.message);
      setIsLoading(false);
    }
  };

  const handleGoogleSignUp = async () => {
    setIsLoading(true);
    setError(null);

    const { error } = await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: {
        redirectTo: `https://database.allbs.cn/login/auth/v1/callback`,
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
          {t("auth.signup")}
        </h1>
        <p className="text-sm text-muted-foreground">
          {t("auth.already_have_account")} <Link href="/login" className="underline underline-offset-4 hover:text-primary">{t("auth.signin")}</Link>
        </p>
      </div>
      <div className="absolute top-4 right-4">
        <LanguageSwitcher />
      </div>
      <div className="grid gap-6">
        <form onSubmit={handleSignUp}>
          <div className="grid gap-4">
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
            <div className="grid gap-2">
              <Label htmlFor="username">{t("auth.username")}</Label>
              <Input
                id="username"
                placeholder="username"
                type="text"
                autoCapitalize="none"
                autoComplete="username"
                autoCorrect="off"
                disabled={isLoading}
                value={username}
                onChange={(e) => setUsername(e.target.value)}
              />
              {usernameError && (
                <p className="text-xs text-destructive">{usernameError}</p>
              )}
            </div>
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
              <Label htmlFor="confirm-password">{t("auth.confirm_password")}</Label>
              <Input
                id="confirm-password"
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
            <Button type="submit" disabled={isLoading} className="bg-supabase hover:bg-supabase/90 text-white">
              {isLoading ? t("common.loading") : t("auth.signup")}
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
          <Button 
            variant="outline" 
            type="button"
            disabled={isLoading}
            onClick={handleGithubSignUp}
            className="flex gap-2"
          >
            <GithubIcon className="h-4 w-4" />
            {t("auth.github")}
          </Button>
          <Button
            variant="outline"
            type="button"
            disabled={isLoading}
            onClick={handleGoogleSignUp}
            className="flex gap-2"
          >
            <svg xmlns="http://www.w3.org/2000/svg" height="16" width="16" viewBox="0 0 488 512">
              <path d="M488 261.8C488 403.3 391.1 504 248 504 110.8 504 0 393.2 0 256S110.8 8 248 8c66.8 0 123 24.5 166.3 64.9l-67.5 64.9C258.5 52.6 94.3 116.6 94.3 256c0 86.5 69.1 156.6 153.7 156.6 98.2 0 135-70.4 140.8-106.9H248v-85.3h236.1c2.3 12.7 3.9 24.9 3.9 41.4z"/>
            </svg>
            {t("auth.google")}
          </Button>
        </div>
      </div>
    </div>
  );
} 