import { QueryClient } from "@tanstack/react-query";
import { createRouter, rootRouteId } from "@tanstack/react-router";
import { describe, expect, it } from "vitest";

import { routeTree } from "@/routeTree.gen";

// Match routes without running loaders or rendering: loaders may need a server or
// network the test run lacks, and jsdom never loads the stylesheets React waits on.
describe("App routing", () => {
  const router = createRouter({ routeTree, context: { queryClient: new QueryClient() } });

  it("matches a page for / instead of falling back to not found", () => {
    const matches = router.matchRoutes("/");
    expect(matches.at(-1)?.routeId).not.toBe(rootRouteId);
  });

  it("matches route for /dashboard", () => {
    const matches = router.matchRoutes("/dashboard");
    expect(matches.at(-1)?.routeId).toBe("/_authenticated/dashboard");
  });

  it("matches route for /students", () => {
    const matches = router.matchRoutes("/students");
    expect(matches.at(-1)?.routeId).toBe("/_authenticated/students/");
  });

  it("matches route for /fees", () => {
    const matches = router.matchRoutes("/fees");
    expect(matches.at(-1)?.routeId).toBe("/_authenticated/fees");
  });

  it("matches route for /attendance", () => {
    const matches = router.matchRoutes("/attendance");
    expect(matches.at(-1)?.routeId).toBe("/_authenticated/attendance");
  });

  it("matches route for /grades", () => {
    const matches = router.matchRoutes("/grades");
    expect(matches.at(-1)?.routeId).toBe("/_authenticated/grades");
  });

  it("matches route for /calendar", () => {
    const matches = router.matchRoutes("/calendar");
    expect(matches.at(-1)?.routeId).toBe("/_authenticated/calendar");
  });

  it("matches route for /rollover", () => {
    const matches = router.matchRoutes("/rollover");
    expect(matches.at(-1)?.routeId).toBe("/_authenticated/rollover");
  });

  it("matches route for /guardians", () => {
    const matches = router.matchRoutes("/guardians");
    expect(matches.at(-1)?.routeId).toBe("/_authenticated/guardians");
  });

  it("matches route for /parent", () => {
    const matches = router.matchRoutes("/parent");
    expect(matches.at(-1)?.routeId).toBe("/parent");
  });

  it("renders StatCard safely whether icon is a component or an element", async () => {
    const { renderToString } = await import("react-dom/server");
    const { StatCard } = await import("../components/app/kit");
    const { Banknote } = await import("lucide-react");

    // Passed as component function
    const html1 = renderToString(<StatCard label="اختبار 1" value="100" icon={Banknote} />);
    expect(html1).toContain("اختبار 1");

    // Passed as JSX element
    const html2 = renderToString(<StatCard label="اختبار 2" value="200" icon={<Banknote className="h-4 w-4" />} />);
    expect(html2).toContain("اختبار 2");
  });
});
