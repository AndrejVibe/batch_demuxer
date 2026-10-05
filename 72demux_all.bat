batch

@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

if exist "%~dp0ffmpeg.exe" (set "FFMPEG=%~dp0ffmpeg.exe") else (set "FFMPEG=ffmpeg")
if exist "%~dp0ffprobe.exe" (set "FFPROBE=%~dp0ffprobe.exe") else (set "FFPROBE=ffprobe")

if "%~1"=="" (
    echo Перетащите один или несколько файлов на этот батник.
    pause
    exit /b
)

set "ROOT="
:loop
if "%~1"=="" goto :done
if not defined ROOT (
    for %%F in ("%~1") do set "ROOT=%%~dpF_extracted"
    echo Корень вывода: !ROOT!
    echo.
)
call :demux "%~1"
shift
goto :loop

:done
echo.
echo Все файлы обработаны. Результат: !ROOT!
pause
exit /b

:demux
set "INFILE=%~1"
for %%F in ("%INFILE%") do (
    set "SRCNAME=%%~nF"
    set "SRCEXT=%%~xF"
)
echo === !SRCNAME!!SRCEXT! ===
set "INFILE_PS=!INFILE!"
set "ROOT_PS=!ROOT!"
set "SRCNAME_PS=!SRCNAME!"
set "SRCEXT_PS=!SRCEXT!"
set "FFMPEG_PS=!FFMPEG!"
set "FFPROBE_PS=!FFPROBE!"

powershell -NoProfile -ExecutionPolicy Bypass -Command "$infile=$env:INFILE_PS;$root=$env:ROOT_PS;$srcname=$env:SRCNAME_PS;$srcext=$env:SRCEXT_PS;$ffmpeg=$env:FFMPEG_PS;$ffprobe=$env:FFPROBE_PS;$streams=(& $ffprobe -v error -show_streams -of json $infile | Out-String | ConvertFrom-Json).streams;$amap=@{'aac'='m4a';'opus'='opus';'mp3'='mp3';'flac'='flac';'vorbis'='ogg';'ac3'='ac3';'eac3'='eac3';'dts'='dts';'truehd'='thd'};$smap=@{'subrip'='srt';'ass'='ass';'ssa'='ssa';'webvtt'='vtt';'hdmv_pgs_subtitle'='sup';'dvd_subtitle'='sub';'mov_text'='srt'};$v=0;$a=0;$s=0;foreach($st in $streams){$type=$st.codec_type;$codec=$st.codec_name;$lang='und';if($st.tags -and $st.tags.language){$lang=$st.tags.language};$title='';if($st.tags -and $st.tags.title){$title=$st.tags.title;foreach($c in [System.IO.Path]::GetInvalidFileNameChars()){$title=$title.Replace($c,'_')}};$suffix='';if($title){$suffix='_'+$title};if($type -eq 'video'){$v++;$folder=Join-Path $root ('video'+$v+$suffix);if(-not(Test-Path $folder)){New-Item -ItemType Directory -Path $folder | Out-Null};$out=Join-Path $folder ($srcname+$srcext);Write-Host ('  video'+$v+' -> '+$out);& $ffmpeg -y -loglevel error -i $infile -map ('0:v:'+($v-1)) -c copy $out}elseif($type -eq 'audio'){$a++;$ext=if($amap.ContainsKey($codec)){$amap[$codec]}else{'mka'};$folder=Join-Path $root ('audio'+$a+'_'+$lang+$suffix);if(-not(Test-Path $folder)){New-Item -ItemType Directory -Path $folder | Out-Null};$out=Join-Path $folder ($srcname+'_a'+$a+'_'+$lang+'.'+$ext);Write-Host ('  audio'+$a+' ['+$codec+'/'+$lang+'] -> '+$out);& $ffmpeg -y -loglevel error -i $infile -map ('0:a:'+($a-1)) -c copy $out}elseif($type -eq 'subtitle'){$s++;$ext=if($smap.ContainsKey($codec)){$smap[$codec]}else{$codec};$folder=Join-Path $root ('subtitle'+$s+'_'+$lang+$suffix);if(-not(Test-Path $folder)){New-Item -ItemType Directory -Path $folder | Out-Null};$out=Join-Path $folder ($srcname+'_s'+$s+'_'+$lang+'.'+$ext);Write-Host ('  sub'+$s+' ['+$codec+'/'+$lang+'] -> '+$out);& $ffmpeg -y -loglevel error -i $infile -map ('0:s:'+($s-1)) -c copy $out}}"
exit /b