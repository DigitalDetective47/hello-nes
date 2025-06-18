.segment "HEADER"

INES_MAPPER = 218
INES_MIRROR = 9
INES_SRAM   = 0

.byte 'N', 'E', 'S', $1A
.byte $01
.byte $00
.byte INES_MIRROR | (INES_SRAM << 1) | ((INES_MAPPER & %00001111) << 4)
.byte (INES_MAPPER & %11110000)
.byte $0, $0, $0, $0, $0, $0, $0, $0

.segment "VECTORS"
.word loop
.word reset
.word $0

.segment "CODE"
reset:
    sei        ; ignore IRQs
    cld        ; disable decimal mode
    ldx #$40
    stx $4017  ; disable APU frame IRQ
    ldx #$ff
    txs        ; Set up stack
    inx        ; now X = 0
    stx $2000  ; disable NMI
    stx $2001  ; disable rendering
    stx $4010  ; disable DMC IRQs

    ; Optional (omitted):
    ; Set up mapper and jmp to further init code here.

    ; The vblank flag is in an unknown state after reset,
    ; so it is cleared here to make sure that @vblankwait1
    ; does not exit immediately.
    bit $2002

    ; First of two waits for vertical blank to make sure that the
    ; PPU has stabilized
@vblankwait1:
    bit $2002
    bpl @vblankwait1

    ; We now have about 30,000 cycles to burn before the PPU stabilizes.
    ; One thing we can do with this time is put RAM in a known state.
    ; Here we fill it with $00, which matches what (say) a C compiler
    ; expects for BSS. Since we haven't modified the X register since
    ; the earlier code above, it's still set to 0, so we can just
    ; transfer it to the Accumulator and save a byte

    ; Other things you can do between vblank waits are set up audio
    ; or set up other mapper registers.

@vblankwait2:
    bit $2002
    bpl @vblankwait2

    lda #$20
    sta $2006
    stx $2006

    lda textdata, X
copytext:
    sta $2007
    inx
    lda textdata, X
    bne copytext

    lda #' '
    ldy #$04
clear_vram:
    sta $2007
    inx
    bne clear_vram
    dey
    bne clear_vram

    sty $2006
    sty $2006
    lda #>chrdata
    sta tiledata_hi
    lda #<chrdata
    sta tiledata_lo
    ldx #$04

copytiles:
    lda (tiledata_lo), Y
    sta $2007
    iny
    bne copytiles
    inc tiledata_hi
    dex
    bne copytiles
 
    lda #$3F
    sta $2006
    sty $2006
    sta $2007
    lda #$30
    sta $2007
    sty $2005
    sty $2005
    lda #$0A
    sta $2001
    lda #$80
    sta $2000

loop:
    bmi loop

.segment "CODE"
textdata:
    .byte "Hello", $7E, " NES", $7F, $00

.segment "CODE"
chrdata:
.incbin "font.chr"

.segment "ZEROPAGE"
tiledata_lo: .res 1
tiledata_hi: .res 1