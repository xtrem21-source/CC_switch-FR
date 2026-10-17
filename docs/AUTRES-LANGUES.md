# Adapter ce patch à une autre langue

Le patch est un **pack de locale**, pas un bricolage franco-français. Remplacer `fr` par un autre
code de langue est mécanique ; l'outillage autour, lui, est câblé sur le français et demande un
renommage (liste en fin de document).

## Ce que fait le patch

| Étape | Fichier | Effet |
|---|---|---|
| 1. dictionnaire | `src/i18n/locales/<code>.json` | les chaînes |
| 2. enregistrement | `src/i18n/index.ts` | import, `resources`, `isLanguage`, détection navigateur |
| 3. langue par défaut | `src/i18n/index.ts` | `DEFAULT_LANGUAGE` |
| 4. type | `src/types.ts` | union `Language` |
| 5. réglages | `src/hooks/useSettingsForm.ts` | type, normalisation, repli |
| 6. tri | `src/hooks/useDragSort.ts` | collation localisée (`fr-FR` → `<code>-<RÉGION>`) |
| 7. sélecteur | `src/components/settings/sections/GeneralSection.tsx` | une entrée de plus |

## Pas à pas (exemple : espagnol, `es`)

### 1. Le dictionnaire

Copie `src/i18n/locales/fr.json` en `src/i18n/locales/es.json` et traduis les valeurs.
**Conserve chaque `{{variable}}`** : i18next substitue `{{count}}`, `{{app}}`, `{{error}}`…
Une variable perdue casse l'écran.

### 2. Enregistrer dans i18next — `src/i18n/index.ts`

```ts
import es from "./locales/es.json";

type Language = "zh" | "zh-TW" | "en" | "ja" | "tr" | "es";

const DEFAULT_LANGUAGE: Language = "es";

const isLanguage = (value: unknown): value is Language =>
  value === "zh" || value === "zh-TW" || value === "en" ||
  value === "ja" || value === "tr" || value === "es";

// détection navigateur
if (navigatorLang?.startsWith("es")) return "es";

const resources = {
  es: { translation: es },
  en: { translation: en },
  /* … les autres langues … */
};
```

Garde `fallbackLng: "en"` : une clé non traduite retombe sur l'anglais, jamais sur du vide.

### 3. `<html lang>`

Le code existant fait `document.documentElement.lang = lng === "zh" ? "zh-CN" : lng;`.
Ajoute un cas seulement si ta langue a besoin d'une région (`pt` → `pt-BR`, par exemple).

### 4. Les types — `src/types.ts`

```ts
language?: "en" | "zh" | "zh-TW" | "ja" | "tr" | "es";
```

### 5. Le formulaire de réglages — `src/hooks/useSettingsForm.ts`

Mets à jour le type `Language` et **toutes** les comparaisons à `"fr"` : le repli par défaut
(`if (!lang) return "es"`), la branche de normalisation et le contrôle de validité.

### 6. Le tri — `src/hooks/useDragSort.ts`

```ts
: i18n.language === "es"
  ? "es-ES"
  : "en"
```

L'étiquette de collation pilote l'ordre alphabétique (accents, `ñ`, digrammes). Utilise
l'étiquette complète, pas le code seul.

### 7. Le sélecteur — `GeneralSection.tsx`

```tsx
{ value: "es", labelKey: "settings.languageOptionSpanish" },
```

Ajoute `settings.languageOptionSpanish` dans **tous** les fichiers de locale, sinon le sélecteur
affiche une clé brute pour les utilisateurs des autres langues.

## L'outillage, lui, est câblé sur le français

Ces fichiers ne suivent pas le code de langue automatiquement :

| Fichier | Ce qu'il faut changer |
|---|---|
| `outils/Maj-CC-Switch-FR.ps1` | chemin `$FrFile`, argument `fr.json`, langue par défaut `fr`, nom du script appelé |
| `outils/prep_sources.py` | code de langue et table de lexique |
| `outils/fill_fr_gaps.py` | argument `--fr`, fichier cible |
| `Mettre-a-jour-CC-Switch-FR.bat` | nom du script appelé |
| `Appliquer-CC-Switch-FR.bat` | l'écriture `language='fr'` dans `settings.json` |
| nommage des releases | `v<version>-fr.N` → `v<version>-es.N` |

Un renommage suffit : il n'y a pas de registre caché.

## Tester une nouvelle langue

1. `pnpm install && pnpm tauri build` dans l'arbre upstream avec ta locale ajoutée.
2. Lance, puis vérifie : Réglages → Langue propose ta langue, l'interface bascule, aucune clé
   brute, aucune chaîne vide.
3. Cherche les libellés tronqués sur les boutons et dans les tableaux — c'est là que les
   traductions longues cassent.
4. Vérifie le tri d'une liste contenant des accents.

## Garder plusieurs langues

`fr.json` et `es.json` peuvent coexister : enregistre les deux dans `resources`, ajoute les deux
entrées au sélecteur. La langue par défaut reste une seule constante ; le repli reste `en`.
