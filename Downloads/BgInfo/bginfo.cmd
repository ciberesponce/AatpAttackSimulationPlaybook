reg add "HKU\.DEFAULT\Software\Sysinternals\BGInfo" /v "EulaAccepted" /t REG_DWORD /d 1
CALL "bginfo64.exe" "C:\BgInfo\BgInfo.bgi" /nolicprompt /timer:0