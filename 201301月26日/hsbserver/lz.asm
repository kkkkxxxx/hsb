; must be a power of 2 (between 8k and 2mb appear reasonable)
BLZ_WORKMEM_SIZE	EQU	1024*1024

.code

putbit0M MACRO
LOCAL bitsleft,done
	test ebp,ebp
	jnz bitsleft
	mov edx,edi
	inc ebp
	add edi,2
bitsleft:
	add bp,bp
	jnc done
	mov word ptr[edx],bp
	xor ebp,ebp
done:
ENDM putbit0M

putbit1M MACRO
LOCAL bitsleft,done
	test ebp,ebp
	jnz bitsleft
	mov edx,edi
	inc ebp
	add edi,2
bitsleft:
	add bp,bp
	inc bp
	jnc done
	mov word ptr[edx],bp
	xor ebp,ebp
done:
ENDM putbit1M

putbitM MACRO
	LOCAL onebit,bitdone
	jc onebit
	putbit0M
	jmp bitdone
onebit:
	putbit1M
bitdone:
ENDM putbitM

putgammaM MACRO
	 LOCAL revmore,outmore,outstart
	 push ebx
	 push eax
	 shr eax,1
	 mov ebx,1
revmore:
	 shr eax,1
	 jz outstart
	 adc ebx,ebx
	 jmp revmore
outmore:
	 putbitM
	 putbit1M
outstart:
	 shr ebx,1
	 jnz outmore
	 pop eax
	 shr eax,1
	 putbitM
	 putbit0M
	 pop ebx
ENDM putgammaM

hash4M MACRO
	 push ecx
	 movzx eax,byte ptr[esi]
	 imul eax,317
	 movzx ecx,byte ptr[esi+1]
	 add eax,ecx
	 imul eax,317
	 movzx ecx,byte ptr[esi+2]
	 add eax,ecx
	 imul eax,317
	 movzx ecx,byte ptr[esi+3]
	 add eax,ecx
	 and eax,(BLZ_WORKMEM_SIZE/4)-1
	 pop ecx
ENDM hash4M

lzgetsize proc lparam
	mov eax,lparam
	mov edx,eax
	shr edx,3
	lea eax,[eax+edx+64]
	ret
lzgetsize endp

lzpack:
	_lens	equ 40
	_lpdst	equ 36
	_lpscr  equ 32
	_lim	equ 24
	_bpt	equ 20
	_lptmp	equ 16
	sub esp,12
	push ebx
	push esi
	push edi
	push ebp
	cld
	invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,BLZ_WORKMEM_SIZE
	mov [esp+_lptmp],eax
	mov esi,[esp+_lpscr]
	mov edi,[esp+_lpdst]
	mov ebx,[esp+_lens]
	lea eax,[ebx+esi-4]
	mov [esp+_lim],eax
	mov [esp+_bpt],esi
	test ebx,ebx
	jz  EODdone
	mov al,byte ptr[esi]
	inc esi
	mov byte ptr[edi],al
	inc edi
	cmp ebx,1
	je  EODdone
	mov bp,1
	mov edx,edi
	add edi,2
	jmp nexttagcheck
no_match:
	putbit0M
	mov al,byte ptr[esi]
	inc esi
	mov byte ptr[edi],al
	inc edi
nexttagcheck:
	cmp esi,[esp+_lim]
	jae donepacking
nexttag:
	mov ecx,[esp+_lptmp]
	mov ebx,esi
	mov esi,[esp+_bpt]
	sub ebx,esi
update:
	hash4M
	mov [ecx+eax*4],esi
	inc esi
	dec ebx
	jnz update
	mov [esp+_bpt],esi
	hash4M
	mov ebx,[ecx+eax*4]
	test ebx,ebx
	jz  no_match
	mov ecx,[esp+_lim]
	sub ecx,esi
	add ecx,4
	push edx
	xor eax,eax
compare:
	mov dl,byte ptr[ebx+eax]
	cmp dl,byte ptr[esi+eax]
	jne matchlen_found
	inc eax
	dec ecx
	jnz compare
matchlen_found:
	pop edx
	cmp eax,4
	jb  no_match
	mov ecx,esi
	sub ecx,ebx
	putbit1M
	add esi,eax
	sub eax,2
	putgammaM
	dec ecx
	mov eax,ecx
	shr eax,8
	add eax,2
	putgammaM
	mov byte ptr[edi],cl
	inc edi
	cmp esi,[esp+_lim]
	jb  nexttag
donepacking:
	mov ebx,[esp+_lim]
	add ebx,4
	jmp check_final_literals
final_literals:
	putbit0M
	mov al,byte ptr[esi]
	inc esi
	mov byte ptr[edi],al
	inc edi
check_final_literals:
	cmp esi,ebx
	jb  final_literals
	test ebp,ebp
	jz  EODdone
doEOD:
	add bp,bp
	jnc doEOD
	mov word ptr[edx],bp
EODdone:
	invoke GlobalFree,[esp+_lptmp]
	mov eax,edi
	sub eax,[esp+_lpdst]
	pop ebp
	pop edi
	pop esi
	pop ebx
	add esp,12
	retn 12

getbitM MACRO
	LOCAL stillbitsleft
	add dx,dx
	jnz stillbitsleft
	sub ebp,2
	jc return_error
	mov dx,word ptr[esi]
	add esi,2
	add dx,dx
	inc dx
stillbitsleft:
ENDM getbitM

domatchM MACRO reg
	push ecx
	mov ecx,[esp+4+_ddlen]
	sub ecx,ebx
	cmp reg,ecx
	pop ecx
	ja return_error
	sub ebx,ecx
	jc return_error
	push esi
	mov esi,edi
	sub esi,reg
	rep movsb
	pop esi
ENDM domatchM

getgammaM MACRO reg
	LOCAL getmore
	mov reg,1
getmore:
	getbitM
	adc reg,reg
	jc return_error
	getbitM
	jc getmore
ENDM getgammaM

lzunpack:
	_ddlen	equ 32
	_dlpdst	equ 28
	_dslen	equ 24
	_dlpscr equ 20
	push ebx
	push esi
	push edi
	push ebp
	mov esi,[esp+_dlpscr]
	mov ebp,[esp+_dslen]
	mov edi,[esp+_dlpdst]
	mov ebx,[esp+_ddlen]
	cld
	mov dx,8000h
literal:
	sub ebp,1
	jc return_error
	mov al,byte ptr[esi]
	inc esi
	sub ebx,1
	jc return_error
	mov byte ptr[edi],al
	inc edi
	test ebx,ebx
	jz donedepacking
nexttagd:
	getbitM
	jnc literal
	getgammaM ecx
	getgammaM eax
	add ecx,2
	shl eax,8
	sub ebp,1
	jc return_error
	mov al,byte ptr[esi]
	inc esi
	add eax,0fffffe01h
	domatchM eax
	test ebx,ebx
	jnz nexttagd
donedepacking:
	mov eax,edi
	sub eax,[esp+_dlpdst]
	jmp return_eax
return_error:
	or eax,-1
return_eax:
	pop ebp
	pop edi
	pop esi
	pop ebx
	retn 16