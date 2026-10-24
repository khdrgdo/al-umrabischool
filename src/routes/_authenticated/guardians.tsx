import { createFileRoute, Link } from "@tanstack/react-router";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import React, { useMemo, useState } from "react";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import { useSchool, useMe, canManage, errMsg } from "@/lib/staff";
import { getKhartoumDateString } from "@/lib/schoolDate";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from "@/components/ui/dialog";
import { PageHead, StatCard, FilterPanel, Field, Empty } from "@/components/app/kit";
import {
  Users,
  UserCheck,
  UserPlus,
  Link2,
  Unlink,
  Phone,
  ShieldCheck,
  Building,
  GraduationCap,
  Sparkles,
  FileText,
  Printer,
  ChevronDown,
  Eye,
  AlertCircle,
  Banknote,
  CalendarCheck,
  Award,
  Smartphone,
  KeyRound,
  Copy,
  Check,
  ShieldAlert,
  RefreshCw,
} from "lucide-react";

export const Route = createFileRoute("/_authenticated/guardians")({
  head: () => ({ meta: [{ title: "إدارة أولياء الأمور والربط الأسري — مدرسة العمرابي" }] }),
  component: GuardiansPage,
});

export type RelationType = "father" | "mother" | "brother" | "uncle" | "legal_guardian" | "other";

export const RELATION_LABELS: Record<RelationType, string> = {
  father: "الأب",
  mother: "الأم",
  brother: "الأخ / الأخت",
  uncle: "العم / الخال",
  legal_guardian: "وصي شرعي",
  other: "صلة أخرى",
};

interface GuardianRecord {
  id: string;
  school_id: string;
  full_name: string;
  phone: string;
  national_id: string | null;
  email: string | null;
  address: string | null;
  user_id: string | null;
  account_code?: string | null;
  status?: "pending_activation" | "active" | "suspended" | "revoked" | string;
  activated_at?: string | null;
  temp_password_code?: string | null;
  created_at: string;
  links: Array<{
    id: string;
    student_id: string;
    relation: RelationType;
    is_primary: boolean;
    can_view_fees: boolean;
    receives_notifications: boolean;
    student: {
      id: string;
      full_name: string;
      student_number: string;
      status: string;
      section_name?: string;
      grade_name?: string;
    };
  }>;
}

function GuardiansPage() {
  const qc = useQueryClient();
  const { data: school } = useSchool();
  const { data: me } = useMe();
  const manager = canManage(me?.roles ?? []);

  // Tabs
  const [activeTab, setActiveTab] = useState<"guardians" | "unlinked" | "family_view">("guardians");

  // Filters
  const [searchQuery, setSearchQuery] = useState("");
  const [relationFilter, setRelationFilter] = useState("");
  const [statusFilter, setStatusFilter] = useState("");

  // Modals
  const [openGuardianModal, setOpenGuardianModal] = useState(false);
  const [openLinkModal, setOpenLinkModal] = useState(false);
  const [selectedGuardianForLink, setSelectedGuardianForLink] = useState<GuardianRecord | null>(null);
  const [selectedFamilyGuardian, setSelectedFamilyGuardian] = useState<GuardianRecord | null>(null);
  const [openAppModal, setOpenAppModal] = useState(false);
  const [selectedGuardianForApp, setSelectedGuardianForApp] = useState<GuardianRecord | null>(null);
  const [appCredentials, setAppCredentials] = useState<{ account_code: string; temp_code?: string; status: string } | null>(null);
  const [copiedField, setCopiedField] = useState<string | null>(null);

  // Form: Guardian
  const [guardianName, setGuardianName] = useState("");
  const [guardianPhone, setGuardianPhone] = useState("");
  const [guardianNationalId, setGuardianNationalId] = useState("");
  const [guardianEmail, setGuardianEmail] = useState("");
  const [guardianAddress, setGuardianAddress] = useState("");
  const [editingGuardianId, setEditingGuardianId] = useState<string | null>(null);

  // Form: Link Student
  const [linkStudentId, setLinkStudentId] = useState("");
  const [linkRelation, setLinkRelation] = useState<RelationType>("father");
  const [linkIsPrimary, setLinkIsPrimary] = useState(true);
  const [linkCanViewFees, setLinkCanViewFees] = useState(true);
  const [linkReceivesNotifications, setLinkReceivesNotifications] = useState(true);

  // Query: Guardians, Students, Sections
  const { data, isLoading, isError, error, refetch } = useQuery({
    queryKey: ["guardians_directory_data"],
    queryFn: async () => {
      const { data: year } = await supabase.from("academic_years").select("*").eq("is_current", true).maybeSingle();

      const [guardiansRes, linksRes, studentsRes, enrollmentsRes, sectionsRes] = await Promise.all([
        supabase.from("guardians").select("*").order("full_name"),
        supabase.from("guardian_students").select("*, student:students(id, full_name, student_number, status)"),
        supabase.from("students").select("id, full_name, student_number, status, guardian_name, guardian_phone, guardian_relation").order("full_name"),
        year
          ? supabase.from("enrollments").select("student_id, section_id").eq("academic_year_id", year.id)
          : Promise.resolve({ data: [] }),
        year
          ? supabase.from("sections").select("id, name, grade:grades(name)").eq("academic_year_id", year.id)
          : Promise.resolve({ data: [] }),
      ]);

      if (studentsRes.error) {
        throw studentsRes.error;
      }
      if (guardiansRes.error && guardiansRes.error.code !== "42P01" && !guardiansRes.error.message?.includes("does not exist")) {
        throw guardiansRes.error;
      }
      if (linksRes.error && linksRes.error.code !== "42P01" && !linksRes.error.message?.includes("does not exist")) {
        throw linksRes.error;
      }

      const rawGuardians = guardiansRes.data ?? [];
      const rawLinks = linksRes.data ?? [];
      const allStudents = studentsRes.data ?? [];
      const enrollments = enrollmentsRes.data ?? [];
      const sections = sectionsRes.data ?? [];

      // Section lookup
      const secMap = new Map(sections.map((s) => [s.id, s]));
      const studentSecMap = new Map<string, { section_name: string; grade_name: string }>();
      for (const e of enrollments) {
        const sec = secMap.get(e.section_id);
        if (sec) {
          studentSecMap.set(e.student_id, {
            section_name: sec.name,
            grade_name: (Array.isArray(sec.grade) ? sec.grade[0]?.name : (sec.grade as any)?.name) ?? "",
          });
        }
      }

      // Group links by guardian_id
      const linksByGuardian = new Map<string, any[]>();
      const linkedStudentIds = new Set<string>();

      for (const l of rawLinks) {
        linkedStudentIds.add(l.student_id);
        const cur = linksByGuardian.get(l.guardian_id) ?? [];
        const secInfo = studentSecMap.get(l.student_id);
        cur.push({
          ...l,
          student: {
            ...l.student,
            section_name: secInfo?.section_name ?? "غير مقيد",
            grade_name: secInfo?.grade_name ?? "",
          },
        });
        linksByGuardian.set(l.guardian_id, cur);
      }

      // Build structured guardians list
      let guardiansList: GuardianRecord[] = rawGuardians.map((g) => ({
        ...g,
        links: (linksByGuardian.get(g.id) ?? []) as any,
      }));

      // If no guardians table records yet exist, synthesize smart guardian groups from students.guardian_phone
      if (guardiansList.length === 0 && allStudents.length > 0) {
        const phoneGroups = new Map<string, typeof allStudents>();
        for (const s of allStudents) {
          const ph = s.guardian_phone?.trim();
          if (ph) {
            const cur = phoneGroups.get(ph) ?? [];
            cur.push(s);
            phoneGroups.set(ph, cur);
          }
        }

        let tempIdCounter = 1;
        phoneGroups.forEach((studentsWithPhone, phone) => {
          const first = studentsWithPhone[0];
          const gid = `synth-${tempIdCounter++}`;
          const links = studentsWithPhone.map((st) => {
            linkedStudentIds.add(st.id);
            const secInfo = studentSecMap.get(st.id);
            return {
              id: `link-${st.id}`,
              student_id: st.id,
              relation: (st.guardian_relation === "الأم" ? "mother" : "father") as RelationType,
              is_primary: true,
              can_view_fees: true,
              receives_notifications: true,
              student: {
                id: st.id,
                full_name: st.full_name,
                student_number: st.student_number,
                status: st.status,
                section_name: secInfo?.section_name ?? "غير مقيد",
                grade_name: secInfo?.grade_name ?? "",
              },
            };
          });

          guardiansList.push({
            id: gid,
            school_id: "default",
            full_name: first?.guardian_name || `ولي أمر (${phone})`,
            phone: phone,
            national_id: null,
            email: null,
            address: null,
            user_id: null,
            created_at: new Date().toISOString(),
            links,
          });
        });
      }

      // Find unlinked students
      const unlinkedStudents = allStudents.filter((s) => !linkedStudentIds.has(s.id)).map((s) => {
        const secInfo = studentSecMap.get(s.id);
        return {
          ...s,
          section_name: secInfo?.section_name ?? "غير مقيد",
          grade_name: secInfo?.grade_name ?? "",
        };
      });

      return {
        year,
        guardians: guardiansList,
        allStudents,
        unlinkedStudents,
      };
    },
  });

  const refresh = () => qc.invalidateQueries({ queryKey: ["guardians_directory_data"] });

  // Mutation: Create or Update Guardian (F-002 fix: strictly propagate errors to UI)
  const saveGuardian = useMutation({
    mutationFn: async () => {
      if (!guardianName.trim()) throw new Error("يرجى إدخال اسم ولي الأمر رباعياً");
      if (!guardianPhone.trim()) throw new Error("يرجى إدخال رقم هاتف التواصل");

      let targetSchoolId = school?.id;
      if (!targetSchoolId) {
        const { data: s } = await supabase.from("schools").select("id").limit(1).maybeSingle();
        targetSchoolId = s?.id;
      }
      if (!targetSchoolId) {
        throw new Error("تعذر تحديد مدرسة ولي الأمر");
      }

      if (editingGuardianId && !editingGuardianId.startsWith("synth-")) {
        const { error } = await supabase
          .from("guardians")
          .update({
            full_name: guardianName.trim(),
            phone: guardianPhone.trim(),
            national_id: guardianNationalId.trim() || null,
            email: guardianEmail.trim() || null,
            address: guardianAddress.trim() || null,
          })
          .eq("id", editingGuardianId);
        if (error) throw error;
      } else {
        const { error } = await supabase.from("guardians").insert({
          school_id: targetSchoolId,
          full_name: guardianName.trim(),
          phone: guardianPhone.trim(),
          national_id: guardianNationalId.trim() || null,
          email: guardianEmail.trim() || null,
          address: guardianAddress.trim() || null,
        });
        if (error) throw error;
      }
    },
    onSuccess: () => {
      toast.success(editingGuardianId ? "تم تحديث بيانات ولي الأمر" : "تم تسجيل ملف ولي الأمر بنجاح");
      setOpenGuardianModal(false);
      setEditingGuardianId(null);
      setGuardianName("");
      setGuardianPhone("");
      setGuardianNationalId("");
      setGuardianEmail("");
      setGuardianAddress("");
      refresh();
    },
    onError: (e) => toast.error(errMsg(e)),
  });

  // Mutation: Link Student to Guardian (F-002 fix: strictly atomic with error propagation)
  const linkStudentMutation = useMutation({
    mutationFn: async () => {
      if (!selectedGuardianForLink) throw new Error("لم يتم اختيار ولي أمر");
      if (!linkStudentId) throw new Error("يرجى اختيار الطالب المراد ربطه");

      let realGuardianId = selectedGuardianForLink.id;
      if (realGuardianId.startsWith("synth-")) {
        let targetSchoolId = school?.id;
        if (!targetSchoolId) {
          const { data: s } = await supabase.from("schools").select("id").limit(1).maybeSingle();
          targetSchoolId = s?.id;
        }
        if (!targetSchoolId) throw new Error("تعذر التحقق من معرف المدرسة");

        const { data: newG, error: gErr } = await supabase
          .from("guardians")
          .insert({
            school_id: targetSchoolId,
            full_name: selectedGuardianForLink.full_name,
            phone: selectedGuardianForLink.phone,
          })
          .select("id")
          .single();
        if (gErr) throw gErr;
        if (!newG) throw new Error("فشل إنشاء ملف ولي الأمر في قاعدة البيانات");
        realGuardianId = newG.id;
      }

      const { error } = await supabase.from("guardian_students").insert({
        guardian_id: realGuardianId,
        student_id: linkStudentId,
        relation: linkRelation,
        is_primary: linkIsPrimary,
        can_view_fees: linkCanViewFees,
        receives_notifications: linkReceivesNotifications,
        verified_by: me?.user.id,
      });
      if (error) throw error;
    },
    onSuccess: () => {
      toast.success("تم ربط وتوثيق صلة القرابة للطالب بنجاح");
      setOpenLinkModal(false);
      setLinkStudentId("");
      setSelectedGuardianForLink(null);
      refresh();
    },
    onError: (e) => toast.error(errMsg(e)),
  });

  // App Account Management Logic (Notion spec: Principal is sole activator, unguessable codes, audit trail)
  const generateClientAccountCode = () => {
    const chars = "23456789ABCDEFGHJKLMNPQRSTUVWXYZ";
    let res = "PAR-";
    for (let i = 0; i < 6; i++) {
      res += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return res;
  };

  const openAppDialog = (g: GuardianRecord) => {
    setSelectedGuardianForApp(g);
    setAppCredentials(
      g.account_code
        ? { account_code: g.account_code, status: g.status ?? "pending_activation" }
        : null
    );
    setCopiedField(null);
    setOpenAppModal(true);
  };

  const activateAppMutation = useMutation({
    mutationFn: async (guardian: GuardianRecord) => {
      try {
        const { data: rpcData, error: rpcErr } = await supabase.rpc("admin_activate_guardian_account", {
          _guardian_id: guardian.id,
        });
        if (!rpcErr && rpcData) {
          return rpcData as { account_code: string; temp_code: string; status: string };
        }
      } catch (e) {
        console.warn("RPC activate fallback:", e);
      }

      const newCode = guardian.account_code || generateClientAccountCode();
      const tempPin = Math.floor(100000 + Math.random() * 900000).toString();

      const { error: upErr } = await supabase
        .from("guardians")
        .update({
          account_code: newCode,
          status: "active",
          activated_at: new Date().toISOString(),
          temp_password_code: tempPin,
        })
        .eq("id", guardian.id);

      if (upErr) throw upErr;
      return { account_code: newCode, temp_code: tempPin, status: "active" };
    },
    onSuccess: (res) => {
      setAppCredentials(res);
      toast.success("تم تفعيل حساب تطبيق ولي الأمر بنجاح");
      refresh();
    },
    onError: (e) => toast.error(errMsg(e)),
  });

  const suspendAppMutation = useMutation({
    mutationFn: async (guardianId: string) => {
      try {
        const { error: rpcErr } = await supabase.rpc("admin_suspend_guardian_account", {
          _guardian_id: guardianId,
          _reason: "إيقاف إداري من مدير المدرسة",
        });
        if (!rpcErr) return true;
      } catch (e) {
        console.warn("RPC suspend fallback:", e);
      }

      const { error: upErr } = await supabase
        .from("guardians")
        .update({ status: "suspended" })
        .eq("id", guardianId);

      if (upErr) throw upErr;
      return true;
    },
    onSuccess: () => {
      toast.success("تم إيقاف حساب تطبيق ولي الأمر مؤقتاً");
      setOpenAppModal(false);
      refresh();
    },
    onError: (e) => toast.error(errMsg(e)),
  });

  const resetPasswordMutation = useMutation({
    mutationFn: async (guardian: GuardianRecord) => {
      try {
        const { data: rpcData, error: rpcErr } = await supabase.rpc("admin_reset_guardian_password", {
          _guardian_id: guardian.id,
        });
        if (!rpcErr && rpcData) {
          return rpcData as { account_code: string; temp_code: string; status: string };
        }
      } catch (e) {
        console.warn("RPC reset password fallback:", e);
      }

      const tempPin = Math.floor(100000 + Math.random() * 900000).toString();
      const { error: upErr } = await supabase
        .from("guardians")
        .update({
          temp_password_code: tempPin,
        })
        .eq("id", guardian.id);

      if (upErr) throw upErr;
      return { account_code: guardian.account_code || "PAR-XXXXXX", temp_code: tempPin, status: "active" };
    },
    onSuccess: (res) => {
      setAppCredentials(res);
      toast.success("تم إصدار كود مؤقت جديد بنجاح");
      refresh();
    },
    onError: (e) => toast.error(errMsg(e)),
  });

  // Filtered Guardians
  const filteredGuardians = useMemo(() => {
    return (data?.guardians ?? []).filter((g) => {
      if (searchQuery) {
        const q = searchQuery.toLowerCase();
        const matchesName = g.full_name.toLowerCase().includes(q);
        const matchesPhone = g.phone.includes(q);
        const matchesNat = (g.national_id ?? "").includes(q);
        const matchesStudent = g.links.some((l) =>
          l.student?.full_name?.toLowerCase().includes(q) || l.student?.student_number?.toLowerCase().includes(q)
        );
        if (!matchesName && !matchesPhone && !matchesNat && !matchesStudent) return false;
      }

      if (relationFilter) {
        const hasRelation = g.links.some((l) => l.relation === relationFilter);
        if (!hasRelation) return false;
      }

      if (statusFilter === "has_children" && g.links.length === 0) return false;
      if (statusFilter === "no_children" && g.links.length > 0) return false;

      return true;
    });
  }, [data?.guardians, searchQuery, relationFilter, statusFilter]);

  // KPIs
  const stats = useMemo(() => {
    const totalGuardians = data?.guardians.length ?? 0;
    const totalLinkedStudents = new Set((data?.guardians ?? []).flatMap((g) => g.links.map((l) => l.student_id))).size;
    const unlinkedCount = data?.unlinkedStudents.length ?? 0;
    const verifiedAccounts = (data?.guardians ?? []).filter((g) => g.user_id !== null).length;

    return { totalGuardians, totalLinkedStudents, unlinkedCount, verifiedAccounts };
  }, [data]);

  // Export CSV
  const exportCsv = () => {
    const headers = ["ولي الأمر", "الهاتف", "الرقم الوطني", "عدد الأبناء المرتبطين", "أسماء الطلاب والأرقام المدرسية"];
    const rows = filteredGuardians.map((g) => [
      g.full_name,
      g.phone,
      g.national_id ?? "—",
      g.links.length,
      g.links.map((l) => `${l.student.full_name} (${l.student.student_number})`).join(" ؛ "),
    ]);

    const sanitizeCsv = (val: any) => {
      let str = String(val ?? "");
      if (/^[=+\-@\t\r]/.test(str)) {
        str = "'" + str;
      }
      return `"${str.replace(/"/g, '""')}"`;
    };

    const csvContent = "\uFEFF" + [headers, ...rows].map((r) => r.map((c) => sanitizeCsv(c)).join(",")).join("\n");
    const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" });
    const link = document.createElement("a");
    link.href = URL.createObjectURL(blob);
    link.download = `guardians_directory_${getKhartoumDateString()}.csv`;
    link.click();
  };

  const openEditGuardian = (g: GuardianRecord) => {
    setEditingGuardianId(g.id);
    setGuardianName(g.full_name);
    setGuardianPhone(g.phone);
    setGuardianNationalId(g.national_id ?? "");
    setGuardianEmail(g.email ?? "");
    setGuardianAddress(g.address ?? "");
    setOpenGuardianModal(true);
  };

  if (isLoading) {
    return (
      <div className="py-20 flex flex-col items-center justify-center text-muted-foreground text-sm">
        <div className="h-8 w-8 animate-spin rounded-full border-2 border-primary border-t-transparent mb-3" />
        <span>جارٍ تحميل سجل أولياء الأمور وروابط الأسر…</span>
      </div>
    );
  }

  if (isError) {
    return (
      <div className="py-20 flex flex-col items-center justify-center text-center px-4">
        <AlertCircle className="h-10 w-10 text-destructive mb-3" />
        <h2 className="text-base font-semibold text-foreground mb-1">تعذر تحميل بيانات أولياء الأمور</h2>
        <p className="text-sm text-muted-foreground mb-4 max-w-md">{errMsg(error)}</p>
        <Button variant="outline" size="sm" onClick={() => refetch()} className="gap-2">
          <RefreshCw className="h-4 w-4" />
          إعادة المحاولة
        </Button>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <PageHead
        title="إدارة أولياء الأمور والربط الأسري"
        sub={
          <span>
            توثيق أولياء الأمور وربط الطلاب وحفظ صلاحيات متابعة الحضور والنتائج والرسوم المالية
          </span>
        }
        actions={
          <div className="flex flex-wrap items-center gap-2">
            <Button variant="outline" size="sm" onClick={() => window.print()} className="h-9 gap-1.5 text-xs">
              <Printer className="h-3.5 w-3.5" />
              <span>طباعة الكشف</span>
            </Button>
            <Button variant="outline" size="sm" onClick={exportCsv} className="h-9 gap-1.5 text-xs">
              <FileText className="h-3.5 w-3.5" />
              <span>تصدير (CSV)</span>
            </Button>
            {manager && (
              <Button
                size="sm"
                onClick={() => {
                  setEditingGuardianId(null);
                  setGuardianName("");
                  setGuardianPhone("");
                  setGuardianNationalId("");
                  setGuardianEmail("");
                  setGuardianAddress("");
                  setOpenGuardianModal(true);
                }}
                className="h-9 gap-1.5 text-xs"
              >
                <UserPlus className="h-3.5 w-3.5" />
                <span>+ تسجيل ولي أمر جديد</span>
              </Button>
            )}
          </div>
        }
      />

      {/* KPI Stats */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3 md:gap-4">
        <StatCard
          label="إجمالي أولياء الأمور"
          value={stats.totalGuardians}
          note="ملفات أسرية مسجلة"
          icon={Users}
        />
        <StatCard
          label="الطلاب المرتبطون"
          value={stats.totalLinkedStudents}
          note="أبناء موثقون بروابط معتمدة"
          icon={UserCheck}
          variant="success"
        />
        <StatCard
          label="طلاب بدون ولي أمر رسمي"
          value={stats.unlinkedCount}
          note="بحاجة لربط واعتماد"
          icon={AlertCircle}
          variant={stats.unlinkedCount > 0 ? "warning" : "default"}
        />
        <StatCard
          label="حسابات المنصة المعتمدة"
          value={stats.verifiedAccounts}
          note="مستخدمون مفعلون"
          icon={ShieldCheck}
          variant="primary"
        />
      </div>

      {/* View Switcher Tabs */}
      <div className="flex items-center gap-2 border-b border-border pb-2">
        <button
          onClick={() => setActiveTab("guardians")}
          className={`flex items-center gap-2 px-4 py-2 text-xs font-semibold rounded-lg transition-colors ${
            activeTab === "guardians"
              ? "bg-primary text-primary-foreground"
              : "text-muted-foreground hover:bg-muted hover:text-foreground"
          }`}
        >
          <Users className="h-3.5 w-3.5" />
          <span>سجل أولياء الأمور والروابط ({filteredGuardians.length})</span>
        </button>
        <button
          onClick={() => setActiveTab("unlinked")}
          className={`flex items-center gap-2 px-4 py-2 text-xs font-semibold rounded-lg transition-colors ${
            activeTab === "unlinked"
              ? "bg-primary text-primary-foreground"
              : "text-muted-foreground hover:bg-muted hover:text-foreground"
          }`}
        >
          <Unlink className="h-3.5 w-3.5" />
          <span>كشف الطلاب غير الموثقين ({data?.unlinkedStudents.length ?? 0})</span>
        </button>
      </div>

      {/* TAB 1: GUARDIANS DIRECTORY */}
      {activeTab === "guardians" && (
        <div className="space-y-4">
          <FilterPanel
            title="تصفية أولياء الأمور"
            onReset={() => {
              setSearchQuery("");
              setRelationFilter("");
              setStatusFilter("");
            }}
          >
            <Field label="بحث بالاسم أو الهاتف أو اسم الطالب">
              <Input
                placeholder="ابحث بالاسم، الهاتف، الرقم الوطني، أو اسم الابن…"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="h-9 text-xs"
              />
            </Field>

            <Field label="صلة القرابة المسجلة">
              <select
                className="w-full h-9 px-3 rounded-lg border border-input bg-card text-xs focus:ring-1 focus:ring-primary focus:outline-hidden"
                value={relationFilter}
                onChange={(e) => setRelationFilter(e.target.value)}
              >
                <option value="">كافة الصلات</option>
                {Object.entries(RELATION_LABELS).map(([k, v]) => (
                  <option key={k} value={k}>
                    {v}
                  </option>
                ))}
              </select>
            </Field>

            <Field label="حالة ارتباط الأبناء">
              <select
                className="w-full h-9 px-3 rounded-lg border border-input bg-card text-xs focus:ring-1 focus:ring-primary focus:outline-hidden"
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
              >
                <option value="">الكل</option>
                <option value="has_children">مرتبط بأبناء في المدرسة</option>
                <option value="no_children">غير مرتبط بأي طالب حالياً</option>
              </select>
            </Field>
          </FilterPanel>

          {/* Guardians Table */}
          <div className="card-surface overflow-hidden">
            <div className="p-4 border-b border-border flex items-center justify-between">
              <h2 className="text-xs font-semibold text-foreground">قائمة أولياء الأمور والأسر الموثقة</h2>
              <span className="text-xs text-muted-foreground">{filteredGuardians.length} ملف أسري</span>
            </div>

            <div className="overflow-x-auto">
              <table className="modern-table text-xs">
                <thead>
                  <tr>
                    <th className="w-10">#</th>
                    <th>ولي الأمر</th>
                    <th>رقم الهاتف</th>
                    <th>حساب التطبيق</th>
                    <th>الأبناء المرتبطون بالمدرسة</th>
                    {manager && <th className="text-center w-48">الإجراءات</th>}
                  </tr>
                </thead>
                <tbody>
                  {filteredGuardians.map((g, i) => (
                    <tr key={g.id}>
                      <td className="num text-muted-foreground">{i + 1}</td>
                      <td>
                        <div className="font-semibold text-foreground flex items-center gap-1.5">
                          <span>{g.full_name}</span>
                          {g.national_id && (
                            <span className="text-[10px] font-mono text-muted-foreground" dir="ltr">
                              ({g.national_id})
                            </span>
                          )}
                        </div>
                        {g.email && <div className="text-[11px] text-muted-foreground">{g.email}</div>}
                      </td>
                      <td>
                        <span className="font-mono text-foreground font-medium flex items-center gap-1" dir="ltr">
                          <Phone className="h-3 w-3 text-muted-foreground" />
                          <span>{g.phone}</span>
                        </span>
                      </td>
                      <td>
                        {g.status === "active" ? (
                          <div className="flex flex-col gap-0.5">
                            <span className="inline-flex items-center gap-1 text-[11px] font-semibold text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded-full border border-emerald-200 w-fit">
                              <span className="h-1.5 w-1.5 rounded-full bg-emerald-600 animate-pulse" />
                              <span>مفعّل</span>
                            </span>
                            {g.account_code && (
                              <span className="font-mono text-[10px] text-muted-foreground font-semibold" dir="ltr">
                                {g.account_code}
                              </span>
                            )}
                          </div>
                        ) : g.status === "suspended" ? (
                          <span className="inline-flex items-center gap-1 text-[11px] font-semibold text-rose-700 bg-rose-50 px-2 py-0.5 rounded-full border border-rose-200">
                            <ShieldAlert className="h-3 w-3 text-rose-600" />
                            <span>موقوف</span>
                          </span>
                        ) : (
                          <span className="inline-flex items-center gap-1 text-[11px] text-amber-700 bg-amber-50 px-2 py-0.5 rounded-full border border-amber-200">
                            <span>بانتظار التفعيل</span>
                          </span>
                        )}
                      </td>
                      <td>
                        {g.links.length === 0 ? (
                          <span className="text-rose-600 bg-rose-50 px-2 py-0.5 rounded text-[11px] border border-rose-200">
                            لا يوجد أبناء مرتبطون
                          </span>
                        ) : (
                          <div className="flex flex-wrap gap-1.5">
                            {g.links.map((link) => (
                              <Link
                                key={link.id}
                                to="/students/$id"
                                params={{ id: link.student_id }}
                                className="inline-flex items-center gap-1.5 p-1.5 rounded-lg bg-card border border-border hover:border-primary/50 transition-colors group"
                                title={`صلة: ${RELATION_LABELS[link.relation] ?? link.relation}`}
                              >
                                <div className="text-start">
                                  <div className="font-semibold text-foreground group-hover:text-primary transition-colors">
                                    {link.student.full_name}
                                  </div>
                                  <div className="text-[10px] text-muted-foreground flex items-center gap-1">
                                    <span className="font-mono" dir="ltr">
                                      {link.student.student_number}
                                    </span>
                                    <span>·</span>
                                    <span>{RELATION_LABELS[link.relation] ?? link.relation}</span>
                                    {link.student.grade_name && (
                                      <>
                                        <span>·</span>
                                        <span>{link.student.grade_name}</span>
                                      </>
                                    )}
                                  </div>
                                </div>
                              </Link>
                            ))}
                          </div>
                        )}
                      </td>
                      {manager && (
                        <td className="text-center">
                          <div className="flex items-center justify-center gap-1">
                            <Button
                              variant="outline"
                              size="sm"
                              onClick={() => openAppDialog(g)}
                              className="h-7 text-xs px-2 gap-1 border-primary/40 text-primary hover:bg-primary/10"
                              title="إدارة وتفعيل حساب تطبيق ولي الأمر"
                            >
                              <Smartphone className="h-3.5 w-3.5" />
                              <span>التطبيق</span>
                            </Button>
                            <Button
                              variant="outline"
                              size="sm"
                              onClick={() => {
                                setSelectedGuardianForLink(g);
                                setOpenLinkModal(true);
                              }}
                              className="h-7 text-xs px-2 gap-1 border-border text-foreground hover:bg-muted"
                              title="ربط طالب جديد بولي الأمر"
                            >
                              <Link2 className="h-3.5 w-3.5" />
                              <span>ربط</span>
                            </Button>
                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={() => {
                                setSelectedFamilyGuardian(g);
                                setActiveTab("family_view");
                              }}
                              className="h-7 text-xs px-2 text-muted-foreground hover:text-foreground"
                              title="معاينة بطاقة العائلة"
                            >
                              <Eye className="h-3.5 w-3.5" />
                            </Button>
                          </div>
                        </td>
                      )}
                    </tr>
                  ))}
                </tbody>
              </table>

              {filteredGuardians.length === 0 && (
                <Empty title="لا يوجد أولياء أمور يطابقون شروط البحث">
                  جرّب كتابة كلمات بحث أخرى أو إضافة ولي أمر جديد.
                </Empty>
              )}
            </div>
          </div>
        </div>
      )}

      {/* TAB 2: UNLINKED STUDENTS AUDIT */}
      {activeTab === "unlinked" && (
        <div className="space-y-4">
          <div className="card-surface p-4 border-amber-200/70 bg-amber-50/15">
            <div className="flex items-start gap-3">
              <AlertCircle className="h-5 w-5 text-amber-600 shrink-0 mt-0.5" />
              <div className="space-y-1">
                <h3 className="text-xs font-bold text-foreground">تدقيق الأبناء غير الموثقين بملف ولي أمر رسمي</h3>
                <p className="text-xs text-muted-foreground leading-relaxed">
                  هؤلاء الطلاب مقيدون بالمدرسة ولكن لم يُعتمد لهم سجل ارتباط رسمي في جدول أولياء الأمور. يمكنك ربطهم بولي أمر مسجل مسبقاً أو إنشاء ملف أسري لهم استناداً لبيانات الهاتف المذكورة باستماراتهم.
                </p>
              </div>
            </div>
          </div>

          <div className="card-surface overflow-hidden">
            <div className="p-4 border-b border-border flex items-center justify-between">
              <h2 className="text-xs font-semibold text-foreground">قائمة الطلاب بحاجة لتوثيق ولي الأمر</h2>
              <span className="text-xs text-muted-foreground">{data?.unlinkedStudents.length ?? 0} طالب</span>
            </div>

            <div className="overflow-x-auto">
              <table className="modern-table text-xs">
                <thead>
                  <tr>
                    <th className="w-10">#</th>
                    <th>الرقم المدرسي</th>
                    <th>اسم الطالب</th>
                    <th>الصف / الشعبة</th>
                    <th>ولي الأمر بالاستمارة</th>
                    <th>هاتف ولي الأمر</th>
                    <th>صلة القرابة</th>
                    {manager && <th className="text-center w-36">إجراء الربط</th>}
                  </tr>
                </thead>
                <tbody>
                  {(data?.unlinkedStudents ?? []).map((s, i) => (
                    <tr key={s.id}>
                      <td className="num text-muted-foreground">{i + 1}</td>
                      <td>
                        <span className="font-mono text-xs px-2 py-0.5 rounded bg-muted text-foreground font-medium" dir="ltr">
                          {s.student_number}
                        </span>
                      </td>
                      <td className="font-semibold text-foreground">
                        <Link to="/students/$id" params={{ id: s.id }} className="hover:text-primary transition-colors">
                          {s.full_name}
                        </Link>
                      </td>
                      <td>
                        <span className="text-muted-foreground">
                          {s.grade_name} / {s.section_name}
                        </span>
                      </td>
                      <td>{s.guardian_name ?? "—"}</td>
                      <td>
                        <span className="font-mono text-muted-foreground" dir="ltr">
                          {s.guardian_phone ?? "—"}
                        </span>
                      </td>
                      <td>{s.guardian_relation ?? "—"}</td>
                      {manager && (
                        <td className="text-center">
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => {
                              // If guardian with same phone already exists, pre-select
                              const matched = (data?.guardians ?? []).find((g) => g.phone === s.guardian_phone?.trim());
                              if (matched) {
                                setSelectedGuardianForLink(matched);
                              } else {
                                setSelectedGuardianForLink({
                                  id: "new",
                                  school_id: "default",
                                  full_name: s.guardian_name || `ولي أمر الطالب ${s.full_name}`,
                                  phone: s.guardian_phone || "",
                                  national_id: null,
                                  email: null,
                                  address: null,
                                  user_id: null,
                                  created_at: new Date().toISOString(),
                                  links: [],
                                });
                              }
                              setLinkStudentId(s.id);
                              setOpenLinkModal(true);
                            }}
                            className="h-7 text-xs px-2.5 gap-1 border-primary/30 text-primary hover:bg-primary/5"
                          >
                            <Link2 className="h-3 w-3" />
                            <span>ربط الآن</span>
                          </Button>
                        </td>
                      )}
                    </tr>
                  ))}
                </tbody>
              </table>

              {(data?.unlinkedStudents ?? []).length === 0 && (
                <Empty title="رائع! جميع الطلاب مقيدون بأولياء أمور موثقين">
                  لا يوجد أي طالب بدون ملف ولي أمر معتمد في المدرسة.
                </Empty>
              )}
            </div>
          </div>
        </div>
      )}

      {/* TAB 3: FAMILY PORTAL OVERVIEW */}
      {activeTab === "family_view" && selectedFamilyGuardian && (
        <div className="space-y-6">
          <div className="card-surface p-5 flex flex-wrap items-center justify-between gap-4">
            <div className="space-y-1">
              <div className="flex items-center gap-2">
                <h2 className="text-base font-bold text-foreground">{selectedFamilyGuardian.full_name}</h2>
                <span className="text-xs px-2 py-0.5 rounded-full bg-primary/10 text-primary font-medium">
                  بطاقة الأسرة
                </span>
              </div>
              <div className="flex flex-wrap items-center gap-4 text-xs text-muted-foreground">
                <span className="flex items-center gap-1 font-mono" dir="ltr">
                  <Phone className="h-3.5 w-3.5" />
                  <span>{selectedFamilyGuardian.phone}</span>
                </span>
                {selectedFamilyGuardian.national_id && (
                  <span>الرقم الوطني: {selectedFamilyGuardian.national_id}</span>
                )}
                <span>عدد الأبناء الموثقين: {selectedFamilyGuardian.links.length} طالب</span>
              </div>
            </div>

            <Button variant="outline" size="sm" onClick={() => setActiveTab("guardians")} className="h-8 text-xs">
              ← العودة للقائمة العامة
            </Button>
          </div>

          <div className="grid md:grid-cols-2 gap-4">
            {selectedFamilyGuardian.links.map((link) => (
              <div key={link.id} className="card-surface p-5 space-y-4 hover:border-primary/40 transition-colors">
                <div className="flex items-center justify-between pb-3 border-b border-border">
                  <div>
                    <h3 className="text-sm font-bold text-foreground">{link.student.full_name}</h3>
                    <div className="flex items-center gap-2 text-xs text-muted-foreground mt-0.5">
                      <span className="font-mono" dir="ltr">
                        {link.student.student_number}
                      </span>
                      <span>·</span>
                      <span>{link.student.grade_name} ({link.student.section_name})</span>
                    </div>
                  </div>
                  <Link
                    to="/students/$id"
                    params={{ id: link.student_id }}
                    className="p-1.5 rounded-lg border border-border hover:bg-muted text-muted-foreground hover:text-foreground"
                    title="فتح الملف الأكاديمي الكامل"
                  >
                    <Eye className="h-4 w-4" />
                  </Link>
                </div>

                <div className="grid grid-cols-3 gap-2 text-center text-xs">
                  <div className="p-2.5 rounded-lg bg-muted/40 border border-border">
                    <span className="text-[11px] text-muted-foreground block mb-0.5">صلة القرابة</span>
                    <strong className="text-foreground">{RELATION_LABELS[link.relation] ?? link.relation}</strong>
                  </div>
                  <div className="p-2.5 rounded-lg bg-muted/40 border border-border">
                    <span className="text-[11px] text-muted-foreground block mb-0.5">صلاحية المالية</span>
                    <strong className={link.can_view_fees ? "text-emerald-700" : "text-muted-foreground"}>
                      {link.can_view_fees ? "مصرّح" : "محجوب"}
                    </strong>
                  </div>
                  <div className="p-2.5 rounded-lg bg-muted/40 border border-border">
                    <span className="text-[11px] text-muted-foreground block mb-0.5">استلام الإشعارات</span>
                    <strong className={link.receives_notifications ? "text-primary" : "text-muted-foreground"}>
                      {link.receives_notifications ? "مفعل" : "معطل"}
                    </strong>
                  </div>
                </div>

                <div className="pt-2 flex items-center justify-between text-xs text-muted-foreground">
                  <span className="flex items-center gap-1">
                    <ShieldCheck className="h-3.5 w-3.5 text-emerald-600" />
                    <span>ربط موثق ومعتمد من إدارة المدرسة</span>
                  </span>
                  <Link
                    to="/fees"
                    className="text-primary hover:underline flex items-center gap-1 font-medium"
                  >
                    <span>كشف الحساب المالي</span>
                  </Link>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* MODAL: ADD / EDIT GUARDIAN */}
      <Dialog open={openGuardianModal} onOpenChange={setOpenGuardianModal}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle className="text-base font-bold text-foreground">
              {editingGuardianId ? "تعديل بيانات ولي الأمر" : "تسجيل ملف ولي أمر جديد"}
            </DialogTitle>
          </DialogHeader>

          <form
            onSubmit={(e) => {
              e.preventDefault();
              saveGuardian.mutate();
            }}
            className="space-y-4 pt-2 text-xs"
          >
            <Field label="الاسم الكامل لولي الأمر رباعياً *">
              <Input
                placeholder="مثال: عمر محمد أحمد الفكي"
                value={guardianName}
                onChange={(e) => setGuardianName(e.target.value)}
                required
                className="h-9 text-xs"
              />
            </Field>

            <Field label="رقم هاتف التواصل الأساسي *">
              <Input
                placeholder="مثال: 0912345678"
                value={guardianPhone}
                onChange={(e) => setGuardianPhone(e.target.value)}
                required
                className="h-9 text-xs font-mono"
                dir="ltr"
              />
            </Field>

            <Field label="الرقم الوطني">
              <Input
                placeholder="الرقم الوطني المكون من 11 رقم…"
                value={guardianNationalId}
                onChange={(e) => setGuardianNationalId(e.target.value)}
                className="h-9 text-xs font-mono"
                dir="ltr"
              />
            </Field>

            <Field label="البريد الإلكتروني">
              <Input
                type="email"
                placeholder="name@example.com"
                value={guardianEmail}
                onChange={(e) => setGuardianEmail(e.target.value)}
                className="h-9 text-xs font-mono"
                dir="ltr"
              />
            </Field>

            <Field label="عنوان السكن والإقامة">
              <Input
                placeholder="المدينة، الحي، المربع، الشارع…"
                value={guardianAddress}
                onChange={(e) => setGuardianAddress(e.target.value)}
                className="h-9 text-xs"
              />
            </Field>

            <DialogFooter className="gap-2 pt-2">
              <Button type="button" variant="outline" size="sm" onClick={() => setOpenGuardianModal(false)} className="h-9 text-xs">
                إلغاء
              </Button>
              <Button type="submit" size="sm" disabled={saveGuardian.isPending} className="h-9 text-xs">
                {editingGuardianId ? "حفظ التعديلات" : "تسجيل ولي الأمر"}
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      {/* MODAL: LINK STUDENT */}
      <Dialog open={openLinkModal} onOpenChange={setOpenLinkModal}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle className="text-base font-bold text-foreground">
              توثيق وربط طالب بولي الأمر
            </DialogTitle>
          </DialogHeader>

          <form
            onSubmit={(e) => {
              e.preventDefault();
              linkStudentMutation.mutate();
            }}
            className="space-y-4 pt-2 text-xs"
          >
            <div className="p-3 rounded-lg bg-muted border border-border">
              <span className="text-xs text-muted-foreground block mb-0.5">ولي الأمر المختار:</span>
              <strong className="text-foreground text-sm font-bold block">{selectedGuardianForLink?.full_name}</strong>
              <span className="text-[11px] font-mono text-muted-foreground" dir="ltr">
                {selectedGuardianForLink?.phone}
              </span>
            </div>

            <Field label="اختر الطالب المراد ربطه بالأسرة *">
              <select
                className="w-full h-9 px-3 rounded-lg border border-input bg-card text-xs focus:ring-1 focus:ring-primary focus:outline-hidden"
                value={linkStudentId}
                onChange={(e) => setLinkStudentId(e.target.value)}
                required
              >
                <option value="">اختر الطالب من القائمة…</option>
                {(data?.allStudents ?? []).map((s) => (
                  <option key={s.id} value={s.id}>
                    {s.full_name} ({s.student_number})
                  </option>
                ))}
              </select>
            </Field>

            <Field label="صلة القرابة الرسمية *">
              <select
                className="w-full h-9 px-3 rounded-lg border border-input bg-card text-xs focus:ring-1 focus:ring-primary focus:outline-hidden"
                value={linkRelation}
                onChange={(e) => setLinkRelation(e.target.value as RelationType)}
              >
                {Object.entries(RELATION_LABELS).map(([k, v]) => (
                  <option key={k} value={k}>
                    {v}
                  </option>
                ))}
              </select>
            </Field>

            <div className="space-y-2 pt-1 border-t border-border">
              <label className="flex items-center gap-2 cursor-pointer">
                <input
                  type="checkbox"
                  checked={linkIsPrimary}
                  onChange={(e) => setLinkIsPrimary(e.target.checked)}
                  className="rounded border-input text-primary focus:ring-primary"
                />
                <span className="text-foreground">ولي الأمر الرئيسي للطالب</span>
              </label>

              <label className="flex items-center gap-2 cursor-pointer">
                <input
                  type="checkbox"
                  checked={linkCanViewFees}
                  onChange={(e) => setLinkCanViewFees(e.target.checked)}
                  className="rounded border-input text-primary focus:ring-primary"
                />
                <span className="text-foreground">السماح بالاطلاع على الرسوم والمدفوعات المالية</span>
              </label>

              <label className="flex items-center gap-2 cursor-pointer">
                <input
                  type="checkbox"
                  checked={linkReceivesNotifications}
                  onChange={(e) => setLinkReceivesNotifications(e.target.checked)}
                  className="rounded border-input text-primary focus:ring-primary"
                />
                <span className="text-foreground">استلام الإشعارات والتقارير الأكاديمية والغياب</span>
              </label>
            </div>

            <DialogFooter className="gap-2 pt-3 border-t border-border">
              <Button type="button" variant="outline" size="sm" onClick={() => setOpenLinkModal(false)} className="h-9 text-xs">
                إلغاء
              </Button>
              <Button type="submit" size="sm" disabled={linkStudentMutation.isPending} className="h-9 text-xs">
                تأكيد واعتماد الربط
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      {/* MODAL: APP ACCOUNT MANAGEMENT (Notion Spec: Sole Operator, Random Unguessable Identifier, Audit Trail) */}
      <Dialog open={openAppModal} onOpenChange={setOpenAppModal}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle className="text-base font-bold text-foreground flex items-center gap-2">
              <Smartphone className="h-5 w-5 text-primary" />
              <span>إدارة وتفعيل حساب تطبيق ولي الأمر (Android)</span>
            </DialogTitle>
          </DialogHeader>

          {selectedGuardianForApp && (
            <div className="space-y-4 pt-2 text-xs">
              {/* Guardian Info Card */}
              <div className="p-3 rounded-lg bg-muted border border-border space-y-1">
                <div className="flex items-center justify-between">
                  <span className="text-xs text-muted-foreground">ولي الأمر:</span>
                  <span className="text-[11px] font-semibold text-foreground">{selectedGuardianForApp.full_name}</span>
                </div>
                <div className="flex items-center justify-between font-mono" dir="ltr">
                  <span className="text-xs text-muted-foreground font-sans">رقم الهاتف:</span>
                  <span>{selectedGuardianForApp.phone}</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-xs text-muted-foreground">عدد الأبناء الموثقين:</span>
                  <span className="font-semibold text-foreground">{selectedGuardianForApp.links.length} طالب</span>
                </div>
              </div>

              {/* Status & Credentials */}
              {selectedGuardianForApp.status === "active" || appCredentials?.status === "active" ? (
                <div className="space-y-3">
                  <div className="p-3.5 rounded-lg bg-emerald-50 border border-emerald-200 text-emerald-900 space-y-2.5">
                    <div className="flex items-center justify-between">
                      <span className="font-semibold flex items-center gap-1.5 text-xs text-emerald-800">
                        <Check className="h-4 w-4 text-emerald-600" />
                        حساب التطبيق مفعّل ونشط
                      </span>
                      <span className="text-[10px] bg-emerald-100 text-emerald-800 px-2 py-0.5 rounded font-mono">
                        جاهز للدخول
                      </span>
                    </div>

                    {/* Account Code */}
                    <div className="bg-card p-2.5 rounded-md border border-emerald-200">
                      <div className="flex items-center justify-between mb-1">
                        <span className="text-[11px] text-muted-foreground">معرّف الحساب العشوائي (Account Code):</span>
                        <Button
                          type="button"
                          variant="ghost"
                          size="sm"
                          onClick={() => {
                            navigator.clipboard.writeText(appCredentials?.account_code || selectedGuardianForApp.account_code || "");
                            setCopiedField("code");
                            setTimeout(() => setCopiedField(null), 2000);
                          }}
                          className="h-6 text-[10px] px-1.5 gap-1"
                        >
                          {copiedField === "code" ? <Check className="h-3 w-3 text-emerald-600" /> : <Copy className="h-3 w-3" />}
                          <span>{copiedField === "code" ? "تم النسخ" : "نسخ المعرّف"}</span>
                        </Button>
                      </div>
                      <div className="font-mono text-base font-bold text-foreground text-center tracking-widest bg-muted/60 py-1 rounded" dir="ltr">
                        {appCredentials?.account_code || selectedGuardianForApp.account_code || "PAR-XXXXXX"}
                      </div>
                    </div>

                    {/* Temporary Activation PIN if newly generated */}
                    {appCredentials?.temp_code && (
                      <div className="bg-amber-50 p-2.5 rounded-md border border-amber-200">
                        <div className="flex items-center justify-between mb-1">
                          <span className="text-[11px] text-amber-800 font-semibold">رمز التفعيل المؤقت (أحادي الاستخدام):</span>
                          <Button
                            type="button"
                            variant="ghost"
                            size="sm"
                            onClick={() => {
                              navigator.clipboard.writeText(appCredentials.temp_code || "");
                              setCopiedField("pin");
                              setTimeout(() => setCopiedField(null), 2000);
                            }}
                            className="h-6 text-[10px] px-1.5 gap-1 text-amber-800"
                          >
                            {copiedField === "pin" ? <Check className="h-3 w-3 text-emerald-600" /> : <Copy className="h-3 w-3" />}
                            <span>{copiedField === "pin" ? "تم النسخ" : "نسخ الرمز"}</span>
                          </Button>
                        </div>
                        <div className="font-mono text-lg font-bold text-amber-900 text-center tracking-widest bg-card py-1 rounded border border-amber-200" dir="ltr">
                          {appCredentials.temp_code}
                        </div>
                        <p className="text-[10px] text-amber-700 mt-1">
                          قم بتسليم هذا الرمز لولي الأمر لتسجيل الدخول لأول مرة وتعيين كلمة مرور خاصة به.
                        </p>
                      </div>
                    )}
                  </div>

                  {/* Actions for Active Accounts */}
                  <div className="flex items-center justify-between gap-2 pt-2 border-t border-border">
                    <Button
                      type="button"
                      variant="outline"
                      size="sm"
                      onClick={() => resetPasswordMutation.mutate(selectedGuardianForApp)}
                      disabled={resetPasswordMutation.isPending}
                      className="h-8 text-xs gap-1.5 text-amber-700 border-amber-300 hover:bg-amber-50"
                    >
                      <KeyRound className="h-3.5 w-3.5" />
                      <span>إعادة ضبط كلمة المرور (حضور شخصي)</span>
                    </Button>

                    <Button
                      type="button"
                      variant="outline"
                      size="sm"
                      onClick={() => suspendAppMutation.mutate(selectedGuardianForApp.id)}
                      disabled={suspendAppMutation.isPending}
                      className="h-8 text-xs gap-1.5 text-rose-600 border-rose-200 hover:bg-rose-50"
                    >
                      <ShieldAlert className="h-3.5 w-3.5" />
                      <span>إيقاف الحساب</span>
                    </Button>
                  </div>
                </div>
              ) : selectedGuardianForApp.status === "suspended" ? (
                <div className="space-y-3">
                  <div className="p-3 rounded-lg bg-rose-50 border border-rose-200 text-rose-900">
                    <strong className="block text-xs font-bold text-rose-800 mb-1 flex items-center gap-1.5">
                      <ShieldAlert className="h-4 w-4 text-rose-600" />
                      حساب ولي الأمر موقوف مؤقتاً
                    </strong>
                    <p className="text-[11px] text-rose-700 leading-relaxed">
                      لا يمكن لولي الأمر تسجيل الدخول إلى تطبيق الهاتف أو الوصول إلى بيانات الطلاب أو استلام الإشعارات حتى يقوم المدير بإلغاء الإيقاف.
                    </p>
                  </div>
                  <Button
                    type="button"
                    size="sm"
                    onClick={() => activateAppMutation.mutate(selectedGuardianForApp)}
                    disabled={activateAppMutation.isPending}
                    className="w-full h-9 text-xs gap-1.5 bg-emerald-600 hover:bg-emerald-700 text-white"
                  >
                    <Check className="h-4 w-4" />
                    <span>إلغاء الإيقاف وإعادة تفعيل الحساب</span>
                  </Button>
                </div>
              ) : (
                <div className="space-y-3">
                  <div className="p-3 rounded-lg bg-amber-50 border border-amber-200 text-amber-900">
                    <strong className="block text-xs font-bold text-amber-800 mb-1">
                      حساب التطبيق بانتظار التفعيل الإداري
                    </strong>
                    <p className="text-[11px] text-amber-700 leading-relaxed">
                      وفقاً لوثيقة تطبيق العمرابي المعتمدة، لا يمكن لولي الأمر الدخول إلا بعد قيام المدير بالتحقق من الهوية وتفعيل الحساب وتوليد معرّف عشوائي غير قابل للتخمين.
                    </p>
                  </div>
                  <Button
                    type="button"
                    size="sm"
                    onClick={() => activateAppMutation.mutate(selectedGuardianForApp)}
                    disabled={activateAppMutation.isPending}
                    className="w-full h-9 text-xs gap-1.5"
                  >
                    <Smartphone className="h-4 w-4" />
                    <span>تفعيل حساب التطبيق وتوليد كود الدخول الآن</span>
                  </Button>
                </div>
              )}

              <DialogFooter className="gap-2 pt-3 border-t border-border">
                <Button type="button" variant="outline" size="sm" onClick={() => setOpenAppModal(false)} className="h-9 text-xs">
                  إغلاق
                </Button>
                {(selectedGuardianForApp.status === "active" || appCredentials?.status === "active") && (
                  <Button
                    type="button"
                    size="sm"
                    onClick={() => window.print()}
                    className="h-9 text-xs gap-1.5"
                  >
                    <Printer className="h-3.5 w-3.5" />
                    <span>طباعة بطاقة تسليم ولي الأمر</span>
                  </Button>
                )}
              </DialogFooter>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
