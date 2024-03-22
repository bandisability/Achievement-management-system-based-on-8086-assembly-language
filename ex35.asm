;版权所有：肖健成

; 成绩管理系统，功能包括录用，查询，排序，和统计。
ASSUME CS:CODES,DS:DATAS,SS:stacksg
datas segment
	; 菜单部分，
	main_menu DB '-----------------------------------------------------------------------------',0DH,0AH
		DB '| FUNCTION1:INPUT ID(0000),NAMES(xxxx),HOMEWORKGRADE(000)*16,BIGJOBGRADE(000)|',0DH,0AH   ; 输入
		DB '| FUNCTION2:ENTER ID TO INQUIRE GRADE                                        |',0DH,0AH   ; 根据id查询
		DB '| FUNCTION3:ENTER NAMES TO INQUIRE GRADE                                     |',0DH,0AH   ; 根据姓名查询
		DB '| FUNCTION4:GRADE SORTING                                                    |',0DH,0AH   ; 排序（排序后会显示所有的成绩）
		DB '| FUNCTION5:STATS GRADE                                                      |',0DH,0AH   ; 统计
		DB '| FUNCTION6:QUIT                                                             |',0DH,0AH
		DB '-----------------------------------------------------------------------------',0DH,0AH
		DB 'Please enter a number(1-6) to chose FUNCTION :$'
	; 菜单
	FUN DW FUNCTION1,FUNCTION2,FUNCTION3,FUNCTION4,FUNCTION5,FUNCTION6

	; 分段成绩
	;分段成绩函数4显示
    GRADE0_59 DB '  0-59:','$'
	GRADE60_79 DB ' 60-79:','$'
	GRADE80_89 DB ' 80-89:','$'
	GRADE90_100 DB '90-100:','$'
	GRADE_COUNT db 0,0,0,0       ; 各个分数段的人数
	; 最高分，最低分，和平均分
	GRADE_MAX_HEADER db 'MAX:$'
	GRADE_MIN_HEADER db 'MIN:$'
	GRADE_AVG_HEADER db 'AVG:$'


	; 数据部分，每一个的学生成绩是按照如下的格式依次排列的
	; id（4个字节+1）name（4个字节+1），平时成绩（16*1个字节），大作业成绩（1个字节），总成绩（1个字节） ,每个学生5+5+16+1+1=26个字节。
	student_length =  28                       ; 每一个学生是占用26个字节
	student_length_value db student_length     
	student_data db student_length*50 dup(0)   ;  上限50
	student_count db 0                         ;  学生数量
	FUNCTION1buf db 80,80 dup(0)               ; 输入的缓冲区
	inquire_key db 5,6 dup(0)                  ; 查询的缓冲区
	ranking     db 0                           
	ten db 10                                  ; 常量


	; 错误信息
	FUNCTION1_bad_format_message db 'FUNCTION1 bad format $', 0DH,0AH
datas ends   ; 
;版权所有：肖健成
;----------------------------------------------------------------------------------
stacksg segment stack
    dw   128  dup(0)   ;安全栈段
stacksg ends

; 如下是宏函数，proc定义的过程或者子函数

OUT_STRING MACRO Y
	;用于输出字符串
	push ax
	push dx
	LEA DX,Y
	MOV AH,9H
	INT 21H
	pop dx
	pop ax
ENDM
;----------------------------------------------------------------------------------
codes segment     

start:
	; 代码主体部分  
  	; 将栈的位置存入寄存器
  	mov ax, stacksg
    mov ss, ax
    mov sp, 128
  ; 将数据的位置存入寄存器
    mov ax, datas
    mov ds, ax
    mov es, ax

	print_main_menu:
		; 打印菜单
		OUT_STRING main_menu
		; 这里要选择哪个功能
		MOV AH,01H
    	INT 21H;调用中断 21H，等待用户输入选项（1-6），并将输入的字符存储在寄存器 AL中。
		SUB AL,30H;将寄存器 AL 中的值减去30H，将字符转换为对应的数字值。
	
		;比较寄存器 AL 中的值与0,6;检查是否小于0或大于6（异常值）。
		CMP AL,0;
		JB print_main_menu
		CMP AL,6
		JA print_main_menu
		; 减去1
		dec al
		; 乘以2
		SHL AL,1
		mov ah, 0         ; 高位置零
		mov  bx, ax       ; 放到偏移寄存器
		call COUTENTER    ; 先换行
		call fun[bx]      ; 跳转到相关的菜单处理
		jmp print_main_menu   ;写成永真循环，除非调用函数6否则一直执行
  
;版权所有：肖健成
COUTENTER PROC
  PUSH AX;保护AX，DX
  PUSH DX
   ;回车换行
    MOV AH,02H
  MOV DL,0DH
  INT 21H
  MOV AH,02H
  MOV DL,0AH;将换行符的0AH存入寄存器DL中
  INT 21H
  POP DX
  POP AX
  RET
COUTENTER ENDP

print_comma proc
	; 打印一个逗号
	push ax
	push dx
	mov ah, 02H
	mov dl , ','
	int 21H
	pop dx 
	pop ax
	ret
print_comma endp

print_sapce proc
	; 打印空格，在调用这个函数时的cx为循环数
	push ax
	push dx
	print_sapce_loop:
		mov ah, 02H
		mov dl , ' '
		int 21H
		loop print_sapce_loop
	pop dx 
	pop ax
	ret
print_sapce endp
;版权所有：肖健成
print8 proc
	; 打印一个字节的数字，输入是ax
    push ax 
    push bx
    push cx
    push dx
    ; 这里要打印这个数字
    ; 首先从低位开始，一个一个的压入堆栈，最后从堆栈中打印
    mov cx , 0 ; 这个当作计数，这个数字有多少位
    mov bl , 10 ; 被除数。
    print1:
        mov ah , 0  ; ax 的高位置零，原先是余数。
        ; 这里每一次都除以10,ax/bl=余数存放在AH, 商存放在AL中，然后将余数放到堆栈中
        div bl
        ; 堆栈是保存16位的，这里先将余数放在dx中，    
        mov dx , 0
        mov dl , ah 
        push dx 
        ; 数字位数计数
        inc cx 
        ; 当商为0表示结束。
        cmp al , 0 
        jne print1
    ; 这里表示取得了所有的数字了，然后进行打印
	mov bx , cx    ; 保存多少位数字
    print2:
        ; 依旧是循环，cx的值在上一步计算出来了。
        ; 每次打印一个数字，因为堆栈的性质，这里第一个打印的是数字的最高位。
        pop dx ; 弹出一个
        add dl , '0' ;要将数字转换为ASCII码，我们可以将该数字加上字符'0'的ASCII码值。
        mov ah , 02H
        int 21H
        loop print2
	
	mov ax , 3 ;  最多3位数
	sub ax , bx  ; 需要多少个空格
	cmp ax , 0
	je print8_ret ; 不需要空格
		mov cx , ax ; 
		call print_sapce
	print8_ret:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
print8 endp

swap_student proc
	; 交换2个学生的位置，参数，si和di，分别指向两个学生的信息
	push si
	push di
	push ax
	push cx 
	mov cx , student_length    ; 交换这么多位
	swap_student_loop:	
		; 这里开始
		mov al , byte ptr [si]
		mov ah , byte ptr [di]
		mov byte ptr [si], ah
		mov byte ptr [di], al
		inc si
		inc di
		loop swap_student_loop
	pop cx
	pop ax
	pop di
	pop si 
	ret
swap_student endp

getlength proc
	; 取得长度，返回值在al中。
	push si    ; 保存堆栈
	mov al , 0 ; 先清空，作为结果保存
	getlength1:
		mov ah, byte ptr [si]
		cmp ah , ' ' ; 如果是空格
		je getlengthret  ; 如果是空格就退出
		cmp ah, 0dh;     ; 换行
		je  getlengthret
		; 下一个
		inc al
		inc si
		jmp getlength1
	getlengthret:
		pop si
		ret
getlength endp
;版权所有：肖健成

print_student proc
	; 这里是打印每一个同学的信息，参数bx，基址
	push ax 
	push cx
	push si
	mov si , 0           ; 这里用基址变址方式读取
	call print_id_name   ; 打印id
	mov si , 5
	call print_id_name   ; 打印姓名 
	; 打印平时分数了
	mov si , 10          ; 地址
	mov cx , 16          ; 计数
	print_student_home:
		mov al, byte ptr [bx+si] ; 取得一个成绩
		call print8              ; 打印
		inc si                   ; 下一个
		loop print_student_home  ; 循环
	; 打印大作业成绩
	mov si , 10+16               ; 
	mov al, byte ptr [bx+si] ; 取得大作业成绩
	call print8              ; 打印
	; 打印总成绩
	mov si , 10+16+1         ; 
	mov al, byte ptr [bx+si] ; 取得总成绩
	call print8              ; 打印
	pop si
	pop cx
	pop ax
	ret
print_student endp
;版权所有：肖健成
print_id_name proc
	; 打印id或者名称
	push ax
	push cx
	push dx
	push si
	mov cx , 0    ; 打印了多少个
	print_id_name_loop:
		; 循环
		mov dl, byte ptr [bx+si] ; 取得一个
		cmp dl , 0 ;我们以0作为分隔符
		je print_id_name_space   ; 这里表示结束
		mov ah , 02H
		int 21h   ; 打印一个字符
		inc si    ; 下一个
		inc cx    
		jmp print_id_name_loop ; 直接跳转到开头

	print_id_name_space:
		; 这里打印空格
		mov ax , 5     ; 姓名与学号均占用5位。
		sub ax , cx    ; 取得要打印的空格数量
		cmp ax , 0
		je print_id_name_ret ; 等于0不需要打印
		mov cx , ax 
		call print_sapce     ; 打印空格

	print_id_name_ret:
		pop si
		pop dx
		pop cx
		pop ax
		ret
print_id_name ENDP


clear_GRADE_COUNT proc
	; 清空GRADE_COUNT,
	push ax
	push cx
	push si
	mov al, 0
	mov cx , 4
	lea si , GRADE_COUNT
	clear_GRADE_COUNT_loop:
		mov byte ptr [si], al
		inc si
		loop clear_GRADE_COUNT_loop
	pop si
	pop cx
	pop ax
	ret
clear_GRADE_COUNT endp
;版权所有：肖健成
FUNCTION5_dengji proc
	; 功能5中的等级分层。

; 统计，分两大部分，第一部分是统计，第二部分是显示
	; 这里首先清空
	call clear_GRADE_COUNT
	; ----- 统计部分
	mov cx , 0
	mov cl , student_count  ; 学生个数
	cmp cl , 0
	je FUNCTION5_show       ; 没有学生就直接显示
	; 这里开始统计
	lea si , student_data ;
	add si , 5+5+16+1       ; 统计的是总成绩
	lea di , GRADE_COUNT    ; 等级
	FUNCTION5_stats:
		mov al, byte ptr [si]  ; 取得成绩
		cmp al , 90
		jb FUNCTION5_stats_2   ; 小于90跳转
			mov al, byte ptr [di+3]
			inc al
			mov byte ptr [di+3] , al ; +1
			jmp FUNCTION5_stats_next
	FUNCTION5_stats_2:
		cmp al , 80
		jb FUNCTION5_stats_3   ; 小于80跳转
			mov al, byte ptr [di+2]
			inc al
			mov byte ptr [di+2] , al ; +1
			jmp FUNCTION5_stats_next
	FUNCTION5_stats_3:
		cmp al , 60
		jb FUNCTION5_stats_4   ; 小于60跳转
			mov al, byte ptr [di+1]
			inc al
			mov byte ptr [di+1] , al ; +1
			jmp FUNCTION5_stats_next
	FUNCTION5_stats_4:
		mov al, byte ptr [di+0]
		inc al
		mov byte ptr [di+0] , al ; +1
	FUNCTION5_stats_next:
		; 下一个学生
		add si , student_length
		loop FUNCTION5_stats


	; ------- 显示部分
	FUNCTION5_show:
		; 依次打印。
		OUT_STRING GRADE0_59  ; 
		mov al , byte ptr [di]   
		call print8
		call COUTENTER      
		OUT_STRING GRADE60_79  ; 
		mov al , byte ptr [di+1]  
		call print8 
		call COUTENTER  
		OUT_STRING GRADE80_89  ; 
		mov al , byte ptr [di+2]   
		call print8
		call COUTENTER  
		OUT_STRING GRADE90_100  ; 
		mov al , byte ptr [di+3]  
		call print8 
		call COUTENTER   

	ret

FUNCTION5_dengji endp
;版权所有：肖健成
FUNCTION5_min proc
	; 最低分
	; 首先显示
	OUT_STRING GRADE_MIN_HEADER
	; 然后统计
	;迭代比较求最低分
	mov al , 100   ; 默认最低是100
	lea si , student_data ;
	add si , 5+5+16+1       ; 统计的是总成绩
	mov cx , 0
	mov cl , student_count  ; 学生个数
	cmp cl , 0
	je FUNCTION5_min_0      ; 没有学生就跳转到这里
	FUNCTION5_min_loop:
		; 循环判断
		mov ah, byte ptr [si] ; 取得一个成绩
		cmp ah , al 
		jae FUNCTION5_min_next ; 大于等于就跳转
		; 找到一个更小的
		mov al, ah 
	FUNCTION5_min_next:
		add si , student_length
		loop FUNCTION5_min_loop  ; 循环
		jmp FUNCTION5_min_show   ; 跳转到显示。

	FUNCTION5_min_0:
		; 表示没有学生
		mov al , 0
	
	FUNCTION5_min_show:
		; 显示这个数字后回车
		call print8
		call COUTENTER
	
	FUNCTION5_min_ret:
		ret

FUNCTION5_min endp

;版权所有：肖健成
FUNCTION5_max proc
	; 最低分
	; 首先显示
	OUT_STRING GRADE_MAX_HEADER
	; 然后统计
	;迭代比较求最高分
	mov al , 0   ; 默认最低是0
	lea si , student_data ;
	add si , 5+5+16+1       ; 统计的是总成绩
	mov cx , 0
	mov cl , student_count  ; 学生个数
	cmp cl , 0
	je FUNCTION5_max_0      ; 没有学生就跳转到这里
	FUNCTION5_max_loop:
		; 循环判断
		mov ah, byte ptr [si] ; 取得一个成绩
		cmp ah , al 
		jbe FUNCTION5_max_next ; 小于等于就跳转
		; 找到一个更小的
		mov al, ah 
	FUNCTION5_max_next:
		add si , student_length
		loop FUNCTION5_max_loop  ; 循环
		jmp FUNCTION5_max_show   ; 跳转到显示。

	FUNCTION5_max_0:
		; 表示没有学生
		mov al , 0
	
	FUNCTION5_max_show:
		; 显示这个数字后回车
		call print8
		call COUTENTER
	
	FUNCTION5_max_ret:
		ret

FUNCTION5_max endp

FUNCTION5_avg proc
	OUT_STRING GRADE_AVG_HEADER
	; 然后统计，
	mov ax , 0   ; 总和
	lea si , student_data ;
	add si , 5+5+16+1       ; 统计的是总成绩
	mov cx , 0
	mov cl , student_count  ; 学生个数
	cmp cl , 0
	je FUNCTION5_avg_show      ; 没有学生就跳转到这里
	FUNCTION5_avg_loop:
		; 循环判断
		mov bx , 0
		mov bl , byte ptr [si] ; 取得分数
		add ax , bx            ; 计算和
		add si , student_length ; 下一个
		loop FUNCTION5_avg_loop ; 循环
	
	FUNCTION5_avg_show:
		; 显示这个数字后回车
		; 这里计算平均分
		mov cl , student_count
		div cl 
		call print8
		call COUTENTER
	
	FUNCTION5_avg_ret:
		ret

FUNCTION5_avg endp


;版权所有：肖健成
;----------------------------------------------------------------------------------
FUNCTION1 proc
	; 这里会输入
	lea dx, FUNCTION1buf
	mov ah, 0Ah
	int 21H
	call COUTENTER
	lea bx, student_data     ; 目标地址。
	mov al, student_count
	mul student_length_value ; 相乘
	add bx , ax               ; 
	lea si , FUNCTION1buf    ; 
	add si , 2               ; 用户真正的输入地址
	; 这里开始解析
	; 总体上分解成4部分，解析id，解析姓名，解析平时作业成绩，解析大作业成绩
	; 要判断id和姓名最多只有4个字符。
	; ------------------- 解析id
	mov di , bx             ; 目标串地址，movsb用到
	call getlength
	cmp al,  0
	jne FUNCTION1_jmp_1  ; 没有的话，错误
	jmp FUNCTION1_bad_format ; 长跳转
	FUNCTION1_jmp_1:
	cmp al , 4
	jbe FUNCTION1_jmp_2      ; 大于4也是跳转
	jmp FUNCTION1_bad_format ; 长跳转
	FUNCTION1_jmp_2:
	mov ah, 0               ; 高位置零
	mov cx , ax             ; 这里进行字符串拷贝，cx是要拷贝的数量
	cld                     ; 则是清方向标志位，也就是使DF值为0，在执行串操作时，使地址按递增的方式变化
	rep movsb               ; si往di的拷贝
	mov byte ptr [di], 0   ; 最后添加一个0
	; 判断最后一位是否空格
	mov cl , byte ptr [si]        
	cmp cl, ' ';    
	je FUNCTION1_jmp_3 ; 回车的话，也是格式错误
	jmp FUNCTION1_bad_format ; 长跳转
	FUNCTION1_jmp_3:
	; ------------------ 解析name
	inc si               ; 下一个数据
	mov di , bx             ; 目标串地址，movsb用到
	add di , 5              ; name是往这里边拷贝。
	; 下边是拷贝上边id的
	call getlength
	cmp al,  0
	jne FUNCTION1_jmp_4      ; 没有的话，错误
	jmp FUNCTION1_bad_format ; 长跳转
	FUNCTION1_jmp_4:
	cmp al , 4
	jbe FUNCTION1_jmp_5      ; 大于4也是跳转
	jmp FUNCTION1_bad_format ; 长跳转
	FUNCTION1_jmp_5:
	mov ah, 0               ; 高位置零
	mov cx , ax             ; 这里进行字符串拷贝，cx是要拷贝的数量
	cld                     ; 清方向标志位，也就是使DF值为0，在执行串操作时，使地址按递增的方式变化
	rep movsb               ; si往di的拷贝
	mov byte ptr [di], 0   ; 最后添加一个0
	; 判断最后一位是否空格
	mov cl , byte ptr [si]        
	cmp cl, ' ';    
	je FUNCTION1_jmp_6       ; 回车的话，也是格式错误
	jmp FUNCTION1_bad_format ; 长跳转
	FUNCTION1_jmp_6:
	; -------------------- 解析平时作业，这里要处理16次
	inc si                  ;下一个
	mov cx , 16             ; 循环处理
	mov di , bx             ; 
	add di , 10             ; 每一个数字都往这里边发送
	FUNCTION1_home:
		; 处理家庭作业的。
		call getlength
		mov ah,  0
		cmp al,  0
		ja FUNCTION1_jmp_7 ;    没有的话，错误
		jmp FUNCTION1_bad_format ; 长跳转
		FUNCTION1_jmp_7:
		cmp al , 3
		jbe FUNCTION1_jmp_8 ; 大于3也是跳转
		jmp FUNCTION1_bad_format ; 长跳转
		FUNCTION1_jmp_8:
		; 这里将文本转成数字
		push cx                   ; 保存原先的
		mov cx , ax               ; 多少位数字
		mov ax , 0
		FUNCTION1_home_string_to_num:
			mul ten    ; al*10=ax ，放在ax中
			mov dx, 0
			mov dl, byte ptr [si] ; 取得一个
			sub dl , '0'          ; 字符转数字
			add ax, dx            ; 加上去
			inc si                ; 下一个字符
			loop  FUNCTION1_home_string_to_num ; 前面cx中已经存位数了
		; 这里意味着已经得到了相应的数字
		; 这里判断一下是否大于100
		cmp al , 100
		ja FUNCTION1_home_string_to_num_err
		; 这里要判断是否是空格
		mov cl , byte ptr [si]        
		cmp cl, ' ';    
		jne FUNCTION1_home_string_to_num_err
		; 保存
		inc si                    ; 下一个
		mov byte ptr [di], al     ; 保存平均成绩
		inc di                    ; 下一个平均成绩
		pop cx                    ; 弹出堆栈
		loop FUNCTION1_home       ; 判断循环是否结束
		jmp FUNCTION1_big         ; 下一个是大作业。

		FUNCTION1_home_string_to_num_err:
			pop cx  
			jmp FUNCTION1_bad_format

	FUNCTION1_big:
		call getlength
		mov ah,  0
		cmp al,  0
		je FUNCTION1_bad_format ; 没有的话，错误
		cmp al , 3
		ja FUNCTION1_bad_format ; 大于3也是跳转
		; 这里将文本转成数字
		push cx                   ; 保存原先的
		mov cx , ax               ; 多少位数字
		mov ax , 0
		FUNCTION1_big_string_to_num:
			mul ten    ; al*10=ax ，放在ax中
			mov dx, 0
			mov dl, byte ptr [si] ; 取得一个
			sub dl , '0'          ; 字符转数字
			add ax, dx            ; 加上去
			inc si                ; 下一个字符
			loop  FUNCTION1_big_string_to_num ; 前面cx中已经存位数了
		; 这里判断一下是否大于100
		cmp al , 100
		ja FUNCTION1_big_string_to_num_err
		; 这里是保存
		mov byte ptr [di], al     ; 
	
	FUNCTION1_total:   ; 总成绩
		mov cx , 16    ; 16个平时成绩
		mov di , bx             ; 
		add di , 10             ; 每一个数字都往这里边发送
		mov ax , 0              ; 和
		FUNCTION1_total_2:
			mov dx , 0
			mov dl , byte ptr [di] ; 取得一个成绩
			add ax , dx            ; 相加
			inc di                 ; 下一个
			loop FUNCTION1_total_2 ; 循环
		mov dl , 16                
		div dl                     ; 平均 ax/dl= 商放在al中，余数放在ah中
		mov ah , 0
		; 然后40%，也就是先乘以40，再除以100
		mov dl , 40
		mul dl       ; al*dl=ax 中
		mov dl , 100 ; 商放在al中
		div dl 
		mov ah , 0
		push ax      ; 平时成绩
		mov al  , byte ptr [di] ; 这里存放的是大作业成绩
		; 大作业60%
		mov dl , 60
		mul dl 
		mov dl , 100
		div dl 
		mov ah , 0
		pop dx 
		add ax, dx    ; 这里是总成绩
		inc di        ; 最后的是总成绩
		mov byte ptr[di]  , al 

		; 学生个数+1
		mov al, student_count
		inc al 
		mov student_count, al 
		jmp FUNCTION1ret


	FUNCTION1_big_string_to_num_err:
			pop cx  ; 需要堆栈平衡。
			jmp FUNCTION1_bad_format

	FUNCTION1_bad_format:
		; 格式错误
		OUT_STRING FUNCTION1_bad_format_message
		jmp FUNCTION1ret

	FUNCTION1ret:
		; 结束		
		ret
FUNCTION1 endp
;----------------------------------------------------------------------------------
FUNCTION2 proc
	; 根据id查询, 
	; 思路是，顺序判断每一个
	; 这里首先要输入信息。
	lea dx, inquire_key
	mov ah, 0Ah
	int 21H
	call COUTENTER         ; 先一个回车

	lea bx , student_data  ; 以这个为基址
	mov cx , 0
	mov cl , student_count ; 学生数量作为循环
	cmp cl , 0
	je FUNCTION2ret        ; 没有学生就不查询
	FUNCTION2_loop:
		lea si , inquire_key   ; 用户输入的缓冲区
		inc si                 ; 指向实际驶入的个数
		mov al, byte ptr [si]  ; 取得实际输入的个数
		inc si                 ; 用户实际输入的
		cmp al, 0
		je FUNCTION2ret        ; 如果用户没有输入，就直接返回
		push cx      ; 保存原先的
		mov ah , 0
		mov cx , ax  ; 用户输入的个数作为计数
		mov di , bx  ; 
		add di , 0   ; 这里是保存的数据
		repe cmpsb   ; 比较
		jnz FUNCTION2_next  ; 不等于0就是下一个
			mov al , byte ptr [di]
			cmp al , 0
			jne FUNCTION2_next
			pop cx              ; 堆栈平衡
			call print_student  ; 打印这个同学信息
			call COUTENTER      ; 换行
			jmp FUNCTION2ret    ; 跳转到结束

		FUNCTION2_next:
			; 下一个
			pop cx                   ; 堆栈平衡
			add bx , student_length  ; 下一个学生
			loop FUNCTION2_loop      ; 循环

	FUNCTION2ret:
	ret
FUNCTION2 endp
;版权所有：肖健成
;----------------------------------------------------------------------------------
FUNCTION3 proc
	; 根据name查询, 
	; 思路是，顺序判断每一个
	; 这里首先要输入信息。
	lea dx, inquire_key
	mov ah, 0Ah
	int 21H
	call COUTENTER         ; 先一个回车

	lea bx , student_data  ; 以这个为基址
	mov cx , 0
	mov cl , student_count ; 学生数量作为循环
	cmp cl , 0
	je FUNCTION3ret        ; 没有学生就不查询
	FUNCTION3_loop:
		lea si , inquire_key   ; 用户输入的缓冲区
		inc si                 ; 指向实际驶入的个数
		mov al, byte ptr [si]  ; 取得实际输入的个数
		inc si                 ; 用户实际输入的
		cmp al, 0
		je FUNCTION3ret        ; 如果用户没有输入，就直接返回
		push cx      ; 保存原先的
		mov ah , 0
		mov cx , ax  ; 用户输入的个数作为计数
		mov di , bx  ; 
		add di , 5   ; 这里是保存的数据
		repe cmpsb   ; 比较
		jnz FUNCTION3_next  ; 不等于0就是下一个
			mov al , byte ptr [di]
			cmp al , 0
			jne FUNCTION2_next
			pop cx              ; 堆栈平衡
			call print_student  ; 打印这个同学信息
			call COUTENTER      ; 换行
			jmp FUNCTION3ret    ; 跳转到结束

		FUNCTION3_next:
			; 下一个
			pop cx                   ; 堆栈平衡
			add bx , student_length  ; 下一个学生
			loop FUNCTION3_loop      ; 循环

	FUNCTION3ret:
	ret
FUNCTION3 endp
;----------------------------------------------------------------------------------
FUNCTION4 proc
	; 这个是分成两大部分，第一部分是排序，第二部分是显示
	mov al , student_count
	cmp al , 0
	je FUNCTION4_ret ; 没有的话就直接跳转
	; ---------排序部分
	cmp al , 1         ; 如果只有一个，就直接显示
	je FUNCTION4_show
	; 这里开始排序，用冒泡排序
	lea si , student_data  
	mov ah , 0   
	mov cx , ax   ; 计数
	dec cx        ; 减去1
	FUNCTION4_loop1:;使用经典的冒泡排序
		push cx     ; 保存原先的
		lea si , student_data
		FUNCTION4_loop2:
			mov al, byte ptr [si+5+5+16+1]                 ; 取得总成绩
			cmp al , byte ptr [si+5+5+16+1+student_length] ; 这两个比较2个同学的分数
			jle FUNCTION4_loop2_next                       ; 小于等于就下一个同学
				mov di , si
				add di , student_length 
				call swap_student   ; 这里是交换2个学生的位置

			FUNCTION4_loop2_next:
				add si , student_length   ; 下一次循环
				loop FUNCTION4_loop2      ; 
			pop cx                        ; 内层循环结束，就
			loop FUNCTION4_loop1          ; 外层循环
	
	; --------- 显示部分
	FUNCTION4_show:
		mov al , student_count
		mov ah , 0
		mov cx , ax            ; 这里作为计数
		lea bx , student_data  ; 基地址
		FUNCTION4_show_loop:
			; 首先输出名次
			mov ax , 0
			mov ax , cx 
			call print8      ; 打印名次
			call print_comma ; 一个逗号
			; 然后打印这个学生的信息
			call print_student
			call COUTENTER  ; 回车
			add bx , student_length   ; 下一个学生
			loop FUNCTION4_show_loop


	FUNCTION4_ret:
	ret
FUNCTION4 endp

;版权所有：肖健成
;----------------------------------------------------------------------------------

FUNCTION5 proc
	; 依次调用
	call FUNCTION5_dengji
	call FUNCTION5_min
	call FUNCTION5_max
	call FUNCTION5_avg

	ret
	
FUNCTION5 endp

;版权所有：肖健成
;----------------------------------------------------------------------------------

FUNCTION6 proc
	; 退出
	mov ax, 4c00h 
    int 21h 
	ret
FUNCTION6 endp

    
codes ends

end start ;结束


;版权所有：肖健成