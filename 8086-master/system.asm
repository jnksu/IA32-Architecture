;------------------------------------------------------------------------------
;    ������: system
;����Դ�ļ�: system
;  ������: ���������������,��ʾcmos�е�ʱ��,�������������,�޸�cmos�е�ʱ��		
;      ˵��: ���ڸó�����Ҫ���������еĲ���ϵͳ��,�����ڲ���ϵͳ�Ļ���������
;�������,���г���,������д������׼��������������,�����ô��������������.
;------------------------------------------------------------------------------
assume cs:code
code segment
;------------------------------------------------------------------------------
;								��������װ����
;------------------------------------------------------------------------------
	start:	mov ax,code
			mov es,ax
			mov bx,offset sys						;es:bxָ��д�뵽���������������ַ
			
			mov ch,0								;�ŵ���
			mov cl,1								;������
			mov dh,0								;���
			mov dl,0								;��������
			mov al,18								;д���������
			mov ah,3								;д����
			
			int 13h									;�����ж�д����
			
			mov ax,4c00h
			int 21h
			
			org 7c00h								;���´���ӵ�һ������ʼ
;------------------------------------------------------------------------------
;								�����ַ���ʾ����
;------------------------------------------------------------------------------
	  sys:	jmp near ptr system						;��ת�����������һ��ָ�
			
		t:	db '1) reset pc',0
	   t1:	db '2) start system',0
	   t2:	db '3) clock',0
	   t3:	db '4) set clock',0
	   t4:	db 'Tips: in select 3) ,F1 to change the clock background,press Esc to reback!',0
	   t5:	db 'Tips: in select 4) ,you can change the time by keyboard',0
	   t6:	db 'Tips: press F1 to change the clock background,press Esc to reback!',0
	   t7:  db 'Tips: please input the time in next line the format is ''YY MM DD HH mm ss''',0
	   t8:	db ':',0
	   t9:	db 'Tips: press Esc to reback!',0
	  t10:	db 'Tips: press Enter change time!',0	
	t_end	dw t,0 * 160,t1,1 * 160,t2,2 * 160,t3,3 * 160,t4,23 * 160,t5,24 * 160,t6,0 * 160,t7,23 * 160,t8,24 * 160,t9,21 * 160,t10,22 * 160
;------------------------------------------------------------------------------
;								�����ڴ���س���
;------------------------------------------------------------------------------
  system:	mov ax,0
			mov es,ax
			mov cl,2									;������
			mov bx,7e00h								;es:bxָ��ڶ���������Ӧ�ĵڶ����ڴ���	
   
    read:	mov ch,0									;�ŵ���
			mov dh,0									;���
			mov dl,0									;��������
			
			mov ah,2									;������
			mov al,1									;��ȡ��������
			
			int 13h										;������0��0��2������ǰ17�����������ݶ�ȡ��0:7e00h��
			
			add bx,512									
			inc cl										;ָ����һ������			
			
			cmp cl,19
			je  read_ok									;����0�ŵ���17�������Ƿ�ȫ��д���ڴ��� 
			
			jmp short read								;����һ������д�����ݵ��ڴ���ȥ

 read_ok:	mov bx,0									;t_end[bx]ָ���ַ��εĵ�һ���ַ���
			mov cx,6									;��ȡ�����ַ���
			
			call show_char_sc							;��ʾ���˵�
			
			jmp near ptr select							;�����û�������
			
			org 7e00h									;���´���ӵڶ�������ʼ
;------------------------------------------------------------------------------
;								�����ַ���ʾ�ӳ���
;------------------------------------------------------------------------------
show_char_sc:	push ax
				push es
				push ds
				push si
				push di									;�Ĵ�����ջ
				
				
				mov ax,0b800h
				mov es,ax								;esָ���Դ��
			
				mov ax,0
				mov ds,ax								;dsָ�����ݶ�
				
			
		show:	mov si,word ptr t_end[bx]				;ds:siָ�����ݶ�
				mov di,word ptr t_end[bx + 2]			;es:diָ���Դ�
			
				push cx									;ѭ��������ջ
			
		char:	mov al,byte ptr ds:[si]					;�����ݶ�ȡ��һ���ַ�
			
				cmp al,0								
				je ok									;����Ƿ��ַ���ĩ��
			
				mov byte ptr es:[di],al					
				mov byte ptr es:[di + 1],0ch			;���ַ�д���Դ�
			
				inc si									;ָ����һ���ַ�
				add di,2								;ָ����һ���Դ���
		
			jmp short char								;��һ��ѭ��
			
	      ok:	pop cx									
				
				add bx,4								
		
			loop show									;ָ����һ���ַ���
			
				pop di
				pop si
				pop ds
				pop es
				pop ax									;�Ĵ�����ջ
			ret											;�ӳ��򷵻�
;------------------------------------------------------------------------------
;								���������жϴ������
;------------------------------------------------------------------------------
		  select:	mov ah,0
					int 16h									;����int16h�ж϶�ȡһ��������ַ�
		
					cmp al,'1'
					je 	reset_pc_l							;���������
  			
					cmp al,'2'
					je  start_system_l						;��ʼ���������Ĳ���ϵͳ
							
					cmp al,'3'
					je  clock_l								;�鿴��ǰʱ��
				
					cmp al,'4'
					je  set_clock_l							;���õ�ǰʱ��
 
					jmp near ptr jump						;������ת��ַ��
					
      reset_pc_l:	jmp near ptr reset_pc					;��ֹ�ӳ���ռ���ڴ�ռ�����ʹje�޷������ת
  start_system_l:	jmp near ptr start_system				;��ֹ�ӳ���ռ���ڴ�ռ�����ʹje�޷������ת	
         
		 clock_l:	call cls								;����
					mov cx,1								;�����ַ�������
					mov bx,24								;�ַ�����t_end���е�λ��
					call show_char_sc						;��ʾ�ַ�
					jmp near ptr clock						;��ֹ�ӳ���ռ���ڴ�ռ�����ʹje�޷������ת
					
	 set_clock_l:	call  cls								;�ٻ������ӳ���
					mov cx,4
					mov bx,28
					call show_char_sc						;��ʾ�ַ�
					jmp near ptr set_clock					;��ֹ�ӳ���ռ���ڴ�ռ�����ʹje�޷������ת	
			
			jump:	nop
			
					jmp short select						;�ٴζ�ȡ�û�������
;------------------------------------------------------------------------------
;								����ϵͳ��������
;------------------------------------------------------------------------------		
	reset_pc:	mov word ptr ds:[2],0ffffh
				mov word ptr ds:[0],0
				
				jmp dword ptr ds:[0]				;��ת��cpuҪִ�еĵ�һ��ָ�
;------------------------------------------------------------------------------
;								����Ӳ��ϵͳ��������
;------------------------------------------------------------------------------	
start_system:	mov ax,0
				mov es,ax
				mov bx,7c00h						;es:bxָ��0:7c00��
				
				mov ch,0							;Ӳ��0�ŵ�
				mov cl,1							;Ӳ��1����
				mov dh,0							;Ӳ��0��ͷ
				mov dl,80h							;Ӳ��C������
				
				mov al,1							;��ȡһ������
				mov ah,2											
				
				int 13h								;�����ж϶�����
				
				mov word ptr ds:[2],0
				mov word ptr ds:[0],7c00h
				
				jmp dword ptr ds:[0]				;��ת��cpuҪִ�еĵ�һ��ָ�
;------------------------------------------------------------------------------
;								����ʱ��int9�жϳ���
;------------------------------------------------------------------------------										
       clock:	mov ax,cs
				mov ds,ax
				mov si,offset int9							;ds:siָ��Դ��ַ
			
				mov ax,0
				mov es,ax
				mov di,0204h								;es:diָ��Ŀ���ַ
			
				mov cx,offset int9_end - offset int9		;���Ƶ��ֽ���
				cld
				rep movsb
								
				push word ptr es:[9 * 4]
				push word ptr es:[9 * 4 + 2]				;��ԭ�жϵ�ַ��ջ
			
				pop word ptr es:[0202h]
				pop word ptr es:[0200h]						;����ԭ�жϵ�ַ
			
				cli
				mov word ptr es:[9 * 4],0204h
				mov word ptr es:[9 * 4 + 2],0				;�޸��ж�������
				sti
				
				jmp near ptr clock_start					;��ת������ʱ����ʾ����	
				
;-----------------------------------------------------------------------	 
		int9:	push ax
				push ds
				push es
				push di
				push cx										;ʹ�õļĴ�����ջ
			
			
				pushf										;��־�Ĵ�����ջ
			
				mov ax,0
				mov ds,ax
			
				call dword ptr ds:[0200h]					;����ԭ�жϳ���
			
				in al,60h									;��ȡɨ���뵽al�Ĵ���
				
				cmp al,3bh
				je color_l									;�ı���ɫ
			
				cmp al,01
				je return_l									;����
			
				jmp near ptr jump_int9						;�����ı���ɫ���ӳ���
  
	 color_l:	mov ax,0b800h
				mov es,ax
				mov di,12 * 160 + 31 * 2 + 1				;es:diָ���Դ�
				mov cx,17									;�޸���ʾ17���ַ�������						
			
	   color:	inc	byte ptr es:[di]
				add di,2
		loop color											;�ı���ɫ

   jump_int9:	jmp near ptr jump_int9_						;�����������˵����ӳ���
	
    return_l:	push word ptr ds:[0202h]
				push word ptr ds:[0200h]
			
				cli
				pop word ptr ds:[9 * 4]
				pop word ptr ds:[9 * 4 + 2]
				sti											;�ָ�ԭ����int9�ж�
				
				pop	cx
				pop di
				pop	es
				pop ds
				pop dx										;�Ĵ�����ջ
				
				pop word ptr ds:[0]
				pop word ptr ds:[2]							;��ջ�д�ŵĵ�ַ��ջ����ǰ�����ݶ���
				
				popf										;��־�Ĵ�����ջ
				
				mov word ptr ds:[0],offset sys_f			;�޸�iretָ�����غ�ĵ�һ��ָ���ƫ�Ƶ�ַ
		 
				jmp dword ptr ds:[0]						;ģ��iretָ��
		 
	   sys_f:	call cls									;�жϹ���Ҫ�ٻ���������
				
				jmp near ptr sys							;�������˵�
				
  jump_int9_:	pop cx
				pop di
				pop es
				pop ds
				pop ax
			iret											;�жϷ���
			
    int9_end:	nop	
	
;------------------------------------------------------------------------------
;								����ʱ����ʾ����
;------------------------------------------------------------------------------	   
				
				time db '00/00/00 00:00:00' 	;��/��/�� ʱ:��:��	
				
 clock_start:	mov si,0						;time:siָ�����ݶ�
			
				mov ax,0b800h
				mov es,ax
				mov di,12 * 160 + 31 * 2		;es:diָ���Դ��
			
				mov bl,9						
				mov cx,3						
			

  clock_show:	mov al,bl						
			
				out 70h,al						;��ȡcmos��9�ŵ�Ԫ
				in  al,71h						;��ȡһ���ֽڵ�al�Ĵ�����
			
				mov ah,al						
			
				shr ah,1
				shr ah,1
				shr ah,1
				shr ah,1						;ah��Ÿ�4λ��BCD��
				and al,00001111b				;����al�еĸ�λBCD��
			
				add ah,30h
				add al,30h						;ת��ΪASCII��
			
				mov byte ptr time[si],ah
				mov byte ptr time[si + 1],al	;д�����ݶ�
			
				add si,3								
				dec bl							;ָ����һ��cmos���ݵ�Ԫ
				
			loop clock_show				
;------------------------------------------------------------------------------
				mov cx,3
				mov bl,4						;��ȡcmos4�ŵ�Ԫ
			
clock_show_:	mov al,bl						
			
				out 70h,al
				in  al,71h						;���ֽڵ�al��
			
				mov ah,al
				shr ah,1
				shr ah,1
				shr ah,1
				shr ah,1						;ah��Ÿ�λBCD��
			
				and al,00001111b				;����al�еĸ�λBCD��
			
				add ah,30h
				add al,30h						;�ַ�ת��				
			
				mov byte ptr time[si],ah			
				mov byte ptr time[si + 1],al	;д�����ݶ�
			
				add si,3
				sub bl,2		
			
			loop clock_show_
;------------------------------------------------------------------------------
			mov si,0
			mov cx,17
			
  screen:	mov bl,byte ptr time[si]				
			mov byte ptr es:[di],bl
			
			inc si
			add di,2
		
		loop screen							;time:siָ��Դ��ַ,es:diָ��Ŀ���ַ
		
			jmp near ptr clock_start		;�ظ���ȡ����
			
;------------------------------------------------------------------------------
;								����ʱ���޸ĳ���
;------------------------------------------------------------------------------
   set_clock:	mov dh,25
				mov dl,2						;����Ļ��25�е�2�������ַ�			
				
				call string						;�����ַ��������
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
			
     no_char:	cmp ah,0eh
				je  backspace					;���˸�����д���
			
				cmp ah,1ch
				je  enter_key					;�Իس������д���
				
				cmp ah,01h
				je  return_string
				
				jmp short string_start			;�������������������¶�ȡ�ַ�
			
   backspace:	mov ah,1
				call char_stack_show			;���ַ�ջ��ɾ��һ���ַ�
			
				mov ah,2
				call char_stack_show			;��ʾջ�е��ַ�
			
				jmp short string_start			;��ȡ��һ������
			
   enter_key:	mov ah,0
				mov al,0
				call char_stack_show			;���ַ�ջ��д���ַ�0		
			
				mov ah,2
				call char_stack_show			;��ʾջ�е��ַ�
				
				call write_cmos					;�޸�cmos�е�ʱ��
				
				call  cls						;�ٻ������ӳ���
				
				pop ax							;ʹ�õļĴ�����ջ
												
				jmp near ptr sys				;�������˵�

return_string:	call cls						;�ٻ������ӳ���
				
				pop ax							;ʹ�õļĴ�����ջ
				
				jmp near ptr sys				;�������˵�
;------------------------------------------------------------------------------
      char_stack_show:	jmp near ptr  char_stack_show_start

		char_table	dw	push_char,pop_char,char_stack_show_l
		char_stack	db 512 dup (0)
	char_stack_top	dw 0
	char_stack_add	db 9,0,0,8,0,0,7,0,0,4,0,0,2,0,0,0,0,0	;�ַ�ջ��Ӧ��cmos�е�ʱ�䵥Ԫ
	
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
						ret 	
;------------------------------------------------------------------------------
;								�޸�cmosʱ��				
;------------------------------------------------------------------------------
  
  write_cmos:	push bx
				push cx
				push ax								;ʹ�õļĴ�����ջ
				
				
				mov bx,0							;bx�������Ѱַ
				mov cx,6							;��ȡ�����ַ�

write_cmos_l:	mov al,byte ptr char_stack_add[bx]	;al�д��cmos�е�ʱ�䵥Ԫ
				out 70h,al
				
				sub byte ptr char_stack[bx],30h		
				mov al,byte ptr char_stack[bx]
				
				shl al,1
				shl al,1
				shl al,1
				shl al,1
				
				sub byte ptr char_stack[bx + 1],30h
				add al,byte ptr char_stack[bx + 1]	;���ַ�ջ�ַ���ΪBCD��						
				
				out 71h,al							;д��cmos��Ԫ
				
				add bx,3							
				
			loop write_cmos_l
			
				pop ax
				pop cx
				pop bx								;ʹ�õļĴ�����ջ
			ret
;------------------------------------------------------------------------------
;								�����ӳ���
;------------------------------------------------------------------------------
	 	 cls:	push ax
				push es
				push di
				push cx								;�Ĵ�����ջ
				
				mov ax,0b800h
				mov es,ax
				mov di,0
				mov cx,2000							;es:diָ���Դ��0ҳ
				
	   clean:	mov byte ptr es:[di],' '
				and byte ptr es:[di + 1],00001111b	;�������ɫ
				add di,2
			loop clean								;�����0ҳ�Դ�
				
				pop cx
				pop di
				pop es
				pop ax								;�Ĵ�����ջ
				
			ret										;�ӳ��򷵻�
;------------------------------------------------------------------------------
code ends
end start