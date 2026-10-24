/**
 * Khartoum Timezone Date Utilities (Africa/Khartoum)
 * Mandated by FIX-1 Step 4.5 to eliminate UTC timezone shifts at midnight
 */

export function getKhartoumDateString(date: Date = new Date()): string {
  // Format as YYYY-MM-DD in Africa/Khartoum
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: "Africa/Khartoum",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(date);
}

export function formatKhartoumDateDisplay(date: Date | string): string {
  const d = typeof date === "string" ? new Date(date) : date;
  if (isNaN(d.getTime())) return "—";
  return new Intl.DateTimeFormat("ar-EG", {
    timeZone: "Africa/Khartoum",
    year: "numeric",
    month: "long",
    day: "numeric",
  }).format(d);
}

export function formatKhartoumShortDate(date: Date | string): string {
  const d = typeof date === "string" ? new Date(date) : date;
  if (isNaN(d.getTime())) return "—";
  return new Intl.DateTimeFormat("ar-EG", {
    timeZone: "Africa/Khartoum",
    year: "numeric",
    month: "numeric",
    day: "numeric",
  }).format(d);
}
