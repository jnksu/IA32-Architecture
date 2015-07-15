;------------------------------------------------------------------------------
;    程序名: system
;程序源文件: system
;  程序功能: 引导计算机的启动,显示cmos中的时间,重新启动计算机,修改cmos中的时间		
;      说明: 由于该程序不需要运行在现有的操作系统中,故先在操作系统的环境下链接
;编译程序,运行程序,将程序写入事先准备好虚拟软驱上,再设置从软驱启动计算机.
;------------------------------------------------------------------------------
assume cs:code
code segment
;------------------------------------------------------------------------------
;								引导程序安装程序
;------------------------------------------------------------------------------
	start:	mov ax,code
			mov es,ax
			mov bx,offset sys						;es:bx指向写入到扇区的引导程序地址
			
			mov ch,0								;磁道号
			mov cl,1								;扇区号
			mov dh,0								;面号
			mov dl,0								;驱动器号
			mov al,18								;写入的扇区数
			mov ah,3								;写扇区
			
			int 13h									;调用中断写扇区
			
			mov ax,4c00h
			int 21h
			
			org 7c00h								;以下代码从第一扇区开始
;------------------------------------------------------------------------------
;								引导字符显示程序
;------------------------------------------------------------------------------
	  sys:	jmp near ptr system						;跳转到引导程序第一条指令处
			
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
;								引导内存加载程序
;------------------------------------------------------------------------------
  system:	mov ax,0
			mov es,ax
			mov cl,2									;扇区号
			mov bx,7e00h								;es:bx指向第二个扇区对应的第二个内存区	
   
    read:	mov ch,0									;磁道号
			mov dh,0									;面号
			mov dl,0									;驱动器号
			
			mov ah,2									;读扇区
			mov al,1									;读取的扇区数
			
			int 13h										;将软驱0道0面2扇区的前17个扇区的内容读取到0:7e00h处
			
			add bx,512									
			inc cl										;指向下一个扇区			
			
			cmp cl,19
			je  read_ok									;检查第0磁道的17个扇区是否全部写入内存中 
			
			jmp short read								;向下一个扇区写入数据到内存中去

 read_ok:	mov bx,0									;t_end[bx]指向字符段的第一个字符串
			mov cx,6									;读取六个字符串
			
			call show_char_sc							;显示主菜单
			
			jmp near ptr select							;接受用户的输入
			
			org 7e00h									;以下代码从第二扇区开始
;------------------------------------------------------------------------------
;								引导字符显示子程序
;------------------------------------------------------------------------------
show_char_sc:	push ax
				push es
				push ds
				push si
				push di									;寄存器入栈
				
				
				mov ax,0b800h
				mov es,ax								;es指向显存段
			
				mov ax,0
				mov ds,ax								;ds指向数据段
				
			
		show:	mov si,word ptr t_end[bx]				;ds:si指向数据段
				mov di,word ptr t_end[bx + 2]			;es:di指向显存
			
				push cx									;循环次数入栈
			
		char:	mov al,byte ptr ds:[si]					;从数据段取出一个字符
			
				cmp al,0								
				je ok									;检查是否到字符串末端
			
				mov byte ptr es:[di],al					
				mov byte ptr es:[di + 1],0ch			;将字符写入显存
			
				inc si									;指向下一个字符
				add di,2								;指向下一个显存区
		
			jmp short char								;下一次循环
			
	      ok:	pop cx									
				
				add bx,4								
		
			loop show									;指向下一个字符串
			
				pop di
				pop si
				pop ds
				pop es
				pop ax									;寄存器出栈
			ret											;子程序返回
;------------------------------------------------------------------------------
;								引导键盘中断处理程序
;------------------------------------------------------------------------------
		  select:	mov ah,0
					int 16h									;调用int16h中断读取一个输入的字符
		
					cmp al,'1'
					je 	reset_pc_l							;重启计算机
  			
					cmp al,'2'
					je  start_system_l						;开始引导本机的操作系统
							
					cmp al,'3'
					je  clock_l								;查看当前时间
				
					cmp al,'4'
					je  set_clock_l							;设置当前时间
 
					jmp near ptr jump						;跳过中转地址表
					
      reset_pc_l:	jmp near ptr reset_pc					;防止子程序占用内存空间过大而使je无法完成跳转
  start_system_l:	jmp near ptr start_system				;防止子程序占用内存空间过大而使je无法完成跳转	
         
		 clock_l:	call cls								;清屏
					mov cx,1								;传送字符串个数
					mov bx,24								;字符串在t_end表中的位置
					call show_char_sc						;显示字符
					jmp near ptr clock						;防止子程序占用内存空间过大而使je无法完成跳转
					
	 set_clock_l:	call  cls								;召唤清屏子程序
					mov cx,4
					mov bx,28
					call show_char_sc						;显示字符
					jmp near ptr set_clock					;防止子程序占用内存空间过大而使je无法完成跳转	
			
			jump:	nop
			
					jmp short select						;再次读取用户的输入
;------------------------------------------------------------------------------
;								引导系统重启程序
;------------------------------------------------------------------------------		
	reset_pc:	mov word ptr ds:[2],0ffffh
				mov word ptr ds:[0],0
				
				jmp dword ptr ds:[0]				;跳转到cpu要执行的第一条指令处
;------------------------------------------------------------------------------
;								引导硬盘系统引导程序
;------------------------------------------------------------------------------	
start_system:	mov ax,0
				mov es,ax
				mov bx,7c00h						;es:bx指向0:7c00处
				
				mov ch,0							;硬盘0磁道
				mov cl,1							;硬盘1扇区
				mov dh,0							;硬盘0磁头
				mov dl,80h							;硬盘C驱动器
				
				mov al,1							;读取一个扇区
				mov ah,2											
				
				int 13h								;调用中断读扇区
				
				mov word ptr ds:[2],0
				mov word ptr ds:[0],7c00h
				
				jmp dword ptr ds:[0]				;跳转到cpu要执行的第一条指令处
;------------------------------------------------------------------------------
;								引导时间int9中断程序
;------------------------------------------------------------------------------										
       clock:	mov ax,cs
				mov ds,ax
				mov si,offset int9							;ds:si指向源地址
			
				mov ax,0
				mov es,ax
				mov di,0204h								;es:di指向目标地址
			
				mov cx,offset int9_end - offset int9		;复制的字节数
				cld
				rep movsb
								
				push word ptr es:[9 * 4]
				push word ptr es:[9 * 4 + 2]				;将原中断地址入栈
			
				pop word ptr es:[0202h]
				pop word ptr es:[0200h]						;保存原中断地址
			
				cli
				mov word ptr es:[9 * 4],0204h
				mov word ptr es:[9 * 4 + 2],0				;修改中断向量表
				sti
				
				jmp near ptr clock_start					;跳转到引导时间显示程序	
				
;-----------------------------------------------------------------------	 
		int9:	push ax
				push ds
				push es
				push di
				push cx										;使用的寄存器入栈
			
			
				pushf										;标志寄存器入栈
			
				mov ax,0
				mov ds,ax
			
				call dword ptr ds:[0200h]					;调用原中断程序
			
				in al,60h									;读取扫描码到al寄存中
				
				cmp al,3bh
				je color_l									;改变颜色
			
				cmp al,01
				je return_l									;返回
			
				jmp near ptr jump_int9						;跳过改变颜色的子程序
  
	 color_l:	mov ax,0b800h
				mov es,ax
				mov di,12 * 160 + 31 * 2 + 1				;es:di指向显存
				mov cx,17									;修改显示17个字符的属性						
			
	   color:	inc	byte ptr es:[di]
				add di,2
		loop color											;改变颜色

   jump_int9:	jmp near ptr jump_int9_						;跳过返回主菜单的子程序
	
    return_l:	push word ptr ds:[0202h]
				push word ptr ds:[0200h]
			
				cli
				pop word ptr ds:[9 * 4]
				pop word ptr ds:[9 * 4 + 2]
				sti											;恢复原来的int9中断
				
				pop	cx
				pop di
				pop	es
				pop ds
				pop dx										;寄存器出栈
				
				pop word ptr ds:[0]
				pop word ptr ds:[2]							;将栈中存放的地址出栈到当前的数据段中
				
				popf										;标志寄存器出栈
				
				mov word ptr ds:[0],offset sys_f			;修改iret指令跳回后的第一条指令的偏移地址
		 
				jmp dword ptr ds:[0]						;模拟iret指令
		 
	   sys_f:	call cls									;中断过后要召唤清屏程序
				
				jmp near ptr sys							;返回主菜单
				
  jump_int9_:	pop cx
				pop di
				pop es
				pop ds
				pop ax
			iret											;中断返回
			
    int9_end:	nop	
	
;------------------------------------------------------------------------------
;								引导时间显示程序
;------------------------------------------------------------------------------	   
				
				time db '00/00/00 00:00:00' 	;年/月/日 时:分:秒	
				
 clock_start:	mov si,0						;time:si指向数据段
			
				mov ax,0b800h
				mov es,ax
				mov di,12 * 160 + 31 * 2		;es:di指向显存段
			
				mov bl,9						
				mov cx,3						
			

  clock_show:	mov al,bl						
			
				out 70h,al						;读取cmos的9号单元
				in  al,71h						;读取一个字节到al寄存器中
			
				mov ah,al						
			
				shr ah,1
				shr ah,1
				shr ah,1
				shr ah,1						;ah存放高4位的BCD码
				and al,00001111b				;除掉al中的高位BCD码
			
				add ah,30h
				add al,30h						;转化为ASCII码
			
				mov byte ptr time[si],ah
				mov byte ptr time[si + 1],al	;写入数据段
			
				add si,3								
				dec bl							;指向下一个cmos数据单元
				
			loop clock_show				
;------------------------------------------------------------------------------
				mov cx,3
				mov bl,4						;读取cmos4号单元
			
clock_show_:	mov al,bl						
			
				out 70h,al
				in  al,71h						;读字节到al中
			
				mov ah,al
				shr ah,1
				shr ah,1
				shr ah,1
				shr ah,1						;ah存放高位BCD码
			
				and al,00001111b				;除掉al中的高位BCD码
			
				add ah,30h
				add al,30h						;字符转换				
			
				mov byte ptr time[si],ah			
				mov byte ptr time[si + 1],al	;写入数据段
			
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
		
		loop screen							;time:si指向源地址,es:di指向目标地址
		
			jmp near ptr clock_start		;重复读取数据
			
;------------------------------------------------------------------------------
;								引导时间修改程序
;------------------------------------------------------------------------------
   set_clock:	mov dh,25
				mov dl,2						;在屏幕第25行第2列输入字符			
				
				call string						;调用字符输入程序
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
			
     no_char:	cmp ah,0eh
				je  backspace					;对退格键进行处理
			
				cmp ah,1ch
				je  enter_key					;对回车键进行处理
				
				cmp ah,01h
				je  return_string
				
				jmp short string_start			;其它键不处理并返回重新读取字符
			
   backspace:	mov ah,1
				call char_stack_show			;从字符栈区删除一个字符
			
				mov ah,2
				call char_stack_show			;显示栈中的字符
			
				jmp short string_start			;读取下一次输入
			
   enter_key:	mov ah,0
				mov al,0
				call char_stack_show			;向字符栈中写入字符0		
			
				mov ah,2
				call char_stack_show			;显示栈中的字符
				
				call write_cmos					;修改cmos中的时间
				
				call  cls						;召唤清屏子程序
				
				pop ax							;使用的寄存器出栈
												
				jmp near ptr sys				;返回主菜单

return_string:	call cls						;召唤清屏子程序
				
				pop ax							;使用的寄存器出栈
				
				jmp near ptr sys				;返回主菜单
;------------------------------------------------------------------------------
      char_stack_show:	jmp near ptr  char_stack_show_start

		char_table	dw	push_char,pop_char,char_stack_show_l
		char_stack	db 512 dup (0)
	char_stack_top	dw 0
	char_stack_add	db 9,0,0,8,0,0,7,0,0,4,0,0,2,0,0,0,0,0	;字符栈对应的cmos中的时间单元
	
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
						ret 	
;------------------------------------------------------------------------------
;								修改cmos时间				
;------------------------------------------------------------------------------
  
  write_cmos:	push bx
				push cx
				push ax								;使用的寄存器入栈
				
				
				mov bx,0							;bx进行相对寻址
				mov cx,6							;读取六个字符

write_cmos_l:	mov al,byte ptr char_stack_add[bx]	;al中存放cmos中的时间单元
				out 70h,al
				
				sub byte ptr char_stack[bx],30h		
				mov al,byte ptr char_stack[bx]
				
				shl al,1
				shl al,1
				shl al,1
				shl al,1
				
				sub byte ptr char_stack[bx + 1],30h
				add al,byte ptr char_stack[bx + 1]	;将字符栈字符改为BCD码						
				
				out 71h,al							;写入cmos单元
				
				add bx,3							
				
			loop write_cmos_l
			
				pop ax
				pop cx
				pop bx								;使用的寄存器出栈
			ret
;------------------------------------------------------------------------------
;								清屏子程序
;------------------------------------------------------------------------------
	 	 cls:	push ax
				push es
				push di
				push cx								;寄存器入栈
				
				mov ax,0b800h
				mov es,ax
				mov di,0
				mov cx,2000							;es:di指向显存第0页
				
	   clean:	mov byte ptr es:[di],' '
				and byte ptr es:[di + 1],00001111b	;清除背景色
				add di,2
			loop clean								;清除第0页显存
				
				pop cx
				pop di
				pop es
				pop ax								;寄存器出栈
				
			ret										;子程序返回
;------------------------------------------------------------------------------
code ends
end start