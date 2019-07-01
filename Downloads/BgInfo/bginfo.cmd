reg add "HKU\.DEFAULT\Software\Sysinternals\BGInfo" /v "EulaAccepted" /t REG_DWORD /d 1 /f
CALL "C:\Users\Public\Lab\BgInfo64.exe" "C:\Users\Public\Lab\BgConfig.bgi" /nolicprompt /timer:0 /all