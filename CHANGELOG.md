# Journal des versions

## v4.0.14-fr.2 — 2026-10-17 (documentation, binaire inchangé)

- Ajout de **`README.en.md`** : notice anglaise complète, écrite pour un lecteur anglophone
  (installation, reconstruction, restauration, limites, intégrité).
- Le README français renvoie vers la version anglaise et ne duplique plus le résumé.
- Nouvelle section **« Autres langues »** dans les deux README : le mécanisme ajoute une locale,
  il n'est pas lié au français.
- Nouveaux guides : `docs/AUTRES-LANGUES.md` (français) et `docs/OTHER-LANGUAGES.md` (anglais),
  avec les ancres exactes des six fichiers à modifier et la liste de ce qui reste câblé sur `fr`
  dans les scripts et l'outillage.
- **Binaire inchangé** : celui de `v4.0.14-fr.1`, non dupliqué dans cette release.

## v4.0.14-fr.1 — 2026-10-17

**Première publication de la traduction française.**

- Traduction de l'interface de **CC Switch 4.0.14** : `fr.json` avec **4 200 clés**.
- Français par défaut, les six langues d'origine restent disponibles (中文, English, 日本語,
  Türkçe, 繁體中文).
- Six fichiers source modifiés : `i18n/index.ts`, `types.ts`, `useSettingsForm.ts`,
  `useDragSort.ts`, `GeneralSection.tsx`, plus le dictionnaire `fr.json`.
- Lexique harmonisé : « fournisseur », « Session », « Enregistrer », « Effacer »,
  « Minimiser la fenêtre ».
- Scripts : `Appliquer-CC-Switch-FR.bat`, `Mettre-a-jour-CC-Switch-FR.bat`,
  `Restaurer-CC-Switch.bat`.
- Outillage : `Maj-CC-Switch-FR.ps1`, `prep_sources.py`, `fill_fr_gaps.py`,
  `cache-traductions.json`.
- Release : `cc-switch.exe` (41,7 Mo) + `SHA256SUMS.txt`.
- Journaux des mises à jour conservés dans `journaux/`, chemins personnels remplacés par
  `<utilisateur>`.

### Vérifications effectuées (reprises de la notice d'origine)

- Mise à jour officielle 4.0.12 → 4.0.14 appliquée et vérifiée.
- Patch français appliqué sur la 4.0.14, interface contrôlée : langue `fr`, menus et pages en
  français.
- Script de mise à jour testé de bout en bout : téléchargement, francisation, compilation,
  installation, relance — interface française au redémarrage.
