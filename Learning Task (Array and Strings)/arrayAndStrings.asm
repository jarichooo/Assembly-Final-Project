section .data
    ; Menu Display Variables
    menu_display db 10, "MENU:", 10, \
                  "[1] Enter five numbers", 10, \
                  "[2] Enter five words", 10, \
                  "[0] Exit", 0

    ; Choice Display and Integer Format Variable
    option db "Enter choice: ", 0
    int_format db "%d", 0
    str_format db "%s", 0             

    ; Return to Menu Display Variable
    ret_menu db 10, "Returning to main menu...", 10, 0

    ; Five Numbers Variables
    num_display db "Enter integer #%d: ", 0
    num_entered db 10, "Numbers entered: ", 0
    num_asc db 10, "Ascending: ", 0
    num_desc db 10, "Descending: ", 0
    int_out db "%d ", 0

    ; Error Display Variables
    err_menu db "ERROR: Invalid menu choice. Please try again.", 10, 0
    err_integer db "ERROR: Input is not a valid integer. Please re-enter.", 10, 0
    err_posi_integer db "ERROR: Only positive integers are allowed. Please re-enter.", 10, 0
    quit db "Program terminated.", 10, 0
    newline db 10, 0

section .bss
    ; Buffer Variables
    input_choice resd 1
    num_input resd 1
    nums resd 5
    inbuf resb 64
    count resd 1

section .text
    global _main
    extern _printf
    extern _scanf

_main:
    ; Display Menu 
    push menu_display
    call _printf
    add esp, 4

    push newline
    call _printf
    add esp, 4

    jmp menu

menu:
    ; Display Option Prompt
    push option
    call _printf
    add esp, 4

    ; Read Option Choice
    push input_choice
    push int_format
    call _scanf
    add esp, 8

    push newline
    call _printf
    add esp, 4

    ; Assign Choice to eax
    mov eax, [input_choice]

    ; Compare Choice to Jump to Desired Function
    cmp eax, 0
    je exit_program

    cmp eax, 1
    je five_numbers

    ; cmp eax, 2
    ; je five_words

    push err_menu
    call _printf
    add esp, 4

    jmp _main

; EXIT FUNCTION
exit_program:
    push quit
    call _printf
    add esp, 4

    mov eax, 0 
    ret

; FIVE NUMBERS FUNCTION
five_numbers:
    ; Make sure the Array is Cleaned to Prevent Leftover Garbage
    mov ecx, 5
    lea esi, [nums]
zero_loop:
    ; Set current element to 0
    mov dword [esi], 0
    add esi, 4
    dec ecx
    ; Repeat til ecx == 0
    jnz zero_loop

    ; Set count to 0
    mov dword [count], 0

read_loop:
    ; Check How Many Numbers Have Been Entered
    mov eax, [count]
    cmp eax, 5
    ; Jump to Sort if count >= 5. If Not Continue
    jge proceed_sort

    ; Display Prompt with 1-Based Index to Make It Numbered
    mov ebx, eax
    inc ebx
    push ebx
    push num_display
    call _printf
    add esp, 8

    ; Read User Input and Store in num_input
    push num_input
    push int_format
    call _scanf
    add esp, 8

    ; Check if a Valid Integer was Read. If not Jump to invalid_input
    cmp eax, 1
    jne invalid_input

    ; Check if Number is Positive. If number <= 0, Jump to not_positive
    mov eax, [num_input]
    cmp eax, 0
    jle not_positive

store_number:
    ; Store the Valid Integers
    lea esi, [nums]
    mov ecx, [count]
    ; shl Multiplies the Index by 4 to Calculate Memory Offset
    shl ecx, 2         
    add esi, ecx
    mov [esi], eax

    ; Increment count and Loop Back to Read Next Number
    inc dword [count]
    jmp read_loop

invalid_input:
    ; Display Error Message
    push err_integer
    call _printf
    add esp, 4

    ; Read the Leftover Invalid to Discard it.
    push inbuf
    push str_format
    call _scanf
    add esp, 8
    ; Read Another Number
    jmp read_loop

not_positive:
    ; Display Error Message
    push err_posi_integer
    call _printf
    add esp, 4
    jmp read_loop

; DISPLAY ENTERED NUMBERS
proceed_sort:
    push num_entered
    call _printf
    add esp, 4

    ; Loop through the nums arrays
    mov ebx, 5
    lea esi, [nums]
print_entered_nums:
    ; Display the Numbers in the Order Entered.
    push dword [esi]
    push int_out
    call _printf
    add esp, 8
    add esi, 4
    dec ebx
    jnz print_entered_nums

    jmp sort_asc

; SORT ASCENDING
sort_asc:
    ; Bubble Sort for 5 Numbers
    mov ecx, 4
outer_asc:
    mov edi, 0
inner_asc:
    ; Compare Neighboring Numbers. Swap if Not in Order. Repeat until Array is Sorted in Ascending Order
    mov eax, [nums + edi*4]
    mov edx, [nums + edi*4 + 4]   
    cmp eax, edx
    jle no_swap_asc
    mov [nums + edi*4], edx
    mov [nums + edi*4 + 4], eax
no_swap_asc:
    inc edi
    cmp edi, ecx
    jl inner_asc
    dec ecx
    jnz outer_asc

    push num_asc
    call _printf
    add esp, 4

    ; Display Numbers in Ascending Order
    mov ebx, 5
    lea esi, [nums]
print_asc:
    push dword [esi]
    push int_out
    call _printf
    add esp, 8
    add esi, 4
    dec ebx
    jnz print_asc

    jmp sort_desc

; SORT DESCENDING
sort_desc:
    ; Display Ascending Array in Reverse
    push num_desc
    call _printf
    add esp, 4

    mov ebx, 5
    ; Start at the last number in the array
    lea esi, [nums + 16]  
print_desc:
    ; Display in Reverse Order to make it an Array in Descending Order
    push dword [esi]
    push int_out
    call _printf
    add esp, 8
    sub esi, 4
    dec ebx
    jnz print_desc

    jmp return_to_menu

; RETURN TO MENU
return_to_menu:
    ; Display ret_menu Text and Jump Back to _main to show Menu Choice Again.
    push newline
    call _printf
    add esp, 4

    push ret_menu
    call _printf
    add esp, 4

    jmp _main