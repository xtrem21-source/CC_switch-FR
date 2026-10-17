# Méthode de francisation

## Principe

CC Switch est une application **Tauri** (Rust + React) sous licence MIT. La francisation ajoute
une locale `fr` au système i18n et la câble dans l'interface ; elle ne modifie aucune logique
métier.

## Ce que fait la mise à jour

```text
Mettre-a-jour-CC-Switch-FR.bat
  └── outils/Maj-CC-Switch-FR.ps1
        1. interroge api.github.com (farion1231/cc-switch) → dernière version
        2. clone les sources de cette version dans %LOCALAPPDATA%\CCSwitchFR\src-<version>
        3. prep_sources.py
             - applique fichiers-modifies/cc-switch-fr.patch si le code correspond exactement
             - sinon applique des règles de repli (ancres de structure) et écrit un rapport
               francisation-<version>.json
        4. fill_fr_gaps.py --en … --fr … + cache-traductions.json
             - traduit les clés apparues depuis la version précédente
             - complète les valeurs manquantes, jamais par une chaîne vide
        5. compile (cargo / tauri) avec CARGO_TARGET_DIR dans %LOCALAPPDATA%\CCSwitchFR
        6. installe target\release\cc-switch.exe, règle language = "fr", relance
```

Tout échec laisse l'installation **intacte** : le binaire n'est remplacé qu'après une compilation
réussie, et le journal de `journaux\` nomme l'étape fautive.

## Les six fichiers modifiés

| Fichier | Rôle dans la francisation |
|---|---|
| `src/i18n/locales/fr.json` | dictionnaire complet (4 200 clés) |
| `src/i18n/index.ts` | enregistrement i18next, langue par défaut `fr`, `<html lang>` |
| `src/types.ts` | type `Language` étendu à `fr` |
| `src/hooks/useSettingsForm.ts` | formulaire de réglages : langue `fr` |
| `src/hooks/useDragSort.ts` | tri alphabétique localisé `fr-FR` |
| `src/components/settings/sections/GeneralSection.tsx` | entrée « Français » du sélecteur |

## Appliquer le patch à la main

```powershell
git clone --depth 1 --branch v4.0.14 https://github.com/farion1231/cc-switch.git
cd cc-switch
git apply --3way ..\fichiers-modifies\cc-switch-fr.patch
pnpm install
pnpm tauri build
```

Le binaire produit se trouve dans `src-tauri\target\release\cc-switch.exe`.

## Ajouter une nouvelle version upstream

1. `Mettre-a-jour-CC-Switch-FR.bat -NoInstall` : le script signale les ancres qui ont bougé.
2. Corriger les fichiers concernés dans `fichiers-modifies/src/`.
3. Régénérer le patch :
   `git diff > fichiers-modifies/cc-switch-fr.patch` depuis l'arbre upstream modifié.
4. Mettre à jour `fichiers-modifies/version.txt`, `VERSION` et `CHANGELOG.md`.
5. Vérifier l'interface, puis publier une release `v<version>-fr.N`.

## Vérifications de référence

- L'application démarre et l'interface est en français.
- Paramètres → Langue propose les six langues.
- Aucun texte vide ; une clé absente retombe sur l'anglais.
- Le tri des listes respecte l'ordre alphabétique français (accents).

## Limites

- Le menu de la zone de notification Windows n'est pas traduit (texte natif de l'application).
- Les textes fournis dynamiquement par les fournisseurs restent dans leur langue.
- Les textes d'aide très longs sont perfectibles : traduction assistée, relue par écrans.
