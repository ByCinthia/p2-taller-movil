# PowerShell helper to run Flutter with a clean Gradle home and temp dir.
# This avoids the disk/cache issues that were breaking Android builds.

param(
  [string[]]$FlutterArgs = @('run', '-d', 'emulator-5554')
)

$projectRoot = Split-Path -Parent $PSScriptRoot
$gradleHome = 'C:\gradle-home'
$gradleTmp = 'C:\gradle-tmp'

New-Item -ItemType Directory -Force $gradleHome | Out-Null
New-Item -ItemType Directory -Force $gradleTmp | Out-Null

$env:GRADLE_USER_HOME = $gradleHome
$env:JAVA_TOOL_OPTIONS = "-Djava.io.tmpdir=$gradleTmp"

Set-Location $PSScriptRoot
flutter @FlutterArgs
