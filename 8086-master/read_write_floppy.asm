assume cs:code
code segment

	start:	mov ax,code
			mov ds,ax
			mov si,offset int7ch 										;ds:siָ��Դ��ַ
			
			mov ax,0
			mov es,ax
			mov di,0200h												;es:diָ��Ŀ���ַ��0:0200��
			
			mov cx,offset int7ch_end - offset int7ch					;���Ƶ��жϳ�����ֽ���
			cld 
			rep movsb
			
			cli			
			mov word ptr es:[7ch * 4],0200h		
			mov word ptr es:[7ch * 4 + 2],0
			sti															;���ο����ε��ⲿ�ж�,���޸��ж�������
			
			
			mov ax,4c00h
			int 21h														;�жϰ�װ�������
			
			org 0200h													;�����жϳ����ƫ����ʼ��ַΪ0200h 
			
   int7ch:	jmp far ptr int7ch_start
			table dw int7ch_read , int7ch_write							;����ֱ�Ӷ�ַ��

			
int7ch_start:	push bx

				cmp ah,1
				ja int7ch_ret
				
				cmp ah,0
				jb int7ch_ret												;�������ֵ�Ƿ�����Ч��Χ��
				
				mov bx,0
				mov bl,ah
				
				add bx,bx
				call  word ptr table[bx]									;�ٻ���Ӧ�Ķ�д�ӳ���
	
  int7ch_ret:	pop bx
				iret
;------------------------------------------------------------------------
 int7ch_read:	push ax
				push dx
				push cx													;ʹ�õļĴ�����ջ
				
				mov ax,dx
				mov dx,0
				mov cx,1440												;dx�д�Ÿ�λ�ı�����,ax��ŵ�λ�ı�����,cx��ų���
				
				div	cx
				
				push ax
				push dx													;�������ջ,
				
				pop ax													;ȡ�����õ�������ax�Ĵ�������
				
				mov dl,18												
				div dl													;����8λ�ĳ���
				
				inc ah													;ah�д�ŵ���������1��Ϊ������
				
				mov cl,ah												;cl���������	
				mov ch,al												;ch��Ŵŵ���
				mov al,1												;al��Ŷ�ȡ��������
				mov ah,2												;ah���int13h�Ĺ��ܺ�
				mov dx,0												
				
				pop dx													
				
				mov dh,dl												;dh��Ŵ�ͷ��
				mov dl,0												;dl�����������
				
				mov ah,2												;������
				int 13h													;����BIOS�ṩ���ж�
				
				pop cx
				pop dx
				pop ax													;ʹ�õļĴ�����ջ
				
				ret
;------------------------------------------------------------------------			
int7ch_write:	push ax
				push dx
				push cx													;ʹ�õļĴ�����ջ
				
				mov ax,dx									
				mov dx,0
				mov cx,1440												;ax����λ������,dx����λ������,cx������
				
				div cx		
				
				push ax
				push dx													;�̺������ֱ���ջ
				
				pop ax					
				
				mov dl,18												;ax��������,dl������
				
				div dl
				
				inc ah													;ah����1��Ϊ������ 
				
				mov cl,ah												;cl���������
							
				mov ch,al												;ch��Ŵŵ���
				
				mov al,1												;al���д��������� 
				mov ah,3												;ah���int13h�Ĺ��ܺ�
				mov dx,0												
				
				pop dx
				
				mov dh,dl												;dh��Ŵ�ͷ��
				mov dl,0												;dl�����������
				
				mov ah,3												;д����
				int 13h													;�����ж�
				
				pop cx
				pop dx
				pop ax													 ;ʹ�õļĴ�����ջ
				
				ret
				
;------------------------------------------------------------------------

int7ch_end:		nop
					
code ends
end start