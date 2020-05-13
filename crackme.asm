sys_exit    equ 60
sys_ptrace  equ 101
sys_write   equ 1
sys_read    equ 0

SEGMENT .text

GLOBAL _start

%macro exit 0
    mov rax, sys_exit                   ; Exit
    xor rdi, rdi                        ; Exit code 0
    syscall
%endmacro

%macro write 2
    mov rax, sys_write
    mov rdi, 1
    mov rsi, %1
    mov rdx, %2
    syscall
%endmacro

_start:
    cld                                 ; Increase indicies in string operations
    mov rax, sys_ptrace                 ; ptrace function
    xor rdi, rdi                        ; PTRACE_TRACEME
    syscall                             ; Attach to itself

    cmp rax, 0
    jl traced                           ; If value is negative (-1), process is already being traced
    
    write nameprompt_msg, nameprompt_msg_len

    lea rsi, [license_name]
    call gets                           ; Read license name
    
    mov rcx, rsi                        ; Copy old RSI to RCX
    lea rsi, [license_name]             ; Put the beginning of the string into RSI register
    sub rcx, rsi                        ; Calculate length of string
    call joaat

    lea rsi, [encrypt_stub]             ; Start of the encrypted sector
    lodsd                               ; Load first segment to check
    xor eax, ebx                        ; XOR it with the hash
    cmp eax, 0x652AFFBE                 ; Check that the first byte is not lesser than it should be
    jbe name_fail                       ; If it is, print message and exit
    cmp eax, 0x656DCE8A                 ; Check that the fist byte is not greater than it should be
    jae name_fail                       ; If it is, print the message and exit

    lodsd                               ; Load second segment to check
    xor eax, ebx                        ; XOR it with the hash value
    cmp eax, 0x6D752C2E                 ; Basically the same idea goes on
    jbe name_fail
    sub eax, 0x12345678
    cmp eax, 0x5B413322
    jae name_fail

    lodsd
    xor eax, ebx
    cmp eax, 0x756A6F11
    jbe name_fail
    ror eax, 16
    cmp eax, 0x6F8AEDA0
    jae name_fail

    lodsd
    xor eax, ebx
    rol eax, 24
    shr eax, 24
    cmp eax, 0x6D
    jne name_fail

    lea rsi, [_encrypted]               ; Set RSI to pointer to encrypted part
    lea rdi, [_encrypted]               ; Set RDI to pointer to encrypted part
    mov rcx, encrypted_len              ; Set RCX to encrypted part's length
    shr rcx, 2                          ; Count number of DWORDs in encrypted part (with ceiling)
    inc rcx

.decryptloop:                           ; Decryption loop
    lodsd                               ; Load DWORD of program into EAX
    xor eax, ebx                        ; Decrypt it
    stosd                               ; Save DWORD of program back into memory
    loop .decryptloop                   ; Proceed

    jmp _encrypted_start

    
;================================================
; Printing the message if license name check had
; failed
;================================================

name_fail:
    write namefail_msg, namefail_msg_len
    exit


;================================================
; Printing the message in case process is being
; traced
;================================================

traced:
    write traced_msg, traced_msg_len
    exit


;================================================
; Function that reads the input 'till the \0
; is encountered
; ENTER: RSI - pointer to buffer
; DESTR: RAX, RDI, RDX, RSI
; EXITL  RSI - pointer to the EOF or '\n'
;================================================

gets:
    mov rdi, 0                          ; Console descriptor
    mov rdx, 1                          ; One character to read

.loop:
    mov rax, sys_read                   ; Read from console
    syscall                             ; Read character
    cmp byte [rsi], 0                   ; Check for the end of string
    je .end                             ; If EOF is reached, exit
    cmp byte [rsi], 0xA                 ; Check for the '\n' symbol
    je .end                             ; If '\n' is reached, exit
    inc rsi                             ; Increment buffer position
    jmp .loop                           ; Proceed reading
    
.end:
    ret                                 ; Return to the caller


;================================================
; Function that calculates Jenkins one_at_a_time
; hash
; ENTER: RCX - Length of string
;        RSI - Pointer to string
; EXIT: EBX - 32-bit hash value
; DESTR: RCX, RSI, EAX, EBX
;================================================

joaat:
    xor ebx, ebx                        ; Set EBX to 0

.loop:                                  ; Main hash loop
    xor eax, eax                        ; Set EAX to 0
    lodsb                              ; Load symbol into AH
    add ebx, eax                        ; Add symbol value to hash
    mov eax, ebx                        ; Copy hash value
    shl eax, 10                         ; Shift value left by 10 bits
    add ebx, eax                        ; Add shifted value to hash
    mov eax, ebx                        ; Copy hash value
    shr eax, 6                          ; Shift value right by 6 bits
    xor ebx, eax                        ; XOR hash and shifted hash
    loop .loop                          ; Proceed while there are symbols left

    mov eax, ebx                        ; Copy hash value
    shl eax, 3                          ; Shift value left by 3 bits
    add ebx, eax                        ; Add shifted value to hash
    mov eax, ebx                        ; Copy hash value
    shr eax, 11                         ; Shift value right by 11 bits
    xor ebx, eax                        ; XOR hash and shifted hash
    mov eax, ebx                        ; Copy hash value
    shl eax, 15                         ; Shift value left by 15 bits
    add ebx, eax                        ; Add shifted value to hash
    ret                                 ; Everything is done. Return to caller

;================================================
; Encrypted section of the programm
; _encrypted - beginning of th section
; _encrypted_start - entry point of the encrypted
; section
;================================================

_encrypted:
encrypt_stub db "Some mumbojumbo here. Don't mind this part of the program. There is no meaning to it. Just move on."

_encrypted_start:
    write numberprompt_msg, numberprompt_msg_len        ; Prompt for licence number
    lea rsi, [encrypt_stub]                           ; Reusing encrypt_stub allows for buffer overflow, though it needs to be carried out carefully
    call gets                                           ; Read serial number
    mov rcx, rsi                                        ; Copy RSI to RCX
    lea rsi, [encrypt_stub]                           ; RSI points to serial number
    sub rcx, rsi                                        ; Calculate serial number length
    cmp rcx, 20                                         ; Serial should consist of 20 symbols
    jne _encrypted_wrongnumber                          ; Show error message and exit

    mov r8d, ebx                                        ; Save previous hash
    call _encrypted_joaat                               ; Calculate JOAAT hash but with another function
    xor ebx, r8d                                        ; XOR new and old hash
    cmp ebx, 0x11111111                                      ; Make sure it's correct
    jne _encrypted_wrongnumber
    write authenticated_msg, authenticated_msg_len      ; Everything is correct c:
    exit


;================================================
; Showing prompt in case wrong number is entered
;================================================

_encrypted_wrongnumber:
    write numberfail_msg, numberfail_msg_len
    exit

;================================================
; Basically copy of joaat, but in encrypted section
;================================================

_encrypted_joaat:
    xor ebx, ebx                        ; Set EBX to 0

.loop:                                  ; Main hash loop
    xor eax, eax                        ; Set EAX to 0
    lodsb                              ; Load symbol into AH
    add ebx, eax                        ; Add symbol value to hash
    mov eax, ebx                        ; Copy hash value
    shl eax, 10                         ; Shift value left by 10 bits
    add ebx, eax                        ; Add shifted value to hash
    mov eax, ebx                        ; Copy hash value
    shr eax, 6                          ; Shift value right by 6 bits
    xor ebx, eax                        ; XOR hash and shifted hash
    loop .loop                          ; Proceed while there are symbols left

    mov eax, ebx                        ; Copy hash value
    shl eax, 3                          ; Shift value left by 3 bits
    add ebx, eax                        ; Add shifted value to hash
    mov eax, ebx                        ; Copy hash value
    shr eax, 11                         ; Shift value right by 11 bits
    xor ebx, eax                        ; XOR hash and shifted hash
    mov eax, ebx                        ; Copy hash value
    shl eax, 15                         ; Shift value left by 15 bits
    add ebx, eax                        ; Add shifted value to hash
    ret                                 ; Everything is done. Return to caller

encrypted_len equ $-_encrypted

encrypted_end db "Ok it's over"

SEGMENT .rodata

traced_msg db "Ты ездил в Бобруйск? Ездил в Бобруйск? В Бобруйск ездил? Ездил, а?", 0xA, 0
traced_msg_len equ $-traced_msg

nameprompt_msg db "Enter licence name: "
nameprompt_msg_len equ $-nameprompt_msg

numberprompt_msg db "Enter licence number: "
numberprompt_msg_len equ $-numberprompt_msg

namefail_msg db "Licence name is incorrect! Terminating...", 0xA
namefail_msg_len equ $-namefail_msg

numberfail_msg db "Licence number is incorrect! Terminating...", 0xA
numberfail_msg_len equ $-numberfail_msg

authenticated_msg db "Thank you for purchasing our software that does absolutely nothing! c:", 0xA
authenticated_msg_len equ $-authenticated_msg 

SEGMENT .data

license_name:    times 256 db 0         ; Max of 256 symbols expected
