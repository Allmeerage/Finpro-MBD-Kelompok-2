#define __SFR_OFFSET 0
#include <avr/io.h>
#define temp          r16
#define state         r26
#define tick_flag     r18
#define timer_counter r19
#define i2c_data      r20
#define score_L       r24
#define score_H       r25

#define STATE_HI_SCORE  0
#define STATE_GAMEPLAY  1
#define STATE_GAME_OVER 2

.equ LCD_ADDR,   0x4E
.equ LCD_RS,     0x01
.equ LCD_EN,     0x04
.equ LCD_BACKLIGHT, 0x08

.section .text
.global main

.global __vector_1   
.global __vector_2   
.global __vector_13  

; =========
; Main loop
; =========


main:
    ldi temp, hi8(RAMEND)
    out SPH, temp
    ldi temp, lo8(RAMEND)
    out SPL, temp

    ldi temp, 0x00
    out DDRD, temp
    ldi temp, 0x0C
    out PORTD, temp

    clr temp
    sts 0x0100, temp
    sts 0x0101, temp

    ldi state, STATE_HI_SCORE
    clr tick_flag
    clr timer_counter
    clr score_L
    clr score_H

    rcall i2c_init
    rcall lcd_init
    rcall timer1_init
    rcall interrupt_init

    sei 

fsm_loop:
    cpi state, STATE_HI_SCORE
    breq handle_hi_score
    cpi state, STATE_GAMEPLAY
    breq handle_gameplay
    cpi state, STATE_GAME_OVER
    breq handle_game_over
    rjmp fsm_loop

; ===================
; Fungsi untuk states
; ===================

handle_hi_score:
    rcall lcd_clear
    
    ldi i2c_data, 0x68 ; h
    rcall lcd_write_char
    ldi i2c_data, 0x69 ; i
    rcall lcd_write_char
    ldi i2c_data, 0x67 ; g
    rcall lcd_write_char
    ldi i2c_data, 0x68 ; h
    rcall lcd_write_char
    ldi i2c_data, 0x20 ; spasi
    rcall lcd_write_char
    ldi i2c_data, 0x73 ; s
    rcall lcd_write_char
    ldi i2c_data, 0x63 ; c
    rcall lcd_write_char
    ldi i2c_data, 0x6F ; o
    rcall lcd_write_char
    ldi i2c_data, 0x72 ; r
    rcall lcd_write_char
    ldi i2c_data, 0x65 ; e
    rcall lcd_write_char

    ldi i2c_data, 0xC0
    rcall lcd_write_cmd

    lds score_L, 0x0100
    rcall lcd_print_score

    ldi temp, 20

delay_hi_loop:
    rcall delay_100ms
    dec temp
    brne delay_hi_loop
    
    clr score_L
    clr score_H
    ldi state, STATE_GAMEPLAY
    rjmp fsm_loop

handle_gameplay:
    rcall lcd_clear
    
    ldi i2c_data, 0x73 ; s
    rcall lcd_write_char
    ldi i2c_data, 0x63 ; c
    rcall lcd_write_char
    ldi i2c_data, 0x6F ; o
    rcall lcd_write_char
    ldi i2c_data, 0x72 ; r
    rcall lcd_write_char
    ldi i2c_data, 0x65 ; e
    rcall lcd_write_char

    ldi i2c_data, 0xC0
    rcall lcd_write_cmd
    rcall lcd_print_score
    
    clr tick_flag

gameplay_wait:
    sbic PIND, 7
    rjmp motion_detected

    tst tick_flag
    breq gameplay_wait
    
    clr tick_flag
    
    ldi temp, 10
    add score_L, temp
    
    ldi i2c_data, 0xC0     
    rcall lcd_write_cmd
    rcall lcd_print_score
    rjmp gameplay_wait

motion_detected:
    ldi state, STATE_GAME_OVER
    rjmp fsm_loop

handle_game_over:
    lds r21, 0x0100
    cp score_L, r21
    brcs skip_highscore_save
    sts 0x0100, score_L

skip_highscore_save:
    rcall lcd_clear

    ldi i2c_data, 0x47 ; G
    rcall lcd_write_char
    ldi i2c_data, 0x41 ; A
    rcall lcd_write_char
    ldi i2c_data, 0x4D ; M
    rcall lcd_write_char
    ldi i2c_data, 0x45 ; E
    rcall lcd_write_char
    ldi i2c_data, 0x20 ; spasi
    rcall lcd_write_char
    ldi i2c_data, 0x4F ; O
    rcall lcd_write_char
    ldi i2c_data, 0x56 ; V
    rcall lcd_write_char
    ldi i2c_data, 0x45 ; E
    rcall lcd_write_char
    ldi i2c_data, 0x52 ; R
    rcall lcd_write_char
    
    ldi temp, 20
delay_go_loop:
    rcall delay_100ms
    dec temp
    brne delay_go_loop

    ldi state, STATE_HI_SCORE
    rjmp fsm_loop

; =================
; Interrupt handler
; =================

__vector_13:
    push temp
    in temp, SREG
    push temp
    
    inc timer_counter
    cpi timer_counter, 50 
    brcs timer1_exit
    
    clr timer_counter
    ldi tick_flag, 1     
    
timer1_exit:
    pop temp
    out SREG, temp
    pop temp
    reti

__vector_1:
    push temp
    in temp, SREG
    push temp
    
    sbic PIND, 2         
    rjmp left_released      
    ldi temp, hi8(3600) 
    sts OCR1AH, temp
    ldi temp, lo8(3600)
    sts OCR1AL, temp
    rjmp end_int0
left_released:
    ldi temp, hi8(2200)
    sts OCR1AH, temp
    ldi temp, lo8(2200)
    sts OCR1AL, temp
end_int0:
    pop temp
    out SREG, temp
    pop temp
    reti

__vector_2:
    push temp
    in temp, SREG
    push temp
    
    sbic PIND, 3         
    rjmp right_released      
    ldi temp, hi8(2400)  
    sts OCR1BH, temp
    ldi temp, lo8(2400)
    sts OCR1BL, temp
    rjmp end_int1
right_released:
    ldi temp, hi8(3800) 
    sts OCR1BH, temp
    ldi temp, lo8(3800)
    sts OCR1BL, temp
end_int1:
    pop temp
    out SREG, temp
    pop temp
    reti

interrupt_init:
    ldi temp, 0x05       
    sts EICRA, temp
    ldi temp, 0x03       
    out EIMSK, temp
    ret

timer1_init:
    sbi DDRB, 1
    sbi DDRB, 2

    ldi temp, (1 << COM1A1) | (1 << COM1B1) | (1 << WGM11)
    sts TCCR1A, temp
    ldi temp, (1 << WGM13) | (1 << WGM12) | (1 << CS11) 
    sts TCCR1B, temp

    ldi temp, hi8(40000)
    sts ICR1H, temp
    ldi temp, lo8(40000)
    sts ICR1L, temp

    ldi temp, hi8(3600)
    sts OCR1AH, temp
    sts OCR1BH, temp
    ldi temp, lo8(3600)
    sts OCR1AL, temp
    sts OCR1BL, temp

    ldi temp, (1 << TOIE1)
    sts TIMSK1, temp
    ret

; =========
; I2C & LCD
; =========

i2c_init:
    sbi DDRC, 4
    sbi DDRC, 5
    sbi PORTC, 4
    sbi PORTC, 5
    ret

i2c_start:
    sbi PORTC, 4         
    sbi PORTC, 5         
    rcall i2c_delay
    cbi PORTC, 4         
    rcall i2c_delay
    cbi PORTC, 5         
    ret

i2c_stop:
    cbi PORTC, 4         
    rcall i2c_delay
    sbi PORTC, 5         
    rcall i2c_delay
    sbi PORTC, 4         
    rcall i2c_delay
    ret

i2c_write:
    push r22
    push r23
    mov r22, i2c_data
    ldi r23, 8
i2c_bit_loop:
    sbrc r22, 7
    sbi PORTC, 4
    sbrs r22, 7
    cbi PORTC, 4
    sbi PORTC, 5         
    rcall i2c_delay
    cbi PORTC, 5         
    lsl r22
    dec r23
    brne i2c_bit_loop
    
    sbi PORTC, 4         
    cbi DDRC, 4          
    sbi PORTC, 5         
    rcall i2c_delay
    cbi PORTC, 5         
    sbi DDRC, 4          
    
    pop r23
    pop r22
    ret

lcd_send_nibble:
    push i2c_data
    rcall i2c_start
    ldi i2c_data, LCD_ADDR
    rcall i2c_write
    pop i2c_data
    rcall i2c_write
    rcall i2c_stop
    ret

lcd_write_cmd:
    push i2c_data
    andi i2c_data, 0xF0
    subi i2c_data, -LCD_BACKLIGHT
    rcall lcd_send_nibble
    subi i2c_data, -LCD_EN
    rcall lcd_send_nibble
    subi i2c_data, LCD_EN
    rcall lcd_send_nibble
    pop i2c_data
    swap i2c_data
    andi i2c_data, 0xF0
    subi i2c_data, -LCD_BACKLIGHT
    rcall lcd_send_nibble
    subi i2c_data, -LCD_EN
    rcall lcd_send_nibble
    subi i2c_data, LCD_EN
    rcall lcd_send_nibble
    ret

lcd_write_char:
    push i2c_data
    andi i2c_data, 0xF0
    subi i2c_data, -LCD_RS
    subi i2c_data, -LCD_BACKLIGHT
    rcall lcd_send_nibble
    subi i2c_data, -LCD_EN
    rcall lcd_send_nibble
    subi i2c_data, LCD_EN
    rcall lcd_send_nibble
    pop i2c_data
    swap i2c_data
    andi i2c_data, 0xF0
    subi i2c_data, -LCD_RS
    subi i2c_data, -LCD_BACKLIGHT
    rcall lcd_send_nibble
    subi i2c_data, -LCD_EN
    rcall lcd_send_nibble
    subi i2c_data, LCD_EN
    rcall lcd_send_nibble
    ret

lcd_init:
    rcall delay_2ms
    rcall delay_2ms
    rcall delay_2ms
    ldi i2c_data, 0x33
    rcall lcd_write_cmd
    rcall delay_2ms
    ldi i2c_data, 0x32
    rcall lcd_write_cmd
    rcall delay_2ms
    ldi i2c_data, 0x28
    rcall lcd_write_cmd
    rcall delay_2ms
    ldi i2c_data, 0x0C
    rcall lcd_write_cmd
    rcall delay_2ms
    ret

lcd_clear:
    ldi i2c_data, 0x01
    rcall lcd_write_cmd
    rcall delay_2ms
    ret

lcd_print_score:
    push r21
    mov r21, score_L
    
    clr r22
calc_100:
    cpi r21, 100
    brcs print_100
    subi r21, 100
    inc r22
    rjmp calc_100
print_100:
    subi r22, -48
    mov i2c_data, r22
    rcall lcd_write_char
    
    clr r22
calc_10:
    cpi r21, 10
    brcs print_10
    subi r21, 10
    inc r22
    rjmp calc_10
print_10:
    subi r22, -48
    mov i2c_data, r22
    rcall lcd_write_char
    
    subi r21, -48
    mov i2c_data, r21
    rcall lcd_write_char
    
    pop r21
    ret

; =============
; Logika timing
; =============

i2c_delay:
    nop
    nop
    ret

delay_2ms:
    push r24
    push r25
    ldi r24, lo8(8000)
    ldi r25, hi8(8000)
d2ms_loop:
    sbiw r24, 1
    brne d2ms_loop
    pop r25
    pop r24
    ret

delay_100ms:
    push r18
    push r24
    push r25
    ldi r18, 32
outer_loop:
    ldi r24, lo8(12500)
    ldi r25, hi8(12500)
inner_loop:
    sbiw r24, 1
    brne inner_loop
    dec r18
    brne outer_loop
    pop r25
    pop r24
    pop r18
    ret
