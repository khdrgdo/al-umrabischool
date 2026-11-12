import { useState } from "react";
import { Input } from "@/components/ui/input";
import { Checkbox } from "@/components/ui/checkbox";
import { Empty } from "@/components/app/kit";

export function SearchChecklist({ label, options, selected, onChange, disabled = false }: {
  label: string; options: { id: string; label: string }[]; selected: string[];
  onChange: (ids: string[]) => void; disabled?: boolean;
}) {
  const [search, setSearch] = useState("");
  const filtered = options.filter((option) => option.label.toLocaleLowerCase().includes(search.trim().toLocaleLowerCase()));
  return <div className="min-w-0 space-y-2">
    <div className="flex justify-between text-xs"><span>{label}</span><span className="text-muted-foreground">المحدد: {selected.length}</span></div>
    <Input aria-label={`بحث ${label}`} placeholder={`بحث ${label}`} value={search} onChange={(e) => setSearch(e.target.value)} maxLength={100} />
    <div className="max-h-48 overflow-y-auto rounded-md border border-border p-2 space-y-1">
      {filtered.map((option) => <label key={option.id} className="flex min-w-0 items-center gap-2 p-2 text-sm cursor-pointer">
        <Checkbox disabled={disabled} checked={selected.includes(option.id)} onCheckedChange={(checked) => onChange(checked === true ? [...new Set([...selected, option.id])] : selected.filter((id) => id !== option.id))} />
        <span className="break-words">{option.label}</span>
      </label>)}
      {!filtered.length && <Empty title="لا توجد نتائج" />}
    </div>
  </div>;
}