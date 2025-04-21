"use client";

import * as React from "react";
import * as DropdownMenu from "@radix-ui/react-dropdown-menu";
import { useI18n } from "@/components/providers/i18n-provider";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";

export function LanguageSwitcher() {
  const { locale, setLocale, t } = useI18n();

  return (
    <DropdownMenu.Root>
      <DropdownMenu.Trigger asChild>
        <Button variant="ghost" size="sm" className="gap-2 px-2">
          <span>🌐</span>
          <span className="sr-only sm:not-sr-only">
            {locale === "zh" ? "中文" : "English"}
          </span>
        </Button>
      </DropdownMenu.Trigger>
      <DropdownMenu.Portal>
        <DropdownMenu.Content
          className={cn(
            "z-50 min-w-[8rem] overflow-hidden rounded-md border border-slate-200 bg-white p-1 shadow-md animate-in data-[side=bottom]:slide-in-from-top-2 data-[side=top]:slide-in-from-bottom-2 dark:border-slate-800 dark:bg-slate-950"
          )}
        >
          <DropdownMenu.RadioGroup value={locale} onValueChange={value => setLocale(value as "zh" | "en")}>
            <DropdownMenu.RadioItem
              value="zh"
              className={cn(
                "relative flex cursor-pointer select-none items-center rounded-sm py-1.5 px-2 text-sm font-medium outline-none transition-colors focus:bg-slate-100 focus:text-slate-900 data-[disabled]:pointer-events-none data-[disabled]:opacity-50 dark:focus:bg-slate-800 dark:focus:text-slate-50",
                locale === "zh" && "bg-slate-100 dark:bg-slate-800"
              )}
            >
              {t("common.chinese")}
            </DropdownMenu.RadioItem>
            <DropdownMenu.RadioItem
              value="en"
              className={cn(
                "relative flex cursor-pointer select-none items-center rounded-sm py-1.5 px-2 text-sm font-medium outline-none transition-colors focus:bg-slate-100 focus:text-slate-900 data-[disabled]:pointer-events-none data-[disabled]:opacity-50 dark:focus:bg-slate-800 dark:focus:text-slate-50",
                locale === "en" && "bg-slate-100 dark:bg-slate-800"
              )}
            >
              {t("common.english")}
            </DropdownMenu.RadioItem>
          </DropdownMenu.RadioGroup>
        </DropdownMenu.Content>
      </DropdownMenu.Portal>
    </DropdownMenu.Root>
  );
} 