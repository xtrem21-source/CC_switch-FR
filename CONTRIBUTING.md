# Contribuer

Merci de vouloir améliorer la version française de CC Switch.

## Ce qui est bienvenu

| Contribution | Canal |
|---|---|
| Correction de traduction | pull request sur `fichiers-modifies/src/i18n/locales/fr.json` |
| Chaîne non traduite | issue avec la capture et l'écran concerné |
| Amélioration du lexique | pull request + justification courte |
| Correctif des scripts | pull request, avec le test réel décrit |

## Règles de traduction

| Règle | Raison |
|---|---|
| Conserver chaque `{{variable}}` **à l'identique** | i18next substitue `{{count}}`, `{{app}}`, `{{error}}`… ; une variable perdue casse l'affichage |
| Ne jamais vider une valeur | le texte vide laisse un trou dans l'interface |
| Ne pas traduire les noms propres | Claude, Codex, Gemini, noms de modèles et de fournisseurs restent tels quels |
| Respecter la longueur | l'interface n'a pas de mise en page élastique partout |
| Rester cohérent avec le lexique | voir ci-dessous |

### Lexique

| Terme | Traduction retenue | À éviter |
|---|---|---|
| provider | **fournisseur** | prestataire |
| session | **session** | séance |
| save | **enregistrer** | sauvegarder (sauf sauvegarde de fichier) |
| clear | **effacer** | clair |
| minimize | **minimiser la fenêtre** | réduire |
| endpoint | **point de terminaison** | — |

## Code

- Les modifications se limitent au **câblage de la locale** : `i18n/index.ts`, `types.ts`,
  `useSettingsForm.ts`, `useDragSort.ts`, `GeneralSection.tsx`. Aucune logique métier upstream
  n'est touchée.
- Pas de binaire, pas de `node_modules`, pas de `target/` dans une pull request.
- Fichiers en **UTF-8 sans BOM**, fins de ligne LF (voir `.gitattributes`).

## Avant d'ouvrir une PR

1. `Mettre-a-jour-CC-Switch-FR.bat -NoInstall` — reconstruit et francise sans rien installer.
2. Vérifie dans l'interface : langue par défaut `fr`, Paramètres → Langue propose les six langues,
   aucun texte anglais résiduel sur les écrans touchés.
3. Décris ce que tu as vérifié **à la main**, et ce que tu n'as pas pu vérifier.

## Commits

`type(portée): description` — exemples : `fix(i18n): variable {{count}} restaurée`,
`docs: précise la procédure de restauration`.
