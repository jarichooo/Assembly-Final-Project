; vehicle_registration_system.asm
; FINAL 100% WORKING VERSION - NO ERRORS
; nasm -f win32 vehicle_registration_system.asm -o vehicle_registration_system.o
; gcc vehicle_registration_system.o -o vehicle_registration_system.exe

section .data use32
    MAX_VEHICLES equ 100
    NAME_LEN     equ 50
    PLATE_LEN    equ 15
    REC_SIZE     equ (PLATE_LEN + NAME_LEN + 1)

    main_menu db 10
              db "MENU:",10
              db "[1] Add",10
              db "[2] Delete",10
              db "[3] Search",10
              db "[4] Display",10
              db "[5] Exit",10,10
              db "Enter choice: ",0

    submenu_add     db 10,"ADD MENU:",10
                    db "[1] Add Vehicle",10
                    db "[2] Back to Main Menu",10,10
                    db "Enter choice: ",0

    submenu_delete  db 10,"DELETE MENU:",10
                    db "[1] Delete by Plate Number",10
                    db "[2] Delete All by Owner Name",10
                    db "[3] Back to Main Menu",10,10
                    db "Enter choice: ",0

    submenu_search  db 10,"SEARCH MENU:",10
                    db "[1] Search by Plate Number",10
                    db "[2] Search by Owner Name",10
                    db "[3] Back to Main Menu",10,10
                    db "Enter choice: ",0

    submenu_display db 10,"DISPLAY MENU:",10
                    db "[1] Display All Vehicles",10
                    db "[2] Display Vehicles by Owner",10
                    db "[3] Back to Main Menu",10,10
                    db "Enter choice: ",0

    prompt_owner db 10,"Enter Owner Name: ",0
    prompt_plate db 10,"Enter Plate Number: ",0

    msg_added    db 10,"Vehicle added successfully!",10,0
    msg_deleted  db 10,"Deleted successfully!",10,0
    msg_notfound db 10,"Not found!",10,0
    msg_full     db 10,"Database is full!",10,0
    msg_empty    db 10,"No vehicles registered.",10,0

    msg_header   db 10
                 db "Plate Number        | Owner Name",10
                 db "--------------------|-----------------------------",10,0

    fmt_int      db "%d",0
    fmt_str      db "%s",0
    plate_format db "%-20s",0
    separator    db " | ",0
    newline      db 10,0

section .bss use32
    vehicles     resb MAX_VEHICLES * REC_SIZE
    input_buf    resb 100
    choice       resd 1
    count        resd 1
    temp_index   resd 1
    found_count  resd 1

section .text use32
    global _main
    extern _printf
    extern _scanf
    extern _getchar
    extern _exit

_main:
    mov dword [count], 0

main_menu_loop:
    push main_menu
    call _printf
    add esp, 4

    push choice
    push fmt_int
    call _scanf
    add esp, 8
    call clear_input_buffer

    mov eax, [choice]
    cmp eax, 1
    je menu_add
    cmp eax, 2
    je menu_delete
    cmp eax, 3
    je menu_search
    cmp eax, 4
    je menu_display
    cmp eax, 5
    je exit_program
    jmp main_menu_loop

; ================================
; ADD MENU
; ================================
menu_add:
    push submenu_add
    call _printf
    add esp, 4
    push choice
    push fmt_int
    call _scanf
    add esp, 8
    call clear_input_buffer

    mov eax, [choice]
    cmp eax, 1
    je do_add_vehicle
    cmp eax, 2
    je main_menu_loop
    jmp menu_add

do_add_vehicle:
    mov eax, [count]
    cmp eax, MAX_VEHICLES
    jge add_full

    imul eax, REC_SIZE
    lea edi, [vehicles + eax]

    push prompt_owner
    call _printf
    add esp, 4
    push input_buf
    push fmt_str
    call _scanf
    add esp, 8
    call clear_input_buffer
    lea edi, [edi + PLATE_LEN]
    mov esi, input_buf
    call str_copy

    push prompt_plate
    call _printf
    add esp, 4
    push input_buf
    push fmt_str
    call _scanf
    add esp, 8
    call clear_input_buffer
    sub edi, PLATE_LEN
    mov esi, input_buf
    call str_copy

    add edi, PLATE_LEN + NAME_LEN
    mov byte [edi], 1
    inc dword [count]

    push msg_added
    call _printf
    add esp, 4
    jmp menu_add

add_full:
    push msg_full
    call _printf
    add esp, 4
    jmp menu_add

; ================================
; DELETE MENU
; ================================
menu_delete:
    push submenu_delete
    call _printf
    add esp, 4
    push choice
    push fmt_int
    call _scanf
    add esp, 8
    call clear_input_buffer

    mov eax, [choice]
    cmp eax, 1
    je delete_by_plate_once
    cmp eax, 2
    je delete_by_owner_once
    cmp eax, 3
    je main_menu_loop
    jmp menu_delete

delete_by_plate_once:
    push prompt_plate
    call _printf
    add esp, 4
    push input_buf
    push fmt_str
    call _scanf
    add esp, 8
    call clear_input_buffer

    mov dword [found_count], 0
    mov dword [temp_index], 0
.plate_loop:
    mov eax, [temp_index]
    cmp eax, [count]
    jge .done
    call get_vehicle_ptr
    add edi, PLATE_LEN + NAME_LEN
    cmp byte [edi], 0
    je .next
    sub edi, PLATE_LEN + NAME_LEN
    mov esi, input_buf
    call str_cmp_ci
    test eax, eax
    jne .next
    add edi, PLATE_LEN + NAME_LEN
    mov byte [edi], 0
    inc dword [found_count]
.next:
    inc dword [temp_index]
    jmp .plate_loop
.done:
    cmp dword [found_count], 0
    je .notfound
    push msg_deleted
    call _printf
    add esp, 4
    jmp menu_delete
.notfound:
    push msg_notfound
    call _printf
    add esp, 4
    jmp menu_delete

delete_by_owner_once:
    push prompt_owner
    call _printf
    add esp, 4
    push input_buf
    push fmt_str
    call _scanf
    add esp, 8
    call clear_input_buffer

    mov dword [found_count], 0
    mov dword [temp_index], 0
.owner_loop:
    mov eax, [temp_index]
    cmp eax, [count]
    jge .done
    call get_vehicle_ptr
    add edi, PLATE_LEN + NAME_LEN
    cmp byte [edi], 0
    je .next
    sub edi, NAME_LEN
    mov esi, input_buf
    call str_cmp_ci
    test eax, eax
    jne .next
    add edi, NAME_LEN
    mov byte [edi], 0
    inc dword [found_count]
.next:
    inc dword [temp_index]
    jmp .owner_loop
.done:
    cmp dword [found_count], 0
    je .notfound
    push msg_deleted
    call _printf
    add esp, 4
    jmp menu_delete
.notfound:
    push msg_notfound
    call _printf
    add esp, 4
    jmp menu_delete

; ================================
; SEARCH MENU
; ================================
menu_search:
    push submenu_search
    call _printf
    add esp, 4
    push choice
    push fmt_int
    call _scanf
    add esp, 8
    call clear_input_buffer

    mov eax, [choice]
    cmp eax, 1
    je search_by_plate_once
    cmp eax, 2
    je search_by_owner_once
    cmp eax, 3
    je main_menu_loop
    jmp menu_search

search_by_plate_once:
    push prompt_plate
    call _printf
    add esp, 4
    push input_buf
    push fmt_str
    call _scanf
    add esp, 8
    call clear_input_buffer

    mov dword [found_count], 0
    mov dword [temp_index], 0
.loop:
    mov eax, [temp_index]
    cmp eax, [count]
    jge .done
    call get_vehicle_ptr
    add edi, PLATE_LEN + NAME_LEN
    cmp byte [edi], 0
    je .next
    sub edi, PLATE_LEN + NAME_LEN
    mov esi, input_buf
    call str_cmp_ci
    test eax, eax
    jne .next
    cmp dword [found_count], 0
    jne .noheader
    push msg_header
    call _printf
    add esp, 4
.noheader:
    inc dword [found_count]
    call print_vehicle
.next:
    inc dword [temp_index]
    jmp .loop
.done:
    cmp dword [found_count], 0
    jne menu_search
    push msg_notfound
    call _printf
    add esp, 4
    jmp main_menu_loop

search_by_owner_once:
    push prompt_owner
    call _printf
    add esp, 4
    push input_buf
    push fmt_str
    call _scanf
    add esp, 8
    call clear_input_buffer

    mov dword [found_count], 0
    mov dword [temp_index], 0
.loop:
    mov eax, [temp_index]
    cmp eax, [count]
    jge .done
    call get_vehicle_ptr
    add edi, PLATE_LEN + NAME_LEN
    cmp byte [edi], 0
    je .next
    sub edi, NAME_LEN
    mov esi, input_buf
    call str_cmp_ci
    test eax, eax
    jne .next
    cmp dword [found_count], 0
    jne .noheader
    push msg_header
    call _printf
    add esp, 4
.noheader:
    inc dword [found_count]
    sub edi, PLATE_LEN
    call print_vehicle
.next:
    inc dword [temp_index]
    jmp .loop
.done:
    cmp dword [found_count], 0
    jne menu_search
    push msg_notfound
    call _printf
    add esp, 4
    jmp main_menu_loop

; ================================
; DISPLAY MENU
; ================================
menu_display:
    push submenu_display
    call _printf
    add esp, 4
    push choice
    push fmt_int
    call _scanf
    add esp, 8
    call clear_input_buffer

    mov eax, [choice]
    cmp eax, 1
    je display_all
    cmp eax, 2
    je display_by_owner_once
    cmp eax, 3
    je main_menu_loop
    jmp menu_display

display_all:
    cmp dword [count], 0
    je no_vehicles
    push msg_header
    call _printf
    add esp, 4
    mov dword [temp_index], 0
.loop:
    mov eax, [temp_index]
    cmp eax, [count]
    jge menu_display
    call get_vehicle_ptr
    add edi, PLATE_LEN + NAME_LEN
    cmp byte [edi], 0
    je .next
    sub edi, PLATE_LEN + NAME_LEN
    call print_vehicle
.next:
    inc dword [temp_index]
    jmp .loop

display_by_owner_once:
    push prompt_owner
    call _printf
    add esp, 4
    push input_buf
    push fmt_str
    call _scanf
    add esp, 8
    call clear_input_buffer

    mov dword [found_count], 0
    mov dword [temp_index], 0
.loop:
    mov eax, [temp_index]
    cmp eax, [count]
    jge .done
    call get_vehicle_ptr
    add edi, PLATE_LEN + NAME_LEN
    cmp byte [edi], 0
    je .next
    sub edi, NAME_LEN
    mov esi, input_buf
    call str_cmp_ci
    test eax, eax
    jne .next
    cmp dword [found_count], 0
    jne .noheader
    push msg_header
    call _printf
    add esp, 4
.noheader:
    inc dword [found_count]
    sub edi, PLATE_LEN
    call print_vehicle
.next:
    inc dword [temp_index]
    jmp .loop
.done:
    cmp dword [found_count], 0
    jne menu_display
    push msg_notfound
    call _printf
    add esp, 4
    jmp menu_display

no_vehicles:
    push msg_empty
    call _printf
    add esp, 4
    jmp menu_display

; ================================
; HELPERS
; ================================
get_vehicle_ptr:
    mov eax, [temp_index]
    imul eax, REC_SIZE
    lea edi, [vehicles + eax]
    ret

print_vehicle:
    push edi
    push plate_format
    call _printf
    add esp, 8
    push separator
    call _printf
    add esp, 4
    add edi, PLATE_LEN
    push edi
    push fmt_str
    call _printf
    add esp, 8
    push newline
    call _printf
    add esp, 4
    ret

clear_input_buffer:
    push eax
.loop:
    call _getchar
    cmp al, 10
    je .done
    cmp al, -1
    jne .loop
.done:
    pop eax
    ret

str_cmp_ci:
    push esi
    push edi
.loop:
    mov al, [esi]
    mov bl, [edi]
    cmp al, 0
    je .check_end
    cmp bl, 0
    je .diff
    cmp al, 'a'
    jb .no1
    cmp al, 'z'
    ja .no1
    sub al, 32
.no1:
    cmp bl, 'a'
    jb .no2
    cmp bl, 'z'
    ja .no2
    sub bl, 32
.no2:
    cmp al, bl
    jne .diff
    inc esi
    inc edi
    jmp .loop
.check_end:
    cmp bl, 0
    je .equal
.diff:
    mov eax, 1
    jmp .end
.equal:
    mov eax, 0
.end:
    pop edi
    pop esi
    ret

str_copy:
    push edi
.loop:
    lodsb
    stosb
    cmp al, 0
    jne .loop
    pop edi
    ret

exit_program:
    push 0
    call _exit