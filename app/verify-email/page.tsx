import Link from "next/link";
import { Button } from "@/components/ui/button";

export default function VerifyEmailPage() {
  return (
    <div className="container flex h-screen w-screen flex-col items-center justify-center">
      <div className="mx-auto flex w-full flex-col justify-center space-y-6 sm:w-[350px]">
        <div className="flex flex-col space-y-2 text-center">
          <h1 className="text-2xl font-semibold tracking-tight">验证您的邮箱</h1>
          <p className="text-sm text-muted-foreground">
            我们已向您的邮箱发送了一封验证邮件，请检查您的收件箱并点击邮件中的链接完成注册。
          </p>
        </div>
        <Button asChild variant="outline">
          <Link href="/login">返回登录</Link>
        </Button>
      </div>
    </div>
  );
} 