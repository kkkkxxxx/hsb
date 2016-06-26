
DesktopView proc uses ebx esi edi uParam,wParam,lParam
	LOCAL @lsls,@lslp,@dwksize,@dwys,@lpys
	m2m @lsls,wParam
	mov esi,lParam
	assume esi:ptr OVERLAPPEDPLUS
	.if @lsls>10
		mov edi,uParam
		m2m @dwys,dword ptr[edi]
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,@dwys
		mov @lpys,eax
		add edi,4
		sub @lsls,4		
		push @dwys
		push @lpys
		push @lsls
		push edi
		push @f
		jmp lzunpack
		@@:
		.if eax!=@dwys
			jmp error
		.endif
		mov edi,@lpys
;		mov edi,uParam
		mov eax,dword ptr[edi]
		mov @lsls,eax
		mov eax,dword ptr[edi+4]
		mov @dwksize,eax
		add edi,8
		mov @lslp,edi
		add edi,sizeof BITMAPINFOHEADER
		add edi,1024
		xor ebx,ebx
		.while ebx<@lsls
			xor eax,eax
			mov ax,word ptr[edi]
			add edi,2
			invoke SetDIBitsToDevice,[esi].hMemDC,0,0,[esi].x,[esi].y,0,0,eax,1,edi,@lslp,DIB_RGB_COLORS
			add edi,@dwksize
			inc ebx
		.endw
error:
		invoke GlobalFree,@lpys
		invoke BitBlt,[esi].hScrDC,0,0,[esi].x,[esi].y,[esi].hMemDC,[esi].nrightPos,[esi].ndownPos,SRCCOPY
	.endif
	assume esi:nothing
	ret
DesktopView endp

CameraView proc uses ebx esi edi uParam,wParam,lParam
	LOCAL @lsls,@dwys,@lpys:dword
	LOCAL @rect:RECT
	m2m @lsls,wParam
	mov esi,lParam
	assume esi:ptr OVERLAPPEDPLUS
	.if @lsls>10
		mov edi,uParam
		m2m @dwys,dword ptr[edi]
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,@dwys
		mov @lpys,eax
		add edi,4
		sub @lsls,4
		push @dwys
		push @lpys
		push @lsls
		push edi
		push @f
		jmp lzunpack
		@@:
		.if eax!=@dwys
			jmp error
		.endif
		push DDF_SAME_HDC
		push [esi].y
		push [esi].x
		push 0
		push 0
		push @lpys
		push [esi].lpbmpinfo
		push [esi].y
		push [esi].x
		push 0
		push 0
		push [esi].hMemDC
		push [esi].hDrwDC
		call lpDrawDibDraw
error:
		invoke GlobalFree,@lpys
		invoke GetClientRect,[esi].hform,addr @rect
		invoke StretchBlt,[esi].hScrDC,0,0,@rect.right,@rect.bottom,[esi].hMemDC,0,0,[esi].x,[esi].y,SRCCOPY
	.endif	
	assume esi:nothing
	ret
CameraView endp

PlayDataCallBack proc uses ebx esi edi hwi,uMsg,dwInstance,dwParam1,dwParam2   
	mov eax,uMsg
	.if eax==WOM_DONE
	    mov esi,dwInstance
	    mov edi,dwParam1
	    assume esi:ptr OVERLAPPEDPLUS,edi:ptr WAVEHDR
	    .if [esi].hBitmap
	    	ret
	    .endif
	    mov ebx,[edi].lpData
		invoke waveOutUnprepareHeader,[esi].hWaveOut,dwParam1,sizeof WAVEHDR
		invoke GlobalFree,ebx
	    assume esi:nothing,edi:nothing
	.elseif eax==WOM_CLOSE
	    mov esi,dwInstance
	    assume esi:ptr OVERLAPPEDPLUS
		invoke waveOutUnprepareHeader,[esi].hWaveOut,dwParam1,sizeof WAVEHDR
	    assume esi:nothing
	.endif
	ret
PlayDataCallBack endp

InitPlay proc uses ebx esi edi lpesi
	LOCAL	@waveform:WAVEFORMATEX
	mov esi,lpesi
	assume esi:ptr OVERLAPPEDPLUS
	mov @waveform.wFormatTag,WAVE_FORMAT_PCM
	mov @waveform.nChannels,1
	mov @waveform.nSamplesPerSec,11025
	mov @waveform.nAvgBytesPerSec,11025
	mov @waveform.nBlockAlign,1
	mov @waveform.wBitsPerSample,8
	mov @waveform.cbSize,0
	invoke waveOutOpen,addr [esi].hWaveOut,WAVE_MAPPER,addr @waveform,addr PlayDataCallBack,esi,CALLBACK_FUNCTION
	mov [esi].hBitmap,0
	assume esi:nothing
	ret
InitPlay endp

StartPlay proc uses ebx esi edi wParam,lpesi
	mov esi,lpesi
	assume esi:ptr OVERLAPPEDPLUS
	invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,sizeof WAVEHDR
	mov [esi].lpWavehdOut,eax
	mov edi,eax
	assume edi:ptr WAVEHDR
	m2m [edi].lpData,wParam
	mov [edi].dwBufferLength,16384
	mov [edi].dwBytesRecorded,0
	mov [edi].dwUser,0
	mov [edi].dwFlags,WHDR_BEGINLOOP AND WHDR_PREPARED
	mov [edi].dwLoops,1
	mov [edi].lpNext,0
	mov [edi].Reserved,0
	invoke waveOutPrepareHeader,[esi].hWaveOut,[esi].lpWavehdOut,sizeof WAVEHDR
	invoke waveOutWrite,[esi].hWaveOut,[esi].lpWavehdOut,sizeof WAVEHDR
	assume edi:nothing
	assume esi:nothing
	ret
StartPlay endp

ProcDlgDesktop	proc uses ebx esi edi hWnd,wMsg,wParam,lParam
LOCAL	@stPos:POINT 
LOCAL	@stps:PAINTSTRUCT
LOCAL	@xy:POINT
LOCAL	lpBitmapBits,lpBitmapInfo,@iVertPos,@lsls,@key:dword
LOCAL	rect:RECT
LOCAL	@scrinfo:SCROLLINFO
        mov eax,wMsg
		.if eax==WM_CLOSE
			invoke GetWindowLong,hWnd,GWL_USERDATA
			mov esi,eax
			assume esi:ptr OVERLAPPEDPLUS
			.if [esi].other==2
				invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,2
				invoke WSASends,[esi].hsocket,eax,2,SOCKETTAG.desktopclose
			.elseif [esi].other==3
				invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,2
				invoke WSASends,[esi].hsocket,eax,2,SOCKETTAG.cameraclose
			.elseif [esi].other==4
				invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,2
				invoke WSASends,[esi].hsocket,eax,2,SOCKETTAG.recclose
			.endif
			mov [esi].otherfree,1
			invoke PostQueuedCompletionStatus,hiocp,0,0,esi
			assume esi:nothing
			invoke EndDialog,hWnd,NULL
		.elseif	eax == WM_INITDIALOG
			invoke LoadIcon,hInstance,ICO_MAIN
			invoke SendMessage,hWnd,WM_SETICON,ICON_BIG,eax
		.elseif eax==WM_PAINT
			invoke BeginPaint,hWnd,addr @stps
			invoke GetWindowLong,hWnd,GWL_USERDATA
			mov esi,eax
			assume esi:ptr  OVERLAPPEDPLUS
			.if [esi].other==2
				invoke BitBlt,[esi].hScrDC,0,0,[esi].x,[esi].y,[esi].hMemDC,[esi].nrightPos,[esi].ndownPos,SRCCOPY
			.elseif [esi].other==3
				invoke GetClientRect,[esi].hform,addr rect
				invoke StretchBlt,[esi].hScrDC,0,0,rect.right,rect.bottom,[esi].hMemDC,0,0,[esi].x,[esi].y,SRCCOPY
			.endif
			assume esi:nothing
			invoke EndPaint,hWnd,addr @stps
		.elseif eax==WM_COMMAND
			mov eax,wParam
			.if ax==IDM_KONGZHI
				invoke GetWindowLong,hWnd,GWL_USERDATA
				mov esi,eax
				assume esi:ptr OVERLAPPEDPLUS
				mov [esi].dwkongzhi,1
				assume esi:nothing	
			.endif
		.elseif eax==WM_MOUSEMOVE
			invoke GetWindowLong,hWnd,GWL_USERDATA
			mov esi,eax
			assume esi:ptr OVERLAPPEDPLUS
			.if [esi].dwkongzhi
				.if wParam==MK_LBUTTON
					mov eax,lParam
					and eax,0FFFFh
					add eax,[esi].nrightPos
					mov @xy.x,eax
					mov eax,lParam
					shr	eax,16
					add eax,[esi].ndownPos
					mov @xy.y,eax
					invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,8
					mov edi,eax
					invoke LYQMoveMemory,edi,addr @xy,8
					invoke WSASends,[esi].hsocket,edi,8,SOCKETTAG.desktopxy
				.endif
			.endif
		.elseif eax==WM_LBUTTONDBLCLK
			invoke GetWindowLong,hWnd,GWL_USERDATA
			mov esi,eax
			assume esi:ptr OVERLAPPEDPLUS
			.if [esi].dwkongzhi
				mov eax,lParam
				and eax,0FFFFh
				add eax,[esi].nrightPos
				mov @xy.x,eax
				mov eax,lParam
				shr	eax,16
				add eax,[esi].ndownPos
				mov @xy.y,eax
				invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,8
				mov edi,eax
				invoke LYQMoveMemory,edi,addr @xy,8
				invoke WSASends,[esi].hsocket,edi,8,SOCKETTAG.desktopldb
			.endif	
			assume esi:nothing	
		.elseif eax==WM_LBUTTONDOWN
			invoke GetWindowLong,hWnd,GWL_USERDATA
			mov esi,eax
			assume esi:ptr OVERLAPPEDPLUS
			.if [esi].dwkongzhi
				mov eax,lParam
				and eax,0FFFFh
				add eax,[esi].nrightPos
				mov @xy.x,eax
				mov eax,lParam
				shr	eax,16
				add eax,[esi].ndownPos
				mov @xy.y,eax
				invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,8
				mov edi,eax
				invoke LYQMoveMemory,edi,addr @xy,8
				invoke WSASends,[esi].hsocket,edi,8,SOCKETTAG.desktopldown
			.endif	
			assume esi:nothing			 
        .elseif eax==WM_RBUTTONDOWN
			invoke GetWindowLong,hWnd,GWL_USERDATA
			mov esi,eax
			assume esi:ptr OVERLAPPEDPLUS
			.if [esi].dwkongzhi==0 && [esi].other==2
				invoke GetCursorPos,addr @stPos
				invoke TrackPopupMenu,hdmenu,TPM_LEFTALIGN,@stPos.x,@stPos.y,NULL,hWnd,NULL
			.endif
			.if [esi].dwkongzhi
				mov eax,lParam
				and eax,0FFFFh
				add eax,[esi].nrightPos
				mov @xy.x,eax
				mov eax,lParam
				shr	eax,16
				add eax,[esi].ndownPos
				mov @xy.y,eax
				invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,8
				mov edi,eax
				invoke LYQMoveMemory,edi,addr @xy,8
				invoke WSASends,[esi].hsocket,edi,8,SOCKETTAG.desktoprdown
			.endif	
			assume esi:nothing	
		.elseif eax==WM_LBUTTONUP
			invoke GetWindowLong,hWnd,GWL_USERDATA
			mov esi,eax
			assume esi:ptr OVERLAPPEDPLUS
			.if [esi].dwkongzhi
				mov eax,lParam
				and eax,0FFFFh
				add eax,[esi].nrightPos
				mov @xy.x,eax
				mov eax,lParam
				shr	eax,16
				add eax,[esi].ndownPos
				mov @xy.y,eax
				invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,8
				mov edi,eax
				invoke LYQMoveMemory,edi,addr @xy,8
				invoke WSASends,[esi].hsocket,edi,8,SOCKETTAG.desktoplup
			.endif	
			assume esi:nothing
		.elseif eax==WM_RBUTTONUP
			invoke GetWindowLong,hWnd,GWL_USERDATA
			mov esi,eax
			assume esi:ptr OVERLAPPEDPLUS
			.if [esi].dwkongzhi
				mov eax,lParam
				and eax,0FFFFh
				add eax,[esi].nrightPos
				mov @xy.x,eax
				mov eax,lParam
				shr	eax,16
				add eax,[esi].ndownPos
				mov @xy.y,eax
				invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,8
				mov edi,eax
				invoke LYQMoveMemory,edi,addr @xy,8
				invoke WSASends,[esi].hsocket,edi,8,SOCKETTAG.desktoprup
			.endif	
			assume esi:nothing
		.elseif eax==WM_KEYDOWN
			invoke GetWindowLong,hWnd,GWL_USERDATA
			mov esi,eax
			assume esi:ptr OVERLAPPEDPLUS
			.if [esi].dwkongzhi
				invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,8
				mov edi,eax
				m2m dword ptr[edi],wParam
				mov eax,lParam
				shl eax,16
				shr eax,24
				mov dword ptr[edi+4],eax
				invoke WSASends,[esi].hsocket,edi,8,SOCKETTAG.desktopkey
			.endif	
			assume esi:nothing
		.elseif eax==WM_SHOWWINDOW
			mov eax,wParam
			.if eax
				invoke GetWindowLong,hWnd,GWL_USERDATA
				mov esi,eax
				assume esi:ptr OVERLAPPEDPLUS
				mov eax,[esi].lpipport
				invoke SetWindowText,hWnd,eax   
				invoke GetClientRect,hWnd,addr rect
				mov eax,[esi].x
				sub eax,rect.right
				mov ebx,[esi].y
				sub ebx,rect.bottom  
				invoke SetScrollRange,hWnd,SB_HORZ,0,eax,TRUE
				invoke SetScrollRange,hWnd,SB_VERT,0,ebx,TRUE
                assume esi:nothing
	        .endif
	    .elseif eax==WM_SIZE
			invoke GetWindowLong,hWnd,GWL_USERDATA
			mov esi,eax
			assume esi:ptr OVERLAPPEDPLUS       
			mov eax,[esi].x
			mov edi,lParam  
			shl edi,16
			shr edi,16
			sub eax,edi
			mov ebx,[esi].y
			mov edi,lParam  
			shr edi,16
			sub ebx,edi 
			invoke SetScrollRange,hWnd,SB_HORZ,0,eax,TRUE
			invoke SetScrollRange,hWnd,SB_VERT,0,ebx,TRUE
            assume esi:nothing
		.elseif	eax ==WM_HSCROLL
			invoke GetWindowLong,hWnd,GWL_USERDATA
			mov esi,eax
			assume esi:ptr OVERLAPPEDPLUS
			mov @scrinfo.cbSize,sizeof SCROLLINFO
			mov @scrinfo.fMask,SIF_ALL
			invoke GetScrollInfo,hWnd,SB_HORZ,addr @scrinfo
			m2m @iVertPos,@scrinfo.nPos
			mov	eax,wParam
			.if ax== SB_LEFT
				m2m @scrinfo.nPos,@scrinfo.nMin
			.elseif ax==SB_RIGHT
				m2m @scrinfo.nPos,@scrinfo.nMax
			.elseif	ax ==SB_LINELEFT
				sub @scrinfo.nPos,20
			.elseif	ax ==SB_LINERIGHT
				add @scrinfo.nPos,20
			.elseif	ax ==SB_PAGELEFT
				sub @scrinfo.nPos,20
			.elseif	ax ==SB_PAGERIGHT
				add @scrinfo.nPos,20
			.endif
			mov @scrinfo.fMask,SIF_POS
			invoke SetScrollInfo,hWnd,SB_HORZ,addr @scrinfo,TRUE
			invoke GetScrollInfo,hWnd,SB_HORZ,addr @scrinfo
			mov eax,@iVertPos
			.if @scrinfo.nPos!=eax
				mov eax,@iVertPos
				sub eax,@scrinfo.nPos
				invoke ScrollWindow,hWnd,eax,0,NULL,NULL
			.endif
			m2m [esi].nrightPos,@scrinfo.nPos
			assume esi:nothing
		.elseif eax== WM_VSCROLL 
			invoke GetWindowLong,hWnd,GWL_USERDATA
			mov esi,eax
			assume esi:ptr OVERLAPPEDPLUS  
			mov @scrinfo.cbSize,sizeof SCROLLINFO
			mov @scrinfo.fMask,SIF_ALL
			invoke GetScrollInfo,hWnd,SB_VERT,addr @scrinfo
			m2m @iVertPos,@scrinfo.nPos
			mov	eax,wParam	
			.if ax==SB_TOP
				m2m @scrinfo.nPos,@scrinfo.nMin
			.elseif ax==SB_BOTTOM
				m2m @scrinfo.nPos,@scrinfo.nMax
			.elseif ax==SB_LINEUP
				sub @scrinfo.nPos,20
			.elseif ax==SB_LINEDOWN
				add @scrinfo.nPos,20
			.elseif ax==SB_PAGEUP
				sub @scrinfo.nPos,20
			.elseif ax==SB_PAGEDOWN	
				add @scrinfo.nPos,20
			.endif
			mov @scrinfo.fMask,SIF_POS
			invoke SetScrollInfo ,hWnd,SB_VERT,addr @scrinfo,TRUE
			invoke GetScrollInfo,hWnd,SB_VERT,addr @scrinfo
			mov eax,@iVertPos
			.if @scrinfo.nPos!=eax
				mov eax,@iVertPos
				sub eax,@scrinfo.nPos
				invoke ScrollWindow,hWnd,0,eax,NULL,NULL
			.endif
			m2m [esi].ndownPos,@scrinfo.nPos
			assume esi:nothing   
        .else
			mov eax,FALSE
			ret	
		.endif	
		mov eax,TRUE
		ret	
ProcDlgDesktop	endp
