import { schoolPageHead } from "@/lib/pageHead";
import { createFileRoute } from "@tanstack/react-router";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useState, useMemo } from "react";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import { useSchool, useMe, errMsg } from "@/lib/staff";
import { formatKhartoumDateDisplay } from "@/lib/schoolDate";
import { printTarget } from "@/lib/printHelper";
import { PageHead, Field, Empty } from "@/components/app/kit";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import {
  FileText,
  Printer,
  Sparkles,
  School,
  CheckCircle2,
  Users,
  Search,
  History,
  Copy,
  SlidersHorizontal,
  Save,
} from "lucide-react";

export const Route = createFileRoute("/_authenticated/templates")({
  head: () =>
    schoolPageHead(
      "استوديو المستندات والطباعة — مدرسة العمرابي",
      "استوديو تحرير وطباعة الشهادات المدرسية والإفادات الرسمية وإشعارات أولياء الأمور بمدرسة العمرابي الثانوية."
    ),
  component: TemplatesStudioPage,
});

interface TemplateDef {
  key: string;
  title: string;
  category: "academic" | "administrative" | "financial";
  description: string;
  defaultSubject: string;
  bodyTemplate: string;
}

const BUILTIN_TEMPLATES: TemplateDef[] = [
  {
    key: "enrollment_certificate",
    title: "إفادة قيد وتسجيل طالب",
    category: "academic",
    description: "شهادة رسمية تثبت قيد الطالب وانتظامه بالدراسة بالمدرسة للعام الدراسي الحالي.",
    defaultSubject: "إفادة قيد دراسي معتمدة",
    bodyTemplate: `تشهد إدارة مدرسة العمرابي الثانوية بنين بأن الطالب / @student.full_name،
والحامل للرقم المدرسي الموحد (@student.school_number) والرقم الوطني (@student.national_id)،
مقيد بالدراسة لدينا بصورة منتظمة في @student.grade_section خلال العام الدراسي (@student.academic_year).

وقد أُعطيت له هذه الإفادة بناءً على طلب ولي أمره (@student.guardian_name) لتقديمها إلى الجهات المختصة دون أدنى مسؤولية على إدارة المدرسة فيما يترتب على استعمالها.`,
  },
  {
    key: "good_conduct",
    title: "شهادة حسن سير وسلوك",
    category: "academic",
    description: "شهادة سلوكية تثبت التزام الطالب بالأخلاق واللوائح المدرسية طيلة فترة قيده.",
    defaultSubject: "شهادة حسن سير وسلوك",
    bodyTemplate: `تشهد إدارة مدرسة العمرابي الثانوية بنين بأن الطالب / @student.full_name،
المقيد بالرقم المدرسي (@student.school_number) بالصف (@student.grade_section)،
كان طيلة فترة دراسته بالمدرسة مثالاً للطالب الخلوق المتميز في الانضباط وحسن السير والسلوك، ولم تصدر منه أية مخالفة للوائح السلوكية أو الأخلاقية المعتمدة بوزارة التربية والتعليم.

وهذه شهادة منا بذلك، ونتمنى له دوام التوفيق والنجاح.`,
  },
  {
    key: "parent_notice",
    title: "إشعار ولي أمر بخصوص الطالب",
    category: "administrative",
    description: "خطاب استدعاء أو إشعار رسمي لولي الأمر بخصوص الأداء الأكاديمي أو الحضور أو الشؤون العامة.",
    defaultSubject: "إشعار إداري / متابعة ولي الأمر",
    bodyTemplate: `إلى ولي أمر الطالب المحترم / @student.guardian_name
السلام عليكم ورحمة الله تعالى وبركاته، وبعد:

تود إدارة مدرسة العمرابي الثانوية بنين إحاطتكم علماً بمتابعة ابنكم الطالب / @student.full_name (الرقم المدرسي: @student.school_number) المقيد في @student.grade_section.
يرجى التكرم بزيارة إدارة المدرسة أو التواصل مع المرشد الأكاديمي لمتابعة الملاحظات المسجلة بملفه المدرسي خلال موعد أقصاه ثلاثة أيام من تاريخ استلام هذا الإشعار.

شاكرين لكم حسن تعاونكم الدائم في مصلحة الطالب.`,
  },
  {
    key: "fee_clearance",
    title: "إفادة براءة ذمة مالية",
    category: "financial",
    description: "إفادة رسمية من القسم المالي والمحاسبي بسداد كافة الرسوم المستحقة على الطالب.",
    defaultSubject: "إفادة براءة ذمة مالية",
    bodyTemplate: `تشهد الإدارة المالية بمدرسة العمرابي الثانوية بنين بأن الطالب / @student.full_name،
المسجل بالرقم المدرسي (@student.school_number) بالصف (@student.grade_section)،
قد قام بتسديد كافة الرسوم الدراسية والالتزامات المالية المقررة عليه بالكامل للعام الدراسي الحالي (@student.academic_year).

بناءً عليه، تم منحه براءة الذمة المالية هذه لاعتماد إجراءات التسجيل أو استلام الشهادات دون مطالبات مالية متبقية.`,
  },
  {
    key: "transfer_certificate",
    title: "إفادة انتقال ومغادرة طالب",
    category: "administrative",
    description: "إفادة مغادرة وانتقال طالب إلى مدرسة أخرى مع حفظ تاريخه الأكاديمي بالكامل.",
    defaultSubject: "إفادة إخلاء طرف وانتقال طالب",
    bodyTemplate: `تفيد إدارة مدرسة العمرابي الثانوية بنين بأن الطالب / @student.full_name،
المقيد بالرقم المدرسي (@student.school_number) وتاريخ الميلاد (@student.birth_date)،
كان مقيداً لدينا بـ @student.grade_section، وقد تم إخلاء طرفه بناءً على طلب ولي أمره رغبةً في الانتقال للدراسة بمدرسة أخرى، بعد استيفاء الشروط الإدارية والمالية.

وقد سُلمت له مستنداته الأكاديمية لمواصلة مسيرته التعليمية.`,
  },
];

const AVAILABLE_PLACEHOLDERS = [
  { code: "@student.full_name", label: "اسم الطالب رباعياً" },
  { code: "@student.school_number", label: "الرقم المدرسي" },
  { code: "@student.national_id", label: "الرقم الوطني" },
  { code: "@student.grade_section", label: "الصف والشعبة" },
  { code: "@student.academic_year", label: "العام الدراسي" },
  { code: "@student.birth_date", label: "تاريخ الميلاد" },
  { code: "@student.guardian_name", label: "اسم ولي الأمر" },
  { code: "@student.guardian_phone", label: "هاتف ولي الأمر" },
  { code: "@document.issue_date", label: "تاريخ التحرير" },
  { code: "@document.reference_number", label: "رقم الإشارة" },
  { code: "@school.name", label: "اسم المدرسة" },
  { code: "@school.principal", label: "مدير المدرسة" },
];

function TemplatesStudioPage() {
  const qc = useQueryClient();
  const { data: me } = useMe();
  const { data: school } = useSchool();

  const [selectedTemplateKey, setSelectedTemplateKey] = useState<string>("enrollment_certificate");
  const [subjectText, setSubjectText] = useState<string>("");
  const [customBody, setCustomBody] = useState<string>("");
  const [selectedStudentId, setSelectedStudentId] = useState<string>("");
  const [studentSearch, setStudentSearch] = useState<string>("");
  const [activeTab, setActiveTab] = useState<"studio" | "history">("studio");

  // Load students, enrollments, sections, and academic year
  const { data: appData, isLoading } = useQuery({
    queryKey: ["templates_page_data"],
    queryFn: async () => {
      const [yearRes, studentsRes, sectionsRes, enrRes] = await Promise.all([
        supabase.from("academic_years").select("*").eq("is_current", true).maybeSingle(),
        supabase.from("students").select("id, full_name, student_number, national_id, birth_date, guardian_name, guardian_phone").order("full_name"),
        supabase.from("sections").select("id, name, grade:grades(name)"),
        supabase.from("enrollments").select("student_id, section_id"),
      ]);

      const secMap = new Map((sectionsRes.data ?? []).map((s: any) => [s.id, s]));
      const enrMap = new Map((enrRes.data ?? []).map((e: any) => [e.student_id, e.section_id]));

      return {
        year: yearRes.data,
        students: studentsRes.data ?? [],
        secMap,
        enrMap,
      };
    },
  });

  // Load issued documents history defensively
  const { data: issuedHistory, refetch: refetchHistory } = useQuery({
    queryKey: ["issued_documents_history"],
    queryFn: async () => {
      try {
        const { data, error } = await supabase
          .from("issued_documents")
          .select("*, student:students(full_name, student_number)")
          .order("issued_at", { ascending: false })
          .limit(50);
        if (error) return [];
        return data ?? [];
      } catch {
        return [];
      }
    },
  });

  const activeTemplate: TemplateDef = useMemo(() => {
    return BUILTIN_TEMPLATES.find((t) => t.key === selectedTemplateKey) ?? BUILTIN_TEMPLATES[0]!;
  }, [selectedTemplateKey]);

  // Sync default texts when changing template
  const currentSubject = subjectText || activeTemplate.defaultSubject;
  const currentBody = customBody || activeTemplate.bodyTemplate;

  // Selected student resolution
  const selectedStudent = useMemo(() => {
    if (!selectedStudentId || !appData?.students) return null;
    return appData.students.find((s) => s.id === selectedStudentId) ?? null;
  }, [selectedStudentId, appData?.students]);

  // Filter students for picker
  const filteredStudents = useMemo(() => {
    if (!appData?.students) return [];
    if (!studentSearch.trim()) return appData.students.slice(0, 15);
    const q = studentSearch.trim().toLowerCase();
    return appData.students
      .filter(
        (s) =>
          (s.full_name ?? "").toLowerCase().includes(q) ||
          (s.student_number ?? "").toLowerCase().includes(q)
      )
      .slice(0, 20);
  }, [appData?.students, studentSearch]);

  // Interpolated Document Text
  const previewData = useMemo(() => {
    const today = formatKhartoumDateDisplay(new Date());
    const refNum = `UMR-${new Date().getFullYear()}-${selectedStudent ? selectedStudent.student_number?.replace(/\D/g, "") : "XXXX"}`;

    let secName = "الصف الأول ثانوي";
    if (selectedStudent && appData) {
      const secId = appData.enrMap.get(selectedStudent.id);
      if (secId) {
        const sec = appData.secMap.get(secId);
        if (sec) {
          secName = `${sec.grade?.name ?? "الصف"} / ${sec.name}`;
        }
      }
    }

    const dict: Record<string, string> = {
      "@student.full_name": selectedStudent?.full_name || "اسم الطالب رباعياً",
      "@student.school_number": selectedStudent?.student_number || "UMR-XXXX-XXXX",
      "@student.national_id": selectedStudent?.national_id || "1XXXXXXXXXX",
      "@student.grade_section": secName,
      "@student.academic_year": appData?.year?.name || "2026/2027م",
      "@student.birth_date": selectedStudent?.birth_date || "2009-01-01",
      "@student.guardian_name": selectedStudent?.guardian_name || "اسم ولي الأمر",
      "@student.guardian_phone": selectedStudent?.guardian_phone || "09XXXXXXXX",
      "@document.issue_date": today,
      "@document.reference_number": refNum,
      "@school.name": school?.name || "مدرسة العمرابي الثانوية بنين",
      "@school.principal": "إدارة مدرسة العمرابي الثانوية",
    };

    let text = currentBody;
    for (const [key, val] of Object.entries(dict)) {
      text = text.replaceAll(key, val);
    }

    return {
      title: currentSubject,
      body: text,
      refNum,
      date: today,
    };
  }, [selectedStudent, appData, school, currentBody, currentSubject]);

  // Save Template Text Mutation
  const saveTemplateMutation = useMutation({
    mutationFn: async () => {
      let targetSchoolId = school?.id;
      if (!targetSchoolId) {
        const { data: s } = await supabase.from("schools").select("id").limit(1).maybeSingle();
        targetSchoolId = s?.id;
      }
      if (!targetSchoolId) throw new Error("تعذر تحديد المدرسة لحفظ القالب.");

      const { data: existing, error: findErr } = await supabase
        .from("document_templates" as any)
        .select("id, version")
        .eq("template_key", activeTemplate.key)
        .maybeSingle();

      if (findErr) {
        if (findErr.code === "42P01" || findErr.message?.includes("does not exist")) {
          return { available: false };
        }
        throw findErr;
      }

      if (existing?.id) {
        const { error: updErr } = await supabase
          .from("document_templates" as any)
          .update({
            title: subjectText || activeTemplate.defaultSubject,
            content_html: customBody || activeTemplate.bodyTemplate,
            version: (existing.version || 1) + 1,
            updated_at: new Date().toISOString(),
          })
          .eq("id", existing.id);
        if (updErr) throw updErr;
      } else {
        const { error: insErr } = await supabase
          .from("document_templates" as any)
          .insert({
            school_id: targetSchoolId,
            template_key: activeTemplate.key,
            title: subjectText || activeTemplate.defaultSubject,
            category: activeTemplate.category,
            content_html: customBody || activeTemplate.bodyTemplate,
            version: 1,
            is_active: true,
          });
        if (insErr) {
          if (insErr.code === "42P01" || insErr.message?.includes("does not exist")) {
            return { available: false };
          }
          throw insErr;
        }
      }
      return { available: true };
    },
    onSuccess: (res) => {
      if (res.available) {
        toast.success("تم حفظ نص القالب وإصدار نسخة جديدة بالسجل");
      } else {
        toast.info("تنبيه: جدول حفظ القوالب (document_templates) غير مفعّل في قاعدة البيانات الحالية حتى يتم اعتماد ترحيل 0012.");
      }
    },
    onError: (e) => toast.error(errMsg(e)),
  });

  // Record issuance mutation with strict foreign-key integrity and honest error handling
  const issueMutation = useMutation({
    mutationFn: async () => {
      if (!selectedStudent) throw new Error("يرجى اختيار الطالب لإصدار المستند باسمه.");
      let targetSchoolId = school?.id;
      if (!targetSchoolId) {
        const { data: s } = await supabase.from("schools").select("id").limit(1).maybeSingle();
        targetSchoolId = s?.id;
      }
      if (!targetSchoolId) throw new Error("تعذر تحديد بيانات المدرسة.");

      // 1. Resolve actual template_id from document_templates
      let validTemplateId: string | null = null;
      let tablesAvailable = true;

      const { data: tmplRecord, error: tmplErr } = await supabase
        .from("document_templates" as any)
        .select("id")
        .eq("template_key", activeTemplate.key)
        .maybeSingle();

      if (tmplErr) {
        if (tmplErr.code === "42P01" || tmplErr.message?.includes("does not exist")) {
          tablesAvailable = false;
        } else {
          throw tmplErr;
        }
      } else if (tmplRecord?.id) {
        validTemplateId = tmplRecord.id;
      } else {
        // Create template record so issued_documents has a valid foreign key
        const { data: newTmpl, error: createTmplErr } = await supabase
          .from("document_templates" as any)
          .insert({
            school_id: targetSchoolId,
            template_key: activeTemplate.key,
            title: currentSubject,
            category: activeTemplate.category,
            content_html: currentBody,
            version: 1,
            is_active: true,
          })
          .select("id")
          .maybeSingle();

        if (createTmplErr) {
          if (createTmplErr.code === "42P01" || createTmplErr.message?.includes("does not exist")) {
            tablesAvailable = false;
          } else {
            throw createTmplErr;
          }
        } else {
          validTemplateId = newTmpl?.id ?? null;
        }
      }

      // 2. Insert into issued_documents only if tables exist and template_id is valid
      if (tablesAvailable && validTemplateId) {
        const { error: insErr } = await supabase
          .from("issued_documents" as any)
          .insert({
            school_id: targetSchoolId,
            document_number: previewData.refNum,
            template_id: validTemplateId,
            template_version: 1,
            student_id: selectedStudent.id,
            academic_year_id: appData?.year?.id,
            rendered_content: previewData.body,
            issued_by: me?.user.id,
            status: "active",
          });

        if (insErr) {
          if (insErr.code === "42P01" || insErr.message?.includes("does not exist")) {
            tablesAvailable = false;
          } else {
            throw insErr;
          }
        }
      }

      return { tablesAvailable, refNum: previewData.refNum };
    },
    onSuccess: (res) => {
      if (res.tablesAvailable) {
        toast.success(`تم إصدار الوثيقة وتوثيقها في السجل الرقمي برقم قيد معتمد: ${res.refNum}`);
        refetchHistory();
      } else {
        toast.info(
          `المستند جاهز للطباعة برقم قيد: ${res.refNum}. (تنبيه: سجل الأرشفة الرقمي غير مفعّل في قاعدة البيانات الحالية حتى يتم تطبيق ترحيل 0012).`
        );
      }
    },
    onError: (e) => toast.error(errMsg(e)),
  });

  const handlePrint = () => {
    if (!selectedStudent) {
      toast.error("يرجى اختيار الطالب قبل الطباعة.");
      return;
    }
    issueMutation.mutate();
    printTarget("official-document-print-area", {
      documentTitle: `${activeTemplate.title} - ${selectedStudent.full_name}`,
    });
  };

  const insertPlaceholder = (ph: string) => {
    setCustomBody((prev) => (prev ? `${prev} ${ph}` : `${activeTemplate.bodyTemplate} ${ph}`));
  };

  return (
    <div className="space-y-6">
      <PageHead
        title="استوديو المستندات والطباعة المعتمدة"
        sub="إصدار الشهادات المدرسية، إفادات القيد، خطابات أولياء الأمور، وبراءة الذمة مع دعم التوليد التلقائي والطباعة المعزولة."
        actions={
          <div className="flex items-center gap-2">
            <Button
              variant={activeTab === "studio" ? "default" : "outline"}
              size="sm"
              onClick={() => setActiveTab("studio")}
              className="h-9 text-xs gap-1.5"
            >
              <FileText className="h-4 w-4" />
              <span>محرر القوالب والطباعة</span>
            </Button>
            <Button
              variant={activeTab === "history" ? "default" : "outline"}
              size="sm"
              onClick={() => setActiveTab("history")}
              className="h-9 text-xs gap-1.5"
            >
              <History className="h-4 w-4" />
              <span>سجل الوثائق الصادرة</span>
            </Button>
          </div>
        }
      />

      {activeTab === "history" ? (
        <div className="card-surface p-6">
          <h2 className="text-sm font-semibold text-foreground mb-4 flex items-center justify-between border-b border-border pb-3">
            <span>سجل الوثائق والشهادات المعتمدة الصادرة</span>
            <span className="text-xs text-muted-foreground font-normal">أرشيف غير قابل للتعديل</span>
          </h2>

          {(issuedHistory ?? []).length === 0 ? (
            <Empty title="لا توجد وثائق محفوظة بالسجل حتى الآن">
              عند إصدار وطباعة أي شهادة أو إفادة رسمية، تُحفظ نسخة رقمية غير قابلة للتعديل هنا مع رقم القيد وتاريخ الإصدار.
            </Empty>
          ) : (
            <div className="overflow-x-auto">
              <table className="modern-table text-xs">
                <thead>
                  <tr>
                    <th>رقم الوثيقة / الإشارة</th>
                    <th>اسم الطالب</th>
                    <th>الرقم المدرسي</th>
                    <th>تاريخ الإصدار</th>
                    <th>حالة الوثيقة</th>
                  </tr>
                </thead>
                <tbody>
                  {(issuedHistory ?? []).map((doc: any) => (
                    <tr key={doc.id}>
                      <td className="font-mono font-medium text-foreground">{doc.document_number}</td>
                      <td className="font-semibold text-foreground">{doc.student?.full_name ?? "—"}</td>
                      <td className="font-mono text-muted-foreground" dir="ltr">
                        {doc.student?.student_number ?? "—"}
                      </td>
                      <td className="text-muted-foreground">
                        {formatKhartoumDateDisplay(new Date(doc.issued_at))}
                      </td>
                      <td>
                        <span className="status-pill active">معتمدة وسارية</span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      ) : (
        <div className="grid lg:grid-cols-12 gap-6">
          {/* Left Column: Template & Student Configuration (5 cols) */}
          <div className="lg:col-span-5 space-y-5">
            {/* Template Selection */}
            <div className="card-surface p-5 space-y-3">
              <label className="text-xs font-semibold text-foreground block">
                اختر نوع النموذج أو الشهادة الرسمية
              </label>
              <div className="grid grid-cols-1 gap-2">
                {BUILTIN_TEMPLATES.map((tmpl) => (
                  <button
                    key={tmpl.key}
                    type="button"
                    onClick={() => {
                      setSelectedTemplateKey(tmpl.key);
                      setSubjectText(tmpl.defaultSubject);
                      setCustomBody(tmpl.bodyTemplate);
                    }}
                    className={`p-3 rounded-lg border text-start transition-all ${
                      selectedTemplateKey === tmpl.key
                        ? "border-primary bg-primary/5 text-foreground shadow-xs"
                        : "border-border hover:bg-muted text-muted-foreground"
                    }`}
                  >
                    <div className="flex items-center justify-between mb-1">
                      <span className="font-bold text-xs text-foreground">{tmpl.title}</span>
                      <span className="text-[10px] px-2 py-0.5 rounded bg-muted text-muted-foreground font-mono">
                        {tmpl.category === "academic" ? "أكاديمي" : tmpl.category === "financial" ? "مالي" : "إداري"}
                      </span>
                    </div>
                    <p className="text-[11px] text-muted-foreground line-clamp-2 leading-relaxed">
                      {tmpl.description}
                    </p>
                  </button>
                ))}
              </div>
            </div>

            {/* Student Search & Selection */}
            <div className="card-surface p-5 space-y-3">
              <div className="flex items-center justify-between">
                <label className="text-xs font-semibold text-foreground">
                  تحديد الطالب لإدراج بياناته *
                </label>
                {selectedStudent && (
                  <button
                    type="button"
                    onClick={() => setSelectedStudentId("")}
                    className="text-[11px] text-primary hover:underline"
                  >
                    إلغاء التحديد
                  </button>
                )}
              </div>

              {selectedStudent ? (
                <div className="p-3 rounded-lg bg-emerald-500/10 border border-emerald-500/30 text-emerald-800 dark:text-emerald-400 space-y-1 text-xs">
                  <div className="flex items-center justify-between font-bold">
                    <span>{selectedStudent.full_name}</span>
                    <span className="font-mono text-[11px]" dir="ltr">
                      {selectedStudent.student_number}
                    </span>
                  </div>
                  <div className="text-[11px] text-muted-foreground flex justify-between">
                    <span>الرقم الوطني: {selectedStudent.national_id ?? "غير مسجل"}</span>
                    <span>ولي الأمر: {selectedStudent.guardian_name ?? "—"}</span>
                  </div>
                </div>
              ) : (
                <div className="space-y-2">
                  <div className="relative">
                    <Search className="h-3.5 w-3.5 absolute start-3 top-3 text-muted-foreground" />
                    <Input
                      placeholder="ابحث بالاسم أو الرقم المدرسي لتحديد الطالب…"
                      value={studentSearch}
                      onChange={(e) => setStudentSearch(e.target.value)}
                      className="ps-9 text-xs h-9"
                    />
                  </div>
                  <div className="max-h-48 overflow-y-auto divide-y divide-border border border-border rounded-lg bg-card">
                    {filteredStudents.length === 0 ? (
                      <div className="p-3 text-center text-[11px] text-muted-foreground">
                        لا يوجد طلاب يطابقون البحث
                      </div>
                    ) : (
                      filteredStudents.map((s) => (
                        <button
                          key={s.id}
                          type="button"
                          onClick={() => setSelectedStudentId(s.id)}
                          className="w-full p-2.5 text-start hover:bg-muted/70 transition-colors flex items-center justify-between text-xs"
                        >
                          <span className="font-medium text-foreground">{s.full_name}</span>
                          <span className="font-mono text-[11px] text-muted-foreground" dir="ltr">
                            {s.student_number}
                          </span>
                        </button>
                      ))
                    )}
                  </div>
                </div>
              )}
            </div>

            {/* Template Variables Helper */}
            <div className="card-surface p-5 space-y-3">
              <label className="text-xs font-semibold text-foreground block">
                المتغيرات المتاحة للإدراج التلقائي (@Placeholders)
              </label>
              <div className="flex flex-wrap gap-1.5">
                {AVAILABLE_PLACEHOLDERS.map((ph) => (
                  <button
                    key={ph.code}
                    type="button"
                    onClick={() => insertPlaceholder(ph.code)}
                    className="inline-flex items-center gap-1 text-[11px] font-mono bg-muted hover:bg-primary/10 hover:text-primary text-muted-foreground px-2 py-1 rounded border border-border transition-colors"
                    title={`انقر لإدراج: ${ph.label}`}
                  >
                    <span>{ph.code}</span>
                  </button>
                ))}
              </div>

              <div className="pt-2 border-t border-border space-y-2">
                <Field label="عنوان الموضوع / الشهادة">
                  <Input
                    value={subjectText || activeTemplate.defaultSubject}
                    onChange={(e) => setSubjectText(e.target.value)}
                    className="text-xs font-semibold"
                  />
                </Field>

                <Field label="نص المستند (يدعم التعديل والمتغيرات)">
                  <Textarea
                    rows={6}
                    value={customBody || activeTemplate.bodyTemplate}
                    onChange={(e) => setCustomBody(e.target.value)}
                    className="text-xs leading-relaxed font-sans"
                  />
                </Field>

                <div className="flex items-center justify-between pt-1">
                  <Button
                    type="button"
                    variant="outline"
                    size="sm"
                    onClick={() => saveTemplateMutation.mutate()}
                    disabled={saveTemplateMutation.isPending}
                    className="h-7 text-[11px] gap-1"
                  >
                    <Save className="h-3 w-3" />
                    <span>حفظ نص القالب بالسجل</span>
                  </Button>
                  <button
                    type="button"
                    onClick={() => {
                      setCustomBody(activeTemplate.bodyTemplate);
                      setSubjectText(activeTemplate.defaultSubject);
                      toast.info("تمت استعادة النص القياسي الأصلي للقالب");
                    }}
                    className="text-[11px] text-muted-foreground hover:underline"
                  >
                    استعادة النص الافتراضي
                  </button>
                </div>
              </div>
            </div>
          </div>

          {/* Right Column: Live Official Document Preview & Target-Only Print (7 cols) */}
          <div className="lg:col-span-7 space-y-4">
            <div className="flex items-center justify-between bg-card p-3 rounded-lg border border-border">
              <div className="flex items-center gap-2">
                <Printer className="h-4 w-4 text-primary" />
                <span className="text-xs font-bold text-foreground">المعاينة المباشرة للطباعة الرسمية (A4)</span>
              </div>
              <Button
                size="sm"
                onClick={handlePrint}
                disabled={!selectedStudent}
                className="h-8 gap-1.5 text-xs bg-primary text-primary-foreground font-semibold"
              >
                <Printer className="h-3.5 w-3.5" />
                <span>طباعة الوثيقة المستهدفة الآن</span>
              </Button>
            </div>

            {/* Document Printable Surface */}
            <div
              id="official-document-print-area"
              className="printable-target p-10 bg-white text-slate-900 border border-border/80 rounded-xl shadow-xs space-y-8 min-h-[640px] relative font-sans leading-relaxed"
              dir="rtl"
            >
              {/* Official Sudanese Educational Header */}
              <div className="border-b-2 border-slate-900 pb-5">
                <div className="flex items-start justify-between">
                  {/* Right Header Text */}
                  <div className="text-xs font-bold space-y-1 text-slate-800">
                    <div>جمهورية السودان</div>
                    <div>وزارة التربية والتعليم</div>
                    <div>ولاية الخرطوم — محلية بحري</div>
                    <div className="font-extrabold text-sm text-slate-900 pt-1">
                      {school?.name || "مدرسة العمرابي الثانوية بنين"}
                    </div>
                  </div>

                  {/* Emblem / Heraldic Shield */}
                  <div className="flex flex-col items-center justify-center px-4">
                    <div className="h-16 w-16 rounded-full border-2 border-slate-900 flex items-center justify-center p-2 mb-1">
                      <School className="h-9 w-9 text-slate-900" />
                    </div>
                    <span className="text-[10px] font-bold text-slate-700 tracking-wider">شعار المدرسة المعتمد</span>
                  </div>

                  {/* Left Metadata (Reference & Date) */}
                  <div className="text-xs space-y-1.5 text-start font-mono text-slate-800" dir="ltr">
                    <div>
                      <span className="font-sans font-bold">الرقم: </span>
                      <span>{previewData.refNum}</span>
                    </div>
                    <div>
                      <span className="font-sans font-bold">التاريخ: </span>
                      <span>{previewData.date}</span>
                    </div>
                    <div>
                      <span className="font-sans font-bold">العام: </span>
                      <span>{appData?.year?.name || "2026/2027م"}</span>
                    </div>
                  </div>
                </div>
              </div>

              {/* Title Section */}
              <div className="text-center pt-2">
                <h1 className="text-lg font-black text-slate-950 underline underline-offset-8 decoration-2 decoration-slate-900">
                  {previewData.title}
                </h1>
              </div>

              {/* Body Content */}
              <div className="py-4 px-2 text-sm text-slate-900 leading-loose whitespace-pre-line text-justify font-normal">
                {previewData.body}
              </div>

              {/* Official Seal and Signature Blocks */}
              <div className="pt-16 grid grid-cols-3 gap-6 text-center text-xs font-bold text-slate-900 border-t border-slate-200 mt-12">
                <div>
                  <div className="mb-14">المشرف / المسجل الأكاديمي</div>
                  <div className="border-t border-dashed border-slate-400 pt-1.5 w-3/4 mx-auto text-[11px] font-normal text-slate-600">
                    التوقيع والاعتماد
                  </div>
                </div>

                <div className="flex flex-col items-center justify-center">
                  <div className="h-20 w-20 rounded-full border-2 border-dashed border-slate-400 flex items-center justify-center text-[10px] text-slate-400 mb-1">
                    ختم المدرسة الرسمي
                  </div>
                </div>

                <div>
                  <div className="mb-14">مدير مدرسة العمرابي الثانوية</div>
                  <div className="border-t border-dashed border-slate-400 pt-1.5 w-3/4 mx-auto text-[11px] font-normal text-slate-600">
                    الختم والتوقيع
                  </div>
                </div>
              </div>

              {/* Document Security Verification Footer */}
              <div className="pt-6 border-t border-slate-200 flex items-center justify-between text-[10px] text-slate-500 font-mono">
                <div>منظومة مدرسة العمرابي الثانوية — وثيقة صادرة إلكترونياً ومعتمدة بالسجل الرسمي</div>
                <div>رمز التحقق: {previewData.refNum.replace(/[^a-zA-Z0-9]/g, "")}</div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
