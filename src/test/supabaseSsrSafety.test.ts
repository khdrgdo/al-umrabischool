import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";

// Server-Side Rendering (SSR) Cloudflare Worker Safety Specification
// Resolves Lovable Cloud initial render 500 crashes
interface SupabaseClientConfig {
  supabaseUrl?: string | undefined;
  supabaseKey?: string | undefined;
  isServer: boolean;
  cfEnv?: Record<string, string> | undefined;
}

function resolveSupabaseConfig(config: SupabaseClientConfig): {
  url: string;
  key: string;
  isFallback: boolean;
} {
  const url =
    config.cfEnv?.["SUPABASE_URL"] ||
    config.cfEnv?.["VITE_SUPABASE_URL"] ||
    config.supabaseUrl ||
    (config.isServer ? "https://placeholder-ssr.supabase.co" : "");

  const key =
    config.cfEnv?.["SUPABASE_PUBLISHABLE_KEY"] ||
    config.cfEnv?.["VITE_SUPABASE_PUBLISHABLE_KEY"] ||
    config.supabaseKey ||
    (config.isServer ? "placeholder-ssr-key" : "");

  const isFallback = url.includes("placeholder-ssr");

  if (!url && !config.isServer) {
    throw new Error("Missing VITE_SUPABASE_URL environment variable on client");
  }

  return { url, key, isFallback };
}

describe("Suite 10: Supabase Client SSR Resilience & Cloudflare Worker Bindings", () => {
  it("never throws 500 exception in SSR environment when env vars are missing", () => {
    // Simulates initial request hitting Cloudflare Worker before environment bindings hydrate
    expect(() => {
      const res = resolveSupabaseConfig({
        isServer: true,
        supabaseUrl: undefined,
        supabaseKey: undefined,
      });
      expect(res.isFallback).toBe(true);
      expect(res.url).toBe("https://placeholder-ssr.supabase.co");
    }).not.toThrow();
  });

  it("prioritizes Cloudflare Worker runtime bindings (__CF_ENV__) when present", () => {
    const res = resolveSupabaseConfig({
      isServer: true,
      cfEnv: {
        SUPABASE_URL: "https://worker-injected.supabase.co",
        SUPABASE_PUBLISHABLE_KEY: "cf-worker-token-xyz",
      },
    });

    expect(res.isFallback).toBe(false);
    expect(res.url).toBe("https://worker-injected.supabase.co");
    expect(res.key).toBe("cf-worker-token-xyz");
  });

  it("successfully resolves standard client-side environment variables in browser", () => {
    const res = resolveSupabaseConfig({
      isServer: false,
      supabaseUrl: "https://c--8b91830b-7424-4960-81c7-67e94cdfd28d-prod.lovable.cloud",
      supabaseKey: "sb_publishable_Cfv0pugkUHNlXrkWNX45JQ_ebr24viE",
    });

    expect(res.isFallback).toBe(false);
    expect(res.url).toBe("https://c--8b91830b-7424-4960-81c7-67e94cdfd28d-prod.lovable.cloud");
  });

  it("throws descriptive error on client if URL is missing in browser hydration", () => {
    expect(() => {
      resolveSupabaseConfig({
        isServer: false,
        supabaseUrl: "",
        supabaseKey: "",
      });
    }).toThrow("Missing VITE_SUPABASE_URL");
  });
});
