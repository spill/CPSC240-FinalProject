; One-digit integer calculator in YASM (64-bit)
; This program assumes input equations in the form a+b-c*d/e

section .data
    prompt db "Enter equation (e.g., a+b-c*d/e):", 0
    prompt_len equ $ - prompt       ; Calculate the length of the string
    result_msg db "Result: ", 0
    result_msg_len equ $ - result_msg
    newline db 10, 0
    error_msg db "Error: Invalid input or division by zero.", 10, 0
    error_len equ $ - error_msg    ; Calculate the length of the error message

section .bss
    input resb 20                  ; Reserve 20 bytes for input buffer
    res resq 1

section .text
    global _start

_start:
    ; Prompt user for input
    mov rax, 1                     ; syscall: write
    mov rdi, 1                     ; file descriptor: stdout
    mov rsi, prompt                ; address of message to print
    mov rdx, prompt_len            ; Use calculated length of prompt
    syscall

    ; Read user input
    mov rax, 0                     ; syscall: read
    mov rdi, 0                     ; file descriptor: stdin
    mov rsi, input                 ; Address of buffer in `.bss`
    mov rdx, 20                    ; Input buffer size
    syscall
    test rax, rax                  ; Check for EOF or error
    jle error_handler

    ; Process input
    mov rdi, input                 ; Pass input buffer to calculation
    call calculate                 ; Perform the calculation

    ; Check for errors
    cmp rax, -1                    ; Check if calculation returned an error
    je error_handler

    ; Display result
    mov rsi, res                   ; Address of the result
    call print_result

    ; Exit program
    mov rax, 60                    ; syscall: exit
    xor rdi, rdi                   ; status: 0
    syscall

error_handler:
    ; Print error message
    mov rax, 1                     ; syscall: write
    mov rdi, 1                     ; file descriptor: stdout
    mov rsi, error_msg             ; address of error message
    mov rdx, error_len             ; length of error message
    syscall

    mov rax, 60                    ; syscall: exit
    mov rdi, 1                     ; status: 1
    syscall

calculate:
    ; Skip newline character if present
    mov rbx, rdi                   ; rbx = input buffer address
    cmp byte [rbx], 10             ; Check if the first character is '\n'
    je error_handler               ; Jump to error if input is just newline

    ; Parse operand1 (a)
    sub byte [rbx], '0'            ; Convert char to integer
    cmp byte [rbx], 9              ; Ensure it’s a single-digit integer
    ja error_handler               ; If greater than 9, jump to error
    movzx rcx, byte [rbx]          ; rcx = operand1

    ; Parse operator1
    inc rbx
    mov dl, [rbx]                  ; dl = operator
    cmp dl, '+'                    ; Check for valid operators
    je valid_operator
    cmp dl, '-'
    je valid_operator
    cmp dl, '*'
    je valid_operator
    cmp dl, '/'
    je valid_operator
    jmp error_handler

valid_operator:
    ; Parse operand2
    inc rbx
    sub byte [rbx], '0'            ; Convert char to integer
    cmp byte [rbx], 9              ; Ensure it’s a single-digit integer
    ja error_handler
    movzx rdx, byte [rbx]          ; rdx = operand2

    ; Perform operation
    cmp dl, '+'
    je add_op
    cmp dl, '-'
    je sub_op
    cmp dl, '*'
    je mul_op
    cmp dl, '/'
    je div_op
    jmp error_handler

add_op:
    add rcx, rdx                   ; rcx = operand1 + operand2
    jmp next_op

sub_op:
    sub rcx, rdx                   ; rcx = operand1 - operand2
    jmp next_op

mul_op:
    imul rcx, rdx                  ; rcx = operand1 * operand2
    jmp next_op

div_op:
    cmp rdx, 0                     ; Check division by zero
    je error_handler
    xor rdx, rdx                   ; Clear rdx for division
    div rcx                        ; rcx = operand1 / operand2

next_op:
    ; Store the result in memory
    mov qword [res], rcx           ; Save the result into `res`
    mov rax, 0                     ; Set rax to 0 to indicate success
    ret

print_result:
    ; Print result as an integer
    mov rax, 1                     ; syscall: write
    mov rdi, 1                     ; file descriptor: stdout
    mov rsi, result_msg            ; Prefix "Result: "
    mov rdx, result_msg_len        ; Length of "Result: "
    syscall

    ; Convert result in [res] to string and print
    mov rax, [res]                 ; Load result
    call int_to_ascii              ; Helper to print number
    ret

int_to_ascii:
    ; Convert integer in rax to ASCII and print
    ; For simplicity, assume rax is less than 10
    add rax, '0'                   ; Convert to ASCII
    mov rsi, rax                   ; Move ASCII result to rsi
    mov rdx, 1                     ; Write one character
    syscall
    ret
