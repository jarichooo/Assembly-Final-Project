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
    char_format db "%c", 0             

    ; Return to Menu Display Variable
    ret_menu db 10, "Returning to main menu...", 10, 0

    ; Five Numbers Variables
    num_display db "Enter integer #%d: ", 0
    num_entered db 10, "Numbers entered: ", 0
    num_asc db 10, "Ascending: ", 0
    num_desc db 10, "Descending: ", 0
    int_out db "%d ", 0

    ; Five Words Variables
    word_prompt db "Enter word #%d: ", 0
    conv_words_msg db 10, "Converted words:", 10, 0
    word_conv_fmt db "%s  -> %s", 10, 0
    word_asc_msg db 10, "Sorted ascending:", 10, 0
    word_desc_msg db 10, "Sorted descending:", 10, 0
    word_fmt db "%s", 10, 0
    err_letters db "ERROR: Words may only contain letters. Please re-enter.", 10, 0
    err_spaces db "ERROR: Words cannot contain spaces. Please re-enter.", 10, 0

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
    
    ; Five Words Variables
    word_input resb 32
    words resb 160         ; Space for 5 words, 32 bytes each
    conv_words resb 160    ; Space for 5 converted words

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
    
    ; Consume the newline left in the buffer by scanf
    push inbuf
    push char_format
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

    cmp eax, 2
    je five_words

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

    push newline
    call _printf
    add esp, 4

    jmp return_to_menu

; FIVE WORDS FUNCTION
five_words:
    ; Reset counter
    mov dword [count], 0

read_word_loop:
    ; Check if we've read 5 words
    mov eax, [count]
    cmp eax, 5
    jge process_words         ; If we have 5 words, process them

    ; Clear word_input buffer
    mov ecx, 32
    mov edi, word_input
clear_word_input:
    mov byte [edi], 0
    inc edi
    loop clear_word_input

    ; Print prompt
    mov ebx, eax
    inc ebx                   ; Add 1 for 1-based display
    push ebx
    push word_prompt
    call _printf
    add esp, 8

    ; Read word character by character until newline
    ; This ensures we only read one line and properly handle input
    mov edi, word_input
    mov ecx, 31               ; Maximum 31 characters (leaving room for null terminator)
    
read_char_loop:
    ; Read one character
    push inbuf
    push char_format
    call _scanf
    add esp, 8
    
    ; Check if scanf failed or returned 0
    cmp eax, 0
    jle end_read_line
    
    ; Get the character we just read
    mov al, [inbuf]
    
    ; Check if it's a newline (end of line)
    cmp al, 10                ; \n
    je end_read_line
    cmp al, 13                ; \r (Windows)
    je handle_cr
    
    ; Store the character
    mov [edi], al
    inc edi
    dec ecx
    jnz read_char_loop        ; Continue reading if we haven't hit max length
    
    ; If we've read 31 characters, consume the rest of the line
    jmp consume_rest_of_line

handle_cr:
    ; On Windows, \r might be followed by \n
    ; Try to read the next character to see if it's \n
    push inbuf
    push char_format
    call _scanf
    add esp, 8
    cmp eax, 0
    jle end_read_line
    mov al, [inbuf]
    cmp al, 10                ; Check if it's \n
    je end_read_line
    ; If not \n, we need to handle this character (unlikely but possible)
    ; For now, just end the line
    jmp end_read_line

consume_rest_of_line:
    ; We've read the maximum length, consume the rest until newline
    push inbuf
    push char_format
    call _scanf
    add esp, 8
    cmp eax, 0
    jle end_read_line
    mov al, [inbuf]
    cmp al, 10                ; \n
    je end_read_line
    cmp al, 13                ; \r
    je handle_cr_rest
    jmp consume_rest_of_line

handle_cr_rest:
    ; Consume \n after \r
    push inbuf
    push char_format
    call _scanf
    add esp, 8
    jmp end_read_line

end_read_line:
    ; Null terminate the string
    mov byte [edi], 0
    
    ; Check if word_input is empty (user just pressed Enter)
    mov esi, word_input
    mov al, [esi]
    test al, al
    jz read_word_loop       ; If empty, read again
    jmp validate_word

validate_word:
    ; Validate word (check for spaces first)
    mov esi, word_input
check_spaces:
    mov al, [esi]
    test al, al              ; Check for null terminator
    jz check_letters         ; If end of string, check for letters
    cmp al, ' '             ; Check for space
    je invalid_spaces
    cmp al, 9               ; Check for tab
    je invalid_spaces
    cmp al, 13              ; Check for carriage return (Windows)
    je invalid_spaces
    cmp al, 10              ; Check for newline (shouldn't be here, but just in case)
    je invalid_spaces
    inc esi
    jmp check_spaces

check_letters:
    mov esi, word_input
check_letter_loop:
    mov al, [esi]
    test al, al              ; Check for null terminator
    jz valid_word            ; If end of string, word is valid
    
    ; Check if character is a letter (A-Z or a-z)
    cmp al, 'A'
    jl invalid_letters
    cmp al, 'Z'
    jle valid_char
    cmp al, 'a'
    jl invalid_letters
    cmp al, 'z'
    jg invalid_letters

valid_char:
    inc esi
    jmp check_letter_loop

invalid_spaces:
    push err_spaces
    call _printf
    add esp, 4
    ; Clear word_input buffer for next read
    mov ecx, 32
    mov edi, word_input
clear_after_error:
    mov byte [edi], 0
    inc edi
    loop clear_after_error
    ; The newline was already consumed, but we need to ensure we wait for NEW input
    ; The next scanf will block and wait for user input, which is what we want
    jmp read_word_loop

invalid_letters:
    push err_letters
    call _printf
    add esp, 4
    ; Clear word_input buffer for next read
    mov ecx, 32
    mov edi, word_input
clear_after_letter_error:
    mov byte [edi], 0
    inc edi
    loop clear_after_letter_error
    ; The newline was already consumed, but we need to ensure we wait for NEW input
    ; The next scanf will block and wait for user input, which is what we want
    jmp read_word_loop

valid_word:
    ; Copy word to words array
    mov esi, word_input
    mov edi, words
    mov eax, [count]
    imul eax, 32             ; Multiply by word size
    add edi, eax             ; Add offset to array base
    
copy_word_loop:
    mov al, [esi]
    mov [edi], al
    test al, al              ; Check for null terminator
    jz word_copied
    inc esi
    inc edi
    jmp copy_word_loop

word_copied:
    inc dword [count]
    jmp read_word_loop

process_words:
    ; Display conversion header
    push conv_words_msg
    call _printf
    add esp, 4

    ; Convert and display each word
    mov ecx, 5               ; Counter for 5 words
    xor ebx, ebx             ; Array index

convert_display_loop:
    push ecx                 ; Save counter

    ; Convert current word
    lea esi, [words + ebx]   ; Source word
    lea edi, [conv_words + ebx] ; Destination for converted word
    call convert_word

    ; Display original and converted
    lea eax, [conv_words + ebx]
    push eax                 ; Converted word
    lea eax, [words + ebx]
    push eax                 ; Original word
    push word_conv_fmt
    call _printf
    add esp, 12

    add ebx, 32              ; Move to next word
    pop ecx
    dec ecx
    jnz convert_display_loop

    ; Sort and display ascending
    push word_asc_msg
    call _printf
    add esp, 4
    
    call sort_words_asc
    call display_sorted_words

    ; Sort and display descending
    push word_desc_msg
    call _printf
    add esp, 4
    
    call sort_words_desc
    call display_sorted_words

    jmp return_to_menu

; Convert word subroutine - converts vowels to numbers
; esi = source word, edi = destination
convert_word:
convert_loop:
    mov al, [esi]
    test al, al              ; Check for end of string
    jz end_convert

    ; Convert vowels to numbers (case-insensitive)
    cmp al, 'a'
    je conv_a
    cmp al, 'A'
    je conv_a
    cmp al, 'e'
    je conv_e
    cmp al, 'E'
    je conv_e
    cmp al, 'i'
    je conv_i
    cmp al, 'I'
    je conv_i
    cmp al, 'o'
    je conv_o
    cmp al, 'O'
    je conv_o
    cmp al, 'u'
    je conv_u
    cmp al, 'U'
    je conv_u

    ; Not a vowel, convert uppercase to lowercase if needed
    cmp al, 'A'
    jl store_char          ; If less than 'A', not a letter, store as-is
    cmp al, 'Z'
    jg store_char          ; If greater than 'Z', not uppercase, store as-is
    ; It's an uppercase letter, convert to lowercase
    add al, 32             ; Convert to lowercase (A=65, a=97, difference is 32)
    
store_char:
    mov [edi], al
    inc esi
    inc edi
    jmp convert_loop

conv_a:
    mov byte [edi], '1'
    jmp next_char
conv_e:
    mov byte [edi], '2'
    jmp next_char
conv_i:
    mov byte [edi], '3'
    jmp next_char
conv_o:
    mov byte [edi], '4'
    jmp next_char
conv_u:
    mov byte [edi], '5'
    jmp next_char

next_char:
    inc esi
    inc edi
    jmp convert_loop

end_convert:
    mov byte [edi], 0       ; Null terminate
    ret

; Sort words ascending (bubble sort)
sort_words_asc:
    mov ecx, 4              ; Outer loop counter (n-1)
outer_sort_asc:
    push ecx                ; Save outer counter
    mov esi, conv_words     ; Start of array
    mov edi, conv_words     ; Next element
    add edi, 32

inner_sort_asc:
    push ecx
    push esi
    push edi
    call compare_strings    ; Compare two strings
    pop edi
    pop esi
    pop ecx
    
    cmp eax, 1             ; If first string > second string, swap
    jle no_swap_words_asc
    
    ; Swap words (32 bytes each)
    push ecx
    push esi
    push edi
    mov ecx, 32
swap_loop_asc:
    mov al, [esi]
    mov bl, [edi]
    mov [esi], bl
    mov [edi], al
    inc esi
    inc edi
    loop swap_loop_asc
    pop edi
    pop esi
    pop ecx
    
no_swap_words_asc:
    add esi, 32
    add edi, 32
    dec ecx
    jnz inner_sort_asc

    pop ecx                 ; Restore outer counter
    dec ecx
    jnz outer_sort_asc
    ret

; Sort words descending
sort_words_desc:
    mov ecx, 4              ; Outer loop counter (n-1)
outer_sort_desc:
    push ecx                ; Save outer counter
    mov esi, conv_words     ; Start of array
    mov edi, conv_words     ; Next element
    add edi, 32

inner_sort_desc:
    push ecx
    push esi
    push edi
    call compare_strings    ; Compare two strings
    pop edi
    pop esi
    pop ecx
    
    cmp eax, -1            ; If first string < second string, swap
    jge no_swap_words_desc
    
    ; Swap words (32 bytes each)
    push ecx
    push esi
    push edi
    mov ecx, 32
swap_loop_desc:
    mov al, [esi]
    mov bl, [edi]
    mov [esi], bl
    mov [edi], al
    inc esi
    inc edi
    loop swap_loop_desc
    pop edi
    pop esi
    pop ecx
    
no_swap_words_desc:
    add esi, 32
    add edi, 32
    dec ecx
    jnz inner_sort_desc

    pop ecx                 ; Restore outer counter
    dec ecx
    jnz outer_sort_desc
    ret

; Compare two strings
; Returns: -1 if str1 < str2, 0 if equal, 1 if str1 > str2
; esi = first string, edi = second string (on stack)
compare_strings:
    push ebp
    mov ebp, esp
    mov esi, [ebp + 12]    ; First string
    mov edi, [ebp + 8]     ; Second string

compare_loop:
    mov al, [esi]
    mov bl, [edi]
    test al, al
    jz check_end
    test bl, bl
    jz str1_greater
    cmp al, bl
    jl str1_less
    jg str1_greater
    inc esi
    inc edi
    jmp compare_loop

check_end:
    test bl, bl
    jz strings_equal
    jmp str1_less

str1_less:
    mov eax, -1
    jmp end_compare

strings_equal:
    xor eax, eax
    jmp end_compare

str1_greater:
    mov eax, 1

end_compare:
    mov esp, ebp
    pop ebp
    ret

; Display sorted words
display_sorted_words:
    mov ecx, 5
    mov esi, conv_words
display_loop:
    push ecx
    
    push esi
    push word_fmt
    call _printf
    add esp, 8
    
    add esi, 32
    pop ecx
    dec ecx
    jnz display_loop
    ret

; RETURN TO MENU
return_to_menu:
    ; Display ret_menu Text and Jump Back to _main to show Menu Choice Again.
    push ret_menu
    call _printf
    add esp, 4

    jmp _main