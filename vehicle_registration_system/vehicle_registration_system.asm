section .data
; ===== DATA SECTION =====
; Constants defining sizes for storage
    MAX_VEHICLES equ 100             ; Maximum number of vehicle records
    NAME_LEN     equ 50              ; Max owner name length
    PLATE_LEN    equ 15              ; Max plate number length
    REC_SIZE     equ (PLATE_LEN + NAME_LEN + 1) ; Total record size (+1 = active flag)

; ----- Text strings for menus and prompts -----
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

; User prompts
    prompt_owner db 10,"Enter Owner Name: ",0
    prompt_plate db 10,"Enter Plate Number: ",0

; Status messages
    msg_added    db 10,"Vehicle added successfully!",10,0
    msg_deleted  db 10,"Deleted successfully!",10,0
    msg_notfound db 10,"Not found!",10,0
    msg_full     db 10,"Database is full!",10,0
    msg_empty    db 10,"No vehicles registered.",10,0
    msg_blank    db 10,"Input cannot be empty!",10,0
    msg_exists   db 10,"Plate number already exists!",10,0
    msg_invalid  db 10,"Invalid choice! Please try again.",10,0
    msg_thankyou db 10,"Thank you! Goodbye!",10,0

; Table header for displaying results
    msg_header   db 10
                 db "Plate Number        | Owner Name",10
                 db "--------------------|-----------------------------",10,0

; Formatting strings for printf
    fmt_name     db "%49[^\n]", 0
    fmt_int      db "%d",0
    fmt_str      db "%s",0
    plate_format db "%-20s",0
    separator    db "| ",0
    newline      db 10,0

section .bss
; ===== BSS SECTION =====
    vehicles     resb MAX_VEHICLES * REC_SIZE  ; Storage space for all vehicles
    input_buf    resb 100                      ; Input buffer for strings
    choice       resd 1                        ; Stores user menu selection
    count        resd 1                        ; Track total vehicles added
    temp_index   resd 1                        ; Loop index for iterating records
    found_count  resd 1                        ; Count matches in search/delete
    scanf_result resd 1                        ; Check if scanf successfully read a number

section .text
    global _main
    extern _printf, _scanf, _getchar, _exit

; ===== PROGRAM ENTRY POINT =====
_main:
    mov dword [count], 0               ; Initialize record count to zero
    jmp main_menu_loop                 ; Enter main menu

; ===================== MAIN MENU =====================
main_menu_loop:
    push main_menu
    call _printf                       ; Print main menu
    add esp, 4

    push choice
    push fmt_int
    call _scanf                        ; Read integer option
    add esp, 8
    mov [scanf_result], eax
    call clear_input_buffer            ; Clean leftover input

    cmp dword [scanf_result], 1        ; If input was not valid integer → invalid
    jne .invalid
    mov eax, [choice]
    cmp eax, 1
    jl .invalid
    cmp eax, 5
    jg .invalid

; Branch to menu options
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

.invalid:
    push msg_invalid
    call _printf
    add esp, 4
    jmp main_menu_loop                 ; Show main menu again

; ===================== ADD MENU =====================
menu_add:
    push submenu_add
    call _printf                       ; Print Add submenu
    add esp, 4

    push choice
    push fmt_int
    call _scanf                        ; Read selection
    add esp, 8
    mov [scanf_result], eax
    call clear_input_buffer

    cmp dword [scanf_result], 1
    jne .invalid
    mov eax, [choice]

    cmp eax, 1
    je do_add_vehicle                  ; Add new vehicle
    cmp eax, 2
    je main_menu_loop                  ; Back to main

.invalid:
    push msg_invalid
    call _printf
    add esp, 4
    jmp menu_add

; ---- Adding a vehicle record ----
do_add_vehicle:
    mov eax, [count]
    cmp eax, MAX_VEHICLES              ; Check if database full
    jge add_full

; Compute pointer to next empty record slot
    imul eax, REC_SIZE
    lea edi, [vehicles + eax]

; --- Read Owner Name ---
.retry_owner:
    push prompt_owner
    call _printf
    add esp, 4

    call read_line                     ; Reads input without cutting any character

    cmp byte [input_buf], 0            ; Check if input is blank
    je .owner_is_blank

    lea edi, [edi + PLATE_LEN]         ; Move to owner field
    mov esi, input_buf
    call str_copy                      ; Copy name to record
    sub edi, PLATE_LEN                 ; Move back to start of record
    jmp .get_plate

.owner_is_blank:
    push msg_blank
    call _printf
    add esp, 4
    jmp .retry_owner                   ; Ask again

; --- Read Plate Number ---
.get_plate:
.retry_plate:
    push prompt_plate
    call _printf
    add esp, 4

    call read_line

    cmp byte [input_buf], 0            ; Check if input is blank
    je .plate_is_blank

    jmp .check_duplicates              ; Proceed to check logic

.plate_is_blank:
    push msg_blank
    call _printf
    add esp, 4
    jmp .retry_plate                   ; Ask plate number input again

; --- Check for duplicates ---
.check_duplicates:
    push edi                           ; Save pointer to new record
    mov dword [temp_index], 0

.check_dup_loop:
    mov eax, [temp_index]
    cmp eax, [count]
    jge .check_dup_done                ; No duplicates found, proceed

; Get existing record
    imul eax, REC_SIZE
    lea esi, [vehicles + eax]
    
; Check if active
    cmp byte [esi + PLATE_LEN + NAME_LEN], 0
    je .check_next

; Compare input_buf (new plate) vs [esi] (existing plate)
    push edi                           ; Save EDI
    mov edi, esi                       ; EDI = existing record plate
    mov esi, input_buf                 ; ESI = new plate input
    call str_cmp_ci
    pop edi                            ; Restore EDI
    
    test eax, eax
    jz .duplicate_found                ; If 0 (equal), duplicate found!

.check_next:
    inc dword [temp_index]
    jmp .check_dup_loop

.duplicate_found:
    pop edi                            ; Clean stack
    push msg_exists
    call _printf
    add esp, 4
    jmp menu_add                       ; Cancel add, go back to menu

.check_dup_done:
    pop edi                            ; Restore pointer to new record

; Copy plate to record (Since no duplicate was found)
    mov esi, input_buf
    call str_copy

; Mark record as active (1)
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

; ===================== DELETE MENU =====================
menu_delete:
    push submenu_delete
    call _printf                       ; Show delete menu
    add esp, 4

    push choice
    push fmt_int
    call _scanf
    add esp, 8
    mov [scanf_result], eax
    call clear_input_buffer

; Validate input
    cmp dword [scanf_result], 1
    jne .invalid
    mov eax, [choice]
    cmp eax, 1
    jl .invalid
    cmp eax, 3
    jg .invalid

; Branch based on delete option
    cmp eax, 1
    je delete_by_plate_once
    cmp eax, 2
    je delete_by_owner_once
    cmp eax, 3
    je main_menu_loop

.invalid:
    push msg_invalid
    call _printf
    add esp, 4
    jmp menu_delete

; -------- Delete by Plate Number --------
; (Search & mark matching record as inactive)
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
    jge .done                            ; Loop end if reached total count
    call get_vehicle_ptr                 ; EDI = record ptr

    add edi, PLATE_LEN + NAME_LEN        ; Go to active flag
    cmp byte [edi], 0
    je .next                             ; Skip inactive
    sub edi, PLATE_LEN + NAME_LEN        ; Back to start of record

; Compare plate (case insensitive)
    mov esi, input_buf
    call str_cmp_ci
    test eax, eax
    jne .next

; Plate matched → mark inactive
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

; -------- Delete by Owner Name --------
delete_by_owner_once:
    push prompt_owner
    call _printf
    add esp, 4

    call read_line

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

; Compare owner name
    mov esi, input_buf
    call str_cmp_ci
    test eax, eax
    jne .next

; Mark record inactive
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

; ===================== SEARCH MENU =====================
menu_search:
    push submenu_search
    call _printf
    add esp, 4

    push choice
    push fmt_int
    call _scanf
    add esp, 8
    mov [scanf_result], eax
    call clear_input_buffer

; Validate
    cmp dword [scanf_result], 1
    jne .invalid
    mov eax, [choice]
    cmp eax, 1
    jl .invalid
    cmp eax, 3
    jg .invalid

; Branch
    cmp eax, 1
    je search_by_plate_once
    cmp eax, 2
    je search_by_owner_once
    cmp eax, 3
    je main_menu_loop

.invalid:
    push msg_invalid
    call _printf
    add esp, 4
    jmp menu_search

; -------- Search by Plate --------
search_by_plate_once:
    push prompt_plate
    call _printf
    add esp, 4

    push input_buf
    push fmt_str
    call _scanf
    add esp, 8
    call clear_input_buffer

; Initialize counters
    mov dword [found_count], 0
    mov dword [temp_index], 0

.loop:
    mov eax, [temp_index]
    cmp eax, [count]
    jge .done
    call get_vehicle_ptr

; Skip inactive
    add edi, PLATE_LEN + NAME_LEN
    cmp byte [edi], 0
    je .next

; Compare plate
    sub edi, PLATE_LEN + NAME_LEN
    mov esi, input_buf
    call str_cmp_ci
    test eax, eax
    jne .next

; Print header only once
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

; If none found
    push msg_notfound
    call _printf
    add esp, 4
    jmp menu_search

; -------- Search by Owner --------
search_by_owner_once:
    push prompt_owner
    call _printf
    add esp, 4

    call read_line

    mov dword [found_count], 0
    mov dword [temp_index], 0

.loop:
    mov eax, [temp_index]
    cmp eax, [count]
    jge .done
    call get_vehicle_ptr

; Skip inactive
    add edi, PLATE_LEN + NAME_LEN
    cmp byte [edi], 0
    je .next

; Compare owner name
    sub edi, NAME_LEN
    mov esi, input_buf
    call str_cmp_ci
    test eax, eax
    jne .next

; Only print header once
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

; No matches
    push msg_notfound
    call _printf
    add esp, 4
    jmp menu_search

; ===================== DISPLAY MENU =====================
menu_display:
    push submenu_display
    call _printf
    add esp, 4

    push choice
    push fmt_int
    call _scanf
    add esp, 8
    mov [scanf_result], eax
    call clear_input_buffer

; Input validation
    cmp dword [scanf_result], 1
    jne .invalid
    mov eax, [choice]
    cmp eax, 1
    jl .invalid
    cmp eax, 3
    jg .invalid

; Branch
    cmp eax, 1
    je display_all
    cmp eax, 2
    je display_by_owner_once
    cmp eax, 3
    je main_menu_loop

.invalid:
    push msg_invalid
    call _printf
    add esp, 4
    jmp menu_display

; -------- Display ALL vehicles --------
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

; Skip inactive entries
    add edi, PLATE_LEN + NAME_LEN
    cmp byte [edi], 0
    je .next

    sub edi, PLATE_LEN + NAME_LEN
    call print_vehicle

.next:
    inc dword [temp_index]
    jmp .loop

; -------- Display by owner filter --------
display_by_owner_once:
    push prompt_owner
    call _printf
    add esp, 4

    call read_line

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

; Compare owner name
    sub edi, NAME_LEN
    mov esi, input_buf
    call str_cmp_ci
    test eax, eax
    jne .next

; Print header once
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

; ===================== HELPER FUNCTIONS =====================
; Reads all the input without cutting off any character.
read_line:
    push edi
    push ebx                           ; Save EBX 
    mov edi, input_buf
    xor ebx, ebx                       ; Use EBX as counter

.rl_loop:
    call _getchar
    cmp al, 10                         ; Check for Newline
    je .rl_done
    cmp al, 13                         ; Check for Carriage Return
    je .rl_loop
    cmp al, -1                         ; Check for EOF
    je .rl_done

    cmp ebx, 90                        ; Prevents buffer overflow
    jge .rl_loop                       ; If full, keep reading to consume line, but don't store

    mov [edi], al                      ; Store character
    inc edi
    inc ebx
    jmp .rl_loop

.rl_done:
    mov byte [edi], 0                  ; Null-terminate the string
    pop ebx                            ; Restore EBX
    pop edi
    ret

; Get pointer to vehicle record based on temp_index
get_vehicle_ptr:
    mov eax, [temp_index]
    imul eax, REC_SIZE
    lea edi, [vehicles + eax]
    ret

; Print plate and owner in formatted layout
print_vehicle:
    push edi  
    push edi
    push plate_format
    call _printf
    add esp, 8

    push separator
    call _printf
    add esp, 4

    pop edi

; Print owner name
    add edi, PLATE_LEN
    push edi
    push fmt_str
    call _printf
    add esp, 8

    push newline
    call _printf
    add esp, 4
    ret

; Clear input buffer after scanf
clear_input_buffer:
    push eax
.loop:
    call _getchar
    cmp al, 10       ; Stop at newline
    je .done
    cmp al, -1       ; EOF?
    jne .loop
.done:
    pop eax
    ret

; Case-insensitive string comparison
; Returns eax=0 if equal, eax=1 if not equal
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

; Convert lower→upper for comparison
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

; String copy (null-terminated)
str_copy:
    push edi
.loop:
    lodsb
    stosb
    cmp al, 0
    jne .loop
    pop edi
    ret

; Program exit
exit_program:
    push msg_thankyou
    call _printf
    add esp, 4

    push 0
    call _exit
