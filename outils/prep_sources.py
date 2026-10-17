#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Applique la francisation de CC Switch a une arborescence de sources.

Strategie en trois etages, du plus sur au plus souple :

  1. on tente d'appliquer le correctif enregistre (git apply) ;
  2. s'il est refuse, on applique des regles semantiques (ancres de code) ;
  3. les fichiers de traduction sont traites a part (copie de fr.json +
     ajout de l'entree "Francais" dans le selecteur de langue des autres
     langues), pour ne jamais ecraser les traductions ameliorees en amont.

Usage :
  python prep_sources.py --tree <dossier_sources> --patch <cc-switch-fr.patch>
                         --fr <fr.json> [--report <rapport.json>]

Code de sortie : 0 = OK, 3 = echec (la compilation ne doit pas etre lancee).
"""

import argparse
import json
import os
import re
import subprocess
import sys
import tempfile

# --------------------------------------------------------------------------
# utilitaires
# --------------------------------------------------------------------------

def read_text(path):
    with open(path, "r", encoding="utf-8", newline="") as fh:
        return fh.read()


def write_text(path, text):
    parent = os.path.dirname(path)
    if parent:
        os.makedirs(parent, exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="") as fh:
        fh.write(text)


def git(tree, *args):
    return subprocess.run(
        ["git", "-C", tree] + list(args),
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )


def split_patch(text):
    """Decoupe un diff git en blocs (chemin, contenu du bloc)."""
    blocks = []
    for part in re.split(r"(?m)^diff --git ", text)[1:]:
        match = re.match(r"a/(\S+) b/(\S+)", part)
        if match:
            blocks.append((match.group(2), "diff --git " + part))
    return blocks


# --------------------------------------------------------------------------
# regles semantiques : un fichier = une fonction
# --------------------------------------------------------------------------

def sem_i18n_index(text):
    changed = False

    # 1. import du fichier de traduction francais
    if './locales/fr.json' not in text:
        new, count = re.subn(
            r'(import en from "\./locales/en\.json";\s*\n)',
            r'\1import fr from "./locales/fr.json";\n',
            text,
            count=1,
        )
        if not count:
            raise RuntimeError('ancre "import en" introuvable')
        text, changed = new, True

    # 2. le type Language doit accepter "fr"
    match = re.search(r"type Language = ([^;]+);", text)
    if not match:
        raise RuntimeError('ancre "type Language" introuvable')
    if '"fr"' not in match.group(1):
        text = text[: match.end(1)] + ' | "fr"' + text[match.end(1):]
        changed = True

    # 3. le francais devient la langue par defaut
    match = re.search(r'const DEFAULT_LANGUAGE: Language = "([^"]*)";', text)
    if not match:
        raise RuntimeError('ancre "DEFAULT_LANGUAGE" introuvable')
    if match.group(1) != "fr":
        text = text[: match.start(1)] + "fr" + text[match.end(1):]
        changed = True

    # 4. isLanguage() doit reconnaitre "fr"
    start = text.find("const isLanguage")
    if start < 0:
        raise RuntimeError('ancre "isLanguage" introuvable')
    end = text.find(";", start)
    if end < 0:
        raise RuntimeError("fin de isLanguage introuvable")
    if '"fr"' not in text[start:end]:
        text = text[:end] + ' ||\n  value === "fr"' + text[end:]
        changed = True

    # 5. detection de la langue du systeme
    if 'startsWith("fr")' not in text:
        match = re.search(r'(?m)^([ \t]*)if \(navigatorLang\?\.startsWith\("en"\)\) \{', text)
        if match:
            indent = match.group(1)
            insert = (
                '{i}if (navigatorLang?.startsWith("fr")) {{\n'
                '{i}  return "fr";\n'
                "{i}}}\n\n"
            ).format(i=indent)
            text = text[: match.start()] + insert + text[match.start():]
            changed = True
        else:
            match = re.search(r'(?m)^\s*return navigatorLang \? "en" : DEFAULT_LANGUAGE;', text)
            if not match:
                raise RuntimeError("ancre de detection de langue systeme introuvable")
            insert = '  if (navigatorLang?.startsWith("fr")) {\n    return "fr";\n  }\n\n'
            text = text[: match.start()] + insert + text[match.start():]
            changed = True

    # 5b. repli : la langue par defaut est le francais, pas l'anglais
    fallback = 'return navigatorLang ? "en" : DEFAULT_LANGUAGE;'
    if fallback in text:
        text = text.replace(fallback, "return DEFAULT_LANGUAGE;")
        changed = True

    # 6. enregistrement des ressources de traduction
    if not re.search(r"(?m)^\s*fr:\s*\{", text):
        match = re.search(r"const resources = \{\n", text)
        if not match:
            raise RuntimeError('ancre "const resources" introuvable')
        text = text[: match.end()] + "  fr: {\n    translation: fr,\n  },\n" + text[match.end():]
        changed = True

    # 7. synchronisation de <html lang>
    if "applyHtmlLang" not in text:
        hook = (
            "// Keep <html lang> in sync so spell-checking, hyphenation and screen readers\n"
            "// follow the selected interface language.\n"
            "if (typeof document !== \"undefined\") {\n"
            "  const applyHtmlLang = (lng: string) => {\n"
            "    document.documentElement.lang = lng === \"zh\" ? \"zh-CN\" : lng;\n"
            "  };\n"
            "  applyHtmlLang(i18n.language);\n"
            "  i18n.on(\"languageChanged\", applyHtmlLang);\n"
            "}\n\n"
        )
        match = re.search(r"(?m)^export default i18n;\s*$", text)
        if match:
            text = text[: match.start()] + hook + text[match.start():]
        else:
            text = text.rstrip("\n") + "\n\n" + hook
        changed = True

    return text if changed else text


def sem_settings_form(text):
    changed = False

    match = re.search(r"type Language = ([^;]+);", text)
    if not match:
        raise RuntimeError('ancre "type Language" introuvable')
    if '"fr"' not in match.group(1):
        text = text[: match.end(1)] + ' | "fr"' + text[match.end(1):]
        changed = True

    # langue par defaut quand aucune valeur n'est fournie
    new, count = re.subn(r'if \(!lang\) return "zh";', 'if (!lang) return "fr";', text)
    if count:
        text, changed = new, True

    # reconnaissance de "fr" dans les tests d'egalite (if (...) ou return (...))
    if 'normalized === "fr"' not in text:
        edits = []
        for match in re.finditer(r'normalized === "tr"', text):
            window = text[max(0, match.start() - 300): match.end() + 300]
            if '"fr"' in window:
                continue
            tail = text[match.end(): match.end() + 40]
            stripped = tail.lstrip()
            if stripped.startswith("||"):
                position = match.end() + (len(tail) - len(stripped)) + 2
                edits.append((position, '\n    normalized === "fr" ||'))
            elif stripped.startswith(")"):
                edits.append((match.end(), ' ||\n    normalized === "fr"'))
        if not edits:
            raise RuntimeError("aucun test de langue a completer")
        for position, snippet in reversed(edits):
            text = text[:position] + snippet + text[position:]
        changed = True

    # valeur de repli en fin de normalisation
    index = text.rfind('return "zh";')
    if index >= 0:
        text = text[:index] + 'return "fr";' + text[index + len('return "zh";'):]
        changed = True

    return text


def sem_types(text):
    match = re.search(r"language\?: ([^;]+);", text)
    if not match:
        raise RuntimeError('champ "language?" introuvable')
    if '"fr"' in match.group(1):
        return text
    return text[: match.end(1)] + ' | "fr"' + text[match.end(1):]


def sem_general_section(text):
    if "languageOptionFrench" in text:
        return text
    match = re.search(
        r'(?m)^([ \t]*)\{ value: "tr", labelKey: "settings\.languageOptionTurkish" \},\s*$',
        text,
    )
    if not match:
        match = re.search(
            r'(?m)^([ \t]*)\{ value: "en", labelKey: "settings\.languageOptionEnglish" \},\s*$',
            text,
        )
    if not match:
        raise RuntimeError("liste des langues introuvable dans GeneralSection")
    indent = match.group(1)
    line = indent + '{ value: "fr", labelKey: "settings.languageOptionFrench" },'
    return text[: match.end()] + "\n" + line + text[match.end():]


def sem_drag_sort(text):
    if "fr-FR" in text:
        return text
    match = re.search(r':\s*"en-US";', text)
    if not match:
        raise RuntimeError('ancre collator "en-US" introuvable')
    replacement = ': i18n.language === "fr" ? "fr-FR" : "en-US";'
    return text[: match.start()] + replacement + text[match.end():]


SEMANTIC = {
    "src/i18n/index.ts": sem_i18n_index,
    "src/hooks/useSettingsForm.ts": sem_settings_form,
    "src/types.ts": sem_types,
    "src/components/settings/sections/GeneralSection.tsx": sem_general_section,
    "src/hooks/useDragSort.ts": sem_drag_sort,
}


# --------------------------------------------------------------------------
# fichiers de traduction
# --------------------------------------------------------------------------

LANGUAGE_LABELS = [
    ("en", "Français"),
    ("zh", "法语"),
    ("zh-TW", "法語"),
    ("ja", "フランス語"),
    ("tr", "Fransızca"),
]


def add_language_option(path, label):
    """Ajoute settings.languageOptionFrench en conservant la mise en forme."""
    text = read_text(path)
    if "languageOptionFrench" in text:
        return False

    lines = text.splitlines(keepends=True)

    def find(key):
        for position, line in enumerate(lines):
            if re.match(r'^\s*"%s"\s*:' % key, line):
                return position
        return None

    anchor = find("languageOptionTurkish")
    if anchor is None:
        anchor = find("languageOptionEnglish")

    if anchor is not None:
        raw = lines[anchor]
        indent = re.match(r"^(\s*)", raw).group(1)
        stripped = raw.rstrip("\r\n")
        newline = raw[len(stripped):] or "\n"
        if not stripped.rstrip().endswith(","):
            stripped = stripped.rstrip() + ","
        lines[anchor] = stripped + newline

        following = ""
        for candidate in lines[anchor + 1:]:
            if candidate.strip():
                following = candidate
                break
        needs_comma = not following.lstrip().startswith("}")
        entry = '{indent}"languageOptionFrench": "{label}"{comma}'.format(
            indent=indent,
            label=label,
            comma="," if needs_comma else "",
        )
        lines.insert(anchor + 1, entry + newline)
        write_text(path, "".join(lines))
        return True

    # repli : reecriture JSON complete
    data = json.loads(text)
    settings = data.get("settings")
    if not isinstance(settings, dict):
        raise RuntimeError("objet settings absent")
    settings["languageOptionFrench"] = label
    write_text(path, json.dumps(data, ensure_ascii=False, indent=2) + "\n")
    return True


# --------------------------------------------------------------------------
# programme principal
# --------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--tree", required=True)
    parser.add_argument("--patch", required=True)
    parser.add_argument("--fr", required=True)
    parser.add_argument("--report", default="")
    args = parser.parse_args()

    tree = os.path.abspath(args.tree)
    report = {"files": [], "warnings": [], "errors": [], "locales": []}

    blocks = split_patch(read_text(args.patch))
    code_blocks = [
        item for item in blocks
        if not item[0].replace("\\", "/").startswith("src/i18n/locales/")
    ]

    tmp_patch = os.path.join(tempfile.gettempdir(), "ccswitchfr-%d.patch" % os.getpid())
    try:
        for path, block in code_blocks:
            target = os.path.join(tree, *path.split("/"))
            if not os.path.exists(target):
                report["warnings"].append("fichier absent de la nouvelle version : " + path)
                continue

            write_text(tmp_patch, block)
            applied = False
            for extra in (["--3way"], []):
                check = git(tree, "apply", "--check", *(extra + [tmp_patch]))
                if check.returncode != 0:
                    continue
                result = git(tree, "apply", *(extra + [tmp_patch]))
                if result.returncode == 0:
                    applied = True
                    break

            if applied:
                report["files"].append({"file": path, "method": "patch"})
                continue

            rule = SEMANTIC.get(path)
            if not rule:
                report["errors"].append("correctif refuse et aucune regle pour : " + path)
                continue
            try:
                before = read_text(target)
                after = rule(before)
                if after != before:
                    write_text(target, after)
                report["files"].append({"file": path, "method": "semantique"})
                report["warnings"].append("applique par regle semantique (a relire) : " + path)
            except Exception as exc:  # noqa: BLE001
                report["errors"].append("%s : %s" % (path, exc))
    finally:
        try:
            os.remove(tmp_patch)
        except OSError:
            pass

    # --- traductions -----------------------------------------------------
    locale_dir = os.path.join(tree, "src", "i18n", "locales")
    if not os.path.isdir(locale_dir):
        report["errors"].append("dossier des traductions introuvable : " + locale_dir)
    else:
        fr_target = os.path.join(locale_dir, "fr.json")
        write_text(fr_target, read_text(args.fr))
        try:
            json.loads(read_text(fr_target))
        except Exception as exc:  # noqa: BLE001
            report["errors"].append("fr.json invalide : %s" % exc)
        report["locales"].append("fr.json (copie)")

        for lang, label in LANGUAGE_LABELS:
            source = os.path.join(locale_dir, lang + ".json")
            if not os.path.exists(source):
                report["warnings"].append("traduction absente en amont : " + lang + ".json")
                continue
            try:
                if add_language_option(source, label):
                    report["locales"].append(lang + ".json (entree Francais)")
            except Exception as exc:  # noqa: BLE001
                report["warnings"].append("%s.json : %s" % (lang, exc))

    # --- controle final ---------------------------------------------------
    index = os.path.join(tree, "src", "i18n", "index.ts")
    if os.path.exists(index):
        content = read_text(index)
        for needle in ("fr.json", '"fr"', "DEFAULT_LANGUAGE"):
            if needle not in content:
                report["errors"].append("verification i18n : %s absent" % needle)

    text_report = json.dumps(report, ensure_ascii=False, indent=2)
    print(text_report)
    if args.report:
        write_text(args.report, text_report + "\n")

    return 3 if report["errors"] else 0


if __name__ == "__main__":
    sys.exit(main())
