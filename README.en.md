# CC Switch — French interface

**French translation of [CC Switch](https://github.com/farion1231/cc-switch) 4.0.14.**
The whole interface is translated, French is the default language, and the six original
languages (中文, English, 日本語, Türkçe, 繁體中文) stay available.

> Independent project, not affiliated with `farion1231/cc-switch`. The upstream code is MIT;
> this translation derives from it. See [NOTICE.md](NOTICE.md).

**Français :** [README.md](README.md) · **Other languages:** [docs/OTHER-LANGUAGES.md](docs/OTHER-LANGUAGES.md)

---

## Versions

| Item | Value |
|---|---|
| Upstream version targeted | **4.0.14** |
| Version of this translation | **4.0.14-fr.1** |
| Translated keys | **4,200** (`src/i18n/locales/fr.json`) |
| Compiled binary | release **`v4.0.14-fr.1`** — `cc-switch.exe` (41.7 MB) |
| Licence | MIT (upstream and translation) |

## Repository layout

| Path | Purpose |
|---|---|
| `Appliquer-CC-Switch-FR.bat` | installs the French build (double-click) |
| `Mettre-a-jour-CC-Switch-FR.bat` | updates from upstream and re-applies the translation |
| `Restaurer-CC-Switch.bat` | restores the official build |
| `patch/` | where the downloaded binary goes (see [patch/README.md](patch/README.md)) |
| `fichiers-modifies/` | modified sources, `fr.json`, full patch, targeted version |
| `outils/` | francisation tooling (`Maj-CC-Switch-FR.ps1`, `prep_sources.py`, `fill_fr_gaps.py`) |
| `journaux/` | update logs, personal paths replaced by `<utilisateur>` |
| `docs/` | original French notice, method, other-language guide |

The scripts' names and messages are in French — this repository is published as the French
build. The **mechanism** is language-agnostic; see [Other languages](#other-languages).

## Install the French build

### A. Prebuilt binary (simplest)

1. Download `cc-switch.exe` from the [latest release](../../releases/latest).
2. Put it in `patch/` (next to the `.bat` files).
3. Close CC Switch, then double-click **`Appliquer-CC-Switch-FR.bat`**.

The script backs up the current install into `old/`, copies the binary, sets the language to
`fr` and relaunches the app. No administrator rights required.

### B. Rebuild from source

```powershell
Mettre-a-jour-CC-Switch-FR.bat
```

The script queries the latest upstream release, downloads the sources, re-applies the
francisation (exact patch, or fallback rules when the code moved), translates new strings,
rebuilds and installs. Requirements: **Git, Node.js, pnpm, Rust (cargo), Python and the Visual
Studio C++ compiler** — the script checks them and offers to install them through `winget`.

Options: `-Force`, `-NoInstall`, `-NoLaunch`, `-NoDownload`.

On failure, **nothing is changed** on the installed app: the log in `journaux/` names the
failing step.

## Restore

```text
Restaurer-CC-Switch.bat
```

Restores official 4.0.14. To return to an older build kept in `old/`, copy its binary into
`%LOCALAPPDATA%\Programs\CC Switch\`.

## What was changed

| File | Change |
|---|---|
| `src/i18n/locales/fr.json` | new `fr` locale — 4,200 keys |
| `src/i18n/index.ts` | i18next registration, default language `fr`, `<html lang>` sync |
| `src/types.ts` | `Language` union extended with `fr` |
| `src/hooks/useSettingsForm.ts` | settings form: `fr` handling |
| `src/hooks/useDragSort.ts` | French-aware alphabetical sorting (`fr-FR` collation) |
| `src/components/settings/sections/GeneralSection.tsx` | "Français" entry in Settings → Language |

Glossary enforced: *fournisseur* (never *prestataire*), *Session*, *Enregistrer*, *Effacer*,
*Minimiser la fenêtre*.

The reproducible diff is `fichiers-modifies/cc-switch-fr.patch` (apply with `git apply`).

## Other languages

**This is not a French-only mechanism.** The patch does three things, none of which depends on
the language being French:

1. add a locale file to `src/i18n/locales/`;
2. register it in i18next and in the settings form;
3. pick a default language.

French is simply the pack shipped here. To target another language, replace `fr` with your
code in six source files (the dictionary, the i18next registration, the `Language` union, the
settings normalisation, the sorting collation and the language-selector entry). The
step-by-step procedure, with the exact anchors, is in
**[docs/OTHER-LANGUAGES.md](docs/OTHER-LANGUAGES.md)** (English) and
[docs/AUTRES-LANGUES.md](docs/AUTRES-LANGUES.md) (French).

One caveat, stated plainly: the **scripts** are named `…-FR` and the update tooling
(`outils/`) hard-codes `fr.json`, the `fr` locale code and the French release naming. Adapting
them to another language is a rename, not magic — the guide lists every place.

## Known limitations

- **Assisted translation**: very long help texts can still be improved.
- The patch targets one upstream version: when the UI changes a lot, the francisation falls
  back to structural rules and a few sentences need review. A missing key falls back to
  English — never an empty string, never an error.
- Proper nouns (Claude, Codex, providers, models) are left untouched.
- The Windows notification-area menu is not translated.
- The binary is not versioned in this repository: it is published as a release asset.

## Integrity

`SHA256SUMS.txt` is attached to the release:

```powershell
certutil -hashfile cc-switch.exe SHA256
```

## Documentation

| Topic | Where |
|---|---|
| French notice (content, options, limits) | [docs/LISEZ-MOI.txt](docs/LISEZ-MOI.txt) |
| Francisation method and updates | [docs/METHODE.md](docs/METHODE.md) |
| Adapting to another language | [docs/OTHER-LANGUAGES.md](docs/OTHER-LANGUAGES.md) |
| Contributing | [CONTRIBUTING.md](CONTRIBUTING.md) |
| Security | [SECURITY.md](SECURITY.md) |
| Changelog | [CHANGELOG.md](CHANGELOG.md) |

## Licence

[MIT](LICENSE), same as upstream. Attribution and limits in [NOTICE.md](NOTICE.md).
