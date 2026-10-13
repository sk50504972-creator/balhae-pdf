# 발해 PDF 편집기 설치 도우미 (아이콘·기본 앱 설정)
# 하는 일: 1) 앱 설치 확인(없으면 크롬/엣지에서 설치 화면 열기) 2) PDF 파일 아이콘 넣기 3) PDF 기본 앱 지정 창 열기
$ErrorActionPreference = 'SilentlyContinue'
$AppId = 'bclpbmgkggjcdlicnnafagbfoepleefp'
$Base  = 'https://balhae.claimworks.kr/balhae-pdf'
$Dir   = Join-Path $env:LOCALAPPDATA 'BalhaePDF'
$Ico   = Join-Path $Dir 'balhae-pdf-file.ico'

function Say($t, $c = 'Gray') { Write-Host $t -ForegroundColor $c }
function Find-ProgIds {
  Get-ChildItem 'HKCU:\Software\Classes' | Where-Object { $_.PSChildName -match '^[A-Za-z]+\.\d+$' } | ForEach-Object {
    $cmd = (Get-ItemProperty -LiteralPath (Join-Path $_.PSPath 'shell\open\command')).'(default)'
    if ($cmd -and $cmd -match $AppId) { $_.PSChildName }
  }
}

Say ''
Say '=== 발해 PDF 편집기 설치 도우미 ===' 'Cyan'
New-Item -ItemType Directory -Force -Path $Dir | Out-Null
try { Invoke-WebRequest -UseBasicParsing "$Base/icons/balhae-pdf-file.ico" -OutFile $Ico } catch {}

# 1) 앱 설치 확인
$ids = @(Find-ProgIds)
if ($ids.Count -eq 0) {
  $browser = @("$env:ProgramFiles\Google\Chrome\Application\chrome.exe", "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe", "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe", "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe", "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
  Say ''
  Say '[1단계] 앱 설치' 'Yellow'
  Say '방금 열린 브라우저 창에서 [PC 앱으로 설치] 버튼(또는 주소창 오른쪽 설치 아이콘)을 누르세요.'
  if ($browser) { Start-Process $browser "$Base/#install" } else { Start-Process "$Base/#install" }
  for ($i = 0; $i -lt 6 -and $ids.Count -eq 0; $i++) {
    Read-Host '설치가 끝나면 이 창에서 Enter 를 누르세요' | Out-Null
    Start-Sleep -Seconds 2
    $ids = @(Find-ProgIds)
    if ($ids.Count -eq 0) { Say '아직 설치가 확인되지 않습니다. 설치 후 PDF 파일을 한 번 이 앱으로 열어 보거나 잠시 뒤 다시 Enter 를 누르세요.' 'Red' }
  }
  if ($ids.Count -eq 0) { Say '설치를 확인하지 못해 여기서 멈춥니다. 설치 후 이 도우미를 다시 실행하세요.' 'Red'; return }
}
Say '앱 설치 확인됨' 'Green'

# 2) PDF 파일 아이콘
if (Test-Path $Ico) {
  foreach ($id in $ids) {
    $k = "HKCU:\Software\Classes\$id\DefaultIcon"
    New-Item -Path $k -Force | Out-Null
    Set-Item -Path $k -Value "$Ico,0"
  }
  try {
    Add-Type -Namespace Balhae -Name Shell -MemberDefinition '[DllImport("shell32.dll")] public static extern void SHChangeNotify(int e, int f, System.IntPtr a, System.IntPtr b);'
    [Balhae.Shell]::SHChangeNotify(0x08000000, 0, [IntPtr]::Zero, [IntPtr]::Zero)
  } catch {}
  Start-Process -WindowStyle Hidden ie4uinit.exe '-show'
  Say 'PDF 파일 아이콘을 넣었습니다' 'Green'
} else { Say '아이콘 파일을 받지 못했습니다 (인터넷 연결 확인)' 'Red' }

# 3) PDF 기본 앱
$cur = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf\UserChoice').ProgId
if ($ids -contains $cur) {
  Say '이미 PDF 기본 앱이 발해 PDF 편집기입니다' 'Green'
} else {
  Say ''
  Say '[마지막 단계] PDF 기본 앱 지정' 'Yellow'
  Say '곧 뜨는 창에서 [발해 PDF 편집기]를 고르고 [항상]을 누르세요. (보이지 않으면 [더 많은 앱] 또는 [이 PC에서 앱 선택] 목록에 있습니다)'
  $pdf = Join-Path $Dir 'balhae-default-app.pdf'
  if (-not (Test-Path $pdf)) {
    $txt = "%PDF-1.4`n1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj`n2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj`n3 0 obj<</Type/Page/Parent 2 0 R/MediaBox[0 0 595 842]>>endobj`ntrailer<</Root 1 0 R>>`n%%EOF`n"
    [IO.File]::WriteAllText($pdf, $txt, [Text.Encoding]::ASCII)
  }
  Start-Process rundll32.exe "shell32.dll,OpenAs_RunDLL $pdf"
  Say '창이 안 뜨면: 설정 > 앱 > 기본 앱 > 위 검색칸에 .pdf > 발해 PDF 편집기 선택 > [기본값 설정]'
}
Say ''
Say '완료. 탐색기 아이콘이 바로 안 바뀌면 탐색기 창을 닫았다 다시 여세요.' 'Cyan'
