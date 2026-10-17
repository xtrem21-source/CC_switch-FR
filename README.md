# CC Switch — interface française

**Traduction française de [CC Switch](https://github.com/farion1231/cc-switch) 4.0.14.**
L'interface est entièrement traduite, le français est la langue par défaut, et les six langues
d'origine (中文, English, 日本語, Türkçe, 繁體中文) restent disponibles.

> Projet **indépendant**, non affilié à `farion1231/cc-switch`. Le code d'origine est sous
> licence MIT ; cette traduction en dérive. Voir [NOTICE.md](NOTICE.md).

---

## Versions

| Élément | Valeur |
|---|---|
| Version upstream ciblée | **4.0.14** |
| Version de cette traduction | **4.0.14-fr.1** |
| Clés traduites | **4 200** (`src/i18n/locales/fr.json`) |
| Binaire compilé | release **`v4.0.14-fr.1`** — `cc-switch.exe` (41,7 Mo) |
| Licence | MIT (upstream et traduction) |

## Ce que contient ce dépôt

| Élément | Rôle |
|---|---|
| `Appliquer-CC-Switch-FR.bat` | installe la version française (double-clic) |
| `Mettre-a-jour-CC-Switch-FR.bat` | met à jour vers la dernière version upstream et refrancise |
| `Restaurer-CC-Switch.bat` | remet la version officielle |
| `patch/` | emplacement du binaire à installer (voir [patch/README.md](patch/README.md)) |
| `fichiers-modifies/` | sources modifiées, `fr.json`, patch complet, version ciblée |
| `outils/` | outillage de francisation (`Maj-CC-Switch-FR.ps1`, `prep_sources.py`, `fill_fr_gaps.py`) |
| `journaux/` | journaux des mises à jour effectuées (chemins personnels remplacés par `<utilisateur>`) |
| `docs/` | notice d'origine et méthode de francisation |

## Installer la version française

Deux chemins, selon que tu veux le binaire prêt à l'emploi ou une reconstruction depuis les sources.

### A. Binaire prêt (le plus simple)

1. Télécharge `cc-switch.exe` depuis la [release `v4.0.14-fr.1`](../../releases/latest).
2. Place-le dans `patch\` (à côté des `.bat`).
3. Ferme CC Switch, puis double-clique **`Appliquer-CC-Switch-FR.bat`**.

Le script sauvegarde l'installation existante dans `old\`, copie le binaire, passe la langue à
`fr` et relance l'application. Aucun droit administrateur n'est nécessaire.

### B. Reconstruction depuis les sources

```powershell
Mettre-a-jour-CC-Switch-FR.bat
```

Le script interroge la dernière version upstream, télécharge les sources, applique la
francisation (patch exact, ou règles de repli si le code a changé), traduit les nouvelles
chaînes, recompile et installe. Prérequis : **Git, Node.js, pnpm, Rust (cargo), Python et le
compilateur C++ de Visual Studio** — le script les vérifie et propose de les installer via
`winget`.

Options : `-Force` (reconstruit même si la version est à jour), `-NoInstall` (compile sans
installer), `-NoLaunch`, `-NoDownload`.

En cas d'échec, **rien n'est modifié** sur l'installation : le journal de `journaux\` nomme
l'étape fautive.

## Revenir en arrière

```text
Restaurer-CC-Switch.bat
```

Remet la 4.0.14 officielle. Pour revenir à une version antérieure conservée, copie le binaire
correspondant dans `%LOCALAPPDATA%\Programs\CC Switch\`.

## Ce qui a été modifié

| Fichier | Modification |
|---|---|
| `src/i18n/locales/fr.json` | ajout de la langue `fr` — 4 200 clés |
| `src/i18n/index.ts` | enregistrement i18next, langue par défaut `fr`, mise à jour de `<html lang>` |
| `src/types.ts` | type `Language` étendu |
| `src/hooks/useSettingsForm.ts` | formulaire de réglages : langue `fr` |
| `src/hooks/useDragSort.ts` | tri alphabétique localisé `fr-FR` |
| `src/components/settings/sections/GeneralSection.tsx` | option « Français » dans Paramètres → Langue |

Lexique harmonisé : « fournisseur » (jamais « prestataire »), « Session », « Enregistrer »,
« Effacer », « Minimiser la fenêtre ».

Le détail reproductible est dans `fichiers-modifies/cc-switch-fr.patch` (diff complet, applicable
avec `git apply`).

## Limites connues

- Traduction **assistée** : certains textes d'aide très longs restent perfectibles.
- Le correctif est lié à une version : si l'interface évolue beaucoup, la francisation s'applique
  par règles et quelques phrases demandent une relecture. Une chaîne non traduite s'affiche en
  anglais — jamais de texte vide ni d'erreur.
- Les noms propres (Claude, Codex, fournisseurs, modèles) restent inchangés.
- Le menu de la zone de notification Windows n'est pas traduit.
- Le binaire n'est pas versionné ici : il est publié dans la release.

## Intégrité

Le fichier `SHA256SUMS.txt` est joint à la release. Vérification sous Windows :

```powershell
certutil -hashfile cc-switch.exe SHA256
```

## Documentation

| Sujet | Où |
|---|---|
| Notice d'origine (contenu, options, limites) | [docs/LISEZ-MOI.txt](docs/LISEZ-MOI.txt) |
| Méthode de francisation et mise à jour | [docs/METHODE.md](docs/METHODE.md) |
| Contribuer | [CONTRIBUTING.md](CONTRIBUTING.md) |
| Sécurité | [SECURITY.md](SECURITY.md) |
| Historique | [CHANGELOG.md](CHANGELOG.md) |

## Licence

[MIT](LICENSE), comme le projet d'origine. Attribution et limites dans [NOTICE.md](NOTICE.md).

---

<details>
<summary><strong>English summary</strong></summary>

French translation of **CC Switch 4.0.14** (`farion1231/cc-switch`, MIT). The UI is fully
translated, French is the default language, and the six original languages remain available.
The repository holds the modified sources, the full patch, the installation/update/restore
scripts and the francisation tooling. The compiled `cc-switch.exe` is published as a release
asset, not versioned. Update path: `Mettre-a-jour-CC-Switch-FR.bat` rebuilds from upstream
sources (needs Git, Node.js, pnpm, Rust, Python, MSVC). Not affiliated with the upstream project.

</details>
