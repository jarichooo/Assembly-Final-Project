; vehicle_registration_system.asm
; NASM Win32 - Fixed: Search loops until found or user goes back

section .data use32
    MAX_VEHICLES equ 100
    NAME_LEN     equ 50
    PLATE_LEN    equ 15
    REC_SIZE     equ (PLATE_LEN + NAME_LEN + 1)

    main_menu db 10
              db "MENU:", 10
              db "[1] Add", 10
              db "[2] Delete", 10
              db "[3] Search", 10
              db "[4] Display", 10
              db "[5] Exit", 10, 10
              db "Enter choice: ", 0

    submenu_add     db 10, "ADD MENU:", 10
                    db "[1] Add Vehicle", 10
                    db "[2] Back to Main Menu", 10, 10
                    db "Enter choice: ", 0

    submenu_delete  db 10, "DELETE MENU:", 10
                    db "[1] Delete by Plate Number", 10
                    db "[2] Delete All by Owner Name", 10
                    db "[3] Back to Main Menu", 10, 10
                    db "Enter choice: ", 0

    submenu_search  db 10, "SEARCH MENU:", 10
                    db "[1] Search by Plate Number", 10
                    db "[2] Search by Owner Name", 10
                    db "[3] Back to Main Menu", 10, 10
                    db "Enter choice: ", 0

    submenu_display db 10, "DISPLAY MENU:", 10
                    db "[1] Display All Vehicles", 10
                    db "[2] Display Vehicles by Owner", 10
                    db "[3] Back to Main Menu", 10, 10
                    db "Enter choice: ", 0

    prompt_owner db 10, "Enter Owner Name: ", 0
    prompt_plate db 10, "Enter Plate Number: ", 0

    msg_added    db 10, "Vehicle added successfully!", 10, 0
    msg_deleted  db 10, "Deleted successfully!", 10, 0
    msg_notfound db 10, "Not found! Try again.", 10, 0
    msg_full     db 10, "Database is full!", 10, 0
    msg_empty    db 10, "No vehicles registered.", 10, 0
    msg_header   db 10, "Plate Number        | Owner Name", 10
                 db "--------------------|-----------------------------", 10, 0

    fmt_int  db "%d", 0
    fmt_str  db "%s", 0
    fmt_strln db "%s", 10, 0
    newline  db 10, 0
    separator db " | ", 0

section .bss use32
    vehicles    resb MAX_VEHICLES * REC_SIZE
    input_buf   resb 100
    choice      resd 1
    count       resd 1

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
; DELETE MENU (same logic)
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
    je delete_by_plate_loop
    cmp eax, 2
    je delete_by_owner_loop
    cmp eax, 3
    je main_menu_loop
    jmp menu_delete

; Delete by Plate - Loops until found or back
delete_by_plate_loop:
    push prompt_plate
    call _printf
    add esp, 4
    push input_buf
    push fmt_str
    call _scanf
    add esp, 8
    call clear_input_buffer

    call find_by_plate
    cmp ebx, -1
    je .notfound
    call mark_deleted
    push msg_deleted
    call _printf
    add esp, 4
    jmp menu_delete

.notfound:
    push msg_notfound
    call _printf
    add esp, 4
    jmp delete_by_plate_loop

delete_by_owner_loop:
    push prompt_owner
    call _printf
    add esp, 4
    push input_buf
    push fmt_str
    call _scanf
    add esp, 8
    call clear_input_buffer

    xor ecx, ecx
    xor ebx, ebx
.del_loop:
    cmp ebx, [count]
    jge .done
    call get_vehicle_ptr
    add edi, PLATE_LEN
    mov esi, input_buf
    call str_cmp
    test eax, eax
    jne .next
    call mark_deleted
    inc ecx
.next:
    inc ebx
    jmp .del_loop
.done:
    test ecx, ecx
    jnz .success
    push msg_notfound
    call _printf
    add esp, 4
    jmp delete_by_owner_loop
.success:
    push msg_deleted
    call _printf
    add esp, 4
    jmp menu_delete

; ================================
; SEARCH MENU - NOW LOOPS ON NOT FOUND
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
    je search_by_plate_loop
    cmp eax, 2
    je search_by_owner_loop
    cmp eax, 3
    je main_menu_loop
    jmp menu_search

; Search by Plate - Keeps asking until found
search_by_plate_loop:
    push prompt_plate
    call _printf
    add esp, 4
    push input_buf
    push fmt_str
    call _scanf
    add esp, 8
    call clear_input_buffer

    call find_by_plate
    cmp ebx, -1
    je .notfound
    call print_vehicle_header
    call print_vehicle
    jmp menu_search

.notfound:
    push msg_notfound
    call _printf
    add esp, 4
    jmp search_by_plate_loop

; Search by Owner - Keeps asking until at least one found
search_by_owner_loop:
    push prompt_owner
    call _printf
    add esp, 4
    push input_buf
    push fmt_str
    call _scanf
    add esp, 8
    call clear_input_buffer

    xor ecx, ecx
    xor ebx, ebx
.search_loop:
    cmp ebx, [count]
    jge .check_found
    call get_vehicle_ptr
    add edi, PLATE_LEN
    mov esi, input_buf
    call str_cmp
    test eax, eax
    jne .next
    test ecx, ecx
    jnz .no_header
    call print_vehicle_header
    inc ecx
.no_header:
    call print_vehicle
.next:
    inc ebx
    jmp .search_loop

.check_found:
    test ecx, ecx
    jnz menu_search
    push msg_notfound
    call _printf
    add esp, 4
    jmp search_by_owner_loop

; ================================
; DISPLAY MENU (unchanged)
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
    call print_vehicle_header
    xor ebx, ebx
.loop:
    cmp ebx, [count]
    jge menu_display
    call get_vehicle_ptr
    add edi, PLATE_LEN + NAME_LEN
    cmp byte [edi], 0
    je .next
    call print_vehicle
.next:
    inc ebx
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

    xor ecx, ecx
    xor ebx, ebx
.loop_owner:
    cmp ebx, [count]
    jge .done
    call get_vehicle_ptr
    add edi, PLATE_LEN
    mov esi, input_buf
    call str_cmp
    test eax, eax
    jne .next_owner
    test ecx, ecx
    jnz .no_header
    call print_vehicle_header
    inc ecx
.no_header:
    call print_vehicle
.next_owner:
    inc ebx
    jmp .loop_owner
.done:
    test ecx, ecx
    jnz menu_display
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
; Helper Functions (unchanged)
; ================================
get_vehicle_ptr:
    mov eax, ebx
    imul eax, REC_SIZE
    lea edi, [vehicles + eax]
    ret

find_by_plate:
    xor ebx, ebx
.loop:
    cmp ebx, [count]
    jge .notfound
    call get_vehicle_ptr
    push edi
    add edi, PLATE_LEN + NAME_LEN
    cmp byte [edi], 0
    pop edi
    je .next
    mov esi, input_buf
    call str_cmp
    test eax, eax
    jz .found
.next:
    inc ebx
    jmp .loop
.notfound:
    mov ebx, -1
.found:
    ret

mark_deleted:
    add edi, PLATE_LEN + NAME_LEN
    mov byte [edi], 0
    ret

print_vehicle_header:
    push msg_header
    call _printf
    add esp, 4
    ret

print_vehicle:
    push edi
    push fmt_strln
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

str_cmp:
    push esi
    push edi
.loop:
    mov al, [esi]
    mov bl, [edi]
    cmp al, bl
    jne .diff
    test al, al
    jz .equal
    inc esi
    inc edi
    jmp .loop
.diff:
    sub eax, ebx
    pop edi
    pop esi
    ret
.equal:
    xor eax, eax
    pop edi
    pop esi
    ret

str_copy:
    push edi
.loop:
    lodsb
    stosb
    test al, al
    jnz .loop
    pop edi
    ret

exit_program:
    push 0
    call _exit