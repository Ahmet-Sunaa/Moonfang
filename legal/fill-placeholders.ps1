# =============================================================================
# 🌙 Moonfang — legal/ sayfalarindaki yer tutuculari tek komutla doldurur
# =============================================================================
# Google Play yayini oncesi privacy-policy.html, account-deletion.html ve
# index.html icindeki [GELİŞTİRİCİ ADI] / [E-POSTA] / [GG.AA.YYYY] / [YIL]
# yer tutucularini doldurur. Ayrica:
#   • "Yayın öncesi doldurulacak alanlar" uyari kutusunu (gelistirici notu)
#     sayfadan KALDIRIR — bu not musteriye gorunmemeli.
#   • Doldurulan degerlerin sari vurgu sarmalayicisini (<span class="ph">)
#     temizler ki sayfa "doldurulmamis" gibi gorunmesin.
#
# Kullanim (repo kokunde ya da legal/ icinde):
#   .\legal\fill-placeholders.ps1 -Name "Ahmet Yilmaz" -Email "ornek@gmail.com"
#   .\legal\fill-placeholders.ps1 -Name "..." -Email "..." -Date "01.11.2026"
#
# Sayfalar yayinlandiktan sonra adresleri uygulamaya da yazabilir:
#   .\legal\fill-placeholders.ps1 -Name "..." -Email "..." `
#       -PrivacyUrl "https://x.netlify.app/privacy-policy.html" `
#       -DeletionUrl "https://x.netlify.app/account-deletion.html"
#
# Once denemek istersen (hicbir dosya degismez, sadece rapor): -DryRun
# =============================================================================

param(
  [Parameter(Mandatory = $true)][string]$Name,
  [Parameter(Mandatory = $true)][string]$Email,
  [string]$Date = (Get-Date).ToString('dd.MM.yyyy'),
  [string]$Year = '',
  [string]$PrivacyUrl = '',
  [string]$DeletionUrl = '',
  [string]$Path = '',
  [switch]$KeepHighlight,
  [switch]$DryRun
)
$ErrorActionPreference = 'Stop'

if (-not $Path) {
  $Path = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
}
$legalDir = (Resolve-Path -LiteralPath $Path).Path
$repoRoot = Split-Path $legalDir -Parent
$legalJs  = Join-Path $repoRoot 'client\src\legal.js'

# --- 1) girdileri dogrula (yanlis deger sayfaya yazilmasin) ---
if ($Name -match '[\[\]]') { throw "Isim koseli parantez icermemeli (yer tutucu gibi gorunur): $Name" }
if ($Email -notmatch '^[^@\s]+@[^@\s]+\.[^@\s]+$') { throw "Gecersiz e-posta: $Email" }
if ($Date -notmatch '^\d{2}\.\d{2}\.\d{4}$') { throw "Tarih GG.AA.YYYY biciminde olmali (ornek: 01.11.2026): $Date" }
if (-not $Year) { $Year = $Date.Substring(6, 4) }
if ($Year -notmatch '^\d{4}$') { throw "Yil 4 haneli olmali: $Year" }
foreach ($u in @($PrivacyUrl, $DeletionUrl)) {
  if ($u -and $u -notmatch '^https://[^\s"]+\.[^\s"]+$') { throw "URL https:// ile baslamali ve gercek bir adres olmali: $u" }
}

Write-Host ''
Write-Host '=== legal/ yer tutuculari dolduruluyor ===' -ForegroundColor Cyan
Write-Host "  Gelistirici : $Name"
Write-Host "  E-posta     : $Email"
Write-Host "  Tarih / Yil : $Date  ($Year)"
if ($DryRun) { Write-Host '  (DENEME MODU — hicbir dosya degistirilmedi)' -ForegroundColor Yellow }
Write-Host "  Klasor      : $legalDir"

# --- 2) yer tutucu -> deger (+ kac kez degistigini say) ---
function Set-Placeholder([string]$Text, [string]$From, [string]$To) {
  $c = ([regex]::Matches($Text, [regex]::Escape($From))).Count
  if ($c -gt 0) { $Text = $Text.Replace($From, $To) }
  return @{ Text = $Text; Count = $c }
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$files = @(Get-ChildItem -LiteralPath $legalDir -Filter '*.html')
if (-not $files.Count) { throw "Hic .html bulunamadi: $legalDir" }

$totalFilled = 0
$problems = @()

foreach ($f in $files) {
  $orig = [IO.File]::ReadAllText($f.FullName, $utf8NoBom)
  $s = $orig
  $noteRemoved = $false

  # 2a) yayin oncesi gelistirici notu kutusunu KALDIR (musteriye gorunmemeli)
  $notePattern = '(?sm)^[ \t]*<div class="card warn">\r?\n\s*⚠️ <b>Yay.n .ncesi doldurulacak alanlar</b>.*?^\s*</div>\r?\n'
  if ([regex]::IsMatch($s, $notePattern)) {
    $s = [regex]::Replace($s, $notePattern, '')
    $noteRemoved = $true
  }

  # 2b) yer tutuculari doldur
  $n = 0
  foreach ($pair in @(
      @('[GELİŞTİRİCİ ADI]', $Name),
      @('[E-POSTA]', $Email),
      @('[GG.AA.YYYY]', $Date),
      @('[YIL]', $Year))) {
    $r = Set-Placeholder $s $pair[0] $pair[1]
    $s = $r.Text
    $n += $r.Count
  }

  # 2c) sari vurgu sarmalayicisini temizle (doldurulmus deger artik yer tutucu degil)
  if (-not $KeepHighlight) {
    $s = [regex]::Replace($s, '<span class="ph">(?<v>[^<]*)</span>', {
        param($m)
        $v = $m.Groups['v'].Value
        if ($v -match '\[') { $m.Value } else { $v }
      })
  }

  $changed = ($s -ne $orig)
  if ($changed -and -not $DryRun) {
    [IO.File]::WriteAllText($f.FullName, $s, $utf8NoBom)
  }
  $totalFilled += $n

  $note = if ($noteRemoved) { ' + uyari kutusu kaldirildi' } else { '' }
  $mode = if ($DryRun) { 'doldurulacak' } else { 'dolduruldu' }
  Write-Host "  $($f.Name): $n yer tutucu $mode$note" -ForegroundColor Green

  # 2d) kalan yer tutucu / vurgu var mi?
  $left = ([regex]::Matches($s, '\[[^\]\r\n]{2,40}\]')).Value | Where-Object { $_ -ne '[]' }
  if ($left) { $problems += "$($f.Name): kalan -> $($left -join ', ')" }
  if (-not $KeepHighlight -and $s -match '<span class="ph">') { $problems += "$($f.Name): sari vurgu (class=ph) kaldi" }
}


# --- 3) istenmisse adresleri client/src/legal.js icine yaz ---
if ($PrivacyUrl -or $DeletionUrl) {
  if (-not (Test-Path -LiteralPath $legalJs)) {
    Write-Host "  [X] legal.js bulunamadi: $legalJs" -ForegroundColor Red
    $problems += 'legal.js bulunamadi'
  } else {
    $js = [IO.File]::ReadAllText($legalJs, $utf8NoBom)
    if ($PrivacyUrl) {
      $js = [regex]::Replace($js, '(PRIVACY_POLICY_URL\s*=\s*)"[^"]*"', "`$1`"$PrivacyUrl`"")
    }
    if ($DeletionUrl) {
      $js = [regex]::Replace($js, '(ACCOUNT_DELETION_URL\s*=\s*)"[^"]*"', "`$1`"$DeletionUrl`"")
    }
    $js = [regex]::Replace($js, '(SUPPORT_EMAIL\s*=\s*)"[^"]*"', "`$1`"$Email`"")
    if ($DryRun) {
      Write-Host '  legal.js: URL/iletisim alanlari doldurulacak (deneme modu)' -ForegroundColor Yellow
    } else {
      [IO.File]::WriteAllText($legalJs, $js, $utf8NoBom)
      Write-Host "  legal.js guncellendi: $legalJs" -ForegroundColor Green
    }
  }
}

# --- 4) ozet ---
Write-Host ''
if ($problems.Count) {
  Write-Host '=== DIKKAT — elle kontrol et ===' -ForegroundColor Yellow
  $problems | ForEach-Object { Write-Host "  [!] $_" -ForegroundColor Yellow }
} else {
  Write-Host '=== [OK] Tum yer tutucular dolduruldu, sayfalar yayina hazir ===' -ForegroundColor Green
}
Write-Host ''
Write-Host 'Sonraki adimlar:' -ForegroundColor Cyan
Write-Host '  1) legal/ klasorunu yayinla (git istemiyorsan https://app.netlify.com/drop adresine surukle)' -ForegroundColor Gray
Write-Host '  2) Cikan adresleri uygulamaya yaz (legal/README.md adim 3)' -ForegroundColor Gray
Write-Host '  3) Sayfalari TELEFONDAN ac (giris yapmadan gorunmeli), sonra Play Console > App content' -ForegroundColor Gray

if ($problems.Count) { exit 1 }
