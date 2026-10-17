# Sécurité

## Signaler une vulnérabilité

**N'ouvrez pas d'issue publique.** Utilisez l'avis de sécurité privé du dépôt :

<https://github.com/xtrem21-source/CC_switch-FR/security/advisories/new>

Indiquez la version de CC Switch, la version de Windows, le script exécuté et le journal
correspondant (`journaux\maj-*.log`, **sans données personnelles**).

## Ce que font les scripts

| Script | Actions | Droits |
|---|---|---|
| `Appliquer-CC-Switch-FR.bat` | arrête `cc-switch.exe`, sauvegarde l'installation dans `old\`, copie le binaire français, met `language = "fr"` dans `%USERPROFILE%\.cc-switch\settings.json`, relance l'application | utilisateur |
| `Mettre-a-jour-CC-Switch-FR.bat` | interroge l'API GitHub, clone les sources upstream, applique la francisation, compile avec cargo/tauri, installe le binaire, relance | utilisateur ; installation du compilateur C++ via `winget` demande l'élévation |
| `Restaurer-CC-Switch.bat` | recopie le binaire officiel sauvegardé dans `old\` | utilisateur |

Aucun script n'écrit ailleurs que dans `%LOCALAPPDATA%\Programs\CC Switch`, `%USERPROFILE%\.cc-switch`,
`%LOCALAPPDATA%\CCSwitchFR`, `%TEMP%\ccswitchfr` et le dossier du dépôt.

## Réseau

| Moment | Destinataire |
|---|---|
| Mise à jour | `api.github.com` et `github.com` (sources upstream, installateur officiel) |
| Installation des prérequis | `winget` |
| Application elle-même | voir la politique de CC Switch ; cette traduction n'ajoute aucun appel réseau |

## Intégrité

Le binaire publié est accompagné de `SHA256SUMS.txt` dans la release :

```powershell
certutil -hashfile cc-switch.exe SHA256
```

Un binaire dont l'empreinte diffère ne doit pas être installé.

## Périmètre

Cette traduction ne modifie pas la logique de l'application : elle ajoute une locale et règle la
langue par défaut. Les vulnérabilités de l'application elle-même se signalent au projet
[upstream](https://github.com/farion1231/cc-switch).

Seule la dernière version publiée de cette traduction est maintenue.
