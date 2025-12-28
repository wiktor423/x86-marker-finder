  ;HOW THE PROGRAM WORKS 


  ;I scan the BMP file pixel by pixel and for each pixel I call get_pixel to return the color
  ;When the black pixel is found, i check one pixel up (unless y=0) to check if the marker or something resembling a marker wasn't already analized 
  ;if pixel above the found black is not black I increment the "thickness" of the letter, the top bar of letter L 
  ;program continues increasing counter of consecutive black pixel, when it finds other pixel after series of black ones it goes back to the begining of the black line 
  ;from the begining of the black line program goes down checking if the pixels are black, and counts the number of them 
  ;once the height of vertical line is found IT IS COMPARED WITH THICKNESS if(height > 2*thickness) -> still potential marker otherwise, go to next pixel 
  ;then program starts scanning horizontally from the bottom of the vertical line 
  ;it compares the width with height to check if their ratio is 1:1 
  ;if the above conditions are met program checks the interior of the marker within its thickness 
  ;after successful checking of the interior the shape is confirmed as a marker and saved, and the scan in the main loop is resumed from the end of the first black line (thickness line) 
  

    section .text 
    global find_markers    

find_markers: 
    ;prologue 
    push    ebp
    mov     ebp, esp 

    push    ebx
    push    edi
    push    esi

    sub     esp, 12

    mov     dword[ebp - 16], 0 ;return value, number of found markers 

    mov     esi, [ebp + 8]          ;buffer

    mov     eax, dword [esi + 18]   ; image width from the header
    mov     [ebp - 20], eax         ; 

    mov     eax, dword [esi + 22]   ; image height from the header
    mov     [ebp - 24], eax  
    ;            [ebp+12];  x_array 
    ;            [ebp+16]   y_array 


    xor     edx, edx

.outer_loop:
    xor     ecx, ecx   ;reset the x (next line)
    cmp     edx, dword[ebp-24]     

    jge     .end_loops ;end of the loop

    xor     edi, edi    ;reset the thickness counter in the next line 

.inner_loop: 
    ;make the comparison with width 
    cmp     ecx, dword[ebp-20]
    jge     .next_row

    mov     eax, esi 

    push    ecx     ;preserve ecx since it is changed in get_pixel

    ;passing 3 arguments for get_pixel 
    push    edx     ;y 
    push    ecx     ;x
    push    eax     ;buffer 

    call    get_pixel 
    add     esp, 12

    ;retriving the old counter 
    pop     ecx

    cmp     eax, 0 
    jz      .inspect_black 
    cmp     edi, 0 

    jz      .skip_pixel                  ;if thickness 0 go to next pixel
    
    mov     eax, ecx 
    sub     eax, edi                     ;begining of vertical line 

    push    ecx                          ;save current x 
    push    edx                          ;save current y  

    push    esi                         ;buffer                 
    push    edx                         ;current y              
    push    eax                         ;begining of horizontal bar 

    call    downward_scan 
    add     esp, 12 

    pop     edx 
    pop     ecx 

    shl     edi, 1                      ;multiply thickness by 2 
    cmp     eax, edi                    ;compare vertical line with thickness 
    jl      .skip_pixel                ; if vertical is not at least 2*thickness of a letter ->skip 
    shr     edi, 1                      ;go back to the old state of edi
    
    ;horizontal scan call   
    mov     ebx, eax 
    push    ecx                         ;saving the scan x_coordinate 
    push    edx                         ;saving the scan y_coordinate 

    sub     ecx, edi                    ;preparing variables for the function call
    add     edx, eax     
    dec     edx                         ;eax+edi gives one too much               

    push    esi                         ;buffer 
    push    edx                         ;y
    push    ecx                         ;x

    call    horizontal_scan 
    add     esp, 12 

    pop     edx 
    pop     ecx 

    cmp     eax, ebx                    ;eax result, ebx saved length (width or height)
    jne     .skip_pixel 

    push    ebx     ;arm length 
    push    edi     ;thickness 
    push    ecx     ;x_coordinate 
    push    edx     ;y_coordinate 
    push    esi     ;buffer 

    call    check_interior 
    add     esp, 20 


    cmp     eax, 1 
    je      .save_marker_coordinates
    jmp     .skip_pixel 

.inspect_black: 
    cmp     edx, 0                       ;if y=0 don't check pixel above 
    jz      .thickness_increase          ;in y=0 we increase thickness without checks

    cmp     edi, 0                       ;check if marker processed only if thickness 0 
    jz      .check_if_marker_processed   ;check pixel one above
    jmp     .thickness_increase          ;if edi!=0 just increase it 

.check_if_marker_processed: 
    push    edx 
    push    ecx 

    mov     eax, esi 

    dec     edx

    push    edx ;y-1
    push    ecx ;x
    push    eax ;buffer

    call    get_pixel 
    add     esp, 12 

    pop     ecx
    pop     edx

    cmp     eax, 0 
    jz      .skip_pixel
    jmp     .thickness_increase

.thickness_increase:
    inc     ecx 
    inc     edi 
    jmp     .inner_loop

.skip_pixel:
    inc     ecx 
    xor     edi, edi 
    jmp     .inner_loop 
    
.next_row: 
    inc     edx 
    jmp     .outer_loop

.save_marker_coordinates: 
    mov    eax, dword[ebp-16]       ;eax = marker_num

    push   ecx                      ;preserving the registers 
    push   edx 

    sub    ecx, edi                 ;ecx = marker_x_pos 
    mov    edi, [ebp+12] 
    mov    [edi + eax*4], ecx  

    add    edx, ebx 
    dec    edx                      ;edx = marker_y_pos

    mov    ebx, [ebp+16] 
    mov    [ebx + eax*4], edx 

    inc    dword[ebp-16] 
    
    pop     edx
    pop     ecx 

    jmp     .skip_pixel

.end_loops:
    ;epilogue
    mov     eax, dword[ebp-16]

    add     esp, 12 

    pop     esi 
    pop     edi 
    pop     ebx 

    mov     esp, ebp 
    pop     ebp 
    ret 

get_pixel:
    push    ebp
    mov     ebp, esp

    push    ebx
    push    esi
    push    edi

    sub     esp, 4

    mov     esi, [ebp+8]    ; esi = buffer_ptr 
    mov     eax, [ebp+12]   ; eax = input_x coordinate
    mov     edx, [ebp+16]   ; edx = input_y coordinate 


    push    eax             

    movzx   eax, byte [esi+10]
    movzx   ebx, byte [esi+11]  
    shl     ebx, 8
    or      eax, ebx
    movzx   ebx, byte [esi+12]
    shl     ebx, 16
    or      eax, ebx
    movzx   ebx, byte [esi+13]
    shl     ebx, 24
    or      eax, ebx
    ;eax now holds pixel_data_start_offset.
    mov     [ebp-16], eax   

    pop     eax             

    ; esi = buffer_ptr
    ; eax = input_x
    ; edx = input_y
    ; [ebp-16] = pixel_data_start_offset 


    mov     ecx, dword [esi + 18]   ; ecx = image_width

    mov     ebx, dword [esi + 22]   ; ebx = image_height 


    mov     edi, ecx                ;image_width
    imul    edi, 3                  ;image_width * 3 (bytes per row without padding)
    add     edi, 3                  ;(image_width * 3) + 3
    and     edi, 0xFFFFFFFC         ;edi & ~3 


    mov     ecx, ebx                
    dec     ecx                     
    sub     ecx, edx                ; (image_height - 1) - input_y (

    imul    ecx, edi                
    imul    eax, eax, 3             

    add     eax, ecx                ; eax = total offset 

    mov     ecx, [ebp-16]          
    add     eax, ecx                


    add     esi, eax                


    movzx   eax, byte [esi]         ;inversing the order -> BBGGRR -> RRGGBB
    movzx   ebx, byte [esi+1]    
    shl     ebx, 8
    or      eax, ebx
    movzx   ebx, byte [esi+2]  
    shl     ebx, 16
    or      eax, ebx

    ;eax now holds RRGGBB

    add     esp, 4          ;dealoacte local variable 
    pop     edi
    pop     esi
    pop     ebx
    mov     esp, ebp
    pop     ebp
    ret
downward_scan: 
    push    ebp 
    mov     ebp, esp 

    sub     esp, 12 

    push    ebx 
    push    esi 
    push    edi 

    ;[ebp-4] :local_x_start 
    ;[ebp-8] :local_y_start 
    ;[ebp-12]:local_v_length 


    mov     eax, [ebp + 8]  ;x from the caller 
    mov     [ebp-4], eax 

    mov     eax, [ebp + 12] ;y fron the caller   
    mov     [ebp-8], eax 

    mov     eax, [ebp+16] ;buffer
    mov     ebx, eax  

    mov     dword [ebp-12], 0  

.downward_scan_start: 
    mov     ecx, [ebp-4] 
    mov     edx, [ebp-8] 

    mov     eax, dword [esi + 22]
    cmp     dword [ebp-12], eax
    je      .downward_scan_finish

    push    edx 
    push    ecx 
    push    ebx 

    call    get_pixel 
    add     esp, 12

    cmp     eax, 0 
    jne     .downward_scan_finish 

    inc     dword [ebp-12]  ;increase vertical length  
    inc     dword [ebp-8]   ;increase the y to go down in the next iteration 
    jmp     .downward_scan_start 
    
.downward_scan_finish: 
    mov eax, [ebp-12] 

    pop edi 
    pop esi 
    pop ebx 

    mov esp, ebp 
    pop ebp 
    ret  
  
horizontal_scan: 
    push    ebp 
    mov     ebp, esp 
    
    sub     esp, 12 

    push    ebx 
    push    edi 
    push    esi 

    mov     eax, [ebp + 8]          ;x from the caller 
    mov     [ebp - 4], eax

    mov     eax, [ebp + 12]         ;y from the caller 
    mov     [ebp - 8], eax

    mov     eax, [ebp + 16]         ;buffer 
    mov     ebx, eax   

    mov     dword [ebp-12], 0       ;width counter

.horizontal_scan_start:
    mov     ecx, [ebp-4]
    mov     edx, [ebp-8] 

    mov     eax, dword [esi + 22]
    cmp     dword[ebp-4], eax
    je      .horizontal_scan_finish

    push    edx 
    push    ecx 
    push    ebx 

    call    get_pixel 
    add     esp, 12

    cmp     eax, 0 
    jne     .horizontal_scan_finish 
 
    inc     dword [ebp-4] 
    inc     dword [ebp-12]

    jmp     .horizontal_scan_start

.horizontal_scan_finish: 
    mov     eax, [ebp-12] 

    pop     esi 
    pop     edi 
    pop     ebx 

    mov     esp, ebp 
    pop     ebp 
    ret


check_interior:
    push    ebp 
    mov     ebp, esp 
    sub     esp, 4 

    push    ebx 
    push    esi 
    push    edi 
    push    ecx 
    push    edx 

    mov     esi,  [ebp+8]   ;buffer
    mov     edi,  [ebp+20]  ;arm_thickness
    mov     ebx,  [ebp+24]  ;arm_length  

    cmp     edi, 1 
    jle     .return_success 

    mov     dword[ebp-4], edi 

.check_interior_loop_start: 
    dec     dword[ebp-4]
    cmp     dword[ebp-4], 0
    jz      .return_success 
    
    push    ecx ;storing x 
    push    edx ;storing y 

    mov     eax, ecx 
    sub     eax, dword[ebp-4] 

    push    esi ;buffer 
    push    edx ;y
    push    eax ;x

    call    downward_scan 
    add     esp, 12 

    pop     edx ;restoring y 
    pop     ecx ;restoring x 

    cmp     eax, ebx 
    jnz     .return_fail  

;   now checking horizontally 

    push   ecx
    push   edx 
    
    sub    ecx, edi

    add    edx, ebx 
    sub    edx, dword[ebp-4]
    dec    edx 

    push    esi 
    push    edx 
    push    ecx 

    call    horizontal_scan 
    add     esp, 12 
    
    pop     edx 
    pop     ecx 

    cmp     eax, ebx 
    jz      .check_interior_loop_start
    jmp     .return_fail 

.return_success: 
    mov     eax, 1 
    jmp     .exit 

.return_fail: 
    mov     eax, 0 
    jmp     .exit

.exit: 
    pop     edx 
    pop     ecx 
    pop     edi 
    pop     esi 
    pop     ebx 
    
    mov     esp, ebp 
    pop     ebp 
    ret 