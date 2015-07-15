;                             栈段由内核程序提供
;======================================================================
;                                 头部段
;======================================================================
section header_seg align=32

	header_seg_offset	dd section.header_seg.start
	data_seg_offset		dd section.data_seg.start
	code_seg_offset		dd section.code_seg.start
	program_size		dd section.tail_seg.start
	
	stack_seg		dd 0x02
	
	program_enter		dd _code_seg_start
				dw 0x0000 ;代码段选择器,由内核填充	
;//////////////////////////////////////////////////////////////////////
;			        符号地址表
;//////////////////////////////////////////////////////////////////////
	salt_items		dd (header_seg_ed - $) / 256

	PrintString		db '@PrintString', 0
				resb 256 - ($ - PrintString)
	
	ReadDiskData		db '@ReadDiskData', 0
				resb 256 - ($ - ReadDiskData)

	TerminateProgram	db '@TerminateProgram',0
				resb 256 - ($ - TerminateProgram)
header_seg_ed:
;======================================================================
;				  数据段
;======================================================================
section data_seg align=32

	buffer resb 1024

	message db 0x0d, 0x0a, 0x0d, 0x0a
		db '**************** User Program'
		db 'is runing****************'
		db 0x0d, 0x0a, 0

	message_1 db '   DiskData:', 0x0d, 0x0a, 0

data_seg_ed:
;======================================================================
;			          代码段
;======================================================================
[bits 32]
section code_seg align=32
	_code_seg_start:
	
				push message
				push ds
				;[段选择器, 段内偏移]
				call far [PrintString]

				push buffer
				push ds
				push 100
				;[逻辑扇区, 数据段选择器, 段内偏移]
				call far [ReadDiskData]

				push message_1
				push ds
				call far [PrintString]

				push buffer
				push ds
				call far [PrintString]

				call far [TerminateProgram]
code_seg_ed:
;======================================================================
;                                 尾巴段
;======================================================================
section tail_seg align=32
tail_seg_ed:
