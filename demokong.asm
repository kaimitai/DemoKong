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

 call ClearBuffer
 call TestBuffer
 
 mov bx,0
 mov al,5
 
 mov dx,0
 mov ah,5

 mov cx,120
 
 call BlitLine
 
 
;;;;;;;;;;;;;;;;;;
mov ah,00       ;  Function To Read Character
int 16h
    
mov ax,03h 
int 10h 
	
mov ah,4ch      ; Terminate and return to dos
mov al,00
int 21h
	
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
		mov ds, ax	; ds:si points to source location in memory

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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;	Blits the screen buffer to visible video memory, offset at (bx, dx) - wrapping aroud	 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	BlitWrap:
	; Blit top left quadrant of screen
	
	mov ax, VideoMemory
	mov es,ax
	
	xor di,di	; es:di points to top left video memory
	
		
	push bx
	call Mult320	; bx now points to the offset to its line in video mem

	mov ax,BufferSegment
	mov ds, ax

	add bx,dx
	mov si,bx		; ds:si now points to the given first loc of the buffer
	
	mov bx,50
	
	mov ax,320
	sub ax,dx		; ax holds the number of pixels to draw (320 minus x-offset)
	;sub dx,ax		; dx holds the number of pixels to skip
	
	BW_Q1_Draw:
		mov cx,ax
	
		rep movsb
		
		add si,dx
		add di,dx
		dec bx
		cmp bx,0
		jne BW_Q1_Draw

	pop bx

	ret
	
	; End blit top left quadrant

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
	TestBuffer:
	mov ax,BufferSegment
	mov es,ax		;ES points to the video buffer
	xor di,di		;DI pointer in the video buffer
 
	mov bl,0
 
	DrawLine:
		mov cx,320
		mov al,bl
		rep stosb	; fill the line (320 pixels)
		inc bl		; increase the color
		cmp bl,200
	jne DrawLine
	ret
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; mult bx by 320 - Get offset to line on screen ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	Mult320:
	push ax
	push bx
	
	shl bx,7
	mov ax,bx	; ax = bx*256

	pop bx
	shl bx,4
	add ax,bx	; ax = ax + bx*64 (=bx*(256+64) = bx*(320))
	
	mov bx,ax	; bx = bx*320
	
	pop ax
	ret

end
