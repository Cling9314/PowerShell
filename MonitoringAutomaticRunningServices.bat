@ECHO OFF
REM Aufruf des Powershellscripts, dass genau wie diese bat benannt ist... 

REM Aufruf der 64-bit Powershell auf 64-bit Systemen, statt der 32-bit-Variante
%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe -Command "& '%~dpn0.ps1'"

REM Diese Variante ruft die Powershell in der gleichen Bittigkeit (32 oder 64bit) auf 
REM wie das Executable, welches den Aufruf initiiert.
REM 
REM PowerShell.exe -Command "& '%~dpn0.ps1'"