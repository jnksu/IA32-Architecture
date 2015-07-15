assume cs:code
code segment
	
	start:	mov dh,25
			mov dl,1							;����Ļ��13�е�1�������ַ�		
			
			call string							;�����ַ��������
			
			mov ax,4c00h
			int 21h
;------------------------------------------------------------------------------
      string:	push ax							;ʹ�õļĴ�����ջ
	  
string_start:	mov ah,0
				int 16h							;�Ӽ��̻�������ȡһ���ַ�
			
				cmp al,20h
				jb  no_char						;�ж��Ƿ����ַ�
			
				mov ah,0
				call char_stack_show			;�ַ���ջ
			
				mov ah,2
				call char_stack_show			;����ջ�е��ַ�
			
				jmp short string_start			;���¶�ȡջ�е��ַ�
			
  no_char:		cmp ah,0eh
				je  backspace					;���˸�����д���
			
				cmp ah,1ch
				je  enter_key					;�Իس������д���
			
				jmp short string_start			;�������������������¶�ȡ�ַ�
			
backspace:		mov ah,1
				call char_stack_show			;���ַ�ջ��ɾ��һ���ַ�
			
				mov ah,2
				call char_stack_show			;��ʾջ�е��ַ�
			
				jmp short string_start			;��ȡ��һ������
			
enter_key:		mov ah,0
				mov al,0
				call char_stack_show			;���ַ�ջ��д���ַ�0		
			
				mov ah,2
				call char_stack_show			;��ʾջ�е��ַ�
				
				call write_cmos					;�޸�cmos�е�ʱ��
				
				pop ax							;ʹ�õļĴ�����ջ
				ret								;�ӳ��򷵻�
;------------------------------------------------------------------------------
      char_stack_show:	jmp near ptr  char_stack_show_start

		char_table	dw	push_char,pop_char,char_stack_show_l
		char_stack	db 512 dup (0)
	char_stack_top	dw 0
	char_stack_add	dw 09,08,07,04,02,00				;�ַ�ջ��Ӧ��cmos�е�ʱ�䵥Ԫ(bug)	
char_stack_show_start:	push bx
						push es
						push dx
						push di							;ʹ�õļĴ�����ջ
						
						cmp ah,2
						ja	char_stack_result			;����Ƿ�������
						
						mov bl,ah
						add bl,bl
						mov bh,0
						jmp word ptr char_table[bx]		;�ٻ���Ӧ���ӳ���
;------------------------------------------------------------------------------
		    push_char:	mov bx,word ptr char_stack_top	;bxָ��ջ��
						
						mov byte ptr char_stack[bx],al	;��ջ��д��һ���ַ�
						
						inc word ptr char_stack_top		;ջ������
						
						jmp short char_stack_result		
;------------------------------------------------------------------------------
			 pop_char:	cmp word ptr char_stack_top,0	;���ջ�Ƿ�Ϊ��
						je  char_stack_result		
						
						dec word ptr char_stack_top		;ջ������
						
						mov bx,word ptr char_stack_top	;bxָ��ջ��
						
						mov al,byte ptr char_stack[bx]	;��ջ�ж�ȡһ���ַ�
						
						jmp short char_stack_result
;------------------------------------------------------------------------------
	char_stack_show_l:	mov ax,0b800h
						mov es,ax						;esָ���Դ�
						
						mov ah,0
						mov al,160
						
						dec dh
						mul dh
						
						mov di,0
						add di,ax						
						
						dec dl
						add dl,dl
						
						mov dh,0
						add di,dx							;es:diָ����Ӧ�Դ�λ��
						
						cmp word ptr char_stack_top,0		;���ջ�Ƿ�Ϊ��
						jne char_stack_no_empty
						
	 char_stack_empty:	mov byte ptr es:[di],' '	
						jmp short char_stack_result
						
  char_stack_no_empty:	mov bx,0							;bxָ��ջ��

   char_stack_show_sc:	mov al,byte ptr char_stack[bx]		
						mov byte ptr es:[di],al
						mov byte ptr es:[di + 1],0ch		;��ʾ��ɫ�ַ�
						mov byte ptr es:[di + 2],' '
						
						inc bx								;bx��ջ���ƶ�
						
						cmp bx,word ptr char_stack_top		
						je  char_stack_result				;bx�Ƿ񵽴�ջ��
						
						add di,2							
						
						jmp short char_stack_show_sc
						
    char_stack_result:	pop di
						pop dx
						pop es
						pop bx								;�Ĵ�����ջ
						ret 								;�ӳ��򷵻�
code ends
end start