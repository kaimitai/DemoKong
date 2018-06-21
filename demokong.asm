.model small
.code
.386

VideoMemory		equ 0a000h	; segment for visible video memory
BufferSegment	equ 0b000h	; segment for video buffer

org     100h

mov ah,0	; display mode function
mov al,13h  ; 320x200 - 256 color mode
int 10h 	; set video mode
;;;;;;;;;;;;;;;;;;

call TestBuffer2
  
 mov ax,50
 mov bx,50
 
 lol:
 push ax
 push bx
 
 call BlitWrap
 
  mov ah, 0bh
  int 21h
  cmp al, 0
  jne  Terminate
  
 pop bx
 pop ax
 
 inc ax
 ;inc bx
 cmp bx,200
 jne noob
 mov bx,50
 noob:
 cmp ax,320
 jne lol
 mov ax,50
 jmp lol

Terminate:
    
mov ax,03h 
int 10h 
	
mov ah,4ch      ; Terminate and return to dos
mov al,00
int 21h
	
ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;	Blits the screen buffer to visible video memory centered on (ax, bx) ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	BlitWrap:
	; draw upper left quadrant
	push ax
	push bx
	
	mov cx,320
	sub cx,ax	; cx is width
	
	mov dx,200
	sub dx,bx
	mov si,dx	; si is height
	
	xor dx,dx
	
;	call BlitRect

	pop bx
	pop ax
	
	; draw lower right quadrant
	push ax
	push bx
	
	mov cx,ax	; cx is width
	mov si,bx	; si is height
	
	mov dx,320
	sub dx,ax
	
	mov ah,200
	sub ah,bl
	
	xor bx,bx
	xor al,al
	
	call BlitRect
	
	pop bx
	pop ax
	
	; draw upper right quadrant
	push ax
	push bx
	
	mov cx,200
	sub cx,bx
	mov si,cx	; si is height
	
	xor ah,ah	; target y is 0
	
	mov cx,ax	; cx is width
	
	mov dx,320
	sub dx,ax	; target x-value is 320-x-value
	
	mov al,bl
	
	xor bx,bx	; source x-value is 0
	
;	call BlitRect
	
	pop bx
	pop ax
	
	; draw lower left quadrant 
	push ax
	push bx

	mov cx,200
	sub cx,bx
	mov si,cx	; height is 200-y
	
	mov cx,ax	; width is x
	
	mov dl,bl
	
	mov bx,320
	sub bx,ax	; source x is 320-x

	mov ah,dl
	
	xor al,al	; source y is 0
	
	xor dx,dx	; target x is 0

	
	call BlitRect
	
	pop bx
	pop ax
	
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Blits a rectangle from the buffer to video memory	;;
;;														;;
;; bx: source x-value									;;
;; al: source y-value									;;
;; cx: length											;;
;; si: height											;;
;;														;;
;; dx: target x-value									;;
;; ah: target y-value									;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	BlitRect:
				
		cmp si,0
		je BR_Done
		
		BR_NextLine:
			push ax
			push bx
			push cx
			push dx
			push si
			call BlitLine
			pop si
			pop dx
			pop cx
			pop bx
			pop ax
			
			inc al
			inc ah
			
			dec si
			cmp si,0
			jne BR_NextLine
		BR_Done:
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Blits a line from the buffer to video memory
;;
;; bx: source x-value
;; al: source y-value
;; cx: length
;;
;; dx: target x-value
;; ah: target y-value
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	BlitLine:
		mov si,bx
		mov di,dx

		mov bx,ax
		mov bl,bh
		xor bh,bh
		call Mult320
		add di,bx
		
		xor ah,ah
		mov bx,ax
		call Mult320
		add si,bx
		
		mov ax,VideoMemory
		mov es,ax	; es:di points to target location in memory
		
		mov ax,BufferSegment
		mov ds,ax	; ds:si points to source location in memory

		rep movsb	; cx already containts length
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;	Blits the screen buffer to visible video memory	 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	Blit:
		mov ax, BufferSegment
		mov ds, ax
		
		xor si,si
		
		mov ax, VideoMemory
		mov es,ax
		
		xor di,di
		
		mov cx,320*200/2
		rep movsw
	ret
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;	Clears video buffer (sets all black)	 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ClearBuffer:
	
		mov ax,BufferSegment
		mov es,ax		;ES points to the video buffer
		xor di,di		;DI pointer in the video buffer
		
		mov al,0
		mov cx,320*200/2
		rep stosw
	
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;	Test procedure to draw lines to video buffer	 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	TestBuffer2:
		mov ax,BufferSegment
		mov es,ax		;ES points to the video buffer
		xor di,di		;DI pointer in the video buffer
	 
		mov bl,0
	 
		DrawLine2:
			mov cx,320
			mov al,bl
			NPixel2:
			stosb	; fill the line (320 pixels)
			dec cx
			inc al
			inc al
			inc al
			cmp cx,0
			jne NPixel2
			inc bl		; increase the color
			cmp bl,200
		jne DrawLine2
	ret
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; multiply bx by 320 - Get offset to line on screen ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	Mult320:
		push ax
		push bx
		
		shl bx,8
		mov ax,bx	; ax = bx*256

		pop bx
		shl bx,6
		add ax,bx	; ax = ax + bx*64 (=bx*(256+64) = bx*(320))
		
		mov bx,ax	; bx = bx*320
		
		pop ax
	ret

end
