"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { useI18n } from "@/components/providers/i18n-provider";
import { isValidEmail, isValidPassword } from "@/lib/utils";

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
      setEmailError("邮箱不能为空");
      isValid = false;
    } else if (!isValidEmail(email)) {
      setEmailError("邮箱格式无效");
      isValid = false;
    } else {
      setEmailError(null);
    }
    
    // 验证密码
    if (!password) {
      setPasswordError("密码不能为空");
      isValid = false;
    } else if (!isValidPassword(password)) {
      setPasswordError("密码必须至少8个字符");
      isValid = false;
    } else {
      setPasswordError(null);
    }
    
    // 验证确认密码
    if (password !== confirmPassword) {
      setConfirmPasswordError("两次密码不匹配");
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
        throw new Error(data.error || '创建管理员失败');
      }

      // 清空表单
      setEmail("");
      setPassword("");
      setConfirmPassword("");
      setSuccess('超级管理员创建成功');
    } catch (err) {
      setError(err instanceof Error ? err.message : '创建管理员时发生未知错误');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="mx-auto flex w-full flex-col justify-center space-y-6 sm:w-[350px]">
      <div className="flex flex-col space-y-2 text-center">
        <h1 className="text-2xl font-semibold tracking-tight">
          创建超级管理员
        </h1>
        <p className="text-sm text-muted-foreground">
          创建具有完全访问权限的超级管理员账户
        </p>
      </div>
      
      <div className="grid gap-6">
        <form onSubmit={handleCreateAdmin}>
          <div className="grid gap-4">
            <div className="grid gap-2">
              <Label htmlFor="admin-email">管理员邮箱</Label>
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
              <Label htmlFor="admin-password">管理员密码</Label>
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
              <Label htmlFor="admin-confirm-password">确认密码</Label>
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
            
            <Button 
              disabled={isLoading} 
              className="bg-red-600 hover:bg-red-700 text-white"
              type="submit"
            >
              {isLoading ? "处理中..." : "创建超级管理员"}
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
} 