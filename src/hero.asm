.label STATUS_HERO_PUSHING = 1
.label STATUS_HERO_STUCK   = 2

hero:
{
		
	init:
				lda #(160 + 24 - 8) / 2	
				sta xpos 
				
				lda #50 + 27
				sta ypos
	
	init_nopos:
				lda #0
				sta clock
				sta status
	
				sta nodrop
						
				lda #[hero_sprites & $3fff] / 64
				sta frame	
	
				rts
				

				
	update:
				lda status
				beq !free+
				cmp #STATUS_HERO_STUCK
				beq !free+	//it looks the same
					
				//status pushing
				ldx clock
				ldy drop_frames,x
				inc clock
				//lda clock
				//cmp #16
				cpx #15
				bne !next+
				lda #0
				sta status
				jmp !next+
				 	
			!free:
				ldy #[hero_sprites & $3fff] / 64
			!next:	
				sty frame
				rts
				
				
drop_frames:
.const hf = [hero_sprites & $3fff] / 64
.byte hf + 0
.fill 4,hf + 4
.fill 7,hf + 8
.fill 3,hf + 4
.byte hf + 0
				
				
xpos:
.byte 0

ypos:
.byte 0

clock:
.byte 0

status:
.byte 0

frame:
.byte [hero_sprites & $3fff] / 64



}