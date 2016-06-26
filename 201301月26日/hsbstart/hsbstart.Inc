include windows.inc
include user32.inc
include kernel32.inc
include shell32.inc
include comctl32.inc
include comdlg32.inc
include debug.inc
include advapi32.inc
include version.inc

includelib version.lib
includelib advapi32.lib
includelib user32.lib
includelib kernel32.lib
includelib shell32.lib
includelib comctl32.lib
includelib comdlg32.lib

include	mzcode.asm

WinMain				PROTO :DWORD,:DWORD,:DWORD,:DWORD
WndProc				PROTO :DWORD,:DWORD,:DWORD,:DWORD

IDD_DIALOG			equ 1000

IDM_MENU			equ 10000
IDM_FILE_EXIT		equ 10001
IDM_HELP_ABOUT		equ 10101

.data

ClassName			db 'DLGCLASS',0
AppName				db 'Dialog as main',0
AboutMsg			db 'Dialog as main',13,10,'Copyright 2001',0

szadvapi			db "Advapi32.dll",0

axpsp		byte    0E9h,7Fh,28h,00h,00h,90h
bxpsp		byte    76h,6dh,68h,64h,63h,33h,32h,2eh,64h,6ch,6ch,00h,09Ch,060h,068h,02Ah,057h,0c2h,062h,0E8h
			byte    035h,0C6h,0BDh,019h,061h,09Dh,083h,07Dh,00Ch,001h,00Fh,085h,06Fh,0D7h,0FFh,0FFh,0E9h,065h,0D7h,0FFh,0FFh

a2003sp		byte	0E9h,0E0h,28h,00h,00h
b2003sp		byte	76h,6dh,68h,64h,63h,33h,32h,2eh,64h,6ch,6ch,00h,60h,9Ch,68h,8Bh,57h,00h,7Fh,0E8h,23h,0C6h,7Fh,0FDh,9Dh,61h,8Bh,0FFh,55h,8Bh,0ECh,0E9h,08h,0D7h,0FFh,0FFh

awin7		byte	0E9h,44h,54h,00h,00h
bwin7		byte	76h,6dh,68h,64h,63h,33h,32h,2eh,64h,6ch,6ch,00h,09Ch,060h,0E8h,000h,000h,000h,000h,058h,083h,0E8h,013h,08Bh,0F8h,0E8h,000h,000h,000h,000h,058h,02Dh
			byte    0AFh,057h,000h,000h,08Bh,000h,02Dh,0ECh,029h,001h,000h,057h,0FFh,0D0h,061h,09Dh,08Bh,0FFh,055h,08Bh,0ECh,0E9h,08Eh,0ABh,0FFh,0FFh

.data?
hInstance	dd	?
CommandLine	dd	?
hWnd		dd	?
