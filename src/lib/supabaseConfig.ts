/**
 * Supabase Client SSR Resilience & Cloudflare Worker Bindings
 * Domain logic for resolving Supabase configuration safely in SSR environments.
 */

export interface SupabaseClientConfig {
  supabaseUrl?: string | undefined;
  supabaseKey?: string | undefined;
  isServer: boolean;
  cfEnv?: Record<string, string> | undefined;
}

export function resolveSupabaseConfig(config: SupabaseClientConfig): {
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
