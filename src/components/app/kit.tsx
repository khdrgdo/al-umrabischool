import React, { isValidElement, createElement, type ReactNode } from "react";
import { Label } from "@/components/ui/label";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import { Filter, RotateCcw, Inbox } from "lucide-react";

export function PageHead({
  title,
  sub,
  actions,
}: {
  title: string;
  sub?: ReactNode;
  actions?: ReactNode;
}) {
  return (
    <header className="flex flex-wrap items-center justify-between gap-4 pb-4 mb-6 border-b border-border">
      <div>
        <h1 className="text-2xl md:text-3xl font-bold tracking-tight text-foreground">{title}</h1>
        {sub && <div className="text-xs md:text-sm text-muted-foreground mt-1 flex items-center gap-2">{sub}</div>}
      </div>
      {actions && <div className="flex flex-wrap items-center gap-2">{actions}</div>}
    </header>
  );
}

export const PageHeader = PageHead;

export function FilterPanel({
  title = "خيارات التصفية",
  onReset,
  children,
  className,
}: {
  title?: string;
  onReset?: () => void;
  children: ReactNode;
  className?: string;
}) {
  return (
    <div className={cn("filter-surface mb-6", className)}>
      <div className="flex items-center justify-between pb-3 mb-4 border-b border-border/60">
        <div className="flex items-center gap-2 text-xs font-semibold text-foreground">
          <Filter className="h-3.5 w-3.5 text-primary" />
          <span>{title}</span>
        </div>
        {onReset && (
          <Button
            variant="ghost"
            size="sm"
            onClick={onReset}
            className="h-7 px-2 text-xs text-muted-foreground hover:text-foreground flex items-center gap-1.5"
          >
            <RotateCcw className="h-3 w-3" />
            <span>مسح التصفية</span>
          </Button>
        )}
      </div>
      <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-3 md:gap-4">
        {children}
      </div>
    </div>
  );
}

export function Field({
  label,
  children,
  className,
}: {
  label: string;
  children: ReactNode;
  className?: string;
}) {
  return (
    <div className={cn("space-y-1.5", className)}>
      <Label className="text-xs text-muted-foreground font-medium block">{label}</Label>
      {children}
    </div>
  );
}

export function Empty({
  title = "لا توجد بيانات",
  children,
}: {
  title?: string;
  children?: ReactNode;
}) {
  return (
    <div className="py-12 px-4 text-center flex flex-col items-center justify-center">
      <div className="h-10 w-10 rounded-full bg-muted flex items-center justify-center mb-3 text-muted-foreground">
        <Inbox className="h-5 w-5 opacity-60" />
      </div>
      <div className="text-sm font-medium text-foreground">{title}</div>
      {children && <div className="text-xs text-muted-foreground mt-1 max-w-sm">{children}</div>}
    </div>
  );
}

export function Stat({
  label,
  value,
  note,
  sub,
  icon,
  variant = "default",
}: {
  label: string;
  value: ReactNode;
  note?: ReactNode;
  sub?: ReactNode;
  icon?: any;
  variant?: "default" | "primary" | "success" | "warning";
}) {
  const accentBorder = {
    default: "border-border",
    primary: "border-primary/40",
    success: "border-emerald-500/40",
    warning: "border-rose-500/40",
  }[variant];

  let renderedIcon = icon;
  if (icon && !isValidElement(icon)) {
    try {
      renderedIcon = createElement(icon, { className: "h-4 w-4" });
    } catch {
      renderedIcon = null;
    }
  }

  return (
    <div className={cn("card-surface p-4 md:p-5 flex flex-col justify-between transition hover:shadow-sm", accentBorder)}>
      <div className="flex items-center justify-between gap-2">
        <span className="text-xs font-medium text-muted-foreground">{label}</span>
        {renderedIcon && <div className="text-muted-foreground/70">{renderedIcon}</div>}
      </div>
      <div className="my-2">
        <div className="text-2xl md:text-3xl font-bold tabular-nums text-foreground tracking-tight">{value}</div>
      </div>
      {(note || sub) && <div className="text-xs text-muted-foreground mt-0.5">{note ?? sub}</div>}
    </div>
  );
}

export const StatCard = Stat;

export const STATUS_LABEL: Record<string, string> = {
  active: "منتظم",
  transferred_out: "منقول",
  withdrawn: "منسحب",
  graduated: "متخرج",
  suspended: "موقوف",
};

export const ENROLL_TYPE: Record<string, string> = {
  new: "مستجد",
  transfer_in: "منقول إلينا",
  continuing: "منقول من صف سابق",
};

export const WEEKDAYS = ["الأحد", "الإثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة", "السبت"];

export function StatusMark({ status }: { status: string }) {
  const pillStyle = {
    active: "bg-emerald-50 text-emerald-700 border-emerald-200/80",
    transferred_out: "bg-rose-50 text-rose-700 border-rose-200/80",
    withdrawn: "bg-rose-50 text-rose-700 border-rose-200/80",
    graduated: "bg-indigo-50 text-indigo-700 border-indigo-200/80",
    suspended: "bg-amber-50 text-amber-700 border-amber-200/80",
  }[status] ?? "bg-slate-50 text-slate-700 border-slate-200/80";

  return (
    <span
      className={cn(
        "inline-flex items-center px-2.5 py-0.5 text-xs font-medium rounded-full border",
        pillStyle
      )}
    >
      {STATUS_LABEL[status] ?? status}
    </span>
  );
}

