controls:
{
				lda hero.status
				beq !skp+
				rts
		!skp:

				lda $dc00
				
				jsr readjoy
				bcc !fire+
				lda #1
				sta buttonreleased + 1
				jmp !testx+
				
				
		!fire:
		
buttonreleased: lda #$00
				beq !testx+
				lda #0
				sta buttonreleased + 1
				
				jsr flowers.drop
				beq !testx+
				jmp !next+
	
		!testx:	
				cpx #0
				beq !next+
				cpx #1
				beq !goesright+
				
			!goesleft:
				lda hero.xpos 
				cmp #(24 + 7 * 8) / 2 + 1
				bcc !next+
				sbc #1
				sta hero.xpos 
				jmp !next+
			!goesright:
				lda hero.xpos 
				cmp #(24 + 31 * 8) / 2 -1
				bcs !next+
				adc #1
				sta hero.xpos 
				jmp !next+	
				
		!next:
				
				rts	
							
				

				
		update:		
		
				lda hero.status
}

readjoy:
{
		
		djrrb:	ldy #0        
				ldx #0       
				lsr           
				bcs djr0      
				dey          
		djr0:	lsr           
				bcs djr1      
				iny           
		djr1:	lsr           
				bcs djr2      
				dex           
		djr2:	lsr           
				bcs djr3      
				inx           
		djr3:	lsr           
				rts
}					