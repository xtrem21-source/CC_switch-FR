# `patch/` — emplacement du binaire à installer

Ce dossier **ne contient pas** `cc-switch.exe` : le binaire n'est pas versionné (41,7 Mo).

1. Télécharge `cc-switch.exe` depuis la [release `v4.0.14-fr.1`](../../releases/latest).
2. Place-le ici, à côté des `.bat`.
3. Vérifie l'empreinte avec `certutil -hashfile cc-switch.exe SHA256` et compare-la à
   `SHA256SUMS.txt` de la release.
4. Double-clique `Appliquer-CC-Switch-FR.bat`.

Si tu ne veux pas télécharger de binaire, utilise `Mettre-a-jour-CC-Switch-FR.bat` : il
reconstruit l'application depuis les sources upstream et la francise.
