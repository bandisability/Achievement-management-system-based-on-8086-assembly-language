;��Ȩ���У�Ф����

; �ɼ�����ϵͳ�����ܰ���¼�ã���ѯ�����򣬺�ͳ�ơ�
ASSUME CS:CODES,DS:DATAS,SS:stacksg
datas segment
	; �˵����֣�
	main_menu DB '-----------------------------------------------------------------------------',0DH,0AH
		DB '| FUNCTION1:INPUT ID(0000),NAMES(xxxx),HOMEWORKGRADE(000)*16,BIGJOBGRADE(000)|',0DH,0AH   ; ����
		DB '| FUNCTION2:ENTER ID TO INQUIRE GRADE                                        |',0DH,0AH   ; ����id��ѯ
		DB '| FUNCTION3:ENTER NAMES TO INQUIRE GRADE                                     |',0DH,0AH   ; ����������ѯ
		DB '| FUNCTION4:GRADE SORTING                                                    |',0DH,0AH   ; ������������ʾ���еĳɼ���
		DB '| FUNCTION5:STATS GRADE                                                      |',0DH,0AH   ; ͳ��
		DB '| FUNCTION6:QUIT                                                             |',0DH,0AH
		DB '-----------------------------------------------------------------------------',0DH,0AH
		DB 'Please enter a number(1-6) to chose FUNCTION :$'
	; �˵�
	FUN DW FUNCTION1,FUNCTION2,FUNCTION3,FUNCTION4,FUNCTION5,FUNCTION6

	; �ֶγɼ�
	;�ֶγɼ�����4��ʾ
    GRADE0_59 DB '  0-59:','$'
	GRADE60_79 DB ' 60-79:','$'
	GRADE80_89 DB ' 80-89:','$'
	GRADE90_100 DB '90-100:','$'
	GRADE_COUNT db 0,0,0,0       ; ���������ε�����
	; ��߷֣���ͷ֣���ƽ����
	GRADE_MAX_HEADER db 'MAX:$'
	GRADE_MIN_HEADER db 'MIN:$'
	GRADE_AVG_HEADER db 'AVG:$'


	; ���ݲ��֣�ÿһ����ѧ���ɼ��ǰ������µĸ�ʽ�������е�
	; id��4���ֽ�+1��name��4���ֽ�+1����ƽʱ�ɼ���16*1���ֽڣ�������ҵ�ɼ���1���ֽڣ����ܳɼ���1���ֽڣ� ,ÿ��ѧ��5+5+16+1+1=26���ֽڡ�
	student_length =  28                       ; ÿһ��ѧ����ռ��26���ֽ�
	student_length_value db student_length     
	student_data db student_length*50 dup(0)   ;  ����50
	student_count db 0                         ;  ѧ������
	FUNCTION1buf db 80,80 dup(0)               ; ����Ļ�����
	inquire_key db 5,6 dup(0)                  ; ��ѯ�Ļ�����
	ranking     db 0                           
	ten db 10                                  ; ����


	; ������Ϣ
	FUNCTION1_bad_format_message db 'FUNCTION1 bad format $', 0DH,0AH
datas ends   ; 
;��Ȩ���У�Ф����
;----------------------------------------------------------------------------------
stacksg segment stack
    dw   128  dup(0)   ;��ȫջ��
stacksg ends

; �����Ǻ꺯����proc����Ĺ��̻����Ӻ���

OUT_STRING MACRO Y
	;��������ַ���
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
	; �������岿��  
  	; ��ջ��λ�ô���Ĵ���
  	mov ax, stacksg
    mov ss, ax
    mov sp, 128
  ; �����ݵ�λ�ô���Ĵ���
    mov ax, datas
    mov ds, ax
    mov es, ax

	print_main_menu:
		; ��ӡ�˵�
		OUT_STRING main_menu
		; ����Ҫѡ���ĸ�����
		MOV AH,01H
    	INT 21H;�����ж� 21H���ȴ��û�����ѡ�1-6��������������ַ��洢�ڼĴ��� AL�С�
		SUB AL,30H;���Ĵ��� AL �е�ֵ��ȥ30H�����ַ�ת��Ϊ��Ӧ������ֵ��
	
		;�ȽϼĴ��� AL �е�ֵ��0,6;����Ƿ�С��0�����6���쳣ֵ����
		CMP AL,0;
		JB print_main_menu
		CMP AL,6
		JA print_main_menu
		; ��ȥ1
		dec al
		; ����2
		SHL AL,1
		mov ah, 0         ; ��λ����
		mov  bx, ax       ; �ŵ�ƫ�ƼĴ���
		call COUTENTER    ; �Ȼ���
		call fun[bx]      ; ��ת����صĲ˵�����
		jmp print_main_menu   ;д������ѭ�������ǵ��ú���6����һֱִ��
  
;��Ȩ���У�Ф����
COUTENTER PROC
  PUSH AX;����AX��DX
  PUSH DX
   ;�س�����
    MOV AH,02H
  MOV DL,0DH
  INT 21H
  MOV AH,02H
  MOV DL,0AH;�����з���0AH����Ĵ���DL��
  INT 21H
  POP DX
  POP AX
  RET
COUTENTER ENDP

print_comma proc
	; ��ӡһ������
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
	; ��ӡ�ո��ڵ����������ʱ��cxΪѭ����
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
;��Ȩ���У�Ф����
print8 proc
	; ��ӡһ���ֽڵ����֣�������ax
    push ax 
    push bx
    push cx
    push dx
    ; ����Ҫ��ӡ�������
    ; ���ȴӵ�λ��ʼ��һ��һ����ѹ���ջ�����Ӷ�ջ�д�ӡ
    mov cx , 0 ; ���������������������ж���λ
    mov bl , 10 ; ��������
    print1:
        mov ah , 0  ; ax �ĸ�λ���㣬ԭ����������
        ; ����ÿһ�ζ�����10,ax/bl=���������AH, �̴����AL�У�Ȼ�������ŵ���ջ��
        div bl
        ; ��ջ�Ǳ���16λ�ģ������Ƚ���������dx�У�    
        mov dx , 0
        mov dl , ah 
        push dx 
        ; ����λ������
        inc cx 
        ; ����Ϊ0��ʾ������
        cmp al , 0 
        jne print1
    ; �����ʾȡ�������е������ˣ�Ȼ����д�ӡ
	mov bx , cx    ; �������λ����
    print2:
        ; ������ѭ����cx��ֵ����һ����������ˡ�
        ; ÿ�δ�ӡһ�����֣���Ϊ��ջ�����ʣ������һ����ӡ�������ֵ����λ��
        pop dx ; ����һ��
        add dl , '0' ;Ҫ������ת��ΪASCII�룬���ǿ��Խ������ּ����ַ�'0'��ASCII��ֵ��
        mov ah , 02H
        int 21H
        loop print2
	
	mov ax , 3 ;  ���3λ��
	sub ax , bx  ; ��Ҫ���ٸ��ո�
	cmp ax , 0
	je print8_ret ; ����Ҫ�ո�
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
	; ����2��ѧ����λ�ã�������si��di���ֱ�ָ������ѧ������Ϣ
	push si
	push di
	push ax
	push cx 
	mov cx , student_length    ; ������ô��λ
	swap_student_loop:	
		; ���￪ʼ
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
	; ȡ�ó��ȣ�����ֵ��al�С�
	push si    ; �����ջ
	mov al , 0 ; ����գ���Ϊ�������
	getlength1:
		mov ah, byte ptr [si]
		cmp ah , ' ' ; ����ǿո�
		je getlengthret  ; ����ǿո���˳�
		cmp ah, 0dh;     ; ����
		je  getlengthret
		; ��һ��
		inc al
		inc si
		jmp getlength1
	getlengthret:
		pop si
		ret
getlength endp
;��Ȩ���У�Ф����

print_student proc
	; �����Ǵ�ӡÿһ��ͬѧ����Ϣ������bx����ַ
	push ax 
	push cx
	push si
	mov si , 0           ; �����û�ַ��ַ��ʽ��ȡ
	call print_id_name   ; ��ӡid
	mov si , 5
	call print_id_name   ; ��ӡ���� 
	; ��ӡƽʱ������
	mov si , 10          ; ��ַ
	mov cx , 16          ; ����
	print_student_home:
		mov al, byte ptr [bx+si] ; ȡ��һ���ɼ�
		call print8              ; ��ӡ
		inc si                   ; ��һ��
		loop print_student_home  ; ѭ��
	; ��ӡ����ҵ�ɼ�
	mov si , 10+16               ; 
	mov al, byte ptr [bx+si] ; ȡ�ô���ҵ�ɼ�
	call print8              ; ��ӡ
	; ��ӡ�ܳɼ�
	mov si , 10+16+1         ; 
	mov al, byte ptr [bx+si] ; ȡ���ܳɼ�
	call print8              ; ��ӡ
	pop si
	pop cx
	pop ax
	ret
print_student endp
;��Ȩ���У�Ф����
print_id_name proc
	; ��ӡid��������
	push ax
	push cx
	push dx
	push si
	mov cx , 0    ; ��ӡ�˶��ٸ�
	print_id_name_loop:
		; ѭ��
		mov dl, byte ptr [bx+si] ; ȡ��һ��
		cmp dl , 0 ;������0��Ϊ�ָ���
		je print_id_name_space   ; �����ʾ����
		mov ah , 02H
		int 21h   ; ��ӡһ���ַ�
		inc si    ; ��һ��
		inc cx    
		jmp print_id_name_loop ; ֱ����ת����ͷ

	print_id_name_space:
		; �����ӡ�ո�
		mov ax , 5     ; ������ѧ�ž�ռ��5λ��
		sub ax , cx    ; ȡ��Ҫ��ӡ�Ŀո�����
		cmp ax , 0
		je print_id_name_ret ; ����0����Ҫ��ӡ
		mov cx , ax 
		call print_sapce     ; ��ӡ�ո�

	print_id_name_ret:
		pop si
		pop dx
		pop cx
		pop ax
		ret
print_id_name ENDP


clear_GRADE_COUNT proc
	; ���GRADE_COUNT,
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
;��Ȩ���У�Ф����
FUNCTION5_dengji proc
	; ����5�еĵȼ��ֲ㡣

; ͳ�ƣ������󲿷֣���һ������ͳ�ƣ��ڶ���������ʾ
	; �����������
	call clear_GRADE_COUNT
	; ----- ͳ�Ʋ���
	mov cx , 0
	mov cl , student_count  ; ѧ������
	cmp cl , 0
	je FUNCTION5_show       ; û��ѧ����ֱ����ʾ
	; ���￪ʼͳ��
	lea si , student_data ;
	add si , 5+5+16+1       ; ͳ�Ƶ����ܳɼ�
	lea di , GRADE_COUNT    ; �ȼ�
	FUNCTION5_stats:
		mov al, byte ptr [si]  ; ȡ�óɼ�
		cmp al , 90
		jb FUNCTION5_stats_2   ; С��90��ת
			mov al, byte ptr [di+3]
			inc al
			mov byte ptr [di+3] , al ; +1
			jmp FUNCTION5_stats_next
	FUNCTION5_stats_2:
		cmp al , 80
		jb FUNCTION5_stats_3   ; С��80��ת
			mov al, byte ptr [di+2]
			inc al
			mov byte ptr [di+2] , al ; +1
			jmp FUNCTION5_stats_next
	FUNCTION5_stats_3:
		cmp al , 60
		jb FUNCTION5_stats_4   ; С��60��ת
			mov al, byte ptr [di+1]
			inc al
			mov byte ptr [di+1] , al ; +1
			jmp FUNCTION5_stats_next
	FUNCTION5_stats_4:
		mov al, byte ptr [di+0]
		inc al
		mov byte ptr [di+0] , al ; +1
	FUNCTION5_stats_next:
		; ��һ��ѧ��
		add si , student_length
		loop FUNCTION5_stats


	; ------- ��ʾ����
	FUNCTION5_show:
		; ���δ�ӡ��
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
;��Ȩ���У�Ф����
FUNCTION5_min proc
	; ��ͷ�
	; ������ʾ
	OUT_STRING GRADE_MIN_HEADER
	; Ȼ��ͳ��
	;�����Ƚ�����ͷ�
	mov al , 100   ; Ĭ�������100
	lea si , student_data ;
	add si , 5+5+16+1       ; ͳ�Ƶ����ܳɼ�
	mov cx , 0
	mov cl , student_count  ; ѧ������
	cmp cl , 0
	je FUNCTION5_min_0      ; û��ѧ������ת������
	FUNCTION5_min_loop:
		; ѭ���ж�
		mov ah, byte ptr [si] ; ȡ��һ���ɼ�
		cmp ah , al 
		jae FUNCTION5_min_next ; ���ڵ��ھ���ת
		; �ҵ�һ����С��
		mov al, ah 
	FUNCTION5_min_next:
		add si , student_length
		loop FUNCTION5_min_loop  ; ѭ��
		jmp FUNCTION5_min_show   ; ��ת����ʾ��

	FUNCTION5_min_0:
		; ��ʾû��ѧ��
		mov al , 0
	
	FUNCTION5_min_show:
		; ��ʾ������ֺ�س�
		call print8
		call COUTENTER
	
	FUNCTION5_min_ret:
		ret

FUNCTION5_min endp

;��Ȩ���У�Ф����
FUNCTION5_max proc
	; ��ͷ�
	; ������ʾ
	OUT_STRING GRADE_MAX_HEADER
	; Ȼ��ͳ��
	;�����Ƚ�����߷�
	mov al , 0   ; Ĭ�������0
	lea si , student_data ;
	add si , 5+5+16+1       ; ͳ�Ƶ����ܳɼ�
	mov cx , 0
	mov cl , student_count  ; ѧ������
	cmp cl , 0
	je FUNCTION5_max_0      ; û��ѧ������ת������
	FUNCTION5_max_loop:
		; ѭ���ж�
		mov ah, byte ptr [si] ; ȡ��һ���ɼ�
		cmp ah , al 
		jbe FUNCTION5_max_next ; С�ڵ��ھ���ת
		; �ҵ�һ����С��
		mov al, ah 
	FUNCTION5_max_next:
		add si , student_length
		loop FUNCTION5_max_loop  ; ѭ��
		jmp FUNCTION5_max_show   ; ��ת����ʾ��

	FUNCTION5_max_0:
		; ��ʾû��ѧ��
		mov al , 0
	
	FUNCTION5_max_show:
		; ��ʾ������ֺ�س�
		call print8
		call COUTENTER
	
	FUNCTION5_max_ret:
		ret

FUNCTION5_max endp

FUNCTION5_avg proc
	OUT_STRING GRADE_AVG_HEADER
	; Ȼ��ͳ�ƣ�
	mov ax , 0   ; �ܺ�
	lea si , student_data ;
	add si , 5+5+16+1       ; ͳ�Ƶ����ܳɼ�
	mov cx , 0
	mov cl , student_count  ; ѧ������
	cmp cl , 0
	je FUNCTION5_avg_show      ; û��ѧ������ת������
	FUNCTION5_avg_loop:
		; ѭ���ж�
		mov bx , 0
		mov bl , byte ptr [si] ; ȡ�÷���
		add ax , bx            ; �����
		add si , student_length ; ��һ��
		loop FUNCTION5_avg_loop ; ѭ��
	
	FUNCTION5_avg_show:
		; ��ʾ������ֺ�س�
		; �������ƽ����
		mov cl , student_count
		div cl 
		call print8
		call COUTENTER
	
	FUNCTION5_avg_ret:
		ret

FUNCTION5_avg endp


;��Ȩ���У�Ф����
;----------------------------------------------------------------------------------
FUNCTION1 proc
	; ���������
	lea dx, FUNCTION1buf
	mov ah, 0Ah
	int 21H
	call COUTENTER
	lea bx, student_data     ; Ŀ���ַ��
	mov al, student_count
	mul student_length_value ; ���
	add bx , ax               ; 
	lea si , FUNCTION1buf    ; 
	add si , 2               ; �û������������ַ
	; ���￪ʼ����
	; �����Ϸֽ��4���֣�����id����������������ƽʱ��ҵ�ɼ�����������ҵ�ɼ�
	; Ҫ�ж�id���������ֻ��4���ַ���
	; ------------------- ����id
	mov di , bx             ; Ŀ�괮��ַ��movsb�õ�
	call getlength
	cmp al,  0
	jne FUNCTION1_jmp_1  ; û�еĻ�������
	jmp FUNCTION1_bad_format ; ����ת
	FUNCTION1_jmp_1:
	cmp al , 4
	jbe FUNCTION1_jmp_2      ; ����4Ҳ����ת
	jmp FUNCTION1_bad_format ; ����ת
	FUNCTION1_jmp_2:
	mov ah, 0               ; ��λ����
	mov cx , ax             ; ��������ַ���������cx��Ҫ����������
	cld                     ; �����巽���־λ��Ҳ����ʹDFֵΪ0����ִ�д�����ʱ��ʹ��ַ�������ķ�ʽ�仯
	rep movsb               ; si��di�Ŀ���
	mov byte ptr [di], 0   ; ������һ��0
	; �ж����һλ�Ƿ�ո�
	mov cl , byte ptr [si]        
	cmp cl, ' ';    
	je FUNCTION1_jmp_3 ; �س��Ļ���Ҳ�Ǹ�ʽ����
	jmp FUNCTION1_bad_format ; ����ת
	FUNCTION1_jmp_3:
	; ------------------ ����name
	inc si               ; ��һ������
	mov di , bx             ; Ŀ�괮��ַ��movsb�õ�
	add di , 5              ; name��������߿�����
	; �±��ǿ����ϱ�id��
	call getlength
	cmp al,  0
	jne FUNCTION1_jmp_4      ; û�еĻ�������
	jmp FUNCTION1_bad_format ; ����ת
	FUNCTION1_jmp_4:
	cmp al , 4
	jbe FUNCTION1_jmp_5      ; ����4Ҳ����ת
	jmp FUNCTION1_bad_format ; ����ת
	FUNCTION1_jmp_5:
	mov ah, 0               ; ��λ����
	mov cx , ax             ; ��������ַ���������cx��Ҫ����������
	cld                     ; �巽���־λ��Ҳ����ʹDFֵΪ0����ִ�д�����ʱ��ʹ��ַ�������ķ�ʽ�仯
	rep movsb               ; si��di�Ŀ���
	mov byte ptr [di], 0   ; ������һ��0
	; �ж����һλ�Ƿ�ո�
	mov cl , byte ptr [si]        
	cmp cl, ' ';    
	je FUNCTION1_jmp_6       ; �س��Ļ���Ҳ�Ǹ�ʽ����
	jmp FUNCTION1_bad_format ; ����ת
	FUNCTION1_jmp_6:
	; -------------------- ����ƽʱ��ҵ������Ҫ����16��
	inc si                  ;��һ��
	mov cx , 16             ; ѭ������
	mov di , bx             ; 
	add di , 10             ; ÿһ�����ֶ�������߷���
	FUNCTION1_home:
		; �����ͥ��ҵ�ġ�
		call getlength
		mov ah,  0
		cmp al,  0
		ja FUNCTION1_jmp_7 ;    û�еĻ�������
		jmp FUNCTION1_bad_format ; ����ת
		FUNCTION1_jmp_7:
		cmp al , 3
		jbe FUNCTION1_jmp_8 ; ����3Ҳ����ת
		jmp FUNCTION1_bad_format ; ����ת
		FUNCTION1_jmp_8:
		; ���ｫ�ı�ת������
		push cx                   ; ����ԭ�ȵ�
		mov cx , ax               ; ����λ����
		mov ax , 0
		FUNCTION1_home_string_to_num:
			mul ten    ; al*10=ax ������ax��
			mov dx, 0
			mov dl, byte ptr [si] ; ȡ��һ��
			sub dl , '0'          ; �ַ�ת����
			add ax, dx            ; ����ȥ
			inc si                ; ��һ���ַ�
			loop  FUNCTION1_home_string_to_num ; ǰ��cx���Ѿ���λ����
		; ������ζ���Ѿ��õ�����Ӧ������
		; �����ж�һ���Ƿ����100
		cmp al , 100
		ja FUNCTION1_home_string_to_num_err
		; ����Ҫ�ж��Ƿ��ǿո�
		mov cl , byte ptr [si]        
		cmp cl, ' ';    
		jne FUNCTION1_home_string_to_num_err
		; ����
		inc si                    ; ��һ��
		mov byte ptr [di], al     ; ����ƽ���ɼ�
		inc di                    ; ��һ��ƽ���ɼ�
		pop cx                    ; ������ջ
		loop FUNCTION1_home       ; �ж�ѭ���Ƿ����
		jmp FUNCTION1_big         ; ��һ���Ǵ���ҵ��

		FUNCTION1_home_string_to_num_err:
			pop cx  
			jmp FUNCTION1_bad_format

	FUNCTION1_big:
		call getlength
		mov ah,  0
		cmp al,  0
		je FUNCTION1_bad_format ; û�еĻ�������
		cmp al , 3
		ja FUNCTION1_bad_format ; ����3Ҳ����ת
		; ���ｫ�ı�ת������
		push cx                   ; ����ԭ�ȵ�
		mov cx , ax               ; ����λ����
		mov ax , 0
		FUNCTION1_big_string_to_num:
			mul ten    ; al*10=ax ������ax��
			mov dx, 0
			mov dl, byte ptr [si] ; ȡ��һ��
			sub dl , '0'          ; �ַ�ת����
			add ax, dx            ; ����ȥ
			inc si                ; ��һ���ַ�
			loop  FUNCTION1_big_string_to_num ; ǰ��cx���Ѿ���λ����
		; �����ж�һ���Ƿ����100
		cmp al , 100
		ja FUNCTION1_big_string_to_num_err
		; �����Ǳ���
		mov byte ptr [di], al     ; 
	
	FUNCTION1_total:   ; �ܳɼ�
		mov cx , 16    ; 16��ƽʱ�ɼ�
		mov di , bx             ; 
		add di , 10             ; ÿһ�����ֶ�������߷���
		mov ax , 0              ; ��
		FUNCTION1_total_2:
			mov dx , 0
			mov dl , byte ptr [di] ; ȡ��һ���ɼ�
			add ax , dx            ; ���
			inc di                 ; ��һ��
			loop FUNCTION1_total_2 ; ѭ��
		mov dl , 16                
		div dl                     ; ƽ�� ax/dl= �̷���al�У���������ah��
		mov ah , 0
		; Ȼ��40%��Ҳ�����ȳ���40���ٳ���100
		mov dl , 40
		mul dl       ; al*dl=ax ��
		mov dl , 100 ; �̷���al��
		div dl 
		mov ah , 0
		push ax      ; ƽʱ�ɼ�
		mov al  , byte ptr [di] ; �����ŵ��Ǵ���ҵ�ɼ�
		; ����ҵ60%
		mov dl , 60
		mul dl 
		mov dl , 100
		div dl 
		mov ah , 0
		pop dx 
		add ax, dx    ; �������ܳɼ�
		inc di        ; �������ܳɼ�
		mov byte ptr[di]  , al 

		; ѧ������+1
		mov al, student_count
		inc al 
		mov student_count, al 
		jmp FUNCTION1ret


	FUNCTION1_big_string_to_num_err:
			pop cx  ; ��Ҫ��ջƽ�⡣
			jmp FUNCTION1_bad_format

	FUNCTION1_bad_format:
		; ��ʽ����
		OUT_STRING FUNCTION1_bad_format_message
		jmp FUNCTION1ret

	FUNCTION1ret:
		; ����		
		ret
FUNCTION1 endp
;----------------------------------------------------------------------------------
FUNCTION2 proc
	; ����id��ѯ, 
	; ˼·�ǣ�˳���ж�ÿһ��
	; ��������Ҫ������Ϣ��
	lea dx, inquire_key
	mov ah, 0Ah
	int 21H
	call COUTENTER         ; ��һ���س�

	lea bx , student_data  ; �����Ϊ��ַ
	mov cx , 0
	mov cl , student_count ; ѧ��������Ϊѭ��
	cmp cl , 0
	je FUNCTION2ret        ; û��ѧ���Ͳ���ѯ
	FUNCTION2_loop:
		lea si , inquire_key   ; �û�����Ļ�����
		inc si                 ; ָ��ʵ��ʻ��ĸ���
		mov al, byte ptr [si]  ; ȡ��ʵ������ĸ���
		inc si                 ; �û�ʵ�������
		cmp al, 0
		je FUNCTION2ret        ; ����û�û�����룬��ֱ�ӷ���
		push cx      ; ����ԭ�ȵ�
		mov ah , 0
		mov cx , ax  ; �û�����ĸ�����Ϊ����
		mov di , bx  ; 
		add di , 0   ; �����Ǳ��������
		repe cmpsb   ; �Ƚ�
		jnz FUNCTION2_next  ; ������0������һ��
			mov al , byte ptr [di]
			cmp al , 0
			jne FUNCTION2_next
			pop cx              ; ��ջƽ��
			call print_student  ; ��ӡ���ͬѧ��Ϣ
			call COUTENTER      ; ����
			jmp FUNCTION2ret    ; ��ת������

		FUNCTION2_next:
			; ��һ��
			pop cx                   ; ��ջƽ��
			add bx , student_length  ; ��һ��ѧ��
			loop FUNCTION2_loop      ; ѭ��

	FUNCTION2ret:
	ret
FUNCTION2 endp
;��Ȩ���У�Ф����
;----------------------------------------------------------------------------------
FUNCTION3 proc
	; ����name��ѯ, 
	; ˼·�ǣ�˳���ж�ÿһ��
	; ��������Ҫ������Ϣ��
	lea dx, inquire_key
	mov ah, 0Ah
	int 21H
	call COUTENTER         ; ��һ���س�

	lea bx , student_data  ; �����Ϊ��ַ
	mov cx , 0
	mov cl , student_count ; ѧ��������Ϊѭ��
	cmp cl , 0
	je FUNCTION3ret        ; û��ѧ���Ͳ���ѯ
	FUNCTION3_loop:
		lea si , inquire_key   ; �û�����Ļ�����
		inc si                 ; ָ��ʵ��ʻ��ĸ���
		mov al, byte ptr [si]  ; ȡ��ʵ������ĸ���
		inc si                 ; �û�ʵ�������
		cmp al, 0
		je FUNCTION3ret        ; ����û�û�����룬��ֱ�ӷ���
		push cx      ; ����ԭ�ȵ�
		mov ah , 0
		mov cx , ax  ; �û�����ĸ�����Ϊ����
		mov di , bx  ; 
		add di , 5   ; �����Ǳ��������
		repe cmpsb   ; �Ƚ�
		jnz FUNCTION3_next  ; ������0������һ��
			mov al , byte ptr [di]
			cmp al , 0
			jne FUNCTION2_next
			pop cx              ; ��ջƽ��
			call print_student  ; ��ӡ���ͬѧ��Ϣ
			call COUTENTER      ; ����
			jmp FUNCTION3ret    ; ��ת������

		FUNCTION3_next:
			; ��һ��
			pop cx                   ; ��ջƽ��
			add bx , student_length  ; ��һ��ѧ��
			loop FUNCTION3_loop      ; ѭ��

	FUNCTION3ret:
	ret
FUNCTION3 endp
;----------------------------------------------------------------------------------
FUNCTION4 proc
	; ����Ƿֳ����󲿷֣���һ���������򣬵ڶ���������ʾ
	mov al , student_count
	cmp al , 0
	je FUNCTION4_ret ; û�еĻ���ֱ����ת
	; ---------���򲿷�
	cmp al , 1         ; ���ֻ��һ������ֱ����ʾ
	je FUNCTION4_show
	; ���￪ʼ������ð������
	lea si , student_data  
	mov ah , 0   
	mov cx , ax   ; ����
	dec cx        ; ��ȥ1
	FUNCTION4_loop1:;ʹ�þ����ð������
		push cx     ; ����ԭ�ȵ�
		lea si , student_data
		FUNCTION4_loop2:
			mov al, byte ptr [si+5+5+16+1]                 ; ȡ���ܳɼ�
			cmp al , byte ptr [si+5+5+16+1+student_length] ; �������Ƚ�2��ͬѧ�ķ���
			jle FUNCTION4_loop2_next                       ; С�ڵ��ھ���һ��ͬѧ
				mov di , si
				add di , student_length 
				call swap_student   ; �����ǽ���2��ѧ����λ��

			FUNCTION4_loop2_next:
				add si , student_length   ; ��һ��ѭ��
				loop FUNCTION4_loop2      ; 
			pop cx                        ; �ڲ�ѭ����������
			loop FUNCTION4_loop1          ; ���ѭ��
	
	; --------- ��ʾ����
	FUNCTION4_show:
		mov al , student_count
		mov ah , 0
		mov cx , ax            ; ������Ϊ����
		lea bx , student_data  ; ����ַ
		FUNCTION4_show_loop:
			; �����������
			mov ax , 0
			mov ax , cx 
			call print8      ; ��ӡ����
			call print_comma ; һ������
			; Ȼ���ӡ���ѧ������Ϣ
			call print_student
			call COUTENTER  ; �س�
			add bx , student_length   ; ��һ��ѧ��
			loop FUNCTION4_show_loop


	FUNCTION4_ret:
	ret
FUNCTION4 endp

;��Ȩ���У�Ф����
;----------------------------------------------------------------------------------

FUNCTION5 proc
	; ���ε���
	call FUNCTION5_dengji
	call FUNCTION5_min
	call FUNCTION5_max
	call FUNCTION5_avg

	ret
	
FUNCTION5 endp

;��Ȩ���У�Ф����
;----------------------------------------------------------------------------------

FUNCTION6 proc
	; �˳�
	mov ax, 4c00h 
    int 21h 
	ret
FUNCTION6 endp

    
codes ends

end start ;����


;��Ȩ���У�Ф����