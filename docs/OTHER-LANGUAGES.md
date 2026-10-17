# Adapting this patch to another language

The patch is a **locale pack**, not a French-only hack. Replacing `fr` with another language
code is mechanical; the tooling around it is French-keyed and needs a rename (listed at the end).

## What the patch does

| Step | File | Effect |
|---|---|---|
| 1. dictionary | `src/i18n/locales/<code>.json` | key/value strings |
| 2. registration | `src/i18n/index.ts` | import, `resources`, `isLanguage`, navigator mapping |
| 3. default | `src/i18n/index.ts` | `DEFAULT_LANGUAGE` |
| 4. type | `src/types.ts` | `Language` union |
| 5. settings | `src/hooks/useSettingsForm.ts` | type + normalisation + fallback |
| 6. sorting | `src/hooks/useDragSort.ts` | locale-aware collation (`fr-FR` → `<code>-<REGION>`) |
| 7. selector | `src/components/settings/sections/GeneralSection.tsx` | one option entry |

## Step by step (example: Spanish, `es`)

### 1. Dictionary

Copy `src/i18n/locales/fr.json` to `src/i18n/locales/es.json` and translate the values.
**Keep every `{{placeholder}}`** — i18next substitutes `{{count}}`, `{{app}}`, `{{error}}`…
A lost placeholder breaks the screen.

### 2. Register in i18next — `src/i18n/index.ts`

```ts
import es from "./locales/es.json";

type Language = "zh" | "zh-TW" | "en" | "ja" | "tr" | "es";

const DEFAULT_LANGUAGE: Language = "es";

const isLanguage = (value: unknown): value is Language =>
  value === "zh" || value === "zh-TW" || value === "en" ||
  value === "ja" || value === "tr" || value === "es";

// navigator mapping
if (navigatorLang?.startsWith("es")) return "es";

const resources = {
  es: { translation: es },
  en: { translation: en },
  /* … the other languages … */
};
```

Keep `fallbackLng: "en"`: an untranslated key falls back to English, never to an empty string.

### 3. `<html lang>`

The existing hook sets `document.documentElement.lang = lng === "zh" ? "zh-CN" : lng;`.
Add a case only if your code needs a region (`pt` → `pt-BR`, for instance).

### 4. Types — `src/types.ts`

```ts
language?: "en" | "zh" | "zh-TW" | "ja" | "tr" | "es";
```

### 5. Settings form — `src/hooks/useSettingsForm.ts`

Update the `Language` type and every `"fr"` comparison: the default fallback (`if (!lang) return "es"`),
the normalisation branch and the validity check.

### 6. Sorting — `src/hooks/useDragSort.ts`

```ts
: i18n.language === "es"
  ? "es-ES"
  : "en"
```

The collation tag drives alphabetical order (accents, `ñ`, digraphs). Use the tag that matches
your language, not the bare code.

### 7. Language selector — `GeneralSection.tsx`

```tsx
{ value: "es", labelKey: "settings.languageOptionSpanish" },
```

Add `settings.languageOptionSpanish` to **every** locale file, otherwise the selector shows a
raw key for users of the other languages.

## The tooling is French-keyed

These do not follow the locale code automatically:

| File | What to change |
|---|---|
| `outils/Maj-CC-Switch-FR.ps1` | `$FrFile` path, `fr.json` argument, default language `fr`, script name in the `.bat` |
| `outils/prep_sources.py` | locale code and lexicon table |
| `outils/fill_fr_gaps.py` | `--fr` argument, target file |
| `Mettre-a-jour-CC-Switch-FR.bat` | script name it calls |
| `Appliquer-CC-Switch-FR.bat` | the `language='fr'` write into `settings.json` |
| release naming | `v<version>-fr.N` → `v<version>-es.N` |

Renaming is enough; there is no hidden registry.

## Testing a new language

1. `pnpm install && pnpm tauri build` in the upstream tree with your locale added.
2. Launch, then check: Settings → Language lists your language, the interface switches, no key
   appears raw, no string is empty.
3. Look for truncated labels on buttons and in tables — that is where long translations break.
4. Verify the sorting of a list with accented names.

## Keeping several languages

`fr.json` and `es.json` can coexist: register both in `resources`, add both selector entries.
The default language is a single constant; the fallback stays `en`.
