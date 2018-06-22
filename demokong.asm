.model small
.code
.386

VideoMemory		equ 0a000h	; segment for visible video memory
BufferSegment	equ 0b000h	; segment for video buffer
TransparentColor equ 0ffh

org     100h

mov ah,0	; display mode function
mov al,13h  ; 320x200 - 256 color mode
int 10h 	; set video mode
;;;;;;;;;;;;;;;;;;

call TestBuffer
	mov dx,00B0Bh
;call ClearBuffer

	mov dx,100
	mov bx,50
	mov cx,0
	call DrawSprite

	mov dx,107
	mov bx,50
	mov cx,30
	call DrawSprite

	mov dx,114
	mov bx,50
	mov cx,60
	call DrawSprite

call Blit

MainLoop:
 
  mov ah, 0bh
  int 21h
  cmp al, 0
  jne  Terminate
  
jmp MainLoop
  
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
		
		mov ax,dx
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
	 
		xor bx,bx
	 
		DrawLine:
			mov cx,320

			NPixel:

			mov dx,cx
			xor dx,bx
			add dx,bx

			Call Mod256
			
			mov al,dl
			
			stosb	; fill the line (320 pixels)
			dec cx
			
			cmp cx,0
			jne NPixel
			inc bl		; increase the color
			cmp bl,200
		jne DrawLine
	ret

;;;;;;;;;;;;;;;;;;;;;
;; return dx % 256 ;;
;;;;;;;;;;;;;;;;;;;;;
	Mod256:
	push cx
	
	mov cx,dx
	shr dx,8	; div by 256, discarding remainder
	shl dx,8	; mul by 256
	
	sub cx,dx
	mov dx,cx	; bx = bx - 256*(bx/256)
	
	pop cx
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

; DRAW SPRITE TEST FUNCTION
;	x: dx
;	y: bx
;	sprite start address: cx
	DrawSprite:

	call Mult320
	
	mov di,bx
	add di,dx
	
	mov ax,BufferSegment
	mov es,ax
	
	mov ax,@data
	mov ds,ax
	mov si,OFFSET K
	add si,cx
	
	mov dl,5
	mov dh,6
	
	SpriteRow:
	lodsb
	cmp al,TransparentColor
	je DrawSpriteSkipPixel
	stosb
	jmp DrawSpriteIncedDi
		DrawSpriteSkipPixel:
		inc di
	DrawSpriteIncedDi:
	dec dl
	cmp dl,0
	jne SpriteRow
	mov dl,5
	dec dh
	cmp dh,0
	je SpriteEnd
	add di,315
	jmp SpriteRow
	
	SpriteEnd:
	
	ret

.data


K		db 01,01,0ffh,0ffh,01
		db 01,01,0ffh,01,0ffh
		db 01,01,01,0ffh,0ffh
		db 01,01,01,0ffh,0ffh
		db 01,01,0ffh,01,0ffh
		db 01,01,0ffh,0ffh,01
A		db 0ffh,04,04,04,0ffh
		db 04,04,0ffh,04,4
		db 04,04,04,04,4
		db 03,03,0ffh,03,3
		db 04,04,0ffh,04,4
		db 04,04,0ffh,04,4
I		db 01,02,03,04,05
		db 0ffh,01,02,03,0ffh
		db 0ffh,0ffh,02,0ffh,0ffh
		db 0ffh,0ffh,02,0ffh,0ffh
		db 0ffh,01,02,03,0ffh
		db 01,02,03,04,05
		
FontM	db 00001110b,	; A
		db 00010110b,
		db 00100110b,
		db 01100110b,
		db 01100110b,
		db 01111110b,
		db 01100110b,
		db 00000000b,

		db 01111110b,	; B
		db 01100110b,
		db 01100110b,
		db 01111100b,
		db 01100110b,
		db 01100110b,
		db 01111110b,
		db 00000000b,
		
		db 00011100b,	; C
		db 00100110b,
		db 01100110b,
		db 01100000b,
		db 01100110b,
		db 01100100b,
		db 00111000b,
		db 00000000b,
		
		db 01111100b,	; D
		db 01100110b,
		db 01100110b,
		db 01100110b,
		db 01100110b,
		db 01100100b,
		db 01111000b,
		db 00000000b,
		
		db 00011100b,	; E
		db 00100110b,
		db 01100000b,
		db 01111000b,
		db 01100000b,
		db 01100100b,
		db 00111000b,
		db 00000000b,
		
		db 01111110b,	; F
		db 01100110b,
		db 01100000b,
		db 01100000b,
		db 01100000b,
		db 01100000b,
		db 01100000b,
		db 00000000b,
		
		db 00011100b,	; G
		db 00100110b,
		db 01100000b,
		db 01100110b,
		db 01100110b,
		db 01100100b,
		db 00111000b,
		db 00000000b,
		
		db 01100110b,	; H
		db 01100110b,
		db 01100110b,
		db 01111110b,
		db 01100110b,
		db 01100110b,
		db 01100110b,
		db 00000000b,
		
		db 00111100b,	; I
		db 00011000b,
		db 00011000b,
		db 00011000b,
		db 00011000b,
		db 00011000b,
		db 00111100b,
		db 00000000b,
		
		db 00001110b,	; J
		db 00000110b,
		db 00000110b,
		db 00000110b,
		db 00000110b,
		db 01100100b,
		db 00111000b,
		db 00000000b,
		
		db 01100110b,	; K
		db 01100110b,
		db 01101100b,
		db 01111000b,
		db 01101100b,
		db 01100110b,
		db 01100110b,
		db 00000000b,

		db 01100000b,	; L
		db 01100000b,
		db 01100000b,
		db 01100000b,
		db 01100000b,
		db 01100110b,
		db 01111110b,
		db 00000000b,

		db 00010100b,	; M
		db 00101010b,
		db 01101011b,
		db 01101011b,
		db 01101011b,
		db 01101011b,
		db 01101011b,
		db 00000000b,
		
		db 01100110b,	;N
		db 01100110b,
		db 01110110b,
		db 01101110b,
		db 01100110b,
		db 01100110b,
		db 01100110b,
		db 00000000b,
		
		db 00011000b,	; O
		db 00100100b,
		db 01100110b,
		db 01100110b,
		db 01100110b,
		db 00100100b,
		db 00011000b,
		db 00000000b,
		
		db 00111100b,	; P
		db 01100110b,
		db 01100110b,
		db 01100110b,
		db 01111100b,
		db 01100000b,
		db 01100000b,
		db 00000000b,
		
		db ,	; Q
		db ,
		db ,
		db ,
		db ,
		db ,
		db ,
		db ,
end