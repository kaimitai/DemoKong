.model small
.code

BufferSegment equ 0b000h

org     100h

mov ah,0	; display mode function
mov al,13h  ; 320x200 - 256 color mode
int 10h 	; set video mode
;;;;;;;;;;;;;;;;;;

 call TestBuffer
 call Blit
 
;;;;;;;;;;;;;;;;;;
mov ah,00       ;  Function To Read Character
int 16h
    
mov ax,03h 
int 10h 
	
mov ah,4ch      ; Terminate and return to dos
mov al,00
int 21h
	
ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;	Blits the screen buffer to visible video memory	 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	Blit:
	mov ax, BufferSegment
	mov ds, ax
	
	xor si,si
	
	mov ax, 0a000h
	mov es,ax
	
	xor di,di
	
	mov cx,320*200/2
	rep movsw
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
	
end
