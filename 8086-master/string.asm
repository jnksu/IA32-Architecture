assume cs:code
code segment
	
	start:	mov dh,25
			mov dl,1							;在屏幕第13行第1列输入字符		
			
			call string							;调用字符输入程序
			
			mov ax,4c00h
			int 21h
;------------------------------------------------------------------------------
      string:	push ax							;使用的寄存器入栈
	  
string_start:	mov ah,0
				int 16h							;从键盘缓冲区读取一个字符
			
				cmp al,20h
				jb  no_char						;判断是否是字符
			
				mov ah,0
				call char_stack_show			;字符入栈
			
				mov ah,2
				call char_stack_show			;显现栈中的字符
			
				jmp short string_start			;重新读取栈中的字符
			
  no_char:		cmp ah,0eh
				je  backspace					;对退格键进行处理
			
				cmp ah,1ch
				je  enter_key					;对回车键进行处理
			
				jmp short string_start			;其它键不处理并返回重新读取字符
			
backspace:		mov ah,1
				call char_stack_show			;从字符栈区删除一个字符
			
				mov ah,2
				call char_stack_show			;显示栈中的字符
			
				jmp short string_start			;读取下一次输入
			
enter_key:		mov ah,0
				mov al,0
				call char_stack_show			;向字符栈中写入字符0		
			
				mov ah,2
				call char_stack_show			;显示栈中的字符
				
				call write_cmos					;修改cmos中的时间
				
				pop ax							;使用的寄存器出栈
				ret								;子程序返回
;------------------------------------------------------------------------------
      char_stack_show:	jmp near ptr  char_stack_show_start

		char_table	dw	push_char,pop_char,char_stack_show_l
		char_stack	db 512 dup (0)
	char_stack_top	dw 0
	char_stack_add	dw 09,08,07,04,02,00				;字符栈对应的cmos中的时间单元(bug)	
char_stack_show_start:	push bx
						push es
						push dx
						push di							;使用的寄存器入栈
						
						cmp ah,2
						ja	char_stack_result			;检查是否误输入
						
						mov bl,ah
						add bl,bl
						mov bh,0
						jmp word ptr char_table[bx]		;召唤相应的子程序
;------------------------------------------------------------------------------
		    push_char:	mov bx,word ptr char_stack_top	;bx指向栈顶
						
						mov byte ptr char_stack[bx],al	;向栈中写入一个字符
						
						inc word ptr char_stack_top		;栈顶下移
						
						jmp short char_stack_result		
;------------------------------------------------------------------------------
			 pop_char:	cmp word ptr char_stack_top,0	;检查栈是否为空
						je  char_stack_result		
						
						dec word ptr char_stack_top		;栈顶上移
						
						mov bx,word ptr char_stack_top	;bx指向栈顶
						
						mov al,byte ptr char_stack[bx]	;从栈中读取一个字符
						
						jmp short char_stack_result
;------------------------------------------------------------------------------
	char_stack_show_l:	mov ax,0b800h
						mov es,ax						;es指向显存
						
						mov ah,0
						mov al,160
						
						dec dh
						mul dh
						
						mov di,0
						add di,ax						
						
						dec dl
						add dl,dl
						
						mov dh,0
						add di,dx							;es:di指向相应显存位置
						
						cmp word ptr char_stack_top,0		;检查栈是否为空
						jne char_stack_no_empty
						
	 char_stack_empty:	mov byte ptr es:[di],' '	
						jmp short char_stack_result
						
  char_stack_no_empty:	mov bx,0							;bx指向栈底

   char_stack_show_sc:	mov al,byte ptr char_stack[bx]		
						mov byte ptr es:[di],al
						mov byte ptr es:[di + 1],0ch		;显示红色字符
						mov byte ptr es:[di + 2],' '
						
						inc bx								;bx向栈顶移动
						
						cmp bx,word ptr char_stack_top		
						je  char_stack_result				;bx是否到达栈顶
						
						add di,2							
						
						jmp short char_stack_show_sc
						
    char_stack_result:	pop di
						pop dx
						pop es
						pop bx								;寄存器出栈
						ret 								;子程序返回
code ends
end start