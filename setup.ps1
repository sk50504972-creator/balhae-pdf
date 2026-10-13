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

$browser = @("$env:ProgramFiles\Google\Chrome\Application\chrome.exe", "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe", "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe", "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe", "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
$isEdge = $browser -and ($browser -match 'msedge')
function Open-Url($u) { if ($browser) { Start-Process $browser $u } else { Start-Process $u } }

# 1) 앱 설치 확인
$ids = @(Find-ProgIds)
if ($ids.Count -eq 0) {
  Say ''
  Say '[1단계] 앱 설치' 'Yellow'
  Say '방금 열린 브라우저 창에서 [PC 앱으로 설치] 버튼(또는 주소창 오른쪽 설치 아이콘)을 누르세요.'
  Open-Url "$Base/#install"
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
Say '탐색기 아이콘이 바로 안 바뀌면 탐색기 창을 닫았다 다시 여세요.'

# 4) 크롬 확장 프로그램 (선택)
Say ''
$a = Read-Host '[선택] 크롬 확장 프로그램도 설치할까요? 크롬·구글 드라이브 웹에서 PDF가 Adobe로 열리는 것을 막아 줍니다 (Y/N)'
if ($a -match '^(y|Y|예|ㅛ)') {
  $ExtDir = Join-Path $Dir 'extension'
  $zip = Join-Path $env:TEMP 'balhae-pdf-extension.zip'
  try {
    Invoke-WebRequest -UseBasicParsing "$Base/balhae-pdf-extension.zip" -OutFile $zip
    New-Item -ItemType Directory -Force -Path $ExtDir | Out-Null
    Expand-Archive -Path $zip -DestinationPath $ExtDir -Force
    Set-Clipboard -Value $ExtDir
    Say "확장 프로그램 파일을 준비했습니다: $ExtDir" 'Green'
    Say '이 폴더 주소는 복사해 두었습니다 (붙여넣기 Ctrl+V).'
    Say '곧 열리는 확장 프로그램 화면에서:'
    Say '  1) 오른쪽 위 「개발자 모드」를 켭니다.'
    Say '  2) 왼쪽 위 「압축해제된 확장 프로그램을 로드합니다」를 누릅니다.'
    Say '  3) 폴더 선택 창 위쪽 주소칸을 클릭하고 Ctrl+V → Enter → [폴더 선택].'
    Say '  4) 퍼즐 아이콘에서 발해 PDF 편집기를 고정(핀)하고, 아이콘을 눌러 「Adobe Acrobat 확장 끄기」를 누르면 끝.'
    Say '  (이미 설치돼 있으면 발해 PDF 편집기 카드의 새로고침 ↻ 아이콘만 누르면 최신으로 바뀝니다)'
    if ($isEdge) { Open-Url 'edge://extensions/' } else { Open-Url 'chrome://extensions/' }
    Read-Host '다 했으면 Enter' | Out-Null
  } catch { Say ('확장 프로그램을 받지 못했습니다: ' + $_) 'Red' }
}

# 5) 구글 드라이브 연결 (선택)
Say ''
$b = Read-Host '[선택] 구글 드라이브 웹에서도 PDF를 발해 PDF로 열게 할까요? (Y/N)'
if ($b -match '^(y|Y|예|ㅛ)') {
  Say '열리는 발해 PDF 창의 1번 [구글 드라이브에 등록]을 누르고 내 구글 계정을 고른 뒤 [계속]을 누르세요.'
  Open-Url "$Base/#install"
  Read-Host '등록했으면 Enter (다음으로 드라이브 설정을 엽니다)' | Out-Null
  Say '드라이브 설정 → 「앱 관리」 → 발해 PDF 편집기 「기본값으로 사용」에 체크하세요.'
  Open-Url 'https://drive.google.com/drive/settings'
}
Say ''
Say '모두 끝났습니다. 이 창은 닫아도 됩니다.' 'Cyan'
