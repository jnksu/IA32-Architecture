assume cs:code
code segment

	start:	mov ax,code
			mov ds,ax
			mov si,offset int7ch 										;ds:si指向源地址
			
			mov ax,0
			mov es,ax
			mov di,0200h												;es:di指向目标地址即0:0200处
			
			mov cx,offset int7ch_end - offset int7ch					;复制的中断程序的字节数
			cld 
			rep movsb
			
			cli			
			mov word ptr es:[7ch * 4],0200h		
			mov word ptr es:[7ch * 4 + 2],0
			sti															;屏蔽可屏蔽的外部中断,并修改中断向量表
			
			
			mov ax,4c00h
			int 21h														;中断安装程序结束
			
			org 0200h													;设置中断程序的偏移起始地址为0200h 
			
   int7ch:	jmp far ptr int7ch_start
			table dw int7ch_read , int7ch_write							;设置直接定址表

			
int7ch_start:	push bx

				cmp ah,1
				ja int7ch_ret
				
				cmp ah,0
				jb int7ch_ret												;检查输入值是否在有效范围内
				
				mov bx,0
				mov bl,ah
				
				add bx,bx
				call  word ptr table[bx]									;召唤相应的读写子程序
	
  int7ch_ret:	pop bx
				iret
;------------------------------------------------------------------------
 int7ch_read:	push ax
				push dx
				push cx													;使用的寄存器入栈
				
				mov ax,dx
				mov dx,0
				mov cx,1440												;dx中存放高位的被除数,ax存放低位的被除数,cx存放除数
				
				div	cx
				
				push ax
				push dx													;将结果入栈,
				
				pop ax													;取出除得的余数到ax寄存器当中
				
				mov dl,18												
				div dl													;进行8位的除法
				
				inc ah													;ah中存放的余数自增1作为扇区号
				
				mov cl,ah												;cl存放扇区号	
				mov ch,al												;ch存放磁道号
				mov al,1												;al存放读取的扇区数
				mov ah,2												;ah存放int13h的功能号
				mov dx,0												
				
				pop dx													
				
				mov dh,dl												;dh存放磁头号
				mov dl,0												;dl存放驱动器号
				
				mov ah,2												;读扇区
				int 13h													;调用BIOS提供的中断
				
				pop cx
				pop dx
				pop ax													;使用的寄存器出栈
				
				ret
;------------------------------------------------------------------------			
int7ch_write:	push ax
				push dx
				push cx													;使用的寄存器入栈
				
				mov ax,dx									
				mov dx,0
				mov cx,1440												;ax作低位被除数,dx作高位被除数,cx作除数
				
				div cx		
				
				push ax
				push dx													;商和余数分别入栈
				
				pop ax					
				
				mov dl,18												;ax作被除数,dl作除数
				
				div dl
				
				inc ah													;ah自增1作为扇区号 
				
				mov cl,ah												;cl存放扇区号
							
				mov ch,al												;ch存放磁道号
				
				mov al,1												;al存放写入的扇区数 
				mov ah,3												;ah存放int13h的功能号
				mov dx,0												
				
				pop dx
				
				mov dh,dl												;dh存放磁头号
				mov dl,0												;dl存放驱动器号
				
				mov ah,3												;写扇区
				int 13h													;调用中断
				
				pop cx
				pop dx
				pop ax													 ;使用的寄存器出栈
				
				ret
				
;------------------------------------------------------------------------

int7ch_end:		nop
					
code ends
end start