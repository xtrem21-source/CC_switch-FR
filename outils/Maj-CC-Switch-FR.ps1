<#
    Mise a jour automatique de CC Switch en francais
    -------------------------------------------------
    Recupere la derniere version publiee, re-applique la francisation,
    recompile l'application, puis installe le resultat.

    Options :
      -Force        reconstruit meme si la version installee est a jour
      -NoInstall    compile seulement, sans toucher a l'application installee
      -NoLaunch     ne relance pas l'application a la fin
      -NoDownload   ne telecharge pas l'installateur officiel

    Aucune modification n'est faite sur l'installation si une etape echoue.
#>

[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$NoInstall,
    [switch]$NoLaunch,
    [switch]$NoDownload
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch { }

# ---------------------------------------------------------------------------
# chemins
# ---------------------------------------------------------------------------
$ScriptDir = $PSScriptRoot
$Root      = Split-Path -Parent $ScriptDir
$ModDir    = Join-Path $Root 'fichiers-modifies'
$PatchFile = Join-Path $ModDir 'cc-switch-fr.patch'
$FrFile    = Join-Path $ModDir 'src\i18n\locales\fr.json'
$WorkRoot  = Join-Path $env:LOCALAPPDATA 'CCSwitchFR'
$LogDir    = Join-Path $Root 'journaux'
$TempDir   = Join-Path $env:TEMP 'ccswitchfr'
$Repo      = 'https://github.com/farion1231/cc-switch.git'
$ApiUrl    = 'https://api.github.com/repos/farion1231/cc-switch/releases/latest'

if ($env:CCTARGET) { $InstallDir = $env:CCTARGET } else { $InstallDir = Join-Path $env:LOCALAPPDATA 'Programs\CC Switch' }
$ExePath = Join-Path $InstallDir 'cc-switch.exe'
$SettingsPath = Join-Path $env:USERPROFILE '.cc-switch\settings.json'

foreach ($folder in @($LogDir, $TempDir)) {
    if (-not (Test-Path -LiteralPath $folder)) { New-Item -ItemType Directory -Path $folder -Force | Out-Null }
}
$script:LogPath = Join-Path $LogDir ("maj-{0}.log" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))

# ---------------------------------------------------------------------------
# sortie console + journal
# ---------------------------------------------------------------------------
function Write-Log {
    param([string]$Text)
    try { Add-Content -LiteralPath $script:LogPath -Value $Text -Encoding UTF8 } catch { }
}

function Say {
    param([string]$Text, [string]$Color = 'Gray')
    Write-Host $Text -ForegroundColor $Color
    Write-Log $Text
}

function Fail {
    param([string]$Text, [string]$Hint = '')
    Say ''
    Say "ECHEC : $Text" Red
    if ($Hint) { Say "        $Hint" Yellow }
    Say "Journal : $($script:LogPath)" DarkGray
    Say ''
    Say "Ton installation actuelle n'a pas ete modifiee." Green
    exit 1
}

function Get-ExeVersion {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    $raw = (Get-Item -LiteralPath $Path).VersionInfo.ProductVersion
    if ($raw -match '\d+(\.\d+){1,3}') { return $Matches[0] }
    return $raw
}

# Execute un programme externe sans que ses messages d'erreur n'arretent le
# script, tout en les conservant dans le journal.
function Invoke-Tool {
    param(
        [Parameter(Mandatory = $true)][string]$Program,
        [string[]]$Arguments = @()
    )
    $errFile = Join-Path $TempDir ("err-" + [guid]::NewGuid().ToString('N') + ".txt")
    $previous = $ErrorActionPreference
    $code = 0
    try {
        $ErrorActionPreference = 'Continue'
        & $Program @Arguments 2> $errFile | Out-Host
        $code = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previous
    }
    if (Test-Path -LiteralPath $errFile) {
        $errors = Get-Content -LiteralPath $errFile -ErrorAction SilentlyContinue
        if ($errors) { $errors | ForEach-Object { Write-Log ([string]$_) } }
        Remove-Item -LiteralPath $errFile -Force -ErrorAction SilentlyContinue
    }
    return $code
}

function Set-FrenchLanguage {
    if (-not (Test-Path -LiteralPath $SettingsPath)) { return $false }
    try {
        $text = [IO.File]::ReadAllText($SettingsPath, [Text.Encoding]::UTF8)
        $json = $text | ConvertFrom-Json
        if ($json.PSObject.Properties.Name -contains 'language') {
            $json.language = 'fr'
        } else {
            $json | Add-Member -NotePropertyName language -NotePropertyValue 'fr'
        }
        $out = $json | ConvertTo-Json -Depth 40
        [IO.File]::WriteAllText($SettingsPath, $out, (New-Object System.Text.UTF8Encoding($false)))
        return $true
    } catch {
        Write-Log ("Echec ecriture settings.json : " + $_.Exception.Message)
        return $false
    }
}

# ---------------------------------------------------------------------------
# 0. en-tete
# ---------------------------------------------------------------------------
Say ''
Say '=====================================================' Cyan
Say '   CC Switch - mise a jour automatique en francais' Cyan
Say '=====================================================' Cyan
Say ''

# ---------------------------------------------------------------------------
# 1. outils necessaires
# ---------------------------------------------------------------------------
$missing = @()
# Outils necessaires a la compilation, avec leur identifiant winget et leur
# adresse de telechargement en cas de besoin.
$dependencies = @(
    @{ Command = 'git';    Name = 'Git';          Winget = 'Git.Git';            Web = 'https://git-scm.com/download/win' },
    @{ Command = 'node';   Name = 'Node.js';      Winget = 'OpenJS.NodeJS.LTS';  Web = 'https://nodejs.org/fr' },
    @{ Command = 'pnpm';   Name = 'pnpm';         Winget = 'pnpm.pnpm';          Web = 'https://pnpm.io/fr/installation' },
    @{ Command = 'cargo';  Name = 'Rust (cargo)'; Winget = 'Rustlang.Rustup';    Web = 'https://rustup.rs' },
    @{ Command = 'python'; Name = 'Python';       Winget = 'Python.Python.3.12'; Web = 'https://www.python.org/downloads/' }
)

function Test-Dependency {
    param($Dependency)
    if ($Dependency.Command -eq 'python') {
        # on ignore l'alias vide de Windows qui ouvre le Microsoft Store
        $command = Get-Command python -ErrorAction SilentlyContinue
        $usable = $command -and ($command.Source -notlike '*WindowsApps\python.exe')
        if (-not $usable) { $usable = [bool](Get-Command py -ErrorAction SilentlyContinue) }
        return [bool]$usable
    }
    return [bool](Get-Command $Dependency.Command -ErrorAction SilentlyContinue)
}

function Get-MissingTools {
    $result = @()
    foreach ($dependency in $dependencies) {
        if (-not (Test-Dependency $dependency)) { $result += $dependency }
    }
    return $result
}

# Les installations winget modifient le PATH du systeme : on le recharge pour
# la session en cours, sinon les outils installes restent invisibles.
function Update-SessionPath {
    $segments = @()
    foreach ($chunk in @(
        [Environment]::GetEnvironmentVariable('Path', 'Machine'),
        [Environment]::GetEnvironmentVariable('Path', 'User'),
        $env:Path
    )) {
        if (-not $chunk) { continue }
        foreach ($entry in $chunk.Split(';')) {
            if ($entry -and ($segments -notcontains $entry)) { $segments += $entry }
        }
    }
    $cargoBin = Join-Path $env:USERPROFILE '.cargo\bin'
    if ((Test-Path -LiteralPath $cargoBin) -and ($segments -notcontains $cargoBin)) { $segments += $cargoBin }
    $env:Path = $segments -join ';'
}

$missing = Get-MissingTools
if ($missing.Count -gt 0) {
    Say 'Il manque des outils necessaires a la compilation :' Yellow
    foreach ($item in $missing) { Say ('   - ' + $item.Name) Yellow }
    Say ''

    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Say 'Je peux les installer automatiquement avec winget.' Gray
        $answer = Read-Host "Installer ces outils maintenant ? (O/N)"
        Say ''
        if ($answer -match '^(o|oui|y|yes)$') {
            foreach ($item in $missing) {
                Say ('Installation de ' + $item.Name + ' ...') Cyan
                & winget install --id $item.Winget -e --accept-package-agreements --accept-source-agreements --disable-interactivity
                $code = $LASTEXITCODE
                Update-SessionPath
                if (Test-Dependency $item) { Say ('   ' + $item.Name + ' installe.') Green }
                else { Say ('   installation de ' + $item.Name + ' en echec (code ' + $code + ')') Yellow }
            }
            Say ''
            Say 'Mise a jour de l environnement de la session...' Gray
            Update-SessionPath
            Start-Sleep -Seconds 2
            $missing = Get-MissingTools
            if ($missing.Count -gt 0) {
                Say 'Toujours introuvables apres installation :' Yellow
                foreach ($item in $missing) { Say ('   - ' + $item.Name + ' : ' + $item.Web) Yellow }
                Fail "des outils restent introuvables" "Ferme puis relance le script, ou installe-les depuis les liens ci-dessus."
            }
            Say 'Tous les outils sont maintenant disponibles.' Green
        } else {
            foreach ($item in $missing) { Say ('   - ' + $item.Name + ' : ' + $item.Web) DarkGray }
            Fail "des outils necessaires sont absents" "Installe-les puis relance ce script."
        }
    } else {
        Say 'winget n est pas disponible sur ce systeme.' Yellow
        foreach ($item in $missing) { Say ('   - ' + $item.Name + ' : ' + $item.Web) DarkGray }
        Fail "des outils necessaires sont absents" "Installe-les puis relance ce script."
    }
}

# Python, desormais present
$Python = $null
if (Get-Command python -ErrorAction SilentlyContinue) { $Python = 'python' }
elseif (Get-Command py -ErrorAction SilentlyContinue) { $Python = 'py' }
if (-not $Python) { Fail "Python est introuvable" }

# ---------------------------------------------------------------------------
# 1b. compilateur C++ (indispensable a Rust sous Windows)
# ---------------------------------------------------------------------------
$msvcFound = $false
$VsWhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
if (Test-Path -LiteralPath $VsWhere) {
    $VsPath = & $VsWhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath 2>$null
    if ($VsPath) { $msvcFound = $true }
}
if (-not $msvcFound) {
    Say ''
    Say 'Le compilateur C++ de Visual Studio est absent.' Yellow
    Say 'Rust en a besoin pour produire le programme.' Gray
    Say 'Installation possible via winget : environ 4 Go, 10 a 20 minutes, droits administrateur.' DarkGray
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        $answer = Read-Host "Installer les outils de compilation C++ maintenant ? (O/N)"
        Say ''
        if ($answer -match '^(o|oui|y|yes)$') {
            Say 'Installation des outils de compilation C++ (patience)...' Cyan
            & winget install --id Microsoft.VisualStudio.2022.BuildTools -e --accept-package-agreements --accept-source-agreements --override "--quiet --wait --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
            if ($LASTEXITCODE -eq 0) { Say 'Outils de compilation installes.' Green }
            else { Say ('   installation en echec (code ' + $LASTEXITCODE + ')') Yellow }
            if (Test-Path -LiteralPath $VsWhere) {
                $VsPath = & $VsWhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath 2>$null
                if ($VsPath) { $msvcFound = $true }
            }
        }
    }
    if (-not $msvcFound) {
        Say 'Commande manuelle :' DarkGray
        Say '  winget install --id Microsoft.VisualStudio.2022.BuildTools -e --override "--quiet --wait --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"' DarkGray
        Fail "le compilateur C++ est absent" "Installe-le puis relance ce script."
    }
}

foreach ($needed in @($PatchFile, $FrFile)) {
    if (-not (Test-Path -LiteralPath $needed)) { Fail "fichier introuvable : $needed" }
}

# ---------------------------------------------------------------------------
# 2. versions
# ---------------------------------------------------------------------------
$installed = Get-ExeVersion $ExePath
if ($installed) { Say "Version installee : $installed" }
else { Say "Aucune installation detectee dans $InstallDir" Yellow }

Say 'Recherche de la derniere version publiee...'
try {
    $release = Invoke-RestMethod -Uri $ApiUrl -Headers @{ 'User-Agent' = 'ccswitch-fr-updater' } -TimeoutSec 60
} catch {
    Fail "impossible de joindre GitHub" $_.Exception.Message
}
$tag = $release.tag_name
$latest = $tag -replace '^v', ''
Say "Derniere version publiee : $latest" Green
Say ''

$upToDate = $false
if ($installed -and $latest) {
    try { $upToDate = ([version]$installed -ge [version]$latest) } catch { $upToDate = $false }
}
if ($upToDate -and -not $Force) {
    Say "CC Switch $installed est deja a jour : rien a faire." Green
    Say '(lance avec -Force pour reconstruire malgre tout)' DarkGray
    exit 0
}

# ---------------------------------------------------------------------------
# 3. sources
# ---------------------------------------------------------------------------
$Tree = Join-Path $WorkRoot ("src-" + $latest)
if (Test-Path -LiteralPath $Tree) { Remove-Item -LiteralPath $Tree -Recurse -Force }
if (-not (Test-Path -LiteralPath $WorkRoot)) { New-Item -ItemType Directory -Path $WorkRoot -Force | Out-Null }

Say "Telechargement des sources $tag ..."
$cloneCode = Invoke-Tool -Program 'git' -Arguments @('clone', '--depth', '1', '--branch', $tag, $Repo, $Tree)
if ($cloneCode -ne 0 -or -not (Test-Path -LiteralPath (Join-Path $Tree 'package.json'))) {
    Fail "le telechargement des sources a echoue" "Verifie ta connexion Internet."
}
Say "Sources pretes : $Tree" Green

# ---------------------------------------------------------------------------
# 4. francisation
# ---------------------------------------------------------------------------
Say ''
Say 'Application de la francisation...' Cyan
$prepReport = Join-Path $WorkRoot ("francisation-" + $latest + ".json")
$prepCode = Invoke-Tool -Program $Python -Arguments @(
    (Join-Path $ScriptDir 'prep_sources.py'),
    '--tree', $Tree,
    '--patch', $PatchFile,
    '--fr', $FrFile,
    '--report', $prepReport
)
if (Test-Path -LiteralPath $prepReport) {
    $rep = [IO.File]::ReadAllText($prepReport, [Text.Encoding]::UTF8) | ConvertFrom-Json
    foreach ($item in $rep.files) { Say ("  - " + $item.file + " (" + $item.method + ")") DarkGray }
    foreach ($item in $rep.locales) { Say ("  - traduction : " + $item) DarkGray }
    foreach ($item in $rep.warnings) { Say ("  ! " + $item) Yellow }
    foreach ($item in $rep.errors) { Say ("  x " + $item) Red }
}
if ($prepCode -ne 0) {
    Fail "la francisation n'a pas pu etre appliquee a la version $latest" "Le journal contient le detail. Envoie-le moi et je prepare le portage."
}
Say 'Francisation appliquee.' Green

# ---------------------------------------------------------------------------
# 5. chaines nouvelles
# ---------------------------------------------------------------------------
Say ''
Say 'Recherche des nouvelles chaines a traduire...' Cyan
$cacheFile = Join-Path $ScriptDir 'cache-traductions.json'
$gapCode = Invoke-Tool -Program $Python -Arguments @(
    (Join-Path $ScriptDir 'fill_fr_gaps.py'),
    '--en', (Join-Path $Tree 'src\i18n\locales\en.json'),
    '--fr', (Join-Path $Tree 'src\i18n\locales\fr.json'),
    '--cache', $cacheFile
)
if ($gapCode -ne 0) {
    Say '  ! la completion des traductions a echoue : la version anglaise sera utilisee pour ces chaines.' Yellow
}

# ---------------------------------------------------------------------------
# 6. dependances
# ---------------------------------------------------------------------------
Say ''
Say 'Installation des dependances...' Cyan
Push-Location $Tree
try {
    $installCode = Invoke-Tool -Program 'pnpm' -Arguments @('install', '--frozen-lockfile')
} finally {
    Pop-Location
}
if ($installCode -ne 0) {
    Say '  ! installation stricte refusee, nouvelle tentative...' Yellow
    Push-Location $Tree
    try {
        $installCode = Invoke-Tool -Program 'pnpm' -Arguments @('install')
    } finally {
        Pop-Location
    }
    if ($installCode -ne 0) { Fail "l'installation des dependances a echoue" }
}
Say 'Dependances installees.' Green

# ---------------------------------------------------------------------------
# 6b. verification des types
# ---------------------------------------------------------------------------
Say ''
Say 'Verification des types TypeScript...' Cyan
Push-Location $Tree
try {
    $typeCode = Invoke-Tool -Program 'pnpm' -Arguments @('typecheck')
} finally {
    Pop-Location
}
if ($typeCode -ne 0) {
    Say '  ! la verification des types signale des erreurs (la compilation tranchera).' Yellow
} else {
    Say '  Types valides.' Green
}

$env:CARGO_TARGET_DIR = Join-Path $WorkRoot 'cargo-target'
if (-not (Test-Path -LiteralPath $env:CARGO_TARGET_DIR)) { New-Item -ItemType Directory -Path $env:CARGO_TARGET_DIR -Force | Out-Null }

# ---------------------------------------------------------------------------
# 7. compilation
# ---------------------------------------------------------------------------
Say ''
Say 'Compilation de l application (cela peut prendre plusieurs minutes)...' Cyan
Write-Log ("CARGO_TARGET_DIR=" + $env:CARGO_TARGET_DIR)
Push-Location $Tree
try {
    $buildCode = Invoke-Tool -Program 'pnpm' -Arguments @('tauri', 'build', '--no-bundle')
} finally {
    Pop-Location
}
if ($buildCode -ne 0) {
    Fail "la compilation a echoue" "Aucune modification n'a ete faite sur ton installation. Le journal contient le detail."
}

$candidates = @()
foreach ($candidate in @(
    (Join-Path $env:CARGO_TARGET_DIR 'release\cc-switch.exe'),
    (Join-Path $Tree 'src-tauri\target\release\cc-switch.exe')
)) {
    if (Test-Path -LiteralPath $candidate) { $candidates += Get-Item -LiteralPath $candidate }
}
if ($candidates.Count -eq 0) { Fail "le binaire compile est introuvable" }
$NewExe = ($candidates | Sort-Object LastWriteTime -Descending)[0]
$builtVersion = Get-ExeVersion $NewExe.FullName
Say ''
Say ("Binaire construit : " + $NewExe.FullName) DarkGray
Say ("Taille : " + [math]::Round($NewExe.Length / 1MB, 1) + " Mo - version " + $builtVersion) DarkGray
if ($builtVersion -ne $latest) { Say ("  ! version attendue : " + $latest) Yellow }

# ---------------------------------------------------------------------------
# 8. installation
# ---------------------------------------------------------------------------
if ($NoInstall) {
    Say ''
    Say "Compilation terminee. Installation ignoree (-NoInstall)." Yellow
    Say "Binaire disponible : $($NewExe.FullName)" Green
    exit 0
}

Say ''
Say 'Installation du nouveau binaire...' Cyan

Get-Process cc-switch -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2

if ($installed) {
    $prevDir = Join-Path $Root ("old\" + $installed)
    if (-not (Test-Path -LiteralPath $prevDir)) { New-Item -ItemType Directory -Path $prevDir -Force | Out-Null }
    if (Test-Path -LiteralPath $ExePath) { Copy-Item -LiteralPath $ExePath -Destination (Join-Path $prevDir 'cc-switch.exe') -Force }
    if (Test-Path -LiteralPath $SettingsPath) { Copy-Item -LiteralPath $SettingsPath -Destination (Join-Path $prevDir 'settings.json') -Force }
    Say "Ancienne version archivee dans old\$installed" DarkGray
}

if (-not (Test-Path -LiteralPath $InstallDir)) {
    Fail "dossier d'installation introuvable : $InstallDir" "Installe d'abord CC Switch normalement."
}

Copy-Item -LiteralPath $NewExe.FullName -Destination (Join-Path $Root 'patch\cc-switch.exe') -Force
Copy-Item -LiteralPath $NewExe.FullName -Destination $ExePath -Force
Say 'Binaire installe.' Green

if (Set-FrenchLanguage) { Say 'Langue de l interface reglee sur francais.' Green }
else { Say '  ! configuration introuvable : la langue sera choisie au premier demarrage.' Yellow }

# ---------------------------------------------------------------------------
# 9. binaire officiel d'origine (pour la restauration)
# ---------------------------------------------------------------------------
if (-not $NoDownload) {
    Say ''
    Say "Recuperation du binaire officiel $latest pour la sauvegarde..." Cyan
    try {
        $msi = $release.assets | Where-Object { $_.name -like '*.msi' } | Select-Object -First 1
        if (-not $msi) { throw "aucun installateur MSI dans la publication" }
        $msiPath = Join-Path $WorkRoot $msi.name
        if (-not (Test-Path -LiteralPath $msiPath)) {
            Invoke-WebRequest -Uri $msi.browser_download_url -OutFile $msiPath -TimeoutSec 300
        }
        $layout = Join-Path $WorkRoot ("msi-" + $latest)
        if (Test-Path -LiteralPath $layout) { Remove-Item -LiteralPath $layout -Recurse -Force }
        $arguments = @('/a', ('"' + $msiPath + '"'), '/qn', ('TARGETDIR="' + $layout + '"'))
        $proc = Start-Process -FilePath 'msiexec.exe' -ArgumentList $arguments -Wait -PassThru -WindowStyle Hidden
        $official = Get-ChildItem -LiteralPath $layout -Recurse -Filter 'cc-switch.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($official -and $proc.ExitCode -eq 0) {
            Copy-Item -LiteralPath $official.FullName -Destination (Join-Path $Root 'old\cc-switch.exe') -Force
            Say 'Binaire officiel sauvegarde dans old\cc-switch.exe' DarkGray
        } else {
            Say '  ! extraction impossible : old\cc-switch.exe conserve la version precedente.' Yellow
        }
    } catch {
        Say ('  ! recuperation impossible : ' + $_.Exception.Message) Yellow
    }
}

# ---------------------------------------------------------------------------
# 10. mise a jour du dossier de livraison
# ---------------------------------------------------------------------------
Say ''
Say 'Mise a jour du correctif et des sources dans le dossier...' Cyan
try {
    Invoke-Tool -Program 'git' -Arguments @('-C', $Tree, 'add', '-A', '--', 'src') | Out-Null
    $changed = & git -C $Tree diff --cached --name-only -- src
    foreach ($file in $changed) {
        $relative = $file -replace '/', '\'
        $destination = Join-Path $ModDir $relative
        $parent = Split-Path -Parent $destination
        if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
        Copy-Item -LiteralPath (Join-Path $Tree $relative) -Destination $destination -Force
    }
    $diffCode = Invoke-Tool -Program 'git' -Arguments @('-C', $Tree, 'diff', '--cached', ("--output=" + $PatchFile), '--', 'src')
    if ($diffCode -eq 0) {
        $size = [math]::Round((Get-Item -LiteralPath $PatchFile).Length / 1KB)
        Say ("Correctif regenere pour la version " + $latest + " : " + $size + " Ko") DarkGray
    }
    Invoke-Tool -Program 'git' -Arguments @('-C', $Tree, 'reset', '-q') | Out-Null
} catch {
    Say ('  ! mise a jour du dossier incomplete : ' + $_.Exception.Message) Yellow
}

Set-Content -LiteralPath (Join-Path $ModDir 'version.txt') -Value $latest -Encoding ASCII

# ---------------------------------------------------------------------------
# 11. relance
# ---------------------------------------------------------------------------
if (-not $NoLaunch) {
    try { Start-Process -FilePath $ExePath } catch { Say '  ! relance automatique impossible.' Yellow }
}

Say ''
Say '=====================================================' Green
Say ("   CC Switch $latest est installe en francais") Green
Say '=====================================================' Green
Say ''
Say "Journal : $($script:LogPath)" DarkGray
exit 0
