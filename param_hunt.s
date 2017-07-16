.define CUSTOM_RESET
.define REQUIRE_DMG
.define ROM_NAME "POKEMON RED"
.include "shell.inc"


reset:
    ; ROM starts with instructions
    ; nop - 4 cycles
    ; jp reset - 16 cycles
    ; So we should account for 20 extra cycles.

    ; Preserve Boot registers id
    push af ; 16
    push bc ; 16
    push de ; 16
    push hl ; 16

    ; Phase 1: Find rDIV and cycle offset
    ; rDiv is simple: we can just read it.
    ; This read starts 84 cycles after ROM got control.
    ldh a, ($04)  ; 12
    ld b, a     ; 4
    ld d, a     ; 4
    
    ; To determine sub-rDiv, we'll create a loop
    ; that reads rDiv exactly 260 cycles apart
    ; each iteration. Then we'll run it 64 times
    ; and note when rDiv changes by 2 (instead of 1).
    ; When that happens, the sub-rDiv value was 0
    ; on the second read, meaning it was 252 on the
    ; first read. However, note that the FF read happens
    ; 8 cycles after the start of the instruction,
    ; so the first read instruction actually started at
    ; 244 (61 in our scale).
    
    ; 20 cycles have passed since the start of the last ldh
    ; So we need to spend 240 more.

    ; Set up iteration for the 64 times loop
    ld e, 64    ; 8
    ; Do the actual stalling
    ld a, 14   ; 8
div_stall: 
    dec a           ; 4
    jr nz, div_stall   ; 12/8
    ; At this point, we've stalled for 16 + 14*16 - 4 = 236 cycles
    nop             ; 4 more for 240.
div_loop:
    ; Read new rDiv
    ldh a, ($04)    ; 12
    sub d           ; 4
    dec a           ; 4
    jr nz, div_store    ; 12/8
div_nostore:
    jr div_loopstall   ; 12
div_store:
    ; In this case, we've spent 4 cycles more than .nostore
    ; So both paths will take 20 cycles when you include the
    ld c, e         ; 4
    nop             ; 4
div_loopstall:
    ; Update d with new value of rDiv
    inc a           ; 4
    add d           ; 4
    ld d, a         ; 4
    ; So far 52 cycles have passed out of the 260.
    ; Assuming that we'll loop again, we will spend 16 cycles at the end.
    ; So we need to stall for 192 cycles.
    ld a, 11        ; 8
div_loopstallloop:
    dec a           ; 4
    jr nz, div_loopstallloop ; 12 / 8
    ; At this point we've stalled for 8 + 16 * 11 - 4 = 180 cycles, so we need 12 more.
    nop             ; 4
    nop             ; 4
    nop             ; 4
    ; Do the loop again
    dec e           ; 4
    jr nz, div_loop     ; 12 / 8

    ; First read happened 84 cycles after boot, and we did 64 reads after that
    ; spaced 260 cycles apart. At this point we would be doing the 65th additional read,
    ; but we saved 4 cycles by exiting the loop.
    ; So our current cycle count is 84 + 260 * 65 - 4 = 16980

    ; At this point we're done figuring out rDiv and sub-rDiv,
    ; but c is encoded a bit, and these values are for a slight offset of the boot
    ; parameters.
    ld hl, $C000    ; 12
    ld a, b         ; 4
    ld (hl+), a     ; 8
    ld a, c         ; 4
    ld (hl+), a     ; 8

    ld c, 0         ; 8

    ; 44 more cycles -> 17024

    ; Phase 2: Find LY and sub-LY
    ; This is similar to the last one except that there are 114 possible sub-LY values (instead of 64)
    ; and the loop length will be 460 cycles (each LY-cycle is 456, and we need to add 4).
    ; NOTE: This assumes that the whole loop finishes before LY wraps to 0.
    ldh a, ($44)    ; 12
    ld b, a         ; 4
    ld d, a         ; 4

    ld e, 114         ; 8
    ; 28 cycles up to here, stall for 432 more
    ld a, 26        ; 8
ly_stall:
    dec a           ; 4
    jr nz, ly_stall; 12/8
    ; At this point, we've stalled for 8 + 26*16 - 4 = 420 cycles, need 12 more.
    nop             ; 4
    nop             ; 4
    nop             ; 4
ly_loop:
    ldh a, ($44)    ; 12
    sub d           ; 4
    dec a           ; 4
    jr nz, ly_store  ; 12/8
ly_nostore:
    jr ly_loopstall ; 12
ly_store:
    ld c, e         ; 4
    nop             ; 4
ly_loopstall:
    ; Update d with new value of LY
    inc a           ; 4
    add d           ; 4
    ld d, a         ; 4
    ; So far 52 cycles have passed out of the 460.
    ; Assuming that we'll loop again, we will spend 16 cycles at the end,
    ; so we need to stall for 392 cycles.
    ld a, 24        ; 8
ly_loopstallloop:
    dec a           ; 4
    jr nz, ly_loopstallloop ; 12/8
    ; At this point we've stalled for 8 + 16 * 24 - 4 = 388 cycles, so we need 4 more.
    nop             ; 4
    ; Do the loop again
    dec e           ; 4
    jr nz, ly_loop      ; 12

    ; At this point we're done figuring out LY and sub-LY, but sub-LY is once again encoded.
    ; and these are for the time after we found DIV, sub-DIV.
    ld a, b
    ld (hl+), a
    ld a, c
    ld (hl+), a

    pop hl
    pop de
    pop bc
    pop af

    jp std_reset

main:
    ; Print out data
    set_test 1

    ; Retrieve initial registers from the original stack
    ld sp, $FFF6
    pop hl
    pop de
    pop bc
    pop af
    ld sp, std_stack
    call print_regs

    ld hl, $C000
    ; Determine rDiv and sub-rDiv at boot. These differ from the stored values by a little bit.
    ld a, (hl+)
    ld b, a
    ; Adjust sub-rDiv to account for differences from boot.
    ld a, (hl+)
    ; If the rDiv jump happens on the first iteration, a will be 64 and
    ; the first read (84 cycles after ROM got control) will be at 244.
    ; So the rom got control at 244 - 84 = 160, which is 40 on our scale.
    ; If the rom gets control 4 cycles earlier, then it will take one more iteration
    ; to see the jump, and a will be one lower. So to adjust we simply subtract 24.
    sub 24
    jr nc, print_div
    add 64
    dec b
print_div:
    ld c, a
    print_str "Div: "
    ld a, b
    call print_a
    print_str newline,"subDiv (/4): "
    ld a, c
    call print_a

    ; Determine LY and sub-LY at boot
    ld a, (hl+)
    ; The read of LY came 17024 cycles after boot, which is 37 LY and 152/4=38 sub-LY changes.
    ; We'll account for the sub-LY change later on, but for now we need to subtract 37.
    sub 37
    jr nc, compute_subly
    add 154
compute_subly:
    ld b, a
    ld a, (hl+)
    ; We use similar logic to adjust subLY. The first read of subLY starts at
    ; 17024 cycles after boot, which as calculated above is 38 subLY changes.
    ; If the LY jump happened on the first iteration, then the first LY
    ; read would happen 111 steps into the cycle (remembering that the actual
    ; register read happens 2 machine cycle after the instruction starts),
    ; meaning that the ROM booted with subLY = 111-38 = 73.
    ; In this case, the value of a will be 114, so to adjust we are subtracting
    ; 114-73 = 41.
    ; You might have noticed that to find this number we could just look at the number
    ; of sub-changes since boot and add 3 (works for DIV calculation too).
    ; The 3 comes from 1 from the loop to get to 0 sub-units and 2 from the
    ; fact that the read happens 2 machine cycles into the instruction.
    sub 41
    ld c, a
    jr nc, print_ly
    add 114
    ld c, a
    ld a, b
    dec a
    cp $ff
    ld b, a
    jr nz, print_ly
    add 154
    ld b, a

print_ly:
    print_str newline,"LY: "
    ld a, b
    call print_a
    print_str newline,"subLY (/4): "
    ld a, c
    call print_a

    jp tests_passed
