import { schoolPageHead } from "@/lib/pageHead";
import { createFileRoute } from "@tanstack/react-router";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import React, { useMemo, useState } from "react";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import { useSchool, useMe, canManage, errMsg } from "@/lib/staff";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { PageHead, StatCard, FilterPanel, Field, Empty } from "@/components/app/kit";
import {
  Calendar as CalendarIcon,
  Megaphone,
  Plus,
  Printer,
  ChevronRight,
  ChevronLeft,
  FileText,
  Clock,
  Users,
  AlertTriangle,
  Eye,
  EyeOff,
  Trash2,
  CalendarCheck2,
  Award,
  Sparkles,
} from "lucide-react";

export const Route = createFileRoute("/_authenticated/calendar")({
  head: () => schoolPageHead("التقويم المدرسي والإعلانات — مدرسة العمرابي", "التقويم المدرسي والإعلانات في نظام إدارة مدرسة العمرابي الثانوية."),
  component: CalendarPage,
});

export type EventType = "term_date" | "exam" | "holiday" | "meeting" | "event" | "result";
export type TargetAudience = "all" | "students" | "teachers" | "parents" | "staff_only";
export type Priority = "normal" | "important" | "urgent";

export interface SchoolEvent {
  id: string;
  school_id: string;
  academic_year_id: string | null;
  title: string;
  description: string | null;
  event_type: EventType;
  starts_on: string;
  ends_on: string | null;
  target_audience: TargetAudience;
  is_published: boolean;
  created_at: string;
}

export interface Announcement {
  id: string;
  school_id: string;
  title: string;
  body: string;
  priority: Priority;
  target_audience: TargetAudience;
  is_published: boolean;
  published_at: string;
  expires_at: string | null;
  created_at: string;
}

const EVENT_TYPE_LABELS: Record<EventType, { label: string; color: string; border: string; bg: string }> = {
  term_date: { label: "بداية / نهاية الفصل", color: "text-blue-700", border: "border-blue-200", bg: "bg-blue-50" },
  exam: { label: "امتحانات واختبارات", color: "text-rose-700", border: "border-rose-200", bg: "bg-rose-50" },
  holiday: { label: "عطلة رسمية", color: "text-emerald-700", border: "border-emerald-200", bg: "bg-emerald-50" },
  meeting: { label: "اجتماع إداري / تربوي", color: "text-purple-700", border: "border-purple-200", bg: "bg-purple-50" },
  event: { label: "فعالية مدرسية ونشاط", color: "text-amber-700", border: "border-amber-200", bg: "bg-amber-50" },
  result: { label: "إعلان نتائج وتقييمات", color: "text-teal-700", border: "border-teal-200", bg: "bg-teal-50" },
};

const AUDIENCE_LABELS: Record<TargetAudience, string> = {
  all: "الجميع (عام)",
  students: "الطلاب فقط",
  teachers: "هيئة التدريس",
  parents: "أولياء الأمور",
  staff_only: "الإدارة والكادر فقط (داخلي)",
};

const PRIORITY_LABELS: Record<Priority, { label: string; badge: string }> = {
  normal: { label: "عادي", badge: "bg-muted text-muted-foreground border-border" },
  important: { label: "مهم", badge: "bg-amber-50 text-amber-700 border-amber-200" },
  urgent: { label: "عاجل وهام", badge: "bg-rose-50 text-rose-700 border-rose-200" },
};

const WEEKDAY_NAMES = ["الأحد", "الإثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة", "السبت"];

function CalendarPage() {
  const qc = useQueryClient();
  const { data: school } = useSchool();
  const { data: me } = useMe();
  const manager = canManage(me?.roles ?? []);

  // View state
  const [activeTab, setActiveTab] = useState<"calendar" | "list" | "announcements">("calendar");
  const [currentDate, setCurrentDate] = useState<Date>(new Date());
  const [selectedDayDate, setSelectedDayDate] = useState<string | null>(null);

  // Filters
  const [typeFilter, setTypeFilter] = useState<string>("");
  const [audienceFilter, setAudienceFilter] = useState<string>("");
  const [searchQuery, setSearchQuery] = useState<string>("");
  const [publishedOnly, setPublishedOnly] = useState<string>("");

  // Modals
  const [openEventModal, setOpenEventModal] = useState(false);
  const [openAnnounceModal, setOpenAnnounceModal] = useState(false);

  // Event Form State
  const [eventTitle, setEventTitle] = useState("");
  const [eventDesc, setEventDesc] = useState("");
  const [eventType, setEventType] = useState<EventType>("term_date");
  const [eventStart, setEventStart] = useState(new Date().toISOString().split("T")[0]);
  const [eventEnd, setEventEnd] = useState("");
  const [eventAudience, setEventAudience] = useState<TargetAudience>("all");
  const [eventPublished, setEventPublished] = useState(true);

  // Announcement Form State
  const [annTitle, setAnnTitle] = useState("");
  const [annBody, setAnnBody] = useState("");
  const [annPriority, setAnnPriority] = useState<Priority>("normal");
  const [annAudience, setAnnAudience] = useState<TargetAudience>("all");
  const [annPublished, setAnnPublished] = useState(true);

  // Query: Events and Announcements
  const { data, isLoading, isError, refetch } = useQuery({
    queryKey: ["school_calendar_and_announcements"],
    queryFn: async () => {
      const { data: year, error: yErr } = await supabase
        .from("academic_years")
        .select("*")
        .eq("is_current", true)
        .maybeSingle();
      if (yErr) throw yErr;

      let events: SchoolEvent[] = [];
      const { data: evs, error: evsError } = await supabase
        .from("school_events")
        .select("*")
        .order("starts_on", { ascending: true });
      if (evsError) {
        if (evsError.code === "42P01" || evsError.message?.includes("does not exist")) {
          events = [];
        } else {
          throw evsError;
        }
      } else {
        events = (evs ?? []) as SchoolEvent[];
      }

      let announcements: Announcement[] = [];
      const { data: anns, error: annsError } = await supabase
        .from("announcements")
        .select("*")
        .order("published_at", { ascending: false });
      if (annsError) {
        if (annsError.code === "42P01" || annsError.message?.includes("does not exist")) {
          announcements = [];
        } else {
          throw annsError;
        }
      } else {
        announcements = (anns ?? []) as Announcement[];
      }

      return { year, events, announcements };
    },
  });

  const refresh = () => qc.invalidateQueries({ queryKey: ["school_calendar_and_announcements"] });

  // Helper to ensure valid school ID
  const getSchoolId = async () => {
    if (school?.id) return school.id;
    const { data: s } = await supabase.from("schools").select("id").limit(1).maybeSingle();
    if (s?.id) return s.id;
    throw new Error("تعذر تحديد المدرسة المسجلة في النظام");
  };

  // Create Event Mutation
  const createEvent = useMutation({
    mutationFn: async () => {
      if (!eventTitle.trim()) throw new Error("يرجى كتابة عنوان الفعالية أو الحدث");
      if (!eventStart) throw new Error("يرجى تحديد تاريخ البداية");

      const schoolId = await getSchoolId();

      const { error } = await supabase.from("school_events").insert({
        school_id: schoolId,
        academic_year_id: data?.year?.id ?? null,
        title: eventTitle.trim(),
        description: eventDesc.trim() || null,
        event_type: eventType,
        starts_on: eventStart,
        ends_on: eventEnd || null,
        target_audience: eventAudience,
        is_published: eventPublished,
      });
      if (error) throw error;
    },
    onSuccess: () => {
      toast.success("تمت إضافة الحدث إلى التقويم بنجاح");
      setOpenEventModal(false);
      setEventTitle("");
      setEventDesc("");
      setEventEnd("");
      refresh();
    },
    onError: (e) => toast.error(errMsg(e)),
  });

  // Create Announcement Mutation
  const createAnnouncement = useMutation({
    mutationFn: async () => {
      if (!annTitle.trim()) throw new Error("يرجى كتابة عنوان الإعلان");
      if (!annBody.trim()) throw new Error("يرجى كتابة نص الإعلان");

      const schoolId = await getSchoolId();

      const { error } = await supabase.from("announcements").insert({
        school_id: schoolId,
        title: annTitle.trim(),
        body: annBody.trim(),
        priority: annPriority,
        target_audience: annAudience,
        is_published: annPublished,
      });
      if (error) throw error;
    },
    onSuccess: () => {
      toast.success("تم نشر الإعلان المدرسي بنجاح");
      setOpenAnnounceModal(false);
      setAnnTitle("");
      setAnnBody("");
      refresh();
    },
    onError: (e) => toast.error(errMsg(e)),
  });

  // Toggle Event Publish
  const toggleEventPublish = useMutation({
    mutationFn: async ({ id, is_published }: { id: string; is_published: boolean }) => {
      const { error } = await supabase.from("school_events").update({ is_published }).eq("id", id);
      if (error) throw error;
    },
    onSuccess: () => {
      toast.success("تم تحديث حالة النشر");
      refresh();
    },
    onError: (e) => toast.error(errMsg(e)),
  });

  // Filtered Events
  const filteredEvents = useMemo(() => {
    return (data?.events ?? []).filter((e) => {
      if (typeFilter && e.event_type !== typeFilter) return false;
      if (audienceFilter && e.target_audience !== audienceFilter) return false;
      if (publishedOnly === "published" && !e.is_published) return false;
      if (publishedOnly === "draft" && e.is_published) return false;
      if (searchQuery) {
        const q = searchQuery.toLowerCase();
        const matchesTitle = e.title.toLowerCase().includes(q);
        const matchesDesc = (e.description ?? "").toLowerCase().includes(q);
        if (!matchesTitle && !matchesDesc) return false;
      }
      return true;
    });
  }, [data?.events, typeFilter, audienceFilter, publishedOnly, searchQuery]);

  // Filtered Announcements
  const filteredAnnouncements = useMemo(() => {
    return (data?.announcements ?? []).filter((a) => {
      if (audienceFilter && a.target_audience !== audienceFilter) return false;
      if (publishedOnly === "published" && !a.is_published) return false;
      if (publishedOnly === "draft" && a.is_published) return false;
      if (searchQuery) {
        const q = searchQuery.toLowerCase();
        const matchesTitle = a.title.toLowerCase().includes(q);
        const matchesBody = a.body.toLowerCase().includes(q);
        if (!matchesTitle && !matchesBody) return false;
      }
      return true;
    });
  }, [data?.announcements, audienceFilter, publishedOnly, searchQuery]);

  // Calendar Calculations
  const year = currentDate.getFullYear();
  const month = currentDate.getMonth();

  const daysInMonth = new Date(year, month + 1, 0).getDate();
  const firstDayIndex = new Date(year, month, 1).getDay(); // 0 is Sunday in JS

  const monthName = currentDate.toLocaleDateString("ar-SD", { month: "long", year: "numeric" });

  const prevMonth = () => setCurrentDate(new Date(year, month - 1, 1));
  const nextMonth = () => setCurrentDate(new Date(year, month + 1, 1));
  const resetToToday = () => setCurrentDate(new Date());

  // KPI Calculations
  const stats = useMemo(() => {
    const totalEvents = data?.events.length ?? 0;
    const examsCount = (data?.events ?? []).filter((e) => e.event_type === "exam").length;
    const holidaysCount = (data?.events ?? []).filter((e) => e.event_type === "holiday").length;
    const activeAnnouncements = (data?.announcements ?? []).filter((a) => a.is_published).length;
    return { totalEvents, examsCount, holidaysCount, activeAnnouncements };
  }, [data]);

  // Events map by YYYY-MM-DD
  const eventsByDate = useMemo(() => {
    const map = new Map<string, SchoolEvent[]>();
    for (const e of filteredEvents) {
      const start = e.starts_on;
      const cur = map.get(start) ?? [];
      cur.push(e);
      map.set(start, cur);
    }
    return map;
  }, [filteredEvents]);

  // Export CSV
  const exportCsv = () => {
    const headers = ["العنوان", "نوع الحدث", "تاريخ البداية", "تاريخ الانتهاء", "الفئة المستهدفة", "حالة النشر", "التفاصيل"];
    const rows = filteredEvents.map((e) => [
      e.title,
      EVENT_TYPE_LABELS[e.event_type]?.label ?? e.event_type,
      e.starts_on,
      e.ends_on ?? "—",
      AUDIENCE_LABELS[e.target_audience] ?? e.target_audience,
      e.is_published ? "منشور للعامة" : "داخلي فقط",
      e.description ?? "—",
    ]);

    const csvContent = "\uFEFF" + [headers, ...rows].map((r) => r.map((c) => `"${String(c).replace(/"/g, '""')}"`).join(",")).join("\n");
    const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" });
    const link = document.createElement("a");
    link.href = URL.createObjectURL(blob);
    link.download = `school_calendar_${new Date().toISOString().split("T")[0]}.csv`;
    link.click();
  };

  if (isError) {
    return (
      <div className="py-20 flex flex-col items-center justify-center text-center p-6 card-surface">
        <p className="text-sm text-destructive font-medium mb-3">حدث خطأ أثناء تحميل التقويم المدرسي والإعلانات.</p>
        <Button variant="outline" size="sm" onClick={() => refetch()} className="text-xs">
          إعادة المحاولة
        </Button>
      </div>
    );
  }

  if (isLoading) {
    return (
      <div className="py-20 flex flex-col items-center justify-center text-muted-foreground text-sm">
        <div className="h-8 w-8 animate-spin rounded-full border-2 border-primary border-t-transparent mb-3" />
        <span>جارٍ تحميل التقويم المدرسي والإعلانات…</span>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <PageHead
        title="التقويم المدرسي والإعلانات"
        sub={
          <span>
            العام الدراسي الحالي: <strong className="text-foreground">{data?.year?.name ?? "2026 / 2027"}</strong>
            {" · "}
            إدارة المواعيد والامتحانات والإجازات والتعاميم المدرسية
          </span>
        }
        actions={
          <div className="flex flex-wrap items-center gap-2">
            <Button variant="outline" size="sm" onClick={() => window.print()} className="h-9 gap-1.5 text-xs">
              <Printer className="h-3.5 w-3.5" />
              <span>طباعة التقويم</span>
            </Button>
            <Button variant="outline" size="sm" onClick={exportCsv} className="h-9 gap-1.5 text-xs">
              <FileText className="h-3.5 w-3.5" />
              <span>تصدير (CSV)</span>
            </Button>
            {manager && (
              <>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => setOpenAnnounceModal(true)}
                  className="h-9 gap-1.5 text-xs border-primary/40 text-primary hover:bg-primary/5"
                >
                  <Megaphone className="h-3.5 w-3.5" />
                  <span>+ إعلان جديد</span>
                </Button>
                <Button size="sm" onClick={() => setOpenEventModal(true)} className="h-9 gap-1.5 text-xs">
                  <Plus className="h-3.5 w-3.5" />
                  <span>+ إضافة حدث للتقويم</span>
                </Button>
              </>
            )}
          </div>
        }
      />

      {/* KPI Stats */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3 md:gap-4">
        <StatCard
          label="إجمالي الفعاليات المقيدة"
          value={stats.totalEvents}
          note="محطات زمنية مسجلة"
          icon={CalendarCheck2}
        />
        <StatCard
          label="مواعيد الامتحانات"
          value={stats.examsCount}
          note="امتحانات نصفية ونهائية"
          icon={Award}
          variant="primary"
        />
        <StatCard
          label="العطلات والإجازات"
          value={stats.holidaysCount}
          note="عطلات رسمية ومدرسية"
          icon={Sparkles}
          variant="success"
        />
        <StatCard
          label="الإعلانات النشطة"
          value={stats.activeAnnouncements}
          note="تعاميم منشورة بالمدرسة"
          icon={Megaphone}
          variant="warning"
        />
      </div>

      {/* View Switcher Tabs */}
      <div className="flex items-center gap-2 border-b border-border pb-2">
        <button
          onClick={() => setActiveTab("calendar")}
          className={`flex items-center gap-2 px-4 py-2 text-xs font-semibold rounded-lg transition-colors ${
            activeTab === "calendar"
              ? "bg-primary text-primary-foreground"
              : "text-muted-foreground hover:bg-muted hover:text-foreground"
          }`}
        >
          <CalendarIcon className="h-3.5 w-3.5" />
          <span>عرض التقويم الشهري</span>
        </button>
        <button
          onClick={() => setActiveTab("list")}
          className={`flex items-center gap-2 px-4 py-2 text-xs font-semibold rounded-lg transition-colors ${
            activeTab === "list"
              ? "bg-primary text-primary-foreground"
              : "text-muted-foreground hover:bg-muted hover:text-foreground"
          }`}
        >
          <FileText className="h-3.5 w-3.5" />
          <span>جدول الفعاليات والأحداث ({filteredEvents.length})</span>
        </button>
        <button
          onClick={() => setActiveTab("announcements")}
          className={`flex items-center gap-2 px-4 py-2 text-xs font-semibold rounded-lg transition-colors ${
            activeTab === "announcements"
              ? "bg-primary text-primary-foreground"
              : "text-muted-foreground hover:bg-muted hover:text-foreground"
          }`}
        >
          <Megaphone className="h-3.5 w-3.5" />
          <span>لوحة الإعلانات والتعاميم ({filteredAnnouncements.length})</span>
        </button>
      </div>

      {/* Filter Panel */}
      <FilterPanel
        title="تصفية المواعيد والفعاليات"
        onReset={() => {
          setTypeFilter("");
          setAudienceFilter("");
          setSearchQuery("");
          setPublishedOnly("");
        }}
      >
        <Field label="البحث في العنوان والتفاصيل">
          <Input
            placeholder="ابحث عن حدث، امتحان، عطلة…"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="h-9 text-xs"
          />
        </Field>

        <Field label="نوع الحدث">
          <select
            className="w-full h-9 px-3 rounded-lg border border-input bg-card text-xs focus:ring-1 focus:ring-primary focus:outline-hidden"
            value={typeFilter}
            onChange={(e) => setTypeFilter(e.target.value)}
          >
            <option value="">كافة الأنواع</option>
            {Object.entries(EVENT_TYPE_LABELS).map(([k, v]) => (
              <option key={k} value={k}>
                {v.label}
              </option>
            ))}
          </select>
        </Field>

        <Field label="الفئة المستهدفة">
          <select
            className="w-full h-9 px-3 rounded-lg border border-input bg-card text-xs focus:ring-1 focus:ring-primary focus:outline-hidden"
            value={audienceFilter}
            onChange={(e) => setAudienceFilter(e.target.value)}
          >
            <option value="">كافة الفئات</option>
            {Object.entries(AUDIENCE_LABELS).map(([k, v]) => (
              <option key={k} value={k}>
                {v}
              </option>
            ))}
          </select>
        </Field>

        <Field label="حالة النشر">
          <select
            className="w-full h-9 px-3 rounded-lg border border-input bg-card text-xs focus:ring-1 focus:ring-primary focus:outline-hidden"
            value={publishedOnly}
            onChange={(e) => setPublishedOnly(e.target.value)}
          >
            <option value="">الكل (منشور ومسودة)</option>
            <option value="published">منشور للعامة وأولياء الأمور</option>
            <option value="draft">داخلي ومسودة فقط</option>
          </select>
        </Field>
      </FilterPanel>

      {/* TAB 1: MONTH CALENDAR GRID */}
      {activeTab === "calendar" && (
        <div className="card-surface p-4 md:p-6 space-y-4">
          {/* Calendar Controls */}
          <div className="flex flex-wrap items-center justify-between gap-3 pb-3 border-b border-border">
            <div className="flex items-center gap-2">
              <Button variant="outline" size="sm" onClick={prevMonth} className="h-8 w-8 p-0">
                <ChevronRight className="h-4 w-4" />
              </Button>
              <h2 className="text-base font-bold text-foreground min-w-44 text-center">{monthName}</h2>
              <Button variant="outline" size="sm" onClick={nextMonth} className="h-8 w-8 p-0">
                <ChevronLeft className="h-4 w-4" />
              </Button>
              <Button variant="ghost" size="sm" onClick={resetToToday} className="h-8 text-xs text-primary font-medium">
                اليوم
              </Button>
            </div>

            {/* Quick Legend */}
            <div className="flex flex-wrap items-center gap-2 text-[11px]">
              <span className="flex items-center gap-1">
                <span className="h-2 w-2 rounded-full bg-rose-500 inline-block" />
                <span>امتحان</span>
              </span>
              <span className="flex items-center gap-1">
                <span className="h-2 w-2 rounded-full bg-emerald-500 inline-block" />
                <span>إجازة</span>
              </span>
              <span className="flex items-center gap-1">
                <span className="h-2 w-2 rounded-full bg-blue-500 inline-block" />
                <span>فصل دراسي</span>
              </span>
              <span className="flex items-center gap-1">
                <span className="h-2 w-2 rounded-full bg-purple-500 inline-block" />
                <span>اجتماع</span>
              </span>
              <span className="flex items-center gap-1">
                <span className="h-2 w-2 rounded-full bg-teal-500 inline-block" />
                <span>نتائج</span>
              </span>
            </div>
          </div>

          {/* Weekday headers */}
          <div className="grid grid-cols-7 gap-1 md:gap-2 text-center text-xs font-semibold text-muted-foreground pb-1">
            {WEEKDAY_NAMES.map((w) => (
              <div key={w} className="py-1">
                {w}
              </div>
            ))}
          </div>

          {/* Days Grid */}
          <div className="grid grid-cols-7 gap-1 md:gap-2">
            {/* Empty slots for first week offset */}
            {Array.from({ length: firstDayIndex }).map((_, i) => (
              <div key={`empty-${i}`} className="min-h-24 rounded-lg bg-muted/20 border border-transparent p-1.5" />
            ))}

            {/* Actual Month Days */}
            {Array.from({ length: daysInMonth }).map((_, i) => {
              const day = i + 1;
              const dateStr = `${year}-${String(month + 1).padStart(2, "0")}-${String(day).padStart(2, "0")}`;
              const dayEvents = eventsByDate.get(dateStr) ?? [];
              const isToday =
                new Date().toISOString().split("T")[0] === dateStr;
              const isSelected = selectedDayDate === dateStr;

              return (
                <div
                  key={dateStr}
                  onClick={() => setSelectedDayDate(dateStr === selectedDayDate ? null : dateStr)}
                  className={`min-h-24 rounded-lg border p-1.5 flex flex-col justify-between transition-colors cursor-pointer ${
                    isSelected
                      ? "border-primary bg-primary/5 ring-1 ring-primary"
                      : isToday
                      ? "border-primary/50 bg-primary/5"
                      : "border-border/60 bg-card hover:border-border"
                  }`}
                >
                  <div className="flex items-center justify-between">
                    <span
                      className={`text-xs font-bold tabular-nums rounded-full h-6 w-6 flex items-center justify-center ${
                        isToday ? "bg-primary text-primary-foreground font-semibold" : "text-foreground"
                      }`}
                    >
                      {day}
                    </span>
                    {dayEvents.length > 0 && (
                      <span className="text-[10px] text-muted-foreground font-mono font-medium">
                        {dayEvents.length}
                      </span>
                    )}
                  </div>

                  <div className="space-y-1 mt-1 overflow-hidden">
                    {dayEvents.slice(0, 2).map((ev) => {
                      const style = EVENT_TYPE_LABELS[ev.event_type] ?? EVENT_TYPE_LABELS.event;
                      return (
                        <div
                          key={ev.id}
                          className={`text-[10px] px-1.5 py-0.5 rounded truncate font-medium border ${style.bg} ${style.color} ${style.border}`}
                          title={`${ev.title} (${style.label})`}
                        >
                          {ev.title}
                        </div>
                      );
                    })}
                    {dayEvents.length > 2 && (
                      <div className="text-[10px] text-muted-foreground text-center font-medium">
                        +{dayEvents.length - 2} المزيد
                      </div>
                    )}
                  </div>
                </div>
              );
            })}
          </div>

          {/* Selected Day Details Panel */}
          {selectedDayDate && (
            <div className="mt-4 p-4 rounded-xl border border-primary/30 bg-primary/5 space-y-3">
              <div className="flex items-center justify-between">
                <div className="text-xs font-bold text-foreground">
                  أحداث وتفاصيل يوم: <span className="font-mono">{selectedDayDate}</span>
                </div>
                <Button variant="ghost" size="sm" onClick={() => setSelectedDayDate(null)} className="h-6 text-xs px-2">
                  إغلاق التفاصيل
                </Button>
              </div>

              {(!eventsByDate.get(selectedDayDate) || eventsByDate.get(selectedDayDate)!.length === 0) ? (
                <p className="text-xs text-muted-foreground">لا توجد فعاليات مسجلة في هذا اليوم المحدد.</p>
              ) : (
                <div className="grid sm:grid-cols-2 gap-3">
                  {eventsByDate.get(selectedDayDate)!.map((ev) => {
                    const style = EVENT_TYPE_LABELS[ev.event_type] ?? EVENT_TYPE_LABELS.event;
                    return (
                      <div key={ev.id} className="p-3 rounded-lg bg-card border border-border space-y-2">
                        <div className="flex items-center justify-between">
                          <span className={`text-[11px] px-2 py-0.5 rounded-full font-medium border ${style.bg} ${style.color} ${style.border}`}>
                            {style.label}
                          </span>
                          <span className="text-[11px] text-muted-foreground">
                            {AUDIENCE_LABELS[ev.target_audience]}
                          </span>
                        </div>
                        <h4 className="text-xs font-bold text-foreground">{ev.title}</h4>
                        {ev.description && <p className="text-xs text-muted-foreground leading-relaxed">{ev.description}</p>}
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
          )}
        </div>
      )}

      {/* TAB 2: EVENTS TIMELINE LIST */}
      {activeTab === "list" && (
        <div className="card-surface overflow-hidden">
          <div className="p-4 border-b border-border flex items-center justify-between">
            <h2 className="text-xs font-semibold text-foreground">سجل الأحداث والمحطات الزمنية</h2>
            <span className="text-xs text-muted-foreground">{filteredEvents.length} حدث</span>
          </div>

          <div className="overflow-x-auto">
            <table className="modern-table text-xs">
              <thead>
                <tr>
                  <th className="w-12">#</th>
                  <th>عنوان الفعالية / الحدث</th>
                  <th>نوع الحدث</th>
                  <th>تاريخ البداية</th>
                  <th>تاريخ الانتهاء</th>
                  <th>الفئة المستهدفة</th>
                  <th>حالة النشر</th>
                  {manager && <th className="text-center w-28">إجراءات</th>}
                </tr>
              </thead>
              <tbody>
                {filteredEvents.map((ev, index) => {
                  const style = EVENT_TYPE_LABELS[ev.event_type] ?? EVENT_TYPE_LABELS.event;
                  return (
                    <tr key={ev.id}>
                      <td className="num text-muted-foreground">{index + 1}</td>
                      <td>
                        <div className="font-semibold text-foreground">{ev.title}</div>
                        {ev.description && (
                          <div className="text-[11px] text-muted-foreground line-clamp-1 mt-0.5">{ev.description}</div>
                        )}
                      </td>
                      <td>
                        <span className={`inline-flex px-2 py-0.5 rounded-full text-[11px] font-medium border ${style.bg} ${style.color} ${style.border}`}>
                          {style.label}
                        </span>
                      </td>
                      <td className="font-mono text-foreground font-medium" dir="ltr">
                        {ev.starts_on}
                      </td>
                      <td className="font-mono text-muted-foreground" dir="ltr">
                        {ev.ends_on ?? "—"}
                      </td>
                      <td>
                        <span className="text-muted-foreground font-medium">
                          {AUDIENCE_LABELS[ev.target_audience]}
                        </span>
                      </td>
                      <td>
                        {ev.is_published ? (
                          <span className="inline-flex items-center gap-1 text-[11px] text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded-full border border-emerald-200">
                            <Eye className="h-3 w-3" />
                            <span>منشور للعامة</span>
                          </span>
                        ) : (
                          <span className="inline-flex items-center gap-1 text-[11px] text-muted-foreground bg-muted px-2 py-0.5 rounded-full border border-border">
                            <EyeOff className="h-3 w-3" />
                            <span>داخلي فقط</span>
                          </span>
                        )}
                      </td>
                      {manager && (
                        <td className="text-center">
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => toggleEventPublish.mutate({ id: ev.id, is_published: !ev.is_published })}
                            className="h-7 text-xs px-2 gap-1 text-muted-foreground hover:text-foreground"
                            title={ev.is_published ? "إلغاء النشر وجعله داخليًا" : "نشر لأولياء الأمور"}
                          >
                            {ev.is_published ? <EyeOff className="h-3.5 w-3.5" /> : <Eye className="h-3.5 w-3.5" />}
                            <span>{ev.is_published ? "إخفاء" : "نشر"}</span>
                          </Button>
                        </td>
                      )}
                    </tr>
                  );
                })}
              </tbody>
            </table>

            {filteredEvents.length === 0 && (
              <Empty title="لا توجد فعاليات مسجلة تطابق التصفية">
                يمكنك إضافة موعد جديد أو إعادة ضبط خيارات التصفية لعرض النتائج.
              </Empty>
            )}
          </div>
        </div>
      )}

      {/* TAB 3: ANNOUNCEMENTS BOARD */}
      {activeTab === "announcements" && (
        <div className="space-y-4">
          <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
            {filteredAnnouncements.map((ann) => {
              const priority = PRIORITY_LABELS[ann.priority] ?? PRIORITY_LABELS.normal;
              return (
                <div key={ann.id} className="card-surface p-5 flex flex-col justify-between space-y-4 hover:border-primary/40 transition-colors">
                  <div className="space-y-2.5">
                    <div className="flex items-center justify-between gap-2">
                      <span className={`inline-flex px-2 py-0.5 rounded-full text-[11px] font-medium border ${priority.badge}`}>
                        {priority.label}
                      </span>
                      <span className="text-[11px] text-muted-foreground">
                        {new Date(ann.published_at).toLocaleDateString("ar-SD", { day: "numeric", month: "short", year: "numeric" })}
                      </span>
                    </div>

                    <h3 className="text-sm font-bold text-foreground leading-snug">{ann.title}</h3>
                    <p className="text-xs text-muted-foreground leading-relaxed whitespace-pre-line">{ann.body}</p>
                  </div>

                  <div className="pt-3 border-t border-border/60 flex items-center justify-between text-[11px] text-muted-foreground">
                    <span className="flex items-center gap-1">
                      <Users className="h-3.5 w-3.5 text-primary" />
                      <span>{AUDIENCE_LABELS[ann.target_audience]}</span>
                    </span>
                    <span className={ann.is_published ? "text-emerald-600 font-medium" : "text-muted-foreground"}>
                      {ann.is_published ? "معروض للجميع" : "مسودة داخلية"}
                    </span>
                  </div>
                </div>
              );
            })}
          </div>

          {filteredAnnouncements.length === 0 && (
            <div className="card-surface p-8 text-center">
              <Empty title="لا توجد إعلانات منشورة">
                لم يتم تسجيل أي تعميم أو إعلان مدرسي يطابق شروط التصفية الحالية.
              </Empty>
            </div>
          )}
        </div>
      )}

      {/* MODAL: ADD CALENDAR EVENT */}
      <Dialog open={openEventModal} onOpenChange={setOpenEventModal}>
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle className="text-lg font-bold">إضافة موعد أو فعالية جديدة إلى التقويم</DialogTitle>
          </DialogHeader>

          <form
            onSubmit={(e) => {
              e.preventDefault();
              createEvent.mutate();
            }}
            className="space-y-4 pt-2 text-xs"
          >
            <Field label="عنوان الفعالية / الحدث *">
              <Input
                placeholder="مثال: بداية امتحانات الفترة الأولى…"
                value={eventTitle}
                onChange={(e) => setEventTitle(e.target.value)}
                required
                className="h-9 text-xs"
              />
            </Field>

            <div className="grid grid-cols-2 gap-3">
              <Field label="نوع الحدث *">
                <select
                  className="w-full h-9 px-3 rounded-lg border border-input bg-card text-xs focus:ring-1 focus:ring-primary focus:outline-hidden"
                  value={eventType}
                  onChange={(e) => setEventType(e.target.value as EventType)}
                >
                  {Object.entries(EVENT_TYPE_LABELS).map(([k, v]) => (
                    <option key={k} value={k}>
                      {v.label}
                    </option>
                  ))}
                </select>
              </Field>

              <Field label="الفئة المستهدفة *">
                <select
                  className="w-full h-9 px-3 rounded-lg border border-input bg-card text-xs focus:ring-1 focus:ring-primary focus:outline-hidden"
                  value={eventAudience}
                  onChange={(e) => setEventAudience(e.target.value as TargetAudience)}
                >
                  {Object.entries(AUDIENCE_LABELS).map(([k, v]) => (
                    <option key={k} value={k}>
                      {v}
                    </option>
                  ))}
                </select>
              </Field>
            </div>

            <div className="grid grid-cols-2 gap-3">
              <Field label="تاريخ البداية *">
                <Input
                  type="date"
                  value={eventStart}
                  onChange={(e) => setEventStart(e.target.value)}
                  required
                  className="h-9 text-xs"
                />
              </Field>

              <Field label="تاريخ الانتهاء (اختياري)">
                <Input
                  type="date"
                  value={eventEnd}
                  onChange={(e) => setEventEnd(e.target.value)}
                  className="h-9 text-xs"
                />
              </Field>
            </div>

            <Field label="تفاصيل وملاحظات إضافية">
              <Textarea
                placeholder="اكتب توضيحات إضافية حول الترتيبات أو الفصول المعنية…"
                value={eventDesc}
                onChange={(e) => setEventDesc(e.target.value)}
                rows={3}
                className="text-xs"
              />
            </Field>

            <div className="flex items-center gap-2 pt-1">
              <input
                type="checkbox"
                id="event_pub"
                checked={eventPublished}
                onChange={(e) => setEventPublished(e.target.checked)}
                className="rounded border-input text-primary focus:ring-primary"
              />
              <label htmlFor="event_pub" className="text-xs text-foreground cursor-pointer">
                نشر الحدث في التقويم العام (يظهر لأولياء الأمور والطلاب)
              </label>
            </div>

            <div className="flex justify-end gap-2 pt-3 border-t border-border">
              <Button type="button" variant="outline" size="sm" onClick={() => setOpenEventModal(false)} className="h-9 text-xs">
                إلغاء
              </Button>
              <Button type="submit" size="sm" disabled={createEvent.isPending} className="h-9 text-xs">
                حفظ وإدراج الحدث
              </Button>
            </div>
          </form>
        </DialogContent>
      </Dialog>

      {/* MODAL: ADD ANNOUNCEMENT */}
      <Dialog open={openAnnounceModal} onOpenChange={setOpenAnnounceModal}>
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle className="text-lg font-bold">إصدار ونشر إعلان مدرسي جديد</DialogTitle>
          </DialogHeader>

          <form
            onSubmit={(e) => {
              e.preventDefault();
              createAnnouncement.mutate();
            }}
            className="space-y-4 pt-2 text-xs"
          >
            <Field label="عنوان الإعلان أو التعميم *">
              <Input
                placeholder="مثال: إشعار هام بخصوص موعد طابور الصباح…"
                value={annTitle}
                onChange={(e) => setAnnTitle(e.target.value)}
                required
                className="h-9 text-xs"
              />
            </Field>

            <div className="grid grid-cols-2 gap-3">
              <Field label="درجة الأهمية">
                <select
                  className="w-full h-9 px-3 rounded-lg border border-input bg-card text-xs focus:ring-1 focus:ring-primary focus:outline-hidden"
                  value={annPriority}
                  onChange={(e) => setAnnPriority(e.target.value as Priority)}
                >
                  {Object.entries(PRIORITY_LABELS).map(([k, v]) => (
                    <option key={k} value={k}>
                      {v.label}
                    </option>
                  ))}
                </select>
              </Field>

              <Field label="الفئة المستهدفة">
                <select
                  className="w-full h-9 px-3 rounded-lg border border-input bg-card text-xs focus:ring-1 focus:ring-primary focus:outline-hidden"
                  value={annAudience}
                  onChange={(e) => setAnnAudience(e.target.value as TargetAudience)}
                >
                  {Object.entries(AUDIENCE_LABELS).map(([k, v]) => (
                    <option key={k} value={k}>
                      {v}
                    </option>
                  ))}
                </select>
              </Field>
            </div>

            <Field label="نص التعميم المدرسي *">
              <Textarea
                placeholder="اكتب التوجيهات أو التعليمات بالتفصيل…"
                value={annBody}
                onChange={(e) => setAnnBody(e.target.value)}
                required
                rows={4}
                className="text-xs"
              />
            </Field>

            <div className="flex items-center gap-2 pt-1">
              <input
                type="checkbox"
                id="ann_pub"
                checked={annPublished}
                onChange={(e) => setAnnPublished(e.target.checked)}
                className="rounded border-input text-primary focus:ring-primary"
              />
              <label htmlFor="ann_pub" className="text-xs text-foreground cursor-pointer">
                اعتماد ونشر الإعلان فورًا للمستهدفين
              </label>
            </div>

            <div className="flex justify-end gap-2 pt-3 border-t border-border">
              <Button type="button" variant="outline" size="sm" onClick={() => setOpenAnnounceModal(false)} className="h-9 text-xs">
                إلغاء
              </Button>
              <Button type="submit" size="sm" disabled={createAnnouncement.isPending} className="h-9 text-xs">
                نشر التعميم
              </Button>
            </div>
          </form>
        </DialogContent>
      </Dialog>
    </div>
  );
}
