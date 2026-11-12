import { z } from "zod";

export const whatsappSchema = z.string().trim().regex(/^[0-9]{8,15}$/, "أدخل من 8 إلى 15 رقماً دولياً دون +");
export const reportStatusSchema = z.enum(["new", "seen", "resolved"]);
export const optionalFeeSchema = z.object({
  grade_id: z.string().uuid("اختر الصف"),
  fee_type_id: z.string().uuid().or(z.literal("")),
  new_type: z.string().trim().max(100),
  amount: z.coerce.number().finite().positive("أدخل مبلغاً أكبر من صفر"),
  due_date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).or(z.literal("")),
  description: z.string().trim().max(1000),
}).refine((v) => !!v.fee_type_id || !!v.new_type, "اختر نوع الرسم أو اكتب اسماً جديداً");

export type TargetSelection = { grades: string[]; sections: string[]; students: string[] };
export type TargetRow = { announcement_id: string; grade_id: string | null; section_id: string | null; student_id: string | null };
export const emptyTargets = (): TargetSelection => ({ grades: [], sections: [], students: [] });
export function targetRows(id: string, selection: TargetSelection): TargetRow[] {
  z.string().uuid().parse(id);
  const rows: TargetRow[] = [];
  for (const [key, ids] of [["grade_id", selection.grades], ["section_id", selection.sections], ["student_id", selection.students]] as const) {
    for (const value of new Set(ids)) {
      z.string().uuid().parse(value);
      rows.push({ announcement_id: id, grade_id: null, section_id: null, student_id: null, [key]: value });
    }
  }
  return rows;
}

export function assignmentChanges(existing: string[], selected: string[]) {
  return { add: [...new Set(selected)].filter((id) => !existing.includes(id)), remove: [...new Set(existing)].filter((id) => !selected.includes(id)) };
}
export function expectedOptionalTotal(amount: number, assignedStudents: number) { return amount * assignedStudents; }
export function paidUnassignments(removed: string[], payments: { student_id: string }[]) {
  return removed.filter((id) => payments.some((p) => p.student_id === id));
}
export function khartoumReportTime(value: string) {
  return new Intl.DateTimeFormat("ar-SD", { timeZone: "Africa/Khartoum", dateStyle: "short", timeStyle: "short" }).format(new Date(value));
}

/** Page through staff lists rather than silently accepting the API's row limit. */
export async function readAll<T>(read: (from: number, to: number) => PromiseLike<{ data: T[] | null; error: unknown }>): Promise<T[]> {
  const rows: T[] = [];
  for (let from = 0; ; from += 500) {
    const result = await read(from, from + 499);
    if (result.error) throw result.error;
    rows.push(...(result.data ?? []));
    if ((result.data?.length ?? 0) < 500) return rows;
  }
}

/** Keep an announcement hidden throughout multi-request target replacement. Failure leaves a draft, never a broadcast. */
export async function replaceAnnouncementTargets(port: {
  hide: () => Promise<void>; replace: () => Promise<void>; finish: () => Promise<void>;
}) {
  await port.hide();
  await port.replace();
  await port.finish();
}