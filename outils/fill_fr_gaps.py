#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Complete fr.json avec les chaines apparues dans en.json depuis la derniere
francisation.

Utilise un cache local (anglais -> francais) pour ne jamais retraduire deux
fois la meme chaine, et la meme interface de traduction que lors de la
creation du fichier francais. Les chaines qui n'ont pas pu etre traduites
gardent l'anglais : l'application reste utilisable, rien ne casse.

Usage :
  python fill_fr_gaps.py --en en.json --fr fr.json --cache cache.json
                         [--no-network] [--report rapport.json]
"""

import argparse
import json
import os
import re
import sys
import time
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor

MAX_WORKERS = 6
TIMEOUT = 25


def read_json(path):
    with open(path, "r", encoding="utf-8") as fh:
        return json.load(fh)


def write_json(path, data):
    with open(path, "w", encoding="utf-8", newline="") as fh:
        fh.write(json.dumps(data, ensure_ascii=False, indent=2) + "\n")


def collect_missing(source, target, path=()):
    """Retourne [(chemin, texte anglais)] pour chaque cle absente ou vide."""
    missing = []
    for key, value in source.items():
        if isinstance(value, dict):
            sub = target.get(key) if isinstance(target.get(key), dict) else {}
            missing.extend(collect_missing(value, sub, path + (key,)))
            continue
        current = target.get(key)
        if isinstance(value, str) and not value.strip():
            continue
        if not isinstance(current, str) or not current.strip():
            missing.append((path + (key,), value))
    return missing


def set_path(root, path, value):
    current = root
    for key in path[:-1]:
        if not isinstance(current.get(key), dict):
            current[key] = {}
        current = current[key]
    current[path[-1]] = value


# --------------------------------------------------------------------------
# traduction
# --------------------------------------------------------------------------

PLACEHOLDER_PATTERNS = [
    r"\{\{[^{}]*\}\}",
    r"\{[^{}]*\}",
    r"</?[A-Za-z][^<>]*>",
    r"`[^`]*`",
    r"https?://[^\s]+",
    r"%[sd@]",
    r"\$t\([^)]*\)",
]


def shield(text):
    """Remplace les elements techniques par des jetons neutres."""
    store = []

    def swap(match):
        store.append(match.group(0))
        return "\u00a7%d\u00a7" % (len(store) - 1)

    protected = text
    for pattern in PLACEHOLDER_PATTERNS:
        protected = re.sub(pattern, swap, protected)
    return protected, store


def unshield(text, store):
    for index, original in enumerate(store):
        text = text.replace("\u00a7%d\u00a7" % index, original)
        text = text.replace("\u00a7 %d \u00a7" % index, original)
        text = text.replace("\u00a7%d \u00a7" % index, original)
        text = text.replace("\u00a7 %d\u00a7" % index, original)
    return text


def translate(text):
    protected, store = shield(text)
    url = (
        "https://clients5.google.com/translate_a/t"
        "?client=dict-chrome-ex&sl=en&tl=fr&q=" + urllib.parse.quote(protected)
    )
    request = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(request, timeout=TIMEOUT) as response:
        body = response.read().decode("utf-8", "replace")
    data = json.loads(body)
    result = None
    if isinstance(data, list) and data:
        first = data[0]
        if isinstance(first, list) and first:
            result = first[0]
        elif isinstance(first, str):
            result = first
    if not isinstance(result, str):
        return None
    return unshield(result, store).strip()


def translate_safe(text, cache):
    if text in cache:
        return cache[text]
    try:
        result = translate(text)
    except Exception:  # noqa: BLE001
        return None
    if result:
        cache[text] = result
        return result
    return None


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--en", required=True)
    parser.add_argument("--fr", required=True)
    parser.add_argument("--cache", required=True)
    parser.add_argument("--no-network", action="store_true")
    parser.add_argument("--report", default="")
    args = parser.parse_args()

    english = read_json(args.en)
    french = read_json(args.fr)

    cache = {}
    if os.path.exists(args.cache):
        try:
            cache = read_json(args.cache)
        except Exception:  # noqa: BLE001
            cache = {}

    missing = collect_missing(english, french)
    report = {
        "missing": len(missing),
        "translated": 0,
        "kept_english": 0,
        "cache_hits": 0,
        "samples": [],
    }

    if not missing:
        print(json.dumps(report, ensure_ascii=False))
        return 0

    texts = []
    for _, text in missing:
        if text not in cache and text not in texts:
            texts.append(text)

    if texts and not args.no_network:
        with ThreadPoolExecutor(max_workers=MAX_WORKERS) as pool:
            list(pool.map(lambda item: translate_safe(item, cache), texts))
        try:
            write_json(args.cache, cache)
        except Exception:  # noqa: BLE001
            pass

    for path, text in missing:
        if text in cache:
            value = cache[text]
            if value != text:
                report["translated"] += 1
            else:
                report["cache_hits"] += 1
        else:
            value = text
            report["kept_english"] += 1
        set_path(french, path, value)
        if len(report["samples"]) < 10:
            report["samples"].append({"key": ".".join(path), "en": text, "fr": value})

    # on retire les cles disparues de l'anglais pour garder un fichier propre
    def prune(node, reference):
        if not isinstance(node, dict):
            return node
        cleaned = {}
        for key, value in node.items():
            if key not in reference:
                continue
            cleaned[key] = prune(value, reference[key]) if isinstance(value, dict) else value
        return cleaned

    french = prune(french, english)

    write_json(args.fr, french)
    print(json.dumps(report, ensure_ascii=False, indent=2))
    if args.report:
        with open(args.report, "w", encoding="utf-8") as fh:
            json.dump(report, fh, ensure_ascii=False, indent=2)
    return 0


if __name__ == "__main__":
    sys.exit(main())
