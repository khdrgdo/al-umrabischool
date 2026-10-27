import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";

export interface JournalEntry {
  idx: number;
  version: string;
  when: number;
  tag: string;
  breakpoints?: boolean;
}

export interface Journal {
  version: string;
  dialect: string;
  entries: JournalEntry[];
}

export interface MigrationIssue {
  type:
    | "JOURNAL_UNREGISTERED"
    | "JOURNAL_ORPHAN"
    | "COUNTERPART_MISSING"
    | "CONTENT_MISMATCH"
    | "SEQUENCE_GAP"
    | "DUPLICATE_INDEX";
  severity: "error" | "warning";
  message: string;
  details?: Record<string, unknown>;
}

export interface AuditResult {
  success: boolean;
  totalDrizzleFiles: number;
  totalSupabaseFiles: number;
  journalEntriesCount: number;
  issues: MigrationIssue[];
}

function normalizeSql(sql: string): string {
  return sql.replace(/\r\n/g, "\n").trim();
}

function sha256(content: string): string {
  return crypto.createHash("sha256").update(content).digest("hex");
}

export function runMigrationAudit(projectRoot: string): AuditResult {
  const drizzleDir = path.join(projectRoot, "drizzle", "migrations");
  const supabaseDir = path.join(projectRoot, "supabase", "migrations");
  const journalPath = path.join(drizzleDir, "meta", "_journal.json");

  const issues: MigrationIssue[] = [];

  // 1. Read Journal
  let journal: Journal = { version: "7", dialect: "postgresql", entries: [] };
  if (!fs.existsSync(journalPath)) {
    issues.push({
      type: "JOURNAL_ORPHAN",
      severity: "error",
      message: `ملف سجل Drizzle غير موجود في: ${journalPath}`,
    });
  } else {
    try {
      journal = JSON.parse(fs.readFileSync(journalPath, "utf-8"));
    } catch (e: any) {
      issues.push({
        type: "JOURNAL_ORPHAN",
        severity: "error",
        message: `ملف _journal.json تالف: ${e.message}`,
      });
    }
  }

  const journalTags = new Set(journal.entries.map((e) => e.tag));

  // 2. Read Drizzle migrations
  const drizzleFiles = fs.existsSync(drizzleDir)
    ? fs.readdirSync(drizzleDir).filter((f) => f.endsWith(".sql"))
    : [];

  // 3. Read Supabase migrations
  const supabaseFiles = fs.existsSync(supabaseDir)
    ? fs.readdirSync(supabaseDir).filter((f) => f.endsWith(".sql"))
    : [];

  // Check 1: Files in drizzle/migrations not registered in _journal.json
  for (const df of drizzleFiles) {
    const tag = df.replace(/\.sql$/, "");
    if (!journalTags.has(tag)) {
      issues.push({
        type: "JOURNAL_UNREGISTERED",
        severity: "error",
        message: `ملف الترحيل '${df}' موجود في Drizzle ولكنه غير مسجل في _journal.json`,
        details: { file: df, tag },
      });
    }
  }

  // Check 2: Entries in _journal.json without a corresponding file on disk
  for (const entry of journal.entries) {
    const expectedFile = `${entry.tag}.sql`;
    if (!drizzleFiles.includes(expectedFile)) {
      issues.push({
        type: "JOURNAL_ORPHAN",
        severity: "error",
        message: `السجل '${entry.tag}' (المعامل ${entry.idx}) في _journal.json لا يقابله ملف في drizzle/migrations/`,
        details: { tag: entry.tag, idx: entry.idx },
      });
    }
  }

  // Check 3: Extract indices and verify counterparts & content parity
  const drizzleByIndex = new Map<string, string>();
  for (const df of drizzleFiles) {
    const match = df.match(/^(\d{4})_(.+)\.sql$/);
    if (match) {
      const idx = match[1];
      if (drizzleByIndex.has(idx)) {
        issues.push({
          type: "DUPLICATE_INDEX",
          severity: "error",
          message: `تكرار في رقم الترحيل ${idx} في مجلد Drizzle: ${df} مع ${drizzleByIndex.get(idx)}`,
        });
      }
      drizzleByIndex.set(idx, df);
    }
  }

  const supabaseByIndex = new Map<string, string>();
  for (const sf of supabaseFiles) {
    const tsMatch = sf.match(/^2026\d{6}(\d{4})_(.+)\.sql$/) || sf.match(/^(\d{4})_(.+)\.sql$/);
    if (tsMatch) {
      const idx = tsMatch[1];
      if (supabaseByIndex.has(idx)) {
        issues.push({
          type: "DUPLICATE_INDEX",
          severity: "error",
          message: `تكرار في رقم الترحيل ${idx} في مجلد Supabase: ${sf} مع ${supabaseByIndex.get(idx)}`,
        });
      }
      supabaseByIndex.set(idx, sf);
    }
  }

  // Compare each Drizzle file with its Supabase counterpart
  for (const [idx, df] of drizzleByIndex.entries()) {
    const sf = supabaseByIndex.get(idx);
    if (!sf) {
      issues.push({
        type: "COUNTERPART_MISSING",
        severity: "error",
        message: `ملف الترحيل '${df}' (الرقم ${idx}) ليس له ملف مقابل في supabase/migrations/`,
        details: { index: idx, drizzleFile: df },
      });
    } else {
      const dContent = normalizeSql(fs.readFileSync(path.join(drizzleDir, df), "utf-8"));
      const sContent = normalizeSql(fs.readFileSync(path.join(supabaseDir, sf), "utf-8"));
      if (sha256(dContent) !== sha256(sContent)) {
        issues.push({
          type: "CONTENT_MISMATCH",
          severity: "error",
          message: `اختلاف في المحتوى النصي بين Drizzle '${df}' و Supabase '${sf}'`,
          details: {
            drizzleFile: df,
            supabaseFile: sf,
            drizzleSha256: sha256(dContent),
            supabaseSha256: sha256(sContent),
          },
        });
      }
    }
  }

  // Check for Supabase files missing in Drizzle
  for (const [idx, sf] of supabaseByIndex.entries()) {
    if (!drizzleByIndex.has(idx)) {
      issues.push({
        type: "COUNTERPART_MISSING",
        severity: "error",
        message: `ملف ترحيل سوبابيس '${sf}' (الرقم ${idx}) ليس له ملف مقابل في drizzle/migrations/`,
        details: { index: idx, supabaseFile: sf },
      });
    }
  }

  return {
    success: issues.length === 0,
    totalDrizzleFiles: drizzleFiles.length,
    totalSupabaseFiles: supabaseFiles.length,
    journalEntriesCount: journal.entries.length,
    issues,
  };
}

// Direct CLI Execution
const isMainModule =
  process.argv[1]?.endsWith("verify-migrations.ts") ||
  process.argv[1]?.endsWith("verify-migrations.js");

if (isMainModule) {
  const root = process.cwd();
  console.log("🔍 فحص ترحيلات Drizzle و Supabase ومطابقة الـ Journal...");
  const result = runMigrationAudit(root);

  console.log(`- عدد ملفات Drizzle: ${result.totalDrizzleFiles}`);
  console.log(`- عدد ملفات Supabase: ${result.totalSupabaseFiles}`);
  console.log(`- عدد الإدخالات المسجلة في Journal: ${result.journalEntriesCount}`);

  if (result.success) {
    console.log("\n✅ كافة الترحيلات متطابقة تماماً ومسجلة في Journal بدون أي فجوة.");
    process.exit(0);
  } else {
    console.error(`\n❌ فشل فحص الترحيلات! تم اكتشاف (${result.issues.length}) مشكلة:\n`);
    for (const [i, issue] of result.issues.entries()) {
      console.error(`[${i + 1}] [${issue.type}] ${issue.message}`);
      if (issue.details) {
        console.error(`    تفاصيل: ${JSON.stringify(issue.details)}`);
      }
    }
    console.error(
      "\n⚠️ تنبيه أمان: يجب حل التناقضات السابقة قبل تطبيق أي ترحيل على قاعدة البيانات الحية لتجنب تلف البيانات."
    );
    process.exit(1);
  }
}
