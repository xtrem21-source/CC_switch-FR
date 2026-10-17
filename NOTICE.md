# NOTICE

## Origine

Ce dépôt contient une **traduction française** de [CC Switch](https://github.com/farion1231/cc-switch),
application publiée sous licence **MIT** par `farion1231` et ses contributeurs.

Le code source d'origine reste leur propriété. Cette traduction en dérive et est distribuée sous
la même licence MIT. **Aucune affiliation, aucun parrainage, aucune approbation** de l'auteur
d'origine n'est impliquée.

## Ce qui est distribué ici

| Contenu | Nature | Licence |
|---|---|---|
| `fichiers-modifies/src/**` | sources modifiées (ajout de la locale `fr`) | MIT, upstream + traduction |
| `fichiers-modifies/cc-switch-fr.patch` | diff complet | MIT |
| `fichiers-modifies/src/i18n/locales/fr.json` | 4 200 traductions | MIT pour l'apport des traducteurs |
| `*.bat`, `outils/**` | scripts d'installation, de mise à jour et de francisation | MIT |
| `journaux/**` | journaux d'exécution, chemins personnels remplacés par `<utilisateur>` | MIT |
| `docs/**` | notice d'origine et méthode | MIT |
| `cc-switch.exe` (release) | **non versionné** : binaire compilé depuis les sources franciscées | MIT |

Aucun binaire de l'application n'est versionné dans ce dépôt : il est publié comme **asset de
release**, conformément au `.gitignore`.

## Marques

« CC Switch » et les noms de fournisseurs cités (Claude, Codex, Gemini, …) appartiennent à leurs
titulaires respectifs. Ils sont mentionnés à titre descriptif.

## Absence de garantie

Le logiciel est fourni « en l'état ». Une mise à jour upstream peut rendre la francisation
partielle ; le script de mise à jour échoue alors proprement, sans modifier l'installation.
Voir [LICENSE](LICENSE).
