import { type ClassValue, clsx } from "clsx";
import { twMerge } from "tailwind-merge";

/**
 * 结合 clsx 和 tailwind-merge
 * 用于合并 tailwind 类名
 */
export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

/**
 * 验证邮箱格式
 */
export function isValidEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

/**
 * 校验是否为邮箱或用户名
 */
export function isEmailOrUsername(input: string): 'email' | 'username' {
  return input.includes('@') ? 'email' : 'username';
}

/**
 * 验证用户名格式
 * 只允许字母、数字和下划线
 * 
 * 注意：此正则表达式已更新，修复了英文无法通过校验的问题
 */
export function isValidUsername(username: string): boolean {
  // 确保用户名字段不为空
  if (!username || username.trim() === "") {
    return false;
  }
  
  // 检查是否只包含字母、数字和下划线
  const usernameRegex = /^[a-zA-Z0-9_]+$/;
  return usernameRegex.test(username);
}

/**
 * 校验密码强度
 * 至少8个字符
 */
export function isValidPassword(password: string): boolean {
  return password.length >= 8;
} 