"use client";

import { createContext, useContext, useEffect, useState } from "react";

// 支持的语言
export type Locale = "zh" | "en";

// 语言上下文类型
type I18nContextType = {
  locale: Locale;
  setLocale: (locale: Locale) => void;
  t: (key: string) => string;
};

// 创建国际化上下文
const I18nContext = createContext<I18nContextType | null>(null);

// 翻译字典
const translations: Record<Locale, Record<string, string>> = {
  zh: {
    "auth.signin": "登录",
    "auth.signup": "注册",
    "auth.email": "邮箱",
    "auth.username_or_email": "用户名或邮箱",
    "auth.username": "用户名",
    "auth.password": "密码",
    "auth.confirm_password": "确认密码",
    "auth.forgot_password": "忘记密码?",
    "auth.continue_with": "或者使用第三方登录",
    "auth.github": "GitHub 登录",
    "auth.google": "Google 登录",
    "auth.already_have_account": "已经有账号?",
    "auth.no_account": "还没有账号?",
    "auth.reset_password": "重置密码",
    "auth.reset_password_instructions": "我们会发送一封邮件给您，以便重置密码。",
    "auth.back_to_login": "返回登录",
    "auth.reset_link_sent": "密码重置链接已发送",
    "auth.password_mismatch": "密码不匹配",
    "auth.password_requirements": "密码至少需要8个字符",
    "auth.invalid_email": "无效的邮箱格式",
    "auth.invalid_email_format": "邮箱格式不正确",
    "auth.invalid_username": "用户名不存在",
    "auth.invalid_username_format": "用户名格式不正确，只能包含字母、数字、下划线、短横线、点和中文字符",
    "auth.required_field": "必填字段",
    "auth.verify_email": "验证您的邮箱",
    "auth.verify_email_instructions": "我们已向您的邮箱发送了一封验证邮件，请检查您的收件箱并点击邮件中的链接完成注册。",
    "auth.update_password": "更新密码",
    "auth.update_password_instructions": "请输入您的新密码",
    "common.loading": "加载中...",
    "common.error": "错误",
    "common.success": "成功",
    "common.cancel": "取消",
    "common.submit": "提交",
    "common.language": "语言",
    "common.chinese": "中文",
    "common.english": "English",
  },
  en: {
    "auth.signin": "Sign In",
    "auth.signup": "Sign Up",
    "auth.email": "Email",
    "auth.username_or_email": "Username or Email",
    "auth.username": "Username",
    "auth.password": "Password",
    "auth.confirm_password": "Confirm Password",
    "auth.forgot_password": "Forgot password?",
    "auth.continue_with": "Or continue with",
    "auth.github": "Continue with GitHub",
    "auth.google": "Continue with Google",
    "auth.already_have_account": "Already have an account?",
    "auth.no_account": "Don't have an account?",
    "auth.reset_password": "Reset Password",
    "auth.reset_password_instructions": "We'll send you an email with a reset link.",
    "auth.back_to_login": "Back to login",
    "auth.reset_link_sent": "Reset link sent",
    "auth.password_mismatch": "Passwords do not match",
    "auth.password_requirements": "Password must be at least 8 characters",
    "auth.invalid_email": "Invalid email format",
    "auth.invalid_email_format": "Invalid email format",
    "auth.invalid_username": "Username not found",
    "auth.invalid_username_format": "Username format is invalid, can only contain letters, numbers, underscores, hyphens, dots and Chinese characters",
    "auth.required_field": "This field is required",
    "auth.verify_email": "Verify Your Email",
    "auth.verify_email_instructions": "We've sent a verification email to your inbox. Please check your email and click the link to complete registration.",
    "auth.update_password": "Update Password",
    "auth.update_password_instructions": "Please enter your new password",
    "common.loading": "Loading...",
    "common.error": "Error",
    "common.success": "Success",
    "common.cancel": "Cancel",
    "common.submit": "Submit",
    "common.language": "Language",
    "common.chinese": "中文",
    "common.english": "English",
  }
};

// i18n 提供者组件
export function I18nProvider({ children }: { children: React.ReactNode }) {
  // 默认语言设置为中文
  const [locale, setLocale] = useState<Locale>("zh");

  // 检查浏览器首选语言
  useEffect(() => {
    const browserLang = navigator.language;
    if (browserLang.startsWith("en")) {
      setLocale("en");
    }
    // 尝试从 localStorage 恢复之前设置的语言
    const savedLocale = localStorage.getItem("locale") as Locale;
    if (savedLocale && (savedLocale === "zh" || savedLocale === "en")) {
      setLocale(savedLocale);
    }
  }, []);

  // 当语言更改时，保存到 localStorage
  useEffect(() => {
    localStorage.setItem("locale", locale);
    document.documentElement.lang = locale;
  }, [locale]);

  // 翻译函数
  const t = (key: string): string => {
    return translations[locale][key] || key;
  };

  return (
    <I18nContext.Provider value={{ locale, setLocale, t }}>
      {children}
    </I18nContext.Provider>
  );
}

// 使用 i18n 的自定义 hook
export function useI18n() {
  const context = useContext(I18nContext);
  if (!context) {
    throw new Error("useI18n must be used within an I18nProvider");
  }
  return context;
} 