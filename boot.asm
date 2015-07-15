%include 'header.asm'
;======================================================================
;32位保护模式下的代码段
[bits 32]
[section code32_seg align=32 vstart=0x0000_8000]	
_code32_seg_start:

	;初始化栈
	mov eax, common_stack_selector
	mov ss, eax
	mov esp, 0x00
	;初始化数据段
	mov eax, common_data_selector
	mov ds, eax
	
	;加载内核头
	push kernel_base_address
	push common_data_selector
	push kernel_base_sector
	;[逻辑扇区, 数据段选择子, 段内偏移]		
	call _read_hard_disk_0	
	
	;计算内核大小
	mov eax, [kernel_base_address + kernel_head_size_offset]
	and eax, 0xFFFF_FE00	;强制512字节对齐
	add eax, 0x200
	test dword [kernel_base_address + kernel_head_size_offset], 0x0000_01FF
	cmovz eax, [kernel_base_address + kernel_head_size_offset]
	
	;是否只有一个扇区
	mov ecx, eax
	shr ecx, 9
	dec ecx
	or ecx, ecx
	jz .setup
	
	;加载剩余内核块到内存中
	mov eax, kernel_base_sector
	inc eax

.readw:
	push ebx
	push common_data_selector
	push eax
	call _read_hard_disk_0
	inc eax
	loop .readw
	
.setup:		
	;计算内核描述符
	;内核数据段
	push data_read_write_0
	mov eax, [kernel_base_address + kernel_head_code_offset]
	sub eax, [kernel_base_address + kernel_head_data_offset]
	dec eax
	push eax
	mov eax, kernel_base_address
	add eax, [kernel_base_address + kernel_head_data_offset]
	push eax
	;[线性起始起始地址2, 段界限3, 段属性4]
	call _make_Descriptor 
	push eax
	push edx
	;[高32位描述符6, 低32位描述符7]
	call _set_up_Gdt_descriptor 

	;内核代码段
	push code_executed_0
	mov eax, [kernel_base_address + kernel_head_API_offset]
	sub eax, [kernel_base_address + kernel_head_code_offset]
	dec eax
	push eax
	mov eax, kernel_base_address
	add eax, [kernel_base_address + kernel_head_code_offset]
	push eax
	call _make_Descriptor
	push eax
	push edx
	call _set_up_Gdt_descriptor
	
	;内核API段
	push code_executed_0
	mov eax, [kernel_base_address + kernel_head_size_offset]
	sub eax, [kernel_base_address + kernel_head_API_offset]
	dec eax
	push eax
	mov eax, kernel_base_address
	add eax, [kernel_base_address + kernel_head_API_offset]
	push eax
	call _make_Descriptor
	push eax
	push edx
	call _set_up_Gdt_descriptor
	
	;进入内核
	jmp far [kernel_base_address + kernel_code_enter]
;======================================================================
_read_hard_disk_0:		;读取一个逻辑扇区
		  		;[逻辑扇区6, 数据段选择器7, 段内偏移8]
		  		;返回 ebx = ebx + 512
		push ds
		push edx
		push eax
		push ecx
		push ebp

		mov ebp, esp
		mov dx, 0x1F2
		mov al, 0x01
		out dx, al

		inc dx		;LBA 0 ~ 7
		mov eax, [ebp + 6 * 4]
		out dx, al
		
		inc dx		;LBA 8 ~ 15
		shr eax, 8
		out dx, al

		inc dx		;LBA 16 ~ 23
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
		mov ds,  [ebp + 7 * 4]
		mov ebx, [ebp + 8 * 4]
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
		ret 12	
;||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
_make_Descriptor:			;[线性起始起始地址2, 段界限3, 段属性4]
		push ebp		;EDX:EAX 描述符
		mov ebp, esp
		
		mov eax, [ebp + 2 * 4]
		shl eax, 16
		or  ax,  [ebp + 3 * 4]

		mov edx, [ebp + 2 * 4]
		and edx, 0xFFFF_0000
		rol edx, 8
		bswap edx

		and dword [ebp + 3 * 4], 0x000F_0000
		or  edx,  [ebp + 3 * 4]
		or  edx,  [ebp + 4 * 4]

		pop ebp
		ret 12
;||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
_set_up_Gdt_descriptor:		;在GDT上安装一个新的描述符
		       		;[高32位描述符6, 低32位描述符7]
		push ds
		push eax
		push edx
		push ebx
		push ebp
		
		mov ebp, esp
		mov ebx, common_data_selector
		mov ds, ebx
		sgdt [Boot_GDT_Temp_Loc]
		movzx ebx, word [Boot_GDT_Temp_Loc]
		inc ebx
		add ebx, [Boot_GDT_Temp_Loc + 0x02]
		mov eax, [ebp + 7 * 4]
		mov dword [ebx + 0x00], eax 
		mov eax, [ebp + 6 * 4]
		mov dword [ebx + 0x04], eax
		add word [Boot_GDT_Temp_Loc], 8
		lgdt [Boot_GDT_Temp_Loc]
		
		pop ebp	
		pop ebx
		pop edx
		pop eax
		pop ds
		ret 8					
;======================================================================
	Boot_GDT_Temp_Loc	dw 0x0000
				dd 0x0000_0000
;======================================================================		
		resb 510 - ($ - $$) 
		db   0x55, 0xAA
code32_seg_ed:
