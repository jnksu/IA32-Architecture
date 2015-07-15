%include 'header.asm'
;=======================================================================
;			内核头
;=======================================================================
section kernel_head_seg align=32 vstart=0
		
	kernel_data_offset	dd section.kernel_data_seg.start
	kernel_code_offset	dd section.kernel_code_seg.start
	kernel_API_offset	dd section.kernel_API_seg.start
	kernel_size		dd section.kernel_tail_seg.start
	
	kernel_enter		dd _kernel_code_start
				dw kernel_code_selector
kernel_head_seg_ed:
;=======================================================================
;			内核数据段	
;=======================================================================
section kernel_data_seg align=32 vstart=0
			
	kernel_mem_line_add     dd 0x8010_0000	;内核内存分配的起始地址
	GDT_Temp_Loc		dw 0x0000       ;临时存放GDT
				dd 0x0000_0000
	kernel_buffer		resb 1024	;内核缓冲区
	
	;页映射位串
	;常规内存区, 上位内存区归内核所占用
	;高端内存区, 用于页分配
	page_map        db 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
	                db 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
	                db 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
	                db 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
	                db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	                db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	                db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	                db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	page_map_size   dd $ - page_map
	
	message_1	db ' If you seen this message, that means we'
			db ' are now in protect mode, and the system'
			db ' kernel is loaded, and the video display'
			db ' routine works perfectly.', 0x0D, 0x0A, 0

	cpu_brand_1     db 0x0D, 0x0A, '      ', 0
	cpu_brand_2	times 48 db 0
	cpu_brand_3	db 0x0D, 0x0A, 0
        
        prgman_msg1     db 0x0D, 0x0A
                        db '[PROGRAM MANAGER]: Hello! I am Program Manager,'
                        db 'run at CPL = 0. Now, create user task and switch'
                        db 'to it by the Call instruction...', 0x0D, 0x0A, 0
        
        prgman_msg2     db  0x0d,0x0a
                        db  '[PROGRAM MANAGER]: I am glad to regain control.'
                        db  'Now,create another user task and switch to '
                        db  'it by the JMP instruction...',0x0d,0x0a,0
                
        prgman_msg3     db  0x0d,0x0a
                        db  '[PROGRAM MANAGER]: I am gain control again,'
                        db  'HALT...orZ',0

kernel_switch_msgi      db  0x0d,0x0a
                        db  '[SYSTEM kernel]: Uh...This task initiated with '
                        db  'CALL instruction or an exeception interrupt,'
                        db  'should use IRETD instruction to switch back...'
                        db  0x0d,0x0a,0

kernel_switch_msgj      db  0x0d,0x0a
                        db  '[SYSTEM kernel]: Uh...This task initiated with '
                        db  'JMP instruction,  should switch to Program '
                        db  'Manager directly by the JMP instruction...'
                        db  0x0d,0x0a,0    
        
        kernel_TSS_addr         dd 0x0000_0000          ;内核TSS起始地址
                                dw 0x0000               ;内核TSS选择器
                                                         
	kernel_TCB_head		dd 0x0000_0000		;内核TCB头指针
        
	salt_1			db '@PrintString'
				resb 256 - ($ - salt_1)
				dd _put_string
				dw kernel_API_selector

	salt_2			db '@ReadDiskData'
				resb 256 - ($ - salt_2)
				dd _read_hard_disk_0
				dw kernel_API_selector

	salt_3			db '@TerminateProgram'
				resb 256 - ($ - salt_3)
				dd _return_kernel
				dw kernel_API_selector

	salt_item_size		equ  $ - salt_3
	salt_items  		dd  ($ - salt_1) / salt_item_size

kernel_data_seg_ed:
;=======================================================================
;			内核代码段
;=======================================================================
[bits 32]
section kernel_code_seg align=32 vstart=0
	
_kernel_code_start:
                        ;加载数据段, 代码段, 堆栈段, 选择器               
			mov eax, kernel_data_selector
			mov ds, eax
			mov eax, common_data_selector
			mov es, eax
			
			push message_1
			push kernel_data_selector
			;[段选择器6, 段内偏移7]
			call kernel_API_selector:_put_string	
			
			mov eax, 0x8000_0000
			CPUID
			
			cmp eax, 0x8000_0004
			jl .exit_
			mov ecx, 0x03
			mov eax, 0x8000_0002
			mov ebx, cpu_brand_2
.cpu_ini:
			push ecx
			push eax
			push ebx
			
			CPUID
			push ebx
			mov  ebp, esp
			mov ebx, [ebp + 4]
			pop dword [ebx + 0x04]
			mov [ebx + 0x00], eax
			mov [ebx + 0x08], ecx
			mov [ebx + 0x0C], edx
			
			pop ebx
			pop eax
			pop ecx
			add ebx,16
			inc eax
			loop .cpu_ini
.exit_:
			push cpu_brand_1	
			push kernel_data_selector
			;[段选择器6, 段内偏移7]		
			call kernel_API_selector:_put_string
			push cpu_brand_2
			push kernel_data_selector
			call kernel_API_selector:_put_string
			push cpu_brand_3
			push kernel_data_selector
			call kernel_API_selector:_put_string
			
			;使用分页机制
			;创建内核的页目录表PDT
			mov ecx, 1024
			mov ebx, PDT_addr
			xor edi, edi
	  .clp:
	                mov dword [es:ebx + edi], 0x0000_0000
	                add edi, 4
	                loop .clp 
	                ;创建与线性地址0xFFFF_F000对应的页目录项
	                mov dword [es:ebx + 4092], 0x0002_0007
	                ;创建用于内核的页目录和页表
	                ;创建与线性地址0x0000_0000对应的页目录项
	                mov dword [es:ebx + 0x00], 0x0002_1007
	                ;创建与线性地址0x0000_0000对应的页表
	                ;用于内核的内存占据内存的低端1MB故共需要
	                ;设置256个页表表项
	                mov ecx, 256
	                mov ebx, 0x0002_1000
	                mov eax, 0x0000_0007
	                xor edi, edi
	  .set:
	                mov dword [es:ebx + edi], eax 
	                add edi, 4
	                add eax, 0x1000
	                loop .set
	                ;设置剩余表项无效
	  .set1:
	                mov dword [es:ebx + edi], 0x0000_0000
	                add edi, 4
	                cmp edi, 4096
	                jnz .set1
	                ;开启页功能
	                mov eax, PDT_addr
	                mov cr3, eax
			mov eax, cr0
			or  eax, 0x8000_0000
			mov cr0, eax
			
			;创建与线性地址0x8000_0000对应的页目录项
                        mov ebx, 0x8000_0000
			shr ebx, 20
			add ebx, 0xFFFF_F000
			mov dword [es:ebx], 0x0002_1007
			;更新GDT
			sgdt [GDT_Temp_Loc]
			mov ecx, 7
			mov ebx, [GDT_Temp_Loc + 0x02]
			mov edi, 0x14
	.setgdt:
	                or dword [es:ebx + edi], 0x8000_0000
	                add edi, 0x08  		
			loop .setgdt
			or dword [GDT_Temp_Loc + 0x02], 0x8000_0000
			lgdt [GDT_Temp_Loc]
			;刷新描述符高速缓存器
			jmp kernel_code_selector:flush
	flush:
	                mov eax, kernel_data_selector
	                mov ds, eax
	                mov eax, common_stack_selector
	                mov ss, eax		
	                mov eax, common_data_selector
	                mov es, eax
	                
			;加载任务管理器
			mov ecx, [kernel_mem_line_add]
			push ecx
			push TSS_SIZE
			;[希望分配的字节6, 起始线性地址7]
			call kernel_API_selector:_allocate_memory
			mov [kernel_mem_line_add], edx
			mov [kernel_TSS_addr], ecx
			;填充当前管理器任务相应字段
			;不存在前一个任务
			mov dword [es:ecx + TSS_PREV], 0x0000_0000
			;除了从调用门返回, 禁止从高特权级转移到低特权级
			;故0特权级的任务, 不需要用于栈切换的临时栈
			;mov [es:ecx + TSS_ESP0], 0x0000_0000
			;CR3
			mov eax, cr3
			mov [es:ecx + TSS_CR3], eax
			;没有LDT
			mov dword [es:ecx + TSS_LDT_selector], 0x0000_0000
			;T = 0
			mov word [es:ecx + TSS_IO_MAP], 0x0000
			;IOMAP
			mov word [es:ecx + TSS_IO_MAP + 0x02], TSS_SIZE - 1
			
			;创建DPL = 0 的TSS描述符, 并安装到GDT中
			push TSS_descriptor
			push TSS_SIZE - 1
			push ecx
			call kernel_API_selector:_make_Descriptor
			push eax
			push edx
			call kernel_API_selector:_set_up_Gdt_descriptor
			;保存任务管理器的TSS描述符到内核数据段
			mov [kernel_TSS_addr + 0x04], cx
			;TR中的内容时任务存在的标志, 该内容也决定了当前任务
			ltr cx
			;现在可以认为"任务管理器"任务正在运行中
			push prgman_msg1
			push kernel_data_selector
			call kernel_API_selector:_put_string
			
			;初始化用于用户程序的调用门
			call kernel_API_selector:_init_kernel_API_gate
			
			;任务A
			;为当前任务建立TCB结点
			mov ecx, [kernel_mem_line_add]
			push ecx
			push TCB_SIZE
			;[希望分配的字节6, 起始线性地址7]
			call kernel_API_selector:_allocate_memory
			mov [kernel_mem_line_add], edx
			;下一个可用的线性地址
			mov dword [es:ecx + TCB_prog_addr], user_mem_start
			;将当前任务的TCB结点加入TCB链表中
			push ecx
			call kernel_API_selector:_append_TCB
			;载入用户程序
			push ecx
			push up_0
			call kernel_API_selector:_load_relocate_program
			;执行任务切换
                        call far [es:ecx + TCB_TSS_addr]
                        
                        push prgman_msg2
                        push kernel_data_selector
                        call kernel_API_selector:_put_string
                        
                        ;任务B
                        ;为当前任务建立TCB结点
                        mov ecx, [kernel_mem_line_add]
                        push ecx
                        push TCB_SIZE
                        ;[希望分配的字节6, 起始线性地址7]
                        call kernel_API_selector:_allocate_memory
                        mov [kernel_mem_line_add], edx
                        ;下一个可用的线性地址
                        mov dword [es:ecx + TCB_prog_addr], user_mem_start 
                        ;将当前任务的TCB结点加入TCB链表中
                        push ecx
                        call kernel_API_selector:_append_TCB
                        ;载入用户程序
                        push ecx
                        push up_0
                        call kernel_API_selector:_load_relocate_program
                        ;执行任务切换
                        jmp far [es:ecx + TCB_TSS_addr]
                        
                        push prgman_msg3
                        push kernel_data_selector
                        call kernel_API_selector:_put_string
			
			hlt
kernel_code_seg_ed:			
;=======================================================================
;			内核API
;=======================================================================
[bits 32]
section kernel_API_seg align=32 vstart=0
_put_string:
					;显示以0结尾的串
					;[段选择器6, 段内偏移7]
					push ds
					push ebx
					push ecx
					push ebp
					mov  ebp, esp
					mov ax, cs
					ARPL [ebp + 6 * 4], ax 
					
					mov eax, [ebp + 6 * 4]
					mov ds, eax
					mov ebx, [ebp + 7 * 4]
	.inner:			
					mov cl, [ebx]
					or  cl, cl
					jz .exit_
					push ecx 		;[字符]
					call _put_char
					inc ebx
					jmp .inner
	.exit_:			
					pop ebp
					pop ecx
					pop ebx
					pop ds
					retf 8
	_put_char:			;显示寄存器cl中的ASCII码
					;[字符11]
					push ds
					push es					
					pushad				
					mov ebp, esp
					mov ecx, [ebp + 11 * 4]

					mov dx, 0x03D4 ;取出当前光标
						       ;的高八位	
					mov al, 0x0E
					out dx, al
					inc dx
					in  al, dx
					mov ah, al

					dec dx	;取出当前光标的低八位
					mov al, 0x0F
					out dx, al
					inc dx
					in  al, dx

					cmp cl, 0x0D
					jne .put_0A
					mov cl, 80
					div cl
					mul cl
					jmp .set_cursor
	.put_0A:		
					cmp cl, 0x0A
					jne .put_other
					add ax, 80
					jmp .roll_screen
	.put_other:
					and eax, 0x0000_FFFF		
					shl ax, 1
					mov ebx, common_video_selector	
					mov es, ebx
					mov [es : eax], cl
					shr ax, 1
					inc ax
	.roll_screen:
					cmp ax, 1999
					jle .set_cursor
					mov ebx, common_video_selector
					mov ds, ebx
					mov es, ebx
					mov esi, 0xA0
					mov edi, 0x00
					cld 
					mov ecx, 1920
					rep movsw
	
					mov ecx, 80
					mov ebx, 3840
	.cls:
					mov word [ebx], 0x0720
					add ebx, 2
					loop .cls
					mov ax, 1920
	.set_cursor:
					mov bx,ax
					mov dx, 0x03D4
					mov al, 0x0E
					out dx, al
					inc dx
					mov al, bh
					out dx, al

					dec dx
					mov al, 0x0F
					out dx, al
					inc dx
					mov al, bl
					out dx, al

					popad
					pop es
					pop ds
					ret 4
;=======================================================================
_read_hard_disk_0:		;读取一个逻辑扇区
				;[逻辑扇区7, 数据段选择器8, 段内偏移9]
				;返回 ebx = ebx + 512
			push ds
			push edx
			push eax
			push ecx
			push ebp 
			mov  ebp, esp
			mov ax, cs
			ARPL [ebp + 8 * 4], ax
			
			mov dx, 0x1F2
			mov al, 0x01
			out dx, al

			inc dx				;LBA 0 ~ 7
			mov eax, [ebp + 7 * 4]
			out dx, al
			
			inc dx				;LBA 8 ~ 15
			shr eax, 8
			out dx, al

			inc dx				;LBA 16 ~ 23
			shr eax,8 
			out dx, al

			inc dx
			shr eax, 8
			and al, 0x0F
			or  al, 0xE0
			out dx, al

			inc dx
			mov al, 0x20
			out dx, al
	.waits: 
			in al, dx
			and al, 0x88
			cmp al, 0x08
			jnz .waits

			mov ecx, 256 
			mov edx, 0x1F0
			mov ds, [ebp + 8 * 4]
			mov ebx, [ebp + 9 * 4]
	.readw:
			in  ax, dx
			mov [ebx], ax
			add ebx, 2
			loop .readw	

			pop ebp
			pop ecx
			pop eax
			pop edx
			pop ds 					
			retf 12
;===================================================================
_return_kernel:
                                ;暂停当前任务
                        mov eax, kernel_data_selector
                        mov ds, eax
                        
                        pushfd
                        pop edx
                        test edx, 100_0000_0000_0000B
                        jnz .riret
                        push kernel_switch_msgj
                        push kernel_data_selector
                        call kernel_API_selector:_put_string
                        jmp far [kernel_TSS_addr]                   
               .riret:
                        push kernel_switch_msgi
                        push kernel_data_selector
                        call kernel_API_selector:_put_string
                        iretd
;===================================================================
_make_Descriptor:		;[线性起始起始地址3, 段界限4, 段属性5]
				;[edx:eax = 描述符]
				push ebp			
				mov ebp, esp
				
				mov eax, [ebp + 3 * 4]
				shl eax, 16
				or  ax,  [ebp + 4 * 4]

				mov edx, [ebp + 3 * 4]
				and edx, 0xFFFF_0000
				rol edx, 8
				bswap edx

				and dword [ebp + 4 * 4], 0x000F_0000
				or  edx,  [ebp + 4 * 4]
				or  edx,  [ebp + 5 * 4]

				pop ebp
				retf 12
;=======================================================================
_make_Gate_Descriptor:
				;[函数所在的选择器3, 段内偏移4, 描述的属性5]
				;edx:eax = 描述符
				push ebp
				mov ebp, esp

				mov eax, [ebp + 3 * 4]
				shl eax, 16
				mov edx, [ebp + 4 * 4]
				and edx, 0xFFFF
				or  eax, edx
				mov edx, [ebp + 4 * 4]
				and edx, 0xFFFF_0000
				or  edx, [ebp + 5 * 4]
				
				pop ebp
				retf 12	
;=======================================================================
_init_kernel_API_gate:
				push ds
				push eax
				push edx
				push esi
				push ecx
				
				mov eax, kernel_data_selector
				mov ds, eax
				mov esi, salt_1				
				
				push kernel_gate_DPL3_para_2
				push _put_string
				push kernel_API_selector
				;[函数所在的选择器3, 段内偏移4, 描述的属性5]				
				call kernel_API_selector:_make_Gate_Descriptor
				push eax
				push edx
				call kernel_API_selector:_set_up_Gdt_descriptor
				mov  [esi + 260], cx 				
				add  esi, salt_item_size
	
				push kernel_gate_DPL3_para_3
				push _read_hard_disk_0
				push kernel_API_selector
				call kernel_API_selector:_make_Gate_Descriptor
				push eax
				push edx
                         	call kernel_API_selector:_set_up_Gdt_descriptor
				mov [esi + 260], cx
				add esi, salt_item_size

				push kernel_gate_DPL3_para_0
				push _return_kernel
				push kernel_API_selector
				call kernel_API_selector:_make_Gate_Descriptor
				push eax
				push edx
				call kernel_API_selector:_set_up_Gdt_descriptor
				mov [esi + 260], cx
				
				pop ecx
				pop esi
				pop edx
				pop eax
				pop ds	
				retf	
;=======================================================================
_allocate_page:                          ;分配一个4KB的页
                                         ;返回值 EAX = 页的物理地址
               push ds
               push ebx
               push ecx
               
               mov eax, kernel_data_selector
               mov ds, eax
               mov ecx, [page_map_size]
               shl ecx, 3
               xor eax, eax
       .lkpg:
               bts [page_map], eax
               jnc .setadd
               inc eax        
               loop .lkpg
               ;内存用尽,计算机停机
               hlt
     .setadd:
               shl eax, 12     
               pop ecx
               pop ebx
               pop ds 
               retf       				
;=======================================================================
_allocate_memory:			 ;[希望分配的字节7, 起始线性地址8]
                                         ;edx = 下一次内存分配的起始地址
                                         ;不能分配大于4MB的内存
					 
		push ds
		push eax
		push ebx
		push ecx 						
		push ebp
		mov ebp, esp
		
		mov eax, common_data_selector
		mov ds, eax
		;不考虑分配大于4MB的情况
		;检查对应的页目录项是否存在
		mov eax, [ebp + 8 * 4]
		shr eax, 20
		and eax, 0xFFFF_FFFC
		or  eax, 0xFFFF_F000
		mov ebx, eax
		test word [ebx], 0x0001
		jnz .checkPET
		
		;插入一个页目录
		call kernel_API_selector:_allocate_page
		or eax, 0x07
		mov [ebx], eax
		        
    .checkPET:
	        ;对希望分配的字节进行页对齐处理
		mov eax, [ebp + 7 * 4]
		and eax, 0xFFFF_F000
		add eax, 0x1000
		test word [ebp + 7 * 4], 0xFFF
		cmovz eax, [ebp + 7 * 4]
		mov edx, [ebp + 8 * 4]
		add edx, eax
		;插入页表项
		mov ecx, eax
		shr ecx, 12
		mov eax, [ebp + 8 * 4]
		shr eax, 10
		and eax, 0x003F_FFFC
		or  eax, 0xFFC0_0000
		mov ebx, eax
		
     .fillPET:		
		call kernel_API_selector:_allocate_page
		or eax,  0x07
		mov [ebx], eax
		add ebx, 0x04
		loop .fillPET
		
		pop ebp
		pop ecx
		pop ebx
		pop eax
		pop ds
		retf 8
;=======================================================================
_set_up_Gdt_descriptor:			;在GDT上安装一个新的描述符
					;[高32位描述符8, 低32位描述符9]
					;返回 RPL = 0 的GDT索引(ecx)
			push ds
			push es
			push eax
			push edx
			push ebx
			push ebp
			
			mov ebp, esp
			mov ebx, kernel_data_selector
			mov ds, ebx
			sgdt [GDT_Temp_Loc]
			mov ebx, common_data_selector
			mov es, ebx
			movzx ebx, word [GDT_Temp_Loc]
			inc   bx
			add  ebx, [GDT_Temp_Loc + 0x02]
		        mov eax, [ebp + 9 * 4]	
			mov dword [es:ebx + 0x00], eax 
			mov eax, [ebp + 8 * 4]
			mov dword [es:ebx + 0x04], eax
			add word [GDT_Temp_Loc], 8
			lgdt [GDT_Temp_Loc]
			
			movzx ecx, word [GDT_Temp_Loc]
		        sub ecx, 7

			pop ebp	
			pop ebx
			pop edx
			pop eax
			pop es
			pop ds
			retf 8
;=======================================================================
_load_relocate_program:		;加载并重定位用户程序
				;[起始逻辑扇区12, 任务TCB结点的地址13]
			push ds
			push es
			pushad
			
			mov ebp, esp
			mov eax, kernel_data_selector
			mov ds, eax
			mov eax, common_data_selector
			mov es,  eax
			
			;清空页目录的前半部分
			mov ecx, 0x200
			mov ebx, 0xFFFF_F000
			xor edi, edi
			
	.clpdt:		mov dword [es:ebx + edi], 0x0000_0000
			shl edi, 0x02
			loop .clpdt
			 
			;读取用户程序头
			push kernel_buffer		  	
			push kernel_data_selector			
			push dword [ebp + 12 * 4]	
			;[逻辑扇区7, 数据段选择器8, 段内偏移9]
			call kernel_API_selector:_read_hard_disk_0

			;计算用户程序的尺寸					
			mov eax, [kernel_buffer + user_head_size_offset]
			and eax, 0xFFFF_F000
			add eax, 0x1000
			test dword [kernel_buffer + user_head_size_offset], 0xFFF
			cmovz  eax, [kernel_buffer + user_head_size_offset]

			;为用户程序分配内存
			mov ebx, [ebp + 13 * 4]
			mov ecx, [es:ebx + TCB_prog_addr]
			push ecx 
			push eax
			;[希望分配的字节6, 起始线性地址7]
			call kernel_API_selector:_allocate_memory
			mov [es:ebx + TCB_prog_addr], edx
					
			;载入用户程序到指定的内存中去
			mov ebx, ecx
			mov ecx, eax
			shr ecx, 9
			mov eax, up_0
	.readw:	
			push ebx
			push common_data_selector
			push eax
			;[逻辑扇区7, 数据段选择器8, 段内偏移9]	
			call kernel_API_selector:_read_hard_disk_0	
			inc eax
			loop .readw
			
			mov ebx, [ebp + 13 * 4]
			;创建任务的TSS
			mov ecx, [kernel_mem_line_add]
			push ecx
			push TSS_SIZE
			call kernel_API_selector:_allocate_memory
			mov [kernel_mem_line_add], edx
			mov [es:ebx + TCB_TSS_addr], ecx
			mov word [es:ebx + TCB_TSS_limit], TSS_SIZE - 1
			;在用户的局部空间创建LDT
			mov ecx, [es:ebx + TCB_prog_addr]
			push ecx
			push user_LDT_size
			call kernel_API_selector:_allocate_memory
			mov [es:ebx + TCB_prog_addr], edx
			mov [es:ebx + TCB_LDT_addr], ecx
			mov word [es:ebx + TCB_LDT_limit], 0xFFFF
			;建立数据段描述符
			mov eax, data_read_write_G_0
			or  eax, 110_0000_0000_0000B
			push eax
			push 0x000F_FFFF
			push 0x0000_0000
			call kernel_API_selector:_make_Descriptor
			push dword [ebp + 13 * 4]
			push eax
			push edx
			call kernel_API_selector:_set_up_LDT_descriptor 
			or  cx, 0011B
			mov edi, [es:ebx + TCB_TSS_addr]
			mov [es:edi + TSS_DS], cx
			mov [es:edi + TSS_ES], cx
			mov [es:edi + TSS_FS], cx
			mov [es:edi + TSS_GS], cx
			mov [es:edi + TSS_SS], cx
			;建立0级特权栈
			push data_read_write_G_0
			push 0x000F_FFFF
			push 0x0000_0000
			call kernel_API_selector:_make_Descriptor
			push dword [ebp + 13 * 4]
			push eax
			push edx
			call kernel_API_selector:_set_up_LDT_descriptor
			mov [es:edi + TSS_SS0], cx
			;建立代码段描述符
			mov eax, code_executed_G_0
			or  eax, 110_0000_0000_0000B
			push eax
			push 0x000F_FFFF
			push 0x0000_0000
			call kernel_API_selector:_make_Descriptor
			push dword [ebp + 13 * 4]
			push eax
			push edx
			call kernel_API_selector:_set_up_LDT_descriptor
			or cx, 0011B
			mov [es:edi + TSS_CS], cx
			;建立堆栈
			push dword [es:ebx + TCB_prog_addr]
			mov eax, [kernel_buffer + user_head_stack_offset]
			shl eax, 12
			push eax
			;[希望分配的字节7, 起始线性地址8]
			call kernel_API_selector:_allocate_memory
			mov [es:ebx + TCB_prog_addr], edx
			mov [es:edi + TSS_ESP], edx
			;用于堆栈切换的0级特权栈
			push dword [es:ebx + TCB_prog_addr]
			mov eax, kernel_gate_stack_size
			shl eax, 12
			push eax
			call kernel_API_selector:_allocate_memory
			mov [es:ebx + TCB_prog_addr], edx
			mov [es:edi + TSS_ESP0], edx
			;用于堆栈切换的1级特权栈
			push dword [es:ebx + TCB_prog_addr]
			mov eax, kernel_gate_stack_size
			shl eax, 12
			push eax
			call kernel_API_selector:_allocate_memory
			mov [es:ebx + TCB_prog_addr], edx
			mov [es:edi + TSS_ESP1], edx
			;用于堆栈切换的2级特权栈
			push dword [es:ebx + TCB_prog_addr]
			mov eax, kernel_gate_stack_size
			shl eax, 12
			push eax
			call kernel_API_selector:_allocate_memory
			mov [es:ebx + TCB_prog_addr], edx
			mov [es:edi + TSS_ESP2], edx
			;登记LDT
			push user_LDT_Des
			movzx eax, word [es:ebx + TCB_LDT_limit]
			push eax
			push dword [es:ebx + TCB_LDT_addr]
			call kernel_API_selector:_make_Descriptor
			push eax
			push edx
			call kernel_API_selector:_set_up_Gdt_descriptor
			mov word [es:ebx + TCB_LDT_sel], cx
			;设置并登记TSS
			;前一个TSS的指针
			mov dword [es:edi + TSS_PREV], 0x0000_0000
			;CR3
		        call kernel_API_selector:_create_copy_cur_pdir
		        mov [es:edi + TSS_CR3], eax
		        ;EIP
		        mov eax, [kernel_buffer + user_head_enter_offset]
		        mov [es:edi + TSS_EIP], eax
		        ;EFLAGES
		        pushfd
		        pop dword [es:edi + TSS_EFLAGES]
		        ;LDT 选择器
		        movzx eax, word [es:ebx + TCB_LDT_sel]
		        mov [es:edi + TSS_LDT_selector], eax
		        ;T = 0
		        mov word [es:edi + TSS_IO_MAP], 0x0000
		        ;IOMAP
		        movzx eax, word [es:ebx + TCB_TSS_limit]
		        mov [es:edi + TSS_IO_MAP + 0x02], ax
		        push TSS_descriptor
		        movzx eax, word [es:ebx + TCB_TSS_limit]
		        push eax
		        push dword [es:ebx + TCB_TSS_addr]
		        ;[线性起始起始地址3, 段界限4, 段属性5]
		        call kernel_API_selector:_make_Descriptor
		        push eax
		        push edx
		        call kernel_API_selector:_set_up_Gdt_descriptor
		        mov [es:ebx + TCB_TSS_sel], cx
		        
			;设置SALT
			mov ecx, [es:user_head_salt_items_offset]
			mov edi, user_head_salt_offset
	.salt:
			push ecx
			push edi

			mov ecx, [salt_items]	
			mov esi, salt_1

.salt_inner:		
			push ecx
			push esi
			push edi

			mov  ecx, 64
			repe cmpsd 
			jnz .salt_inner_1 
			mov eax, [esi]
			mov [es:edi - 256], eax
			movzx eax, word [esi + 0x04]
			;将给用户使用的内核API调用门的选择器的RPL设置为3
			or  eax, 0011B
			mov [es:edi - 252], ax

.salt_inner_1:	
			pop edi
			pop esi
			pop ecx
			add esi, salt_item_size
			loop .salt_inner

			pop edi
			pop ecx
			add edi, 0x100
			loop .salt
		        
			popad 
			pop es
			pop ds

			retf 8
;===================================================================
_create_copy_cur_pdir:           
                                ;创建新的页目录, 并复制当前页目录内容
                                ;输出 eax = 新的页目录物理地址
                       push ds
                       push es
                       push ebx
                       push ecx
                       push esi
                       push edi 
                       
                       mov eax, common_data_selector
                       mov ds, eax
                       mov es, eax
                       
                       call kernel_API_selector:_allocate_page
                       mov ebx, eax
                       or  ebx, 0x07
                       mov [0xFFFF_FFF8], ebx
                       
                       mov esi, 0xFFFF_F000
                       mov edi, 0xFFFF_E000
                       mov ecx, 0x400
                       cld 
                       rep movsd
                       
                       pop edi
                       pop esi
                       pop ecx
                       pop ebx
                       pop es
                       pop ds
                       retf                      
;===================================================================
_set_up_LDT_descriptor:         
				;安装描述符到LDT中
				;[高32位描述符7, 低32位描述符8, TCB起始地址9]
				;ecx = 描述符的选择器, RPL = 0			
			push es
			push eax
			push ebx
			push edi			
			push ebp 
			
			mov ebp, esp
			mov eax, common_data_selector
			mov es, eax
			;es:edi指向当前TCB结点			
			mov edi, [ebp + 9 * 4]
			mov ebx, [es:edi + TCB_LDT_addr]
 			add bx,  [es:edi + TCB_LDT_limit]
			inc bx
			;安装描述符
			mov eax, [ebp + 8 * 4]
			mov [es:ebx + 0x00], eax
			mov eax, [ebp + 7 * 4]
			mov [es:ebx + 0x04], eax
			;重新设置段界限
			movzx ebx, word [es:edi + TCB_LDT_limit]
			add bx, 8
			mov [es:edi + TCB_LDT_limit], bx
			;设置LDT的选择器
			sub bx, 7
			;置TI位			
			or  bx, 0100B 
	 		movzx ecx, bx

			pop ebp
			pop edi
			pop ebx
			pop eax
			pop es
			retf 12 						
;=======================================================================
_append_TCB:
						;添加TCB到TCB链表中
			 			;[TCB结点的地址]
			push ds
			push es
			push eax
			push ebx
			push ebp

			mov ebp, esp
			mov eax, kernel_data_selector
			mov ds, eax
			mov ebx, [kernel_TCB_head]
			mov eax, common_data_selector
			mov es, eax
		
			;判断头结点是否位空
			or ebx, ebx
			jnz .find_tail
			;头结点为空
			mov eax, [ebp + 7 * 4]
			mov [kernel_TCB_head], eax
			jmp .end
	.find_tail:	
			mov eax, [es:ebx]
			or eax, eax
			jnz .find_next_tail
			mov eax, [ebp + 7 * 4]
			mov [es:ebx], eax
			jmp .end
   .find_next_tail:    
			mov ebx, eax
			jmp .find_tail
              .end:
			pop ebp
			pop ebx
			pop eax
			pop es
			pop ds
			retf 4
kernel_API_seg_ed:	
;=======================================================================
;			内核尾
;=======================================================================
section kernel_tail_seg align=32 vstart=0
kernel_tail_seg_ed:
