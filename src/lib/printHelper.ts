/**
 * Target-only Print Utility for Al-Umrabi School System.
 * Ensures clean, distraction-free printing of certificates, receipts, and reports.
 */

export interface PrintTargetOptions {
  documentTitle?: string;
}

export function printTarget(targetElementId: string, options?: PrintTargetOptions): void {
  if (typeof window === "undefined" || typeof document === "undefined") return;

  const originalTitle = document.title;
  if (options?.documentTitle) {
    document.title = options.documentTitle;
  }

  const targetEl = document.getElementById(targetElementId);
  if (!targetEl) {
    window.print();
    return;
  }

  targetEl.setAttribute("data-print-target-active", "true");
  document.body.classList.add("printing-target-mode");

  let cleanedUp = false;
  const cleanup = () => {
    if (cleanedUp) return;
    cleanedUp = true;
    document.body.classList.remove("printing-target-mode");
    targetEl.removeAttribute("data-print-target-active");
    if (options?.documentTitle) {
      document.title = originalTitle;
    }
    window.removeEventListener("afterprint", cleanup);
  };

  window.addEventListener("afterprint", cleanup);

  // Allow browser DOM to update before calling native print dialog
  setTimeout(() => {
    window.print();
    // Safety fallback in case afterprint does not fire in some embedded engines
    setTimeout(cleanup, 2500);
  }, 100);
}
