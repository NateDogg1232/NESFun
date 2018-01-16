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


LoadBackground:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$20
  STA $2006             ; write the high byte of $2000 address
  LDA #$00
  STA $2006             ; write the low byte of $2000 address
  LDX #$00              ; start out at 0
LoadBackgroundLoop:
  LDA nametable, x     ; load data from address (background + the value in x)
  STA $2007             ; write to PPU
  INX                   ; X = X + 1
  CPX #$80              ; Compare X to hex $80, decimal 128 - copying 128 bytes
  BNE LoadBackgroundLoop  ; Branch to LoadBackgroundLoop if compare was Not Equal to zero
                        ; if compare was equal to 128, keep going down

LoadAttribute:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$23
  STA $2006             ; write the high byte of $23C0 address
  LDA #$C0
  STA $2006             ; write the low byte of $23C0 address
  LDX #$00              ; start out at 0
LoadAttributeLoop:
  LDA attribute, x      ; load data from address (attribute + the value in x)
  STA $2007             ; write to PPU
  INX                   ; X = X + 1
  CPX #$08              ; Compare X to hex $08, decimal 8 - copying 8 bytes
  BNE LoadAttributeLoop

  LDA #%10010000 ;enable NMI, sprites from Pattern 0, background from Pattern 1
  STA $2000

  LDA #%00011110 ; enable sprites, enable background
  STA $2001


Forever:
  JMP Forever     ;jump back to Forever, infinite loop


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
  BNE BtnDown

  LDA $4016     ; player 1 - Left
  AND #%00000001
  BNE BtnLeft

  LDA $4016     ; player 1 - Right
  AND #%00000001
  BNE BtnRight

  jmp updatescreen

BtnUp:
  jsr MovUp
  jmp updatescreen
BtnDown:
  jsr MovDown
  jmp updatescreen
BtnLeft:
  jsr MovLeft
  jmp updatescreen
BtnRight:
  jsr MovRight
  jmp updatescreen


updatescreen:
    LDA #$00
    STA $2003  ; set the low byte (00) of the RAM address
    LDA #$02
    STA $4014  ; set the high byte (02) of the RAM address, start the transfer

  RTI        ; return from interrupt

MovUp:
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
  RTS

MovDown:
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
  RTS

MovLeft:
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
  RTS

MovRight:
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
  RTS

;;;;;;;;;;;;;;



  .bank 1
  .org $E000
palette:
  .db $22,$29,$1A,$0F,$22,$36,$17,$0F,$22,$30,$21,$0F,$22,$27,$17,$0F
spritelen:
  .db $10
sprites:
  ;we store sprite data here. Format is as follows
  ;vert coord, tile no, attributes, horiz coord
  .db $80, $32, $00, $80
  .db $80, $33, $00, $88
  .db $88, $34, $00, $80
  .db $88, $35, $00, $88

nametable:
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;row 1
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;all sky ($24 = sky)
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;row 2
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;all sky
  .db $24,$24,$24,$24,$45,$45,$24,$24,$45,$45,$45,$45,$45,$45,$24,$24  ;;row 3
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$53,$54,$24,$24  ;;some brick tops
  .db $24,$24,$24,$24,$47,$47,$24,$24,$47,$47,$47,$47,$47,$47,$24,$24  ;;row 4
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$55,$56,$24,$24  ;;brick bottoms
attribute:
  .db %00000000, %00010000, %0010000, %00010000, %00000000, %00000000, %00000000, %00110000




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
