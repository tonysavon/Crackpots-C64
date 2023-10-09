environment:
{
	init:
	
			ldy #5
		!:	jsr random_
			and #3
			tax
			lda flower_color_map,x
			sta flower_color,y
			dey
			bpl !-
			
	init_no_rnd:
	
			lda #1
			ldx #5
		!:	sta ledge,x
			dex
			bpl !- 
		
			jsr draw_ledge
			rts
			
			
	
	draw_ledge:
	
		
			ldx penalty
			lda screenrow.lo + 6,x
			clc
			adc #9
			sta p0tmp
			lda screenrow.hi + 6,x
			adc #0
			sta p0tmp + 1

			lda p0tmp
			clc
			adc #40
			sta p0tmp + 2
			lda p0tmp + 1
			adc #0
			sta p0tmp + 3
			
			
			lda colorrow.lo + 6,x
			clc
			adc #9
			sta p0tmp + 4
			lda colorrow.hi + 6,x
			adc #0
			sta p0tmp + 5

			lda p0tmp + 4
			clc
			adc #40
			sta p0tmp + 6
			lda p0tmp + 5
			adc #0
			sta p0tmp + 7
			
			
			ldx #5 //loops on pots
	
		!:
			txa
			asl
			asl

			tay
			
			lda ledge,x	
			beq !clear+
		!pot:
			lda flower_color,x
			ora #8
			sta (p0tmp + 4),y
			iny
			sta (p0tmp + 4),y
			lda #02 + 8
			sta (p0tmp + 6),y
			dey
			sta (p0tmp + 6),y
			
			lda #FLOWERS_CHARS
			sta (p0tmp),y
			lda #FLOWERS_CHARS + 2
			sta (p0tmp + 2),y
			
			iny

			lda #FLOWERS_CHARS + 1
			sta (p0tmp),y
			lda #FLOWERS_CHARS + 3
			sta (p0tmp + 2),y
			jmp !next+
			
			
		!clear:
			lda #0
			sta (p0tmp),y
			sta (p0tmp + 2),y
			iny
			sta (p0tmp),y
			sta (p0tmp + 2),y

		!next:
			dex
			bpl !-	
			rts
	
//luma scale
/*
  00
06  09
02  0b
04  08
0e  0c
05  0a
03  0f
0d  07
  01
*/

spidercolorgradient:
.byte $05,$0a,$0a,$03, $03,$0d,$0d,$0d, $01,$01,$01,$01, $01,$07,$03,$0e
			
//used for spiders			
level_spider_color:
.byte 0,6,2,13//5

ledge:
.byte 0,0,0,0,0,0

flower_color:
.byte 0,0,0,0,0,0


flower_color_map:
.byte 2,6,4,7


//this maps the possible penalties to the top end of the ledger
penaltytoy0:
.fill 6,(6 + i) * 8 + 50

}