import { useState, useMemo } from "react";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";
import { Field } from "./kit";
import {
  FileCheck2,
  AlertTriangle,
  ArrowRightLeft,
  UserPlus,
  RotateCcw,
  ShieldAlert,
  GraduationCap,
  Building,
} from "lucide-react";

export type AdmissionWorkflow = "new" | "transfer_in" | "continuing" | "re_enrollment" | "transfer_out";

export interface StudentAdmissionDetails {
  workflow: AdmissionWorkflow;
  has_intermediate_cert: boolean;
  has_prior_term_report: boolean;
  has_birth_cert: boolean;
  has_guardian_id: boolean;
  waiver_reason: string;
  previous_grade?: string | null;
  previous_term?: string | null;
}

export type StudentInput = {
  full_name: string;
  gender: string | null;
  birth_date: string | null;
  national_id: string | null;
  address: string | null;
  guardian_name: string | null;
  guardian_relation: string | null;
  guardian_phone: string | null;
  previous_school: string | null;
  notes: string | null;
  admission_details?: StudentAdmissionDetails;
};

export const emptyStudent: StudentInput = {
  full_name: "",
  gender: null,
  birth_date: null,
  national_id: null,
  address: null,
  guardian_name: null,
  guardian_relation: null,
  guardian_phone: null,
  previous_school: null,
  notes: null,
  admission_details: {
    workflow: "new",
    has_intermediate_cert: false,
    has_prior_term_report: false,
    has_birth_cert: false,
    has_guardian_id: false,
    waiver_reason: "",
    previous_grade: null,
    previous_term: null,
  },
};

export interface StudentFormProps {
  studentNumber?: string;
  initial: StudentInput;
  onSubmit: (v: StudentInput) => void;
  busy?: boolean;
  submitLabel: string;
  extra?: React.ReactNode;
  mode?: "create" | "edit";
  existingStudents?: Array<{ id: string; full_name: string; national_id: string | null; student_number?: string }>;
  onWorkflowChange?: (workflow: AdmissionWorkflow) => void;
}

export function StudentForm({
  initial,
  onSubmit,
  busy,
  submitLabel,
  extra,
  studentNumber,
  mode = "create",
  existingStudents = [],
  onWorkflowChange,
}: StudentFormProps) {
  const [v, setV] = useState<StudentInput>(initial);
  const [admission, setAdmission] = useState<StudentAdmissionDetails>(
    initial.admission_details ?? {
      workflow: "new",
      has_intermediate_cert: false,
      has_prior_term_report: false,
      has_birth_cert: false,
      has_guardian_id: false,
      waiver_reason: "",
      previous_grade: null,
      previous_term: null,
    }
  );

  const updateWorkflow = (wf: AdmissionWorkflow) => {
    setAdmission((a) => ({ ...a, workflow: wf }));
    onWorkflowChange?.(wf);
  };

  const set = (k: keyof StudentInput) => (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) =>
    setV((prev) => ({ ...prev, [k]: e.target.value === "" ? null : e.target.value }));

  // Duplicate identity warning check
  const duplicateWarning = useMemo(() => {
    if (mode === "edit" || !v.full_name.trim()) return null;
    const nameMatch = existingStudents.find(
      (s) => s.full_name.trim().toLowerCase() === v.full_name.trim().toLowerCase()
    );
    if (nameMatch) {
      return `تنبيه: مسجل مسبقاً طالب بنفس الاسم: "${nameMatch.full_name}" (رقم القيد: ${nameMatch.student_number ?? "—"}). تأكد من عدم التكرار.`;
    }
    if (v.national_id && v.national_id.trim().length > 4) {
      const nidMatch = existingStudents.find(
        (s) => s.national_id && s.national_id.trim() === v.national_id?.trim()
      );
      if (nidMatch) {
        return `تحذير: الرقم الوطني "${v.national_id}" مسجل مسبقاً للطالب: "${nidMatch.full_name}".`;
      }
    }
    return null;
  }, [v.full_name, v.national_id, existingStudents, mode]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    // Secondary intermediate cert validation
    if (mode === "create") {
      if (!admission.has_intermediate_cert && !admission.waiver_reason.trim()) {
        alert("شهادة المرحلة المتوسطة إلزامية للقبول الثانوي، أو يجب إدخال سبب الاستثناء الإداري المعتمد.");
        return;
      }
      if (admission.workflow === "transfer_in" && !admission.has_prior_term_report && !admission.waiver_reason.trim()) {
        alert("تقرير درجات الفصل السابق مطلوب للطلاب المنقولين، أو يجب إدخال سبب الاستثناء الإداري المعتمد.");
        return;
      }
    }

    onSubmit({
      ...v,
      previous_school: admission.workflow === "transfer_in" ? (v.previous_school || "مدرسة سابقة") : v.previous_school,
      admission_details: admission,
    });
  };

  return (
    <form className="space-y-5" onSubmit={handleSubmit}>
      {mode === "create" && (
        <div className="space-y-3 pb-3 border-b border-border">
          <label className="text-xs font-semibold text-muted-foreground block">
            مسار ونوع القبول المدرسي
          </label>
          <div className="grid grid-cols-3 gap-2">
            <button
              type="button"
              onClick={() => updateWorkflow("new")}
              className={`p-2.5 rounded-lg border text-xs text-start font-medium transition-colors flex items-center gap-2 ${
                admission.workflow === "new"
                  ? "border-primary bg-primary/5 text-primary font-semibold"
                  : "border-border hover:bg-muted text-muted-foreground"
              }`}
            >
              <UserPlus className="h-4 w-4 shrink-0" />
              <span>مستجد (ثانوي جديد)</span>
            </button>

            <button
              type="button"
              onClick={() => updateWorkflow("transfer_in")}
              className={`p-2.5 rounded-lg border text-xs text-start font-medium transition-colors flex items-center gap-2 ${
                admission.workflow === "transfer_in"
                  ? "border-primary bg-primary/5 text-primary font-semibold"
                  : "border-border hover:bg-muted text-muted-foreground"
              }`}
            >
              <ArrowRightLeft className="h-4 w-4 shrink-0" />
              <span>طالب منقول من مدرسة</span>
            </button>

            <button
              type="button"
              onClick={() => updateWorkflow("continuing")}
              className={`p-2.5 rounded-lg border text-xs text-start font-medium transition-colors flex items-center gap-2 ${
                admission.workflow === "continuing"
                  ? "border-primary bg-primary/5 text-primary font-semibold"
                  : "border-border hover:bg-muted text-muted-foreground"
              }`}
            >
              <RotateCcw className="h-4 w-4 shrink-0" />
              <span>استمرار قيد / إعادة تسجيل</span>
            </button>
          </div>
        </div>
      )}

      {/* Duplicate warning notification */}
      {duplicateWarning && (
        <div className="p-3 rounded-lg bg-amber-500/10 border border-amber-500/30 text-amber-700 dark:text-amber-400 text-xs flex items-start gap-2">
          <AlertTriangle className="h-4 w-4 shrink-0 mt-0.5" />
          <span>{duplicateWarning}</span>
        </div>
      )}

      <fieldset className="grid sm:grid-cols-2 gap-3">
        <legend className="text-sm font-semibold mb-2 text-foreground">بيانات الطالب الشخصية</legend>
        <Field label="الاسم رباعيًا *" className="sm:col-span-2">
          <Input value={v.full_name} onChange={set("full_name")} required placeholder="مثال: محمد أحمد علي عثمان" />
        </Field>
        <Field label="الرقم المدرسي">
          <div className="h-9 flex items-center px-3 rounded-md border border-dashed text-xs text-muted-foreground font-mono" dir="ltr">
            {studentNumber ?? "يُولَّد تلقائيًا برقم مسلسل معتمد عند الحفظ"}
          </div>
        </Field>
        <Field label="النوع">
          <select className="field-select w-full text-xs" value={v.gender ?? ""} onChange={set("gender")}>
            <option value="">— حدد النوع —</option>
            <option value="male">ذكر</option>
            <option value="female">أنثى</option>
          </select>
        </Field>
        <Field label="تاريخ الميلاد">
          <Input type="date" value={v.birth_date ?? ""} onChange={set("birth_date")} className="text-xs" />
        </Field>
        <Field label="الرقم الوطني">
          <Input value={v.national_id ?? ""} onChange={set("national_id")} dir="ltr" placeholder="الرقم الوطني من 11 خانة" className="text-xs font-mono" />
        </Field>
        <Field label="عنوان السكن" className="sm:col-span-2">
          <Input value={v.address ?? ""} onChange={set("address")} placeholder="المدينة، الحي، رقم المنزل…" className="text-xs" />
        </Field>
      </fieldset>

      {/* Transfer Information */}
      {admission.workflow === "transfer_in" && (
        <fieldset className="grid sm:grid-cols-2 gap-3 p-3.5 rounded-lg bg-muted/40 border border-border">
          <legend className="text-xs font-bold text-foreground flex items-center gap-1.5 px-1">
            <Building className="h-3.5 w-3.5 text-primary" />
            بيانات الانتقال والمدرسة السابقة
          </legend>
          <Field label="المدرسة المنقول منها *" className="sm:col-span-2">
            <Input
              value={v.previous_school ?? ""}
              onChange={set("previous_school")}
              required={admission.workflow === "transfer_in"}
              placeholder="اسم المدرسة السابقة وموقعها…"
              className="text-xs"
            />
          </Field>
          <Field label="الصف السابق بالمدرسة السابقة">
            <Input
              value={admission.previous_grade ?? ""}
              onChange={(e) => setAdmission((a) => ({ ...a, previous_grade: e.target.value }))}
              placeholder="مثال: الصف الأول ثانوي"
              className="text-xs"
            />
          </Field>
          <Field label="الفصل / الفترة الدراسية المكتملة">
            <Input
              value={admission.previous_term ?? ""}
              onChange={(e) => setAdmission((a) => ({ ...a, previous_term: e.target.value }))}
              placeholder="مثال: الفصل الدراسي الأول"
              className="text-xs"
            />
          </Field>
        </fieldset>
      )}

      {/* Mandatory Admission Documents Checklist (Plan 1 Section 3) */}
      {mode === "create" && (
        <fieldset className="space-y-3 p-3.5 rounded-lg bg-card border border-border">
          <legend className="text-xs font-bold text-foreground flex items-center gap-1.5 px-1">
            <FileCheck2 className="h-4 w-4 text-primary" />
            قائمة الوثائق الإلزامية والتحقق (Admissions Checklist)
          </legend>

          <div className="space-y-2.5">
            {/* 1. Intermediate School Certificate */}
            <label className="flex items-start gap-2.5 p-2 rounded-md hover:bg-muted/50 cursor-pointer border border-transparent hover:border-border transition-colors">
              <input
                type="checkbox"
                checked={admission.has_intermediate_cert}
                onChange={(e) => setAdmission((a) => ({ ...a, has_intermediate_cert: e.target.checked }))}
                className="mt-0.5 rounded border-input text-primary focus:ring-primary h-4 w-4"
              />
              <div className="text-xs">
                <span className="font-semibold text-foreground">
                  شهادة المرحلة المتوسطة (الأصل أو صورة موثقة) *
                </span>
                <p className="text-[11px] text-muted-foreground mt-0.5">
                  وثيقة إلزامية للقبول في المرحلة الثانوية للتأكد من استحقاق القيد واجتياز المرحلة السابقة.
                </p>
              </div>
            </label>

            {/* 2. Prior term report if transfer */}
            {admission.workflow === "transfer_in" && (
              <label className="flex items-start gap-2.5 p-2 rounded-md hover:bg-muted/50 cursor-pointer border border-transparent hover:border-border transition-colors">
                <input
                  type="checkbox"
                  checked={admission.has_prior_term_report}
                  onChange={(e) => setAdmission((a) => ({ ...a, has_prior_term_report: e.target.checked }))}
                  className="mt-0.5 rounded border-input text-primary focus:ring-primary h-4 w-4"
                />
                <div className="text-xs">
                  <span className="font-semibold text-foreground">
                    تقرير درجات / شهادة الفصل السابق من المدرسة السابقة *
                  </span>
                  <p className="text-[11px] text-muted-foreground mt-0.5">
                    إلزامي للطلاب المنقولين لصفوف متقدمة للتحقق من الاستمرار الأكاديمي.
                  </p>
                </div>
              </label>
            )}

            {/* 3. General verification items */}
            <div className="grid sm:grid-cols-2 gap-2 pt-1 border-t border-border/60">
              <label className="flex items-center gap-2 text-xs text-muted-foreground cursor-pointer">
                <input
                  type="checkbox"
                  checked={admission.has_birth_cert}
                  onChange={(e) => setAdmission((a) => ({ ...a, has_birth_cert: e.target.checked }))}
                  className="rounded border-input text-primary focus:ring-primary h-3.5 w-3.5"
                />
                <span>الرقم الوطني / شهادة الميلاد الأصلية</span>
              </label>

              <label className="flex items-center gap-2 text-xs text-muted-foreground cursor-pointer">
                <input
                  type="checkbox"
                  checked={admission.has_guardian_id}
                  onChange={(e) => setAdmission((a) => ({ ...a, has_guardian_id: e.target.checked }))}
                  className="rounded border-input text-primary focus:ring-primary h-3.5 w-3.5"
                />
                <span>إثبات هوية ولي الأمر ورقم الاتصال</span>
              </label>
            </div>

            {/* Waiver Reason Box if any mandatory document is missing */}
            {(!admission.has_intermediate_cert || (admission.workflow === "transfer_in" && !admission.has_prior_term_report)) && (
              <div className="mt-2.5 p-3 rounded-lg bg-amber-500/10 border border-amber-500/30 space-y-2">
                <div className="flex items-center gap-1.5 text-xs font-semibold text-amber-800 dark:text-amber-400">
                  <ShieldAlert className="h-4 w-4" />
                  <span>استثناء إداري معتمد (Waiver Policy)</span>
                </div>
                <p className="text-[11px] text-amber-700 dark:text-amber-300 leading-relaxed">
                  الوثائق المحددة أعلاه إلزامية بموجب اللائحة. لا يمكن إتمام التسجيل دون إرفاقها إلا بوجود استثناء معتمد من مدير المدرسة أو المشرف مع تدوين السبب الرسمي لحفظه في سجل التدقيق.
                </p>
                <Field label="سبب الاستثناء الإداري المعتمد *" className="mt-1">
                  <Input
                    required
                    placeholder="مثال: تعهد خطي من ولي الأمر بإحضار الشهادة خلال أسبوعين، أو انتقال بسبب ظروف طارئة…"
                    value={admission.waiver_reason}
                    onChange={(e) => setAdmission((a) => ({ ...a, waiver_reason: e.target.value }))}
                    className="text-xs bg-card"
                  />
                </Field>
              </div>
            )}
          </div>
        </fieldset>
      )}

      <fieldset className="grid sm:grid-cols-3 gap-3">
        <legend className="text-sm font-semibold mb-2 text-foreground">بيانات ولي الأمر</legend>
        <Field label="اسم ولي الأمر" className="sm:col-span-3">
          <Input value={v.guardian_name ?? ""} onChange={set("guardian_name")} placeholder="اسم ولي الأمر ثلاثيًا أو رباعيًا" className="text-xs" />
        </Field>
        <Field label="صلة القرابة">
          <Input value={v.guardian_relation ?? ""} onChange={set("guardian_relation")} placeholder="الأب، العم، الوالدة…" className="text-xs" />
        </Field>
        <Field label="رقم هاتف ولي الأمر" className="sm:col-span-2">
          <Input value={v.guardian_phone ?? ""} onChange={set("guardian_phone")} dir="ltr" placeholder="09XXXXXXXX أو 01XXXXXXXX" className="text-xs font-mono" />
        </Field>
      </fieldset>

      <Field label="ملاحظات إضافية">
        <Textarea rows={2} value={v.notes ?? ""} onChange={set("notes")} placeholder="أي ملاحظات صحية أو إدارية تخص الطالب…" className="text-xs" />
      </Field>

      {extra}

      <div className="pt-2 flex justify-end">
        <Button type="submit" disabled={busy} className="gap-1.5">
          {busy ? "جارٍ الحفظ والاعتماد…" : submitLabel}
        </Button>
      </div>
    </form>
  );
}
