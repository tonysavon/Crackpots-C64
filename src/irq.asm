.macro setirq(addr,line)
{
		lda #<addr
		sta $fffe
		lda #>addr
		sta $ffff
		lda #line
		sta $d012
}


.macro setirqaddr(addr)
{
		lda #<addr
		sta $fffe
		lda #>addr
		sta $ffff
}

clear_irq:
{
				lda #$7f                    //CIA interrupt off
				sta $dc0d
				sta $dd0d
				lda $dc0d
				lda $dd0d
				
				lda #$01                    //Raster interrupt on
				sta $d01a
				lsr $d019
				rts
}			
	

irq_00:
{
				sta savea + 1
				stx savex + 1
				sty savey + 1
	
				lda #$09
				sta $d021
	
				lda $d011
				ora #8
				sta $d011
							
				lda #$0e	
				sta $d022	
	
				lda #$00 // $0a			
				sta $d023
	
				
				//places the note sprite if needed
			note_sprf:		
				lda #[note_sprites & $3fff] / 64
				sta scrn + $3f8 + 0	
				lda #2
				sta $d027 + 0
				
				lda #$ff
				sta $d01c
				
				lda #$00
				sta $d025
				lda #$0f
				sta $d026
			
			
				lda #49
				sta $d001
				lda #$ff
				sta $d000
	
				lda #0
				sta $d010
							
			note_display:		
				lda #1
				sta $d015
							
				jsr sid.play
				
				lsr $d019
				:setirq(irq_01, 51 + 16)
		savea:	lda #0
		savex:	ldx #0
		savey:	ldy #0
				rti		
}


irq_01:
{
				sta savea + 1
				
				lda #$04
				sta $d023
								
				//places hero sprite here, unless it's gameover, in which case it sets gameover mode!
	
				lda #$ff
				sta $d015
				sta $d01c
				
				lda #$0
				sta $d010

				lda gameovermode
				bne !gameover+
				jmp !hero+
		!gameover:
				lda #1
				sta $d025
				lda #0
				sta $d026
				lda #13
				.for (var i = 0; i < 8; i++)
				{
					sta $d027 + i
				}
				lda #51 + 48
				.for (var i = 0; i < 8; i++)				
				{
					sta $d001 + i * 2
				}
				
				.for (var i = 0; i < 8; i++)
				{
					lda #255-192 + 24 + 24 * i
					sta $d000 + 2 * i
					
					lda #[gameover_sprites & $3fff] / 64 + i
					sta scrn + $3f8 + i
				}
				
				jmp !next+

			!hero:					
				lda penalty
				asl
				asl
				asl
				
				adc hero.ypos
				adc finescroll
				
				sta $d001 + 4 * 2
				sta $d001 + 5 * 2
				sta $d001 + 6 * 2
				sta $d001 + 7 * 2
				
				lda hero.xpos
				asl 
				sta $d000 + 4 * 2
				sta $d000 + 5 * 2
				sta $d000 + 6 * 2
				sta $d000 + 7 * 2
				
				bcc !no+
				lda #%11110000
				sta $d010
			!no:	
				lda #10
				sta $d027 + 4
				lda #2
				sta $d027 + 5
				lda #6
				sta $d027 + 6
				lda #7
				sta $d027 + 7
				
				lda #0
				sta $d025
				lda #1
				sta $d026
				
				lda hero.frame
				sta scrn + $3f8 + 4
				clc
				adc #1
				sta scrn + $3f8 + 5
				adc #1
				sta scrn + $3f8 + 6
				adc #1
				sta scrn + $3f8 + 7
		!next:		
				
				lsr $d019
				:setirq(irq_02, 51 + 30)
		savea:	lda #$00
				rti
}


//sky gradient, places flowers sprites
irq_02:
{				
				sta savea + 1
				stx savex + 1
				sty savey + 1
									
				lda #$0a
				sta $d022
				
				ldx #$08
				lda #51 + 30
			!:	cmp $d012
				bcs !-

				stx $d023
				
				ldx #$03
				lda #51 + 32
			!:	cmp $d012
				bcs !-
				stx $d023

				
				ldx #$0d		
				lda #51 + 33
			!:	cmp $d012
				bcs !-
				stx $d022
				
				ldx #$07
				lda #51 + 34
			!:	cmp $d012
				bcs !-
				stx $d023
				
				ldx #$01
				lda #51 + 35
			!:	cmp $d012
				bcs !-
				stx $d022

				lda #51 + 38
			!:	cmp $d012
				bcs !-
				
				lda #$0f
				sta $d022
				lda #$0c
				sta $d023	

				lda #$00
				sta $7fff
								
				
				lda #$1b
				clc
				adc finescroll
				sta $d011	
				
					
				//lda $d01e //clear hw spr spr collision		
								
				//place flowers sprites, unless it's gameover mode
				
				lda gameovermode
				bne !done+
				
				lda $d015
				and #%11110000
				sta $d015
				
				lda $d010
				and #%11110000
				sta $d010
				
				lda flowers.frame
				sta scrn + $3f8 + 0
				lda flowers.frame + 1
				sta scrn + $3f8 + 1
				lda flowers.frame + 2
				sta scrn + $3f8 + 2
				
								
				ldx flowers.column
				lda environment.flower_color,x
				sta $d027 + 0
				ldx flowers.column + 1
				lda environment.flower_color,x
				sta $d027 + 1
				ldx flowers.column + 2
				lda environment.flower_color,x
				sta $d027 + 2
				
				lda #0
				sta cnt
				
				ldx #0 //index on flowers 
			!vloop:	
				lda flowers.status,x
				beq !next+
				lda flowers.ypos,x
				ldy cnt
				sta $d001,y
				
				ldy flowers.column,x
				
				cpy #5
				bne !skp+
				
				lda $d010
				ora or_mask + 0,x
				sta $d010
				
			!skp:	
				lda flowers.xoff,y
				ldy cnt
				sta $d000 + 0,y
				lda $d015
				ora or_mask + 0,x
				sta $d015
				
			!next:
				inc cnt
				inc cnt
				inx
				cpx #3
				bne !vloop-	
					
			!done:	
						
				lsr $d019
				
				lda penalty
				asl
				asl
				asl					
				adc #51 + 47	
				adc finescroll
				sta $d012
					
				:setirqaddr(irq_03)

		savea:	lda #$00
		savex:	ldx #$00
		savey:	ldy #$00	
				rti

cnt:			
.byte  0				
}
	
			
//ledge, plus places spider sprites
irq_03:											
{				
				sta savea + 1	
				
				lda #$0f
				sta $d021
				
				stx savex + 1
				sty savey + 1
				
				
				lda $d012
			!:	cmp $d012
				beq !-

				
				//change mc colors for vase sprites and chars
				lda #$05
				sta $d023
				sta $d026
							
				lda #$08
				sta $d022
				sta $d025
		
				
				lda $d01e //clear hw spr spr collision		
			
				//place spider sprites
				//sprite 0,1,2 are used for vases, which are still on display.
				//sprites 4,5,6,7 are player sprite, but can be reused.
				//we therefore use sprites 3,4,5 for the spiders
				
				lda #%00000111
				sta $d01c
				
				lda $d015
				and #%00000111
				sta $d015
				
				lda $d010
				and #%00000111
				sta $d010
				
				ldy level
				
				lda  environment.level_spider_color,y
				
				sta $d027 + 3
				sta $d027 + 4
				sta $d027 + 5
				sta $d027 + 6
				sta $d027 + 7
				
				.for (var i = 0; i < 5; i++)
				{
					lda spider.status + i
					and #STATUS_SPIDER_DYING
					beq !skp+
					
					ldy spider.clock + i
					lda environment.spidercolorgradient,y
					sta $d027 + 3 + i	
				
				!skp:	
				}	
				lda #0
				sta cnt
						
				ldx #0 //index on spiders
			!sloop:	
				lda spider.status,x
				beq !next+
				lda spider.ypos,x
				ldy cnt
				sta $d001 + 6,y
				
				lda spider.xpos_l,x
				sta $d000 + 6,y
				
				lda spider.xpos_h,x
				beq !skp+
				
				lda $d010
				ora or_mask + 3,x
				sta $d010
				
			!skp:	
				
				lda spider.status,x
				and #STATUS_SPIDER_DEAD
				bne !skp+
				
				lda $d015
				ora or_mask + 3,x
				sta $d015
			!skp:	
				lda spider.frame,x
				sta scrn + $3f8 + 3,x
				
			!next:
				inc cnt
				inc cnt
				inx
				cpx #5
				bne !sloop-	
						
				lsr $d019	
								
				lda penalty
				asl
				asl
				asl					
				adc #51 + 64	
				adc finescroll
				sta $d012
				
				:setirqaddr(irq_04)		
				
		savea:	lda #$00
		savex:	ldx #$00	
		savey:	ldy #$00
		
				rti
				
cnt:
.byte 0
}



//end of ledger
irq_04:
{
				sta savea + 1
								
				lda #$0c
				sta $d021
				
				lda #$0f
				sta $d023
				lda #$01
				sta $d022
				
				lsr $d019
				lda penalty
				asl
				asl
				asl					
				adc #51 + 85	
				adc finescroll
				sta $d012
				:setirqaddr(irq_05)
				
		savea:	lda #$00
//		savex:	ldx #$00	
				rti
}


//end of window.
irq_05:
{ 

				sta savea + 1
				lda #$07
				sta $d022
				lda #$08
				sta $d023
				lsr $d019
				
				lda penalty
				asl
				asl
				asl					
				adc #51 + 90	
				adc finescroll
				sta $d012
				:setirqaddr(irq_06)
				
		savea:	lda #$00	
				rti
}
				
//right after the windows. sets multicolor for the bricks Takes care of some of the colours of the sidewalk				
irq_06:
{				
				sta savea + 1
				
				lda #8
				sta $d022
				lda #2
				sta $d023
				
			
				lsr $d019
				//lda penalty
				//asl
				//asl
				//asl					
				//adc #51 + 167	
				
				lda #51 + 167
				clc
				adc finescroll
				sta $d012
				:setirqaddr(irq_07)
				
		savea:	lda #$00	
				rti
}
		
//changes some colors for the sidewalk
irq_07:
{

				sta savea + 1						
				stx savex + 1
				
				lda #$0f
				sta $d022
				lda #$0b
				sta $d023
		
				lsr $d019
				
				//lda penalty
				//asl
				//asl
				//asl					
				//adc #51 + 175	
				lda #51 + 175
				clc
				adc finescroll
				sta $d012
				
				:setirqaddr(irq_08)
								
		savea:	lda #$00
		savex:	ldx #$00	
				rti
}

//skirting. changes more color for the sidewalk.
irq_08:
{
				sta savea + 1
	
			//	lda #$0b
			//	sta $d021
				
				lda #$08
				sta $d023

	/*			lda $d012
			!:	cmp $d012
				beq !-
	*/			
				lda #7
				sta $d022		
				
				lsr $d019
				
				lda #51 + 183
				clc
				adc finescroll
				sta $d012
				
				:setirqaddr(irq_09)
		savea:	lda #$00
				rti
}
				
irq_09:
{
				sta savea + 1					
				lda #$0b
				sta $d021
				
				lsr $d019		
				:setirq(irq_logo, $f9)
				
		savea:	lda #$00	
				rti
}
		
// Opens bottom border and places the activision logo, which is made of several sprites

irq_logo:
{
			sta savea + 1
			stx savex + 1
	
			lda $d01e
			sta ghostd01e
		

			lda #1
			sta frameflag //display has been drawn
					
			lda #$00
			sta $d01b //restore priority
			
			lda $d011
			and #%00010000
			ora #%00000011
			sta $d011	//border off
			
			lda #$ff
			sta $7fff
				
			lda #$ff
			sta $d015
			
			//place logo at $ff
			lda #%00001000
			sta $d01c
			
			lda #$0
			sta $d010
			
			lda #[logo_bars & $3fff] / 64
			sta scrn + $3f8 + 3
			lda #[logo_bars & $3fff] / 64 + 1
			sta scrn + $3f8 + 4
			lda #[logo_bars & $3fff] / 64 + 2
			sta scrn + $3f8 + 5
			lda #[logo_bars & $3fff] / 64 + 3
			sta scrn + $3f8 + 6
			
			ldx #1
			
			.for (var i = 0; i < 3; i++)
			{
				lda #[logo_sprites & $3fff] / 64 + i
				sta scrn + $3f8 + i
				stx $d027 + i
			}
			
			lda #2
			sta $d027 + 3
			lda #8
			sta $d025
			lda #7
			sta $d026
			lda #5
			sta $d027 + 4
			lda #3
			sta $d027 + 5
			lda #6
			sta $d027 + 6
			
			
			lda #$ff
			.for (var i = 0; i < 7; i++)
			sta $d001 + i * 2
				
			.for (var i = 0; i < 3; i++)
			{
				lda #24 + 160 - 36 + 24 * i + 4
				sta $d000 + i * 2
			}
					
	
			lda #24 + 160 - 36 - 8 + 4
			sta $d000 + 3 * 2
			sta $d000 + 4 * 2
			sta $d000 + 5 * 2
			sta $d000 + 6 * 2
			
			lsr $d019
			:setirq(irq_00, 8)
			
	savea:	lda #$00
	savex:	ldx #$00

			rti
}


or_mask:
.byte 1,2,4,8,16,32,64,128

and_mask:
.byte %11111110,%11111101,%11111011,%11110111,%11101111,%11011111,%10111111,%01111111