// Adds A * 100  to the score, so 100 to 900 in steps of 100
add_score_xx:
{
			ldx #3
			jmp add_score_x.opt
}

// Adds A * 10 to the score, so 10 to 90 in steps of 10. 
add_score_x:
{
			ldx #4
opt:		//ldy #0 //flag for extralives
		!:	clc
			adc score,x
			sta score,x
			cmp #$0a
			bcc !done+
			sbc #$0a
			sta score,x
			lda #1
//			cpx #2
//			bne !skp+
			
//			iny

		!skp:	
			dex 
			bpl !- 
		//overflow!
			lda #9
			sta score
			sta score + 1
			sta score + 2
			sta score + 3
			sta score + 4
			sta score + 5
			
			jsr put_score
			//jmp game_over //this is the good gameover!

				lda #3
				jsr sid.init
		
				//lda #1
				//sta gameovermode
				
				ldx #$7f
			!:	jsr vsync
			
				txa
				pha
				jsr controls
				pla
				tax
			
				dex
				bpl !-
				
				jsr wait_button

				jsr blank				
				jmp splashloop
			
			
		!done:

			rts			
			//no lives in this game, so we don't need to check anythng here
		
			//jmp put_score  //it's up next anyway 
}


put_score:
{
			
				ldx #0
				ldy #0
				
			!:	
				lda score,x
				asl	//also clears carry, because score digits are < 128
				adc #DIGIT_CHARS
				sta scrn + 40 + 20 - 6,y 
				iny
				adc #1
				sta scrn + 40 + 20 - 6,y
				iny
				inx
				cpx #6 //this will also clear the carry
				bne !-
				
				rts
				
}

hud_init:
{	
				lda #6
				sta hud_spiders
				
				ldx level
				
				lda environment.level_spider_color,x
				and #7
	//			ora #8
				
				ldx #6*2 -1
			!:	sta $d800 + 23 * 40 + 20 - 3*2,x
				sta $d800 + 24 * 40 + 20 - 3*2,x
				dex
				bpl !-
				
		
				ldx #6*2 -1
			!:	lda spider_hud_pattern,x
				sta scrn + 23 * 40 + 20 - 3*2,x
				lda spider_hud_pattern + 12,x
				sta scrn + 24 * 40 + 20 - 3*2,x
				dex
				bpl !-

				//color score area
				ldx #6 * 2 - 1
				lda #9
			!:	sta $d800 + 40 + 20 - 6,x
				dex
				bpl !- 
				
				jsr put_score
				
				rts

	spider_hud_pattern:				
	.for (var i = 0; i < 6; i++)
	{
		.byte SPIDER_HUD
		.byte SPIDER_HUD + 1
	}
	.for (var i = 0; i < 6; i++)
	{
		.byte SPIDER_HUD + 2
		.byte SPIDER_HUD + 3 				
	}
}

//when a spider gets in, we must basically blank in the hud
update_hud_spiders:
{
				lda hud_spiders
				asl
				adc #<[scrn + 40 * 23 + 20 - 6]
				sta p0tmp
				lda #0
				adc #>[scrn + 40 * 23 + 20 - 6]
				sta p0tmp + 1
				
				ldy #0
				lda #0
				
				sta (p0tmp),y
				iny
				sta (p0tmp),y
				ldy #40
				sta (p0tmp),y
				iny
				sta (p0tmp),y
				rts
				
}