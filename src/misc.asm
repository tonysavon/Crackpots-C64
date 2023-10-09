vsync:
{
			bit $d011
			bpl * -3
			bit $d011
			bmi * -3
			rts
}


framesync:
{
			!:	lda frameflag
				beq !-
				lda #0
				sta frameflag
				rts
}

//32 bit random number generator
random_:
{
			asl random
			rol random+1
			rol random+2
			rol random+3
			bcc nofeedback
			lda random
			eor #$b7
			sta random
			lda random+1
			eor #$1d
			sta random+1
			lda random+2
			eor #$c1
			sta random+2
			lda random+3
			eor #$04
			sta random+3
		nofeedback:
			rts

random: .byte $ff,$ff,$ff,$ff
}


wait_button:
			!:	
				jsr vsync
				lda $dc00
				and #%00010000
				bne !-

			!:	
				jsr vsync
				lda $dc00
				and #%00010000
				beq !-				
				
				rts
				
blank:
				jsr vsync
				lda $d011
				and #%01101111
				sta $d011
				rts
				
unblank:
				jsr vsync
				lda $d011
				and #%01111111
				ora #%00010000
				sta $d011
				rts