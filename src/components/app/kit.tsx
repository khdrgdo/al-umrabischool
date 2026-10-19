import type { ReactNode } from "react";
import { Label } from "@/components/ui/label";
import { cn } from "@/lib/utils";

export function PageHead({ title, sub, actions }: { title: string; sub?: ReactNode; actions?: ReactNode }) {
  return (
    <header className="flex flex-wrap items-end justify-between gap-3 border-b-2 border-ink pb-3 mb-6">
      <div>
        <h1 className="text-3xl md:text-4xl leading-tight">{title}</h1>
        {sub && <div className="text-sm text-muted-foreground mt-1">{sub}</div>}
      </div>
      {actions && <div className="flex flex-wrap gap-2">{actions}</div>}
    </header>
  );
}

export function Field({ label, children, className }: { label: string; children: ReactNode; className?: string }) {
  return (
    <div className={cn("space-y-1", className)}>
      <Label className="text-xs text-muted-foreground font-normal">{label}</Label>
      {children}
    </div>
  );
}

export function Empty({ children }: { children: ReactNode }) {
  return <div className="py-10 text-center text-muted-foreground text-sm">{children}</div>;
}

export function Stat({ label, value, note }: { label: string; value: ReactNode; note?: ReactNode }) {
  return (
    <div className="border-s-2 border-ink ps-3">
      <div className="text-xs text-muted-foreground">{label}</div>
      <div className="font-display text-3xl leading-tight">{value}</div>
      {note && <div className="text-xs text-muted-foreground">{note}</div>}
    </div>
  );
}

export const STATUS_LABEL: Record<string, string> = {
  active: "منتظم", transferred_out: "منقول", withdrawn: "منسحب", graduated: "متخرج", suspended: "موقوف",
};
export const ENROLL_TYPE: Record<string, string> = { new: "مستجد", transfer_in: "منقول إلينا", continuing: "منقول من صف سابق" };
export const WEEKDAYS = ["الأحد", "الإثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة", "السبت"];

export function StatusMark({ status }: { status: string }) {
  return (
    <span className={cn("stamp", status === "active" ? "text-ok" : "text-stamp")}>{STATUS_LABEL[status] ?? status}</span>
  );
}
