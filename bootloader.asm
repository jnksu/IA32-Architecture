%include 'header.asm'
;=======================================================================
;16位初始化的代码段
[section code16 align=16 vstart=0x0000_7C00]

	mov eax, cs
	mov ds, eax
	mov ss, eax
	mov esp, 0x7C00
	
	xor edx, edx
	mov eax, [pgdt + 0x02]
	mov ecx, 16
	div ecx
	mov ds, eax
	mov ebx, edx
	
	;#0空描述符
	mov dword [ebx + 0x00], 0x0000_0000
	mov dword [ebx + 0x04], 0x0000_0000
	;#1公共数据段
	mov dword [ebx + 0x08], 0x0000_FFFF
	mov dword [ebx + 0x0C], 0x00CF_9200
	;#3公共堆栈段
	mov dword [ebx + 0x10], 0x7C00_FFFD
	mov dword [ebx + 0x14], 0x00CF_9600
	;#4公共视频段
	mov dword [ebx + 0x18], 0x8000_7FFF
	mov dword [ebx + 0x1C], 0x0040_920B
	;#2Boot代码段
	mov dword [ebx + 0x20], 0x8000_01FF
	mov dword [ebx + 0x24], 0x0040_9800
	
	mov word [cs:pgdt], 0x27
	lgdt [cs:pgdt]
	
	;加载LBA为1的Boot到0000:8000
	push boot_logic_addr_memst_offset
	push boot_logic_addr_seg
	push boot_loader_sector
	call read_hard_disk_0	;[逻辑扇区6, 数据段选择器7, 段内偏移8]
	
	;打开A20
	in al, 0x94
	or al, 0010B
	out 0x94, al
	;关闭中断
	cli
	;进入保护模式
	mov eax, cr0
	or eax, 0001B
	mov cr0, eax
	;进入Boot
	jmp dword boot_code_selector:boot_line_addr_codest_offset
;16位初始化的数据段
pgdt	dw 0x0000
	dd 0x0000_7E00
;16位子过程
;=======================================================================
read_hard_disk_0:	;读取一个逻辑扇区
		 	;[逻辑扇区5, 数据段选择器5 * 4 + 2, 段内偏移6]	
		 	;返回 ebx = ebx + 512
			push edx
			push eax
			push ecx
			push ebp
			push ds
								
			mov ebp, esp
			mov dx, 0x1f2	;设置要读取的扇区数量
			mov al, 0x01
			out dx, al
			
			inc dx							
			mov eax, [ebp + 5 * 4]
			out dx, al	;LBA 0~7
			
			inc dx		;0x1f4
			shr eax, 8
			out dx, al	;LBA 8~15
			
			
			inc dx		;0x1f5
			shr eax, 8
			out dx, al	;LBA 16~23
			
			inc dx		;0x1f6
			shr eax, 8
			and al, 0x0F	;LBA 24~27
			or  al, 0xe0	;设置从主硬盘以LBA模式读取数据
			out dx, al
			
			inc dx
			mov al, 0x20
			out dx, al	;请求硬盘读
			
	.waits:
			in  al, dx	;读取硬盘当前状态
			and al, 0x88	;读取BSY位和REDDY位
			cmp al, 0x08
			jnz .waits
			
			mov ecx, 256	;准备读取数据
			mov edx, 0x1f0
			mov ds,  [ebp + 5 * 4 + 2]
			movzx ebx, word [ebp + 6 * 4]
	.readw:	
			in  ax, dx
			mov [ebx], ax
			add ebx, 2
			loop .readw
			
			pop ds
			pop ebp
			pop ecx
			pop eax
			pop edx
	ret 6
;=======================================================================
	resb 510 - ($ - $$)
 	db 0x55, 0xAA
