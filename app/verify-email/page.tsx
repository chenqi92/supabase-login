"use client";

import Link from "next/link";
import { Button } from "@/components/ui/button";
import { useI18n } from "@/components/providers/i18n-provider";
import { LanguageSwitcher } from "@/components/auth/language-switcher";

export default function VerifyEmailPage() {
  const { t } = useI18n();
  
  return (
    <div className="container flex h-screen w-screen flex-col items-center justify-center">
      <div className="absolute top-4 right-4">
        <LanguageSwitcher />
      </div>
      <div className="mx-auto flex w-full flex-col justify-center space-y-6 sm:w-[350px]">
        <div className="flex flex-col space-y-2 text-center">
          <h1 className="text-2xl font-semibold tracking-tight">
            {t("auth.verify_email")}
          </h1>
          <p className="text-sm text-muted-foreground">
            {t("auth.verify_email_instructions")}
          </p>
        </div>
        <Button asChild variant="outline">
          <Link href="/login">{t("auth.back_to_login")}</Link>
        </Button>
      </div>
    </div>
  );
} 