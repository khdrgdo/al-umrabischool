import { createFileRoute } from "@tanstack/react-router";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import { useSchool, errMsg } from "@/lib/staff";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";

export const Route = createFileRoute("/_authenticated/students")({
  head: () => ({ meta: [{ title: "الطلاب — مدرسة العمرابي" }] }),
  component: Students,
});

const sel = "h-9 rounded-md border border-input bg-card px-2 text-sm";
const STATUS: Record<string, string> = {
  active: "نشط", transferred_out: "منقول", withdrawn: "منسحب", graduated: "متخرج", suspended: "موقوف",
};
const ETYPE = { new: "جديد", transfer_in: "منقول من مدرسة أخرى", continuing: "مستمر" } as const;

function Students() {
  const qc = useQueryClient();
  const { data: school } = useSchool();
  const [q, setQ] = useState("");
  const [f, setF] = useState({ number: "", name: "", gender: "", guardian: "", phone: "" });
  const [enroll, setEnroll] = useState<{ student: string; section: string; type: keyof typeof ETYPE }>({ student: "", section: "", type: "new" });

  const { data } = useQuery({
    queryKey: ["students"],
    queryFn: async () => {
      const { data: year } = await supabase.from("academic_years").select("*").eq("is_current", true).maybeSingle();
      const [students, sections, enrollments] = await Promise.all([
        supabase.from("students").select("*").order("full_name"),
        year ? supabase.from("sections").select("id,name,grade:grades(name)").eq("academic_year_id", year.id) : Promise.resolve({ data: [] }),
        year ? supabase.from("enrollments").select("student_id,section_id").eq("academic_year_id", year.id) : Promise.resolve({ data: [] }),
      ]);
      return { year, students: students.data ?? [], sections: (sections.data ?? []) as { id: string; name: string; grade: { name: string } | null }[], enrollments: (enrollments.data ?? []) as { student_id: string; section_id: string }[] };
    },
  });

  const add = useMutation({
    mutationFn: async () => {
      const { error } = await supabase.from("students").insert({
        school_id: school!.id, student_number: f.number, full_name: f.name,
        gender: f.gender || null, guardian_name: f.guardian || null, guardian_phone: f.phone || null,
      });
      if (error) throw error;
    },
    onSuccess: () => { setF({ number: "", name: "", gender: "", guardian: "", phone: "" }); qc.invalidateQueries({ queryKey: ["students"] }); toast.success("أضيف الطالب"); },
    onError: (e) => toast.error(errMsg(e)),
  });
  const doEnroll = useMutation({
    mutationFn: async () => {
      const { error } = await supabase.from("enrollments").insert({
        student_id: enroll.student, section_id: enroll.section, academic_year_id: data!.year!.id, enrollment_type: enroll.type,
      });
      if (error) throw error;
    },
    onSuccess: () => { setEnroll({ student: "", section: "", type: "new" }); qc.invalidateQueries({ queryKey: ["students"] }); toast.success("تم التسجيل في الشعبة"); },
    onError: (e) => toast.error(errMsg(e)),
  });

  const sectionLabel = (id?: string) => {
    const s = data?.sections.find((x) => x.id === id);
    return s ? `${s.grade?.name ?? ""} — ${s.name}` : undefined;
  };
  const enrolledIn = (sid: string) => data?.enrollments.find((e) => e.student_id === sid)?.section_id;
  const list = (data?.students ?? []).filter((s) => !q || s.full_name.includes(q) || s.student_number.includes(q));
  const unenrolled = (data?.students ?? []).filter((s) => s.status === "active" && !enrolledIn(s.id));

  return (
    <div className="space-y-6">
      <h1 className="text-3xl font-bold text-primary">الطلاب</h1>

      <Card className="p-4 space-y-3">
        <h2 className="font-bold">ملف طالب جديد</h2>
        <form className="grid md:grid-cols-3 gap-2" onSubmit={(e) => { e.preventDefault(); add.mutate(); }}>
          <Input placeholder="الرقم المدرسي" value={f.number} onChange={(e) => setF({ ...f, number: e.target.value })} required />
          <Input placeholder="الاسم الكامل" value={f.name} onChange={(e) => setF({ ...f, name: e.target.value })} required />
          <select className={sel} value={f.gender} onChange={(e) => setF({ ...f, gender: e.target.value })}>
            <option value="">النوع</option><option value="male">ذكر</option><option value="female">أنثى</option>
          </select>
          <Input placeholder="اسم ولي الأمر" value={f.guardian} onChange={(e) => setF({ ...f, guardian: e.target.value })} />
          <Input placeholder="هاتف ولي الأمر" dir="ltr" value={f.phone} onChange={(e) => setF({ ...f, phone: e.target.value })} />
          <Button disabled={add.isPending || !school}>حفظ</Button>
        </form>
      </Card>

      <Card className="p-4 space-y-3">
        <h2 className="font-bold">التسجيل في شعبة {data?.year ? `(${data.year.name})` : ""}</h2>
        {!data?.year ? (
          <p className="text-sm text-muted-foreground">حدد السنة الدراسية الحالية أولًا من صفحة الهيكل الدراسي.</p>
        ) : (
          <form className="flex flex-wrap gap-2" onSubmit={(e) => { e.preventDefault(); doEnroll.mutate(); }}>
            <select className={sel} value={enroll.student} onChange={(e) => setEnroll({ ...enroll, student: e.target.value })} required>
              <option value="">الطالب ({unenrolled.length} غير مسجل)</option>
              {unenrolled.map((s) => <option key={s.id} value={s.id}>{s.full_name}</option>)}
            </select>
            <select className={sel} value={enroll.section} onChange={(e) => setEnroll({ ...enroll, section: e.target.value })} required>
              <option value="">الشعبة</option>
              {data.sections.map((s) => <option key={s.id} value={s.id}>{sectionLabel(s.id)}</option>)}
            </select>
            <select className={sel} value={enroll.type} onChange={(e) => setEnroll({ ...enroll, type: e.target.value as keyof typeof ETYPE })}>
              {Object.entries(ETYPE).map(([k, v]) => <option key={k} value={k}>{v}</option>)}
            </select>
            <Button disabled={doEnroll.isPending}>تسجيل</Button>
          </form>
        )}
      </Card>

      <Input placeholder="بحث بالاسم أو الرقم" value={q} onChange={(e) => setQ(e.target.value)} />
      <Card className="divide-y">
        {list.length === 0 && <p className="p-6 text-center text-muted-foreground">لا يوجد طلاب</p>}
        {list.map((s) => (
          <div key={s.id} className="p-3 flex flex-wrap items-center justify-between gap-2">
            <div>
              <div className="font-medium">{s.full_name}</div>
              <div className="text-xs text-muted-foreground">#{s.student_number} {s.guardian_name && `· ولي الأمر: ${s.guardian_name}`}</div>
            </div>
            <div className="flex gap-2 items-center">
              <span className="text-sm">{sectionLabel(enrolledIn(s.id)) ?? <span className="text-muted-foreground">غير مسجل هذا العام</span>}</span>
              <Badge variant={s.status === "active" ? "default" : "secondary"}>{STATUS[s.status]}</Badge>
            </div>
          </div>
        ))}
      </Card>
    </div>
  );
}
