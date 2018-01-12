  .inesprg 1   ; 1x 16KB PRG code
  .ineschr 1   ; 1x  8KB CHR data
  .inesmap 0   ; mapper 0 = NROM, no bank swapping
  .inesmir 1   ; background mirroring

;;;;;;;;;;;;;;;
CharSpeed	= $02

  .bank 0
  .org $C000
RESET:
  SEI          ; disable IRQs
  CLD          ; disable decimal mode
  LDX #$40
  STX $4017    ; disable APU frame IRQ
  LDX #$FF
  TXS          ; Set up stack
  INX          ; now X = 0
  STX $2000    ; disable NMI
  STX $2001    ; disable rendering
  STX $4010    ; disable DMC IRQs

vblankwait1:       ; First wait for vblank to make sure PPU is ready
  BIT $2002
  BPL vblankwait1

clrmem:
  LDA #$00
  STA $0000, x
  STA $0100, x
  STA $0300, x
  STA $0400, x
  STA $0500, x
  STA $0600, x
  STA $0700, x
  LDA #$FE
  STA $0200, x    ;move all sprites off screen
  INX
  BNE clrmem

vblankwait2:      ; Second wait for vblank, PPU is ready after this
  BIT $2002
  BPL vblankwait2



; ************** NEW CODE ****************
LoadPalettes:
  LDA $2002    ; read PPU status to reset the high/low latch
  LDA #$3F
  STA $2006    ; write the high byte of $3F00 address
  LDA #$00
  STA $2006    ; write the low byte of $3F00 address
  LDX #$00
LoadPalettesLoop:
    LDA palette, x        ;load palette byte
    STA $2007             ;write to PPU
    INX                   ;set index to next byte
    CPX #$20
  BNE LoadPalettesLoop  ;if x = $20, 32 bytes copied, all done

LoadSprites:
  LDX #$00
LoadSpritesLoop:
    LDA sprites, X
    STA $0200, X
    INX
    CPX spritelen
    BNE LoadSpritesLoop

  LDA #%10000000   ; enable NMI, sprites from Pattern Table 0
  STA $2000

  LDA #%00010000   ; enable sprites
  STA $2001

Forever:
  JMP Forever     ;jump back to Forever, infinite loop


BtnDwn:
  LDA $0200
  CLC
  ADC #CharSpeed
  STA $0200
  LDA $0204
  CLC
  ADC #CharSpeed
  STA $0204
  LDA $0208
  CLC
  ADC #CharSpeed
  STA $0208
  LDA $020C
  CLC
  ADC #CharSpeed
  STA $020C
  JMP updatescreen

BtnRight:
  LDA $0203
  CLC
  ADC #CharSpeed
  STA $0203
  LDA $0207
  CLC
  ADC #CharSpeed
  STA $0207
  LDA $020B
  CLC
  ADC #CharSpeed
  STA $020B
  LDA $020F
  CLC
  ADC #CharSpeed
  STA $020F
  JMP updatescreen


NMI:
  ;First we check the controller state
  LDA #$01

  STA $4016

  LDA #$00

  STA $4016     ; tell both the controllers to latch buttons


  LDA $4016     ; player 1 - A

  LDA $4016     ; player 1 - B

  LDA $4016     ; player 1 - Select

  LDA $4016     ; player 1 - Start

  LDA $4016     ; player 1 - Up
  AND #%00000001
  BNE BtnUp
  LDA $4016     ; player 1 - Down
  AND #%00000001
  BNE BtnDwn

  LDA $4016     ; player 1 - Left
  AND #%00000001
  BNE BtnLeft

  LDA $4016     ; player 1 - Right
  AND #%00000001
  BNE BtnRight

updatescreen:
    LDA #$00
    STA $2003  ; set the low byte (00) of the RAM address
    LDA #$02
    STA $4014  ; set the high byte (02) of the RAM address, start the transfer

  RTI        ; return from interrupt

BtnUp:
  LDA $0200
  SEC
  SBC #CharSpeed
  STA $0200
  LDA $0204
  SEC
  SBC #CharSpeed
  STA $0204
  LDA $0208
  SEC
  SBC #CharSpeed
  STA $0208
  LDA $020C
  SEC
  SBC #CharSpeed
  STA $020C
  JMP updatescreen

BtnLeft:
  LDA $0203
  SEC
  SBC #CharSpeed
  STA $0203
  LDA $0207
  SEC
  SBC #CharSpeed
  STA $0207
  LDA $020B
  SEC
  SBC #CharSpeed
  STA $020B
  LDA $020F
  SEC
  SBC #CharSpeed
  STA $020F
  JMP updatescreen

;;;;;;;;;;;;;;



  .bank 1
  .org $E000
palette:
  .db $0F,$31,$32,$33,$0F,$35,$36,$37,$0F,$39,$3A,$3B,$0F,$3D,$3E,$0F
  .db $0F,$1C,$15,$14,$0F,$02,$38,$3C,$0F,$1C,$15,$14,$0F,$02,$38,$3C
spritelen:
  .db $10
sprites:
  ;we store sprite data here. Format is as follows
  ;vert coord, tile no, attributes, horiz coord
  .db $80, $32, $00, $80
  .db $80, $33, $00, $88
  .db $88, $34, $00, $80
  .db $88, $35, $00, $88


  .org $FFFA     ;first of the three vectors starts here
  .dw NMI        ;when an NMI happens (once per frame if enabled) the
  ;processor will jump to the label NMI:
  .dw RESET      ;when the processor first turns on or is reset, it will jump
  ;to the label RESET:
  .dw 0          ;external interrupt IRQ is not used in this tutorial


;;;;;;;;;;;;;;


  .bank 2
  .org $0000
  .incbin "mario.chr"   ;includes 8KB graphics file from SMB1
