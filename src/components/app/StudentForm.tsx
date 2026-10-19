import { useState } from "react";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";
import { Field } from "./kit";

export type StudentInput = {
  student_number: string; full_name: string; gender: string | null; birth_date: string | null; national_id: string | null;
  address: string | null; guardian_name: string | null; guardian_relation: string | null; guardian_phone: string | null;
  previous_school: string | null; notes: string | null;
};

export const emptyStudent: StudentInput = {
  student_number: "", full_name: "", gender: null, birth_date: null, national_id: null, address: null,
  guardian_name: null, guardian_relation: null, guardian_phone: null, previous_school: null, notes: null,
};

export function StudentForm({ initial, onSubmit, busy, submitLabel, extra }: {
  initial: StudentInput; onSubmit: (v: StudentInput) => void; busy?: boolean; submitLabel: string; extra?: React.ReactNode;
}) {
  const [v, setV] = useState<StudentInput>(initial);
  const set = (k: keyof StudentInput) => (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) =>
    setV({ ...v, [k]: e.target.value === "" ? null : e.target.value });
  return (
    <form className="space-y-5" onSubmit={(e) => { e.preventDefault(); onSubmit(v); }}>
      <fieldset className="grid sm:grid-cols-2 gap-3">
        <legend className="text-sm font-medium mb-2">بيانات الطالب</legend>
        <Field label="الاسم رباعيًا *" className="sm:col-span-2"><Input value={v.full_name} onChange={set("full_name")} required /></Field>
        <Field label="الرقم المدرسي *"><Input value={v.student_number} onChange={set("student_number")} required dir="ltr" /></Field>
        <Field label="النوع">
          <select className="field-select w-full" value={v.gender ?? ""} onChange={set("gender")}>
            <option value="">—</option><option value="male">ذكر</option><option value="female">أنثى</option>
          </select>
        </Field>
        <Field label="تاريخ الميلاد"><Input type="date" value={v.birth_date ?? ""} onChange={set("birth_date")} /></Field>
        <Field label="الرقم الوطني"><Input value={v.national_id ?? ""} onChange={set("national_id")} dir="ltr" /></Field>
        <Field label="السكن" className="sm:col-span-2"><Input value={v.address ?? ""} onChange={set("address")} /></Field>
        <Field label="المدرسة السابقة" className="sm:col-span-2"><Input value={v.previous_school ?? ""} onChange={set("previous_school")} /></Field>
      </fieldset>
      <fieldset className="grid sm:grid-cols-3 gap-3">
        <legend className="text-sm font-medium mb-2">ولي الأمر</legend>
        <Field label="الاسم" className="sm:col-span-3"><Input value={v.guardian_name ?? ""} onChange={set("guardian_name")} /></Field>
        <Field label="صلة القرابة"><Input value={v.guardian_relation ?? ""} onChange={set("guardian_relation")} placeholder="الأب، الأم…" /></Field>
        <Field label="الهاتف" className="sm:col-span-2"><Input value={v.guardian_phone ?? ""} onChange={set("guardian_phone")} dir="ltr" /></Field>
      </fieldset>
      <Field label="ملاحظات"><Textarea rows={2} value={v.notes ?? ""} onChange={set("notes")} /></Field>
      {extra}
      <Button type="submit" disabled={busy}>{submitLabel}</Button>
    </form>
  );
}
