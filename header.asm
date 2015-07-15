;======================================================================
;				GDT的位置
;======================================================================
	gdt_loc					equ 0x0000_7E00
;======================================================================
;				GDT选择器
;======================================================================
	null_point_selectro     equ 0x00	;空指针
	common_data_selector 	equ 0x08	;公共数据段选择器
	common_stack_selector	equ 0x10	;公共栈段选择器
	common_video_selector 	equ 0x18	;公共视频段选择器
	boot_code_selector 	    equ 0x20	;引导代码选择器
	kernel_data_selector 	equ 0x28	;内核数据段选择器
	kernel_code_selector 	equ 0x30	;内核代码段选择器
	kernel_API_selector 	equ 0x38	;内核API选择器
;======================================================================
;				描述符属性
;======================================================================
code_executed_0		equ   0x0040_9800	;G = 0 32位
  						;DPL = 0 非依从的代码段
code_executed_G_0       equ   0x00C0_9800       ;G = 1 32位
                                                ;DPL = 0 非依从的代码段
data_read_write_0       equ   0x0040_9200	;G = 0 32位
						;DPL = 0 读写数据段
data_read_write_G_0	equ   0x00C0_9200	;G = 1 32位
						;DPL = 0 读写的数据段
stack_0			equ   0x0040_9600	;G = 0 32位
						;DPL = 0 向下扩展的栈段
stack_G_0		equ   0x00C0_9600	;G = 1 32位
						;DPL = 0 向下扩展的栈段
;======================================================================
;				BootLoader
;======================================================================
boot_logic_addr_memst_offset	equ 0x8000      ;Boot在内存中的起始位置
boot_logic_addr_seg             equ 0x0000      ;Boot的段选择子(16位)
boot_loader_sector              equ 0x0001      ;Boot在硬盘上的位置(LBA)
;======================================================================
;				BOOT
;======================================================================
boot_line_addr_codest_offset    equ 0x0000_0000   ;Boot代码段起始偏移
;======================================================================
;				内核
;======================================================================
kernel_code_enter	equ 0x10          ;内核入口(相对于内核头的偏移)
kernel_base_address 	equ 0x0004_0000   ;内核加载到256KB处
kernel_base_sector  	equ 0x0000_0002   ;内核位于逻辑扇区二

kernel_head_data_offset equ 0x00          ;内核头数据段偏移的位置
kernel_head_code_offset equ 0x04          ;内核头代码段偏移的位置
kernel_head_API_offset  equ 0x08          ;内核头API段偏移的位置
kernel_head_size_offset equ 0x0C          ;内核头尺寸偏移的位置
kernel_head_enter_offset equ 0x10         ;内核头入口的偏移
;======================================================================
;				用户程序
;======================================================================
up_start	equ 0x14		  ;用户程序入口
up_0		equ 50			  ;用户程序0位于硬盘逻辑扇区50
up_1		equ 100			  ;用户程序1位于硬盘逻辑扇区100
up_2		equ 200			  ;用户程序2位于硬盘逻辑扇区200
user_mem_start  equ 0x0000_0000           ;用户任务局部空间的分配从0开始
user_head_head_offset   equ 0x00          ;用户头部段相对偏移      
user_head_data_offset   equ 0x04
user_head_code_offset   equ 0x08
user_head_size_offset   equ 0x0C
user_head_stack_offset  equ 0x10
user_head_enter_offset  equ 0x14
user_head_salt_items_offset equ 0x1A
user_head_salt_offset       equ 0x1E 
;======================================================================
;				任务的TCB
;======================================================================
TCB_SIZE        equ 0x20                  ;TCB的尺寸

TCB_next	equ 0x00		  ;下一个TCB的地址
TCB_task_status equ 0x04		  ;任务状态
TCB_prog_addr   equ 0x06		  ;下一个可用的线性地址

TCB_LDT_limit   equ 0x0A	          ;LDT的段界限
TCB_LDT_addr    equ 0x0C                  ;LDT的线性地址
TCB_LDT_sel     equ 0x10                  ;LDT的选择器

TCB_TSS_limit   equ 0x12                  ;TSS的段界限
TCB_TSS_addr    equ 0x14                  ;TSS的线性地址
TCB_TSS_sel     equ 0x18                  ;TSS的选择器
;======================================================================
;				任务的LDT
;======================================================================
user_LDT_size equ 0x200			 ;任务LDT的尺寸
user_LDT_Des  equ 0x8200		 ;LDT段的描述符属性
;=======================================================================
;				调用门
;=======================================================================
kernel_gate_DPL3_para_0	equ 0xEC00
kernel_gate_DPL3_para_1 equ 0xEC01
kernel_gate_DPL3_para_2 equ 0xEC02
kernel_gate_DPL3_para_3 equ 0xEC03
kernel_gate_stack_size  equ 0x02 ;用于堆栈切换的堆栈尺寸(以4KB为单位)
;=======================================================================
;				TSS
;=======================================================================
TSS_SIZE equ 0x68			;基本的TSS尺寸
TSS_PREV equ 0x00			;前一个TSS的指针
TSS_ESP0 equ 0x04			;用于堆栈切换的0级特权栈栈顶指针
TSS_SS0  equ 0x08			;用于堆栈切换的0级特权栈段选择器
TSS_ESP1 equ 0x0C			;用于堆栈切换的1级特权栈栈顶指针
TSS_SS1  equ 0x10			;用于堆栈切换的1级特权栈段选择器
TSS_ESP2 equ 0x14			;用于堆栈切换的2级特权栈栈顶指针
TSS_SS2  equ 0x18			;用于堆栈切换的2级特权栈段选择器
TSS_CR3  equ 0x1C			;寄存器快照CR3
TSS_EIP  equ 0x20			;寄存器快照EIP
TSS_EFLAGES equ 0x24			;寄存器快照EFLAGES
TSS_EAX equ 0x28			;寄存器快照EAX
TSS_ECX equ 0x2C			;寄存器快照ECX
TSS_EDX equ 0x30			;寄存器快照EDX
TSS_EBX equ 0x34			;寄存器快照EBX
TSS_ESP equ 0x38			;寄存器快照ESP
TSS_EBP equ 0x3C			;寄存器快照EBP
TSS_ESI equ 0x40			;寄存器快照ESI
TSS_EDI equ 0x44			;寄存器快照EDI
TSS_ES  equ 0x48			;寄存器快照ES
TSS_CS  equ 0x4C			;寄存器快照CS
TSS_SS  equ 0x50			;寄存器快照SS
TSS_DS  equ 0x54			;寄存器快照DS
TSS_FS  equ 0x58			;寄存器快照FS
TSS_GS  equ 0x5C			;寄存器快照GS
TSS_LDT_selector equ 0x60		;LDT选择器
TSS_IO_MAP equ 0x64			;IO映射偏移
TSS_descriptor equ 0x8900		;DPL = 0 B = 0 P = 1 G = 0
;===================================================================
;                               分页机制
;===================================================================
PDT_addr        equ 0x0002_0000         ;页目录表的物理地址
;===================================================================
;                               内存分配
;===================================================================
;7C00 ~ 7DFF 共512字节为BootLoader所有
;7E00 ~ 7FFF 共512字节为GDT所有
;8000 ~ 81FF 共512字节为Boot所有

;0x0004_0000                    内核位置
;0x0010_0000 ~ 0x001F_FFFF      用户内存区域 
;EOF
