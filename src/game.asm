.const sid = LoadSid("../sid/Crack_Pots_C64.sid")
.const p0start = $02
.var p0current = p0start
.function reservep0(n)
{
	.var result = p0current
	.eval p0current = p0current + n
	.return result	
}

.const frameflag = reservep0(1)
.const p0tmp = reservep0(8)

.const nodrop = reservep0(1)

.const spider_speed = reservep0(2)

.const menustage = reservep0(1)
.const level = reservep0(1) //0..3
.const stage = reservep0(1)

.const hud_spiders = reservep0(1)
.const score = reservep0(6)
.const penalty = reservep0(1)

.const music_on = reservep0(1)
.const key_clock = reservep0(1)
.const hud_clock = reservep0(1)

.const finescroll = reservep0(1)

.const ghostd01e = reservep0(1)

.const gameovermode = reservep0(1)
.const scrn = $4400
.pc = $0801 
:BasicUpstart(main)
.pc  = $0820 "main"
main:
				sei
				lda #$35
				sta $01
			

				jsr showpic
			
				jsr wait_button
				
				lda #$0b
				sta $d011
	
				
				lda #1
				sta menustage
			
			splashloop:		
				jsr splash	
			
				jsr blank
					
				jsr set_game_screen
				jsr clear_irq

				:setirq(irq_00, $08)
				
				lda #0
				sta level				
				ldx menustage
				dex
				stx stage
				
				jsr game_init
				jsr hero.init
				
				lda #2
				jsr sid.init
				
				jsr unblank
				
				cli
				
				ldx #$7f
			!:	jsr vsync
				dex
				bpl !-
							
		levelloop:
				jsr level_init						
				jsr environment.init
				
				jsr hero.init_nopos
				jsr spider.init
				jsr flowers.init
				
				//deploy the first one, all the others will come
				jsr spider.deploy
				
		gameloop:
	
				jsr framesync
		
				jmp test_game_events
			return_from_test_game_events:	

				jsr controls
				jsr hero.update
				jsr flowers.update
				jsr spider.update

				jmp gameloop

			
				
// this manages some game events, like collisions, game over, level complete etc.
test_game_events:
{

				//additional controls
				lda key_clock
				beq !skp+
				dec key_clock
			!skp:

				lda hud_clock
				beq !skp+
				
				dec hud_clock
				bne !skp+
				
				lda #0
				sta irq_00.note_display + 1
				
			!skp:	

				//check keypress for various things, such as pause or music on/off
				lda $dc01
				cmp #239
				bne !skp+

				jsr  pause
				lda #255
				
			!skp:
			
				cmp #253
				bne !skp+
				
				jsr toggle_music
			
			!skp:			
				//6 spiders got in?
				lda hud_spiders
				bne test_end_of_level
				
				lda #$ff // > #12, means spider no more spiders allowed because it's already game over.
				sta spider.counter
				//accelerate
				lda #0
				sta spider_speed
				lda #2
				sta spider_speed + 1
				
				lda #1
				sta nodrop
				//let's wait for all the spiders to get in
				jsr hero.init_nopos
			!w:	
				jsr flowers.update
				jsr spider.update 
				jsr controls
				
				jsr framesync
				
				ldx #4
				lda #0
			!:	ora spider.status,x
				dex
				bpl !-
				and #STATUS_SPIDER_POSITIONING | STATUS_SPIDER_CLIMBING 
				bne !w-
						
				jsr vsync
				jsr collapse
				lda penalty
				cmp #6
				bne !skp+
				jmp game_over
			!skp:	
				lda #0
				sta nodrop
				jmp levelloop
				
				
			test_end_of_level:
				lda spider.counter
				cmp #12				
				bne test_collisions
				
				ldx #4
				lda #00
			!:	ora spider.status,x
				dex
				bpl !-
			
				cmp #00
				bne test_collisions
			
				lda #1
				sta nodrop	
				
				jsr hero.init_nopos
				
				ldx #$4f
				
			!:	txa
				pha
				jsr vsync
				jsr flowers.update
				jsr controls
				pla
				tax
			
				dex
				bpl !-
			
				jsr hero.init_nopos
				jsr end_of_level
					
				lda #0
				sta nodrop
				
				inc level
				lda level
				cmp #4
				bne !+
				lda #0
				sta level
				inc stage
			!:
				jmp levelloop
				
				
			test_collisions:
				//collision
				lda #%00001000
				sta p0tmp	  // bitmask
				
				ldx #$00	 // counter on spider
			!sl:	
				bit ghostd01e
				beq !next+	
				
				lda spider.status,x
				and #STATUS_SPIDER_DYING | STATUS_SPIDER_DEAD
				bne !next+  //already dying
				
				lda spider.status,x
				ora #STATUS_SPIDER_DYING
				sta spider.status,x
				lda #0
				sta spider.clock,x
				
				//adding score it's 10..40 for levels, times stage number until 8
				stx savex + 1
				
				lda level
				clc
				adc #1
				sta p0tmp + 1
				
				ldy stage 
				cpy #8
				bcc !+
				
				ldy #7
				
			!:	lda p0tmp + 1
				jsr add_score_x
				dey
				bpl !-
			
				jsr put_score	
				
				:sfx(SFX_SQUASH)
				
			savex:
				ldx #0	
							
			!next:

				asl p0tmp
				lda p0tmp
				inx
				cpx #5
				bne !sl-
				
				jmp return_from_test_game_events 
				
								
}				

level_init:
{
				//restore 6 spider icons in the HUD
				jsr hud_init
				jsr spider.init
			
				lda penalty
				asl
				asl
				sta p0tmp
				
				lda stage
			
				asl
				asl
				ora level
				sec
				sbc p0tmp
				bcs !skp+
				lda #0
			!skp:	
				cmp #48
				bcc !skp+	
				lda #47
			!skp:	
				tax
				
				lda spider_speed_table.lo,x
				sta spider_speed
				lda spider_speed_table.hi,x
				sta spider_speed + 1
	
				
				ldx level
				lda deploy_strategy_table.lo,x
				sta spider.deploy_strategy + 1
				lda deploy_strategy_table.hi,x
				sta spider.deploy_strategy + 2
										
				lda update_strategy_table.lo,x
				sta spider.update_strategy + 1
				lda update_strategy_table.hi,x
				sta spider.update_strategy + 2
							
				rts
				
.const deploy_strategy_list = List().add(spider.deploy_black, spider.deploy_blue, spider.deploy_red, spider.deploy_green)
.const update_strategy_list	= List().add(spider.update_black, spider.update_blue, spider.update_red, spider.update_green)			

deploy_strategy_table:
.lohifill 4, deploy_strategy_list.get(i)

update_strategy_table:
.lohifill 4, update_strategy_list.get(i)

				
spider_speed_table:
.lohifill 48, 180 + 16*i				

}


game_init:
{
				lda #0
				sta score
				sta score + 1
				sta score + 2
				sta score + 3
				sta score + 4
				sta score + 5
			
				
				sta penalty
				
				sta finescroll
		
				sta gameovermode
		
				lda #$00
				sta key_clock
				
				lda #$7f
				sta hud_clock
				
				lda #1
				sta music_on
		
				jsr hud_init
										
				rts
}

set_game_screen:
				lda #$0c
				sta $d021
				lda #$00
				sta $d020
				lda #2
				sta $dd00
				lda #%00010010
				sta $d018
				lda #$d8
				sta $d016
				:TS_DECRUNCH(compressed_bg,$4400)
				ldx #0
			!:	.for (var i = 0; i < 4; i++)
				{
					lda colormap + i * $100,x
					sta $d800 + i * $100,x
				}					
				inx
				bne !-
				rts
				
game_over:
				
				lda #3
				jsr sid.init
		
				lda #1
				sta gameovermode
				
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
				

end_of_level:
			!b:	dec hud_spiders
				jsr update_hud_spiders
				:sfx(SFX_BONUS)
				
				lda #2
				jsr add_score_xx
				jsr put_score
				
				ldx #$0f
			!:	jsr vsync
				
			
				txa
				pha
				jsr controls
				pla
				tax
			
				dex
				bpl !-	
		
				
						
				lda hud_spiders
				bne !b-	
			
				ldx #$1f
			!:	jsr vsync
				txa
				pha
				jsr controls
				pla
				tax
				dex
				bpl !-
				
				rts
				
				
					
.const MUNCH = 100 //munch char				
//plays the building collapse sequence				
collapse:
{

				lda #0
				sta flowers.status
				sta flowers.status + 1
				sta flowers.status + 2
				
				//chew the base
	
				ldx #0 //loop on chars
			!c:	
			
				txa
				pha
				:sfx(SFX_MUNCH)
				pla
				tax
			
				cpx #40
				bcs !skp+
				
				lda #0
				sta $d800 + 20 * 40,x
			!skp:
						
				ldy #0 //loop on pixel pairs
			!p:	
			
				sty p0tmp
				stx p0tmp + 1
		
				jsr controls
				jsr wait_crunch_line
				ldy p0tmp
				ldx p0tmp + 1
				
				tya
				lsr
				clc
				adc #[spider_sprites & $3fff] / 64 + 4
				sta scrn + $3f8 
				lda #1
				sta $d015
				
				txa
				clc
				adc #2
				asl
				asl
				asl
				sta $d000
				lda #0
				rol
				sta $d010
				tya
				asl
				adc $d000
				sta $d000
				
				lda #210
				sta $d001
				lda #0
				sta $d01c
				
				ldy level
				lda environment.level_spider_color,y
				sta $d027
				
				ldy p0tmp
				ldx p0tmp + 1
				
				cpx #40
				bcs !skp+
							
				tya
		
				adc #100
				sta scrn + 20 * 40,x
		
			!skp:				

				jsr vsync
				

				iny
				cpy #4
				bne !p-
					
				inx
				cpx #42
				bne !c-

				ldx #$0f
			!:	jsr vsync
			
				txa
				pha
				jsr controls
				pla
				tax
			
				dex
				bpl !-
				//collapse building
				
				:sfx(SFX_CRASH)
				
				lda penalty
				clc
				adc #5 
				sta p0tmp  // final
				
				ldy #20
				
			!l:
				tya
				tax
				
				lda screenrow.lo,x
				sta dst + 1
				lda screenrow.hi,x
				sta dst + 2
				
				dex
				lda screenrow.lo,x
				sta src + 1
				lda screenrow.hi,x
				sta src + 2
					
				
				ldx #39
				
			!:	
		src:	lda scrn + 40*19,x
		dst:	sta scrn + 40*20,x
				
				dex
				bpl !-
				
				dey
			
				cpy p0tmp
				bne !l-
			
				lda screenrow.lo,y
				sta dst2 + 1
				lda screenrow.hi,y
				sta dst2 + 2
				
				lda #0
				ldx #39
		dst2:	sta scrn + 40 * 5,x
				dex
				bpl dst2	
				
				
				lda #8
				ldx #39
			!:	sta $d800 + 40 * 20,x
				dex
				bpl !-
				
				//we must copy 7 charlines worth of colourdata = 280 chars
				
				lda penalty
				clc
				adc #6
				tax
				
				clc
				lda colorrow.lo,x
				sta dstc0 + 1
				adc #140
				sta dstc1 + 1
				lda colorrow.hi,x
				sta dstc0 + 2
				adc #0
				sta dstc1 + 2
				
				ldx #0
				
			!:	lda colormap + 5 * 40,x
		dstc0:	sta $d800 + 6 * 40,x
				lda colormap + 5 * 40 + 140,x
		dstc1:	sta $d800 + 6 * 40 + 140,x
				inx
				cpx #140
				bne !-
					
				inc penalty
				jsr environment.draw_ledge
				
				//add a bit of shaking
				
				ldy #$3f
			!:	jsr vsync	
				tya
				pha
				jsr controls
				pla
				tay
				jsr random_
				and #3
				sta finescroll
			
				dey
				bpl !-
				
				lda #0
				sta finescroll
		
				rts
				
				
wait_crunch_line:
				lda #200
			!:	cmp $d012
				bcs !-
			
				rts
				
}
		


pause:
{
			!:	jsr framesync
				lda $dc01
				cmp #239
				beq !-
				
			!:	jsr framesync
				lda $dc01
				cmp #239
				bne !-
				
			!:	jsr framesync
				lda $dc01
				cmp #239
				beq !-
					
				rts
}
		
screenrow:
.lohifill 25, scrn + 40 * i

colorrow:				
.lohifill 25, $d800 + 40 * i	
				
.import source "splash.asm"
.import source "irq.asm"
.import source "sfx.asm"
.import source "hero.asm"
.import source "controls.asm"				
.import source "misc.asm"
.import source "environment.asm"
.import source "actors.asm"
.import source "hud.asm"
.import source "decrunch.asm"

.pc = * "compressed bg"
compressed_bg:
.import binary "../gfx/map.ts"

.align $100
colormap:
.const char_attr = LoadBinary("../gfx/chars_attr.bin")
.const char_map = LoadBinary("../gfx/map.bin")
.fill 960,char_attr.uget(char_map.uget(i))

.pc = $9000 "sid"
.fill sid.size,sid.getData(i)

.pc = $4800 "chars"
chars:
.import binary "../gfx/chars.bin"
.label FLOWERS_CHARS = [ * - chars] / 8
.const flowers_chars_png = LoadPicture("../assets/flowers2.png", List().add($483AAA,$99692D,$72B14B,$924A40))
.for (var cy = 0; cy < 16; cy+=8)
	.for(var cx = 0; cx < 2; cx++)
		.for (var b = 0; b < 8; b++)
			.byte flowers_chars_png.getMulticolorByte(cx,cy + b)
.label SPIDER_HUD = [ * - chars] / 8
.const spider_hud_png = LoadPicture("../assets/spider_icon.png", List().add($6b6d6b,$000000))
.for (var cy = 0; cy < 16; cy+=8)
	.for(var cx = 0; cx < 2; cx++)
		.for (var b = 0; b < 8; b++)
			.byte spider_hud_png.getSinglecolorByte(cx,cy + b)

.label DIGIT_CHARS = [* - chars] / 8
digits:
.const digitpic = LoadPicture("../gfx/digits_shadow.png", List().add($000002,$0000ff,$000000,$ffffff)) // bg,mc1,mc2,charcolor
.for (var c = 0; c < 20; c++)
	.for (var b = 0; b < 8; b++)
		.byte digitpic.getMulticolorByte(c,b) 			
			

.macro LoadSprite(pic,x0,y0,bg,col1,col2,col3)
{
	.var p = LoadPicture(pic,List().add(bg,col1,col2,col3)) //bg,mc1,spritecolor,mc2
	.for (var y = y0; y < y0 + 21; y++)
		.for (var x = x0; x < x0 + 3; x++)
			.byte p.getMulticolorByte(x,y)
	.byte col1 
}

.pc = $5000 "sprites"
hero_sprites:

.for (var s = 0; s < 3; s++)
{
	:LoadSprite("../assets/hero.png", 6 * s, 0, $675200,$000000,$C18178,$ffffff) // mc (black and white plus pink
	:LoadSprite("../assets/hero.png", 6 * s, 0, $675200,$000001,$924A40,$fffff1) // red
	:LoadSprite("../assets/hero.png", 6 * s, 0, $675200,$000001,$483aaa,$fffff1) // blue
	:LoadSprite("../assets/hero.png", 6 * s, 0, $675200,$000001,$D5DF7C,$fffff1) // yellow
}

flowers_sprites:
.const flowers_sprites_png = LoadPicture("../assets/flowers2_sprites.png", List().add($483AAA,$99692D,$924A40,$72B14B))
.import binary "../sprites/flowers.bin"

.align 64 //everything before is filled up with zeroes
spider_sprites:
.import binary "../sprites/spider.bin"
logo_bars:
.import binary "../gfx/logo_bars.bin"
logo_sprites:

.var logopic = LoadPicture("../gfx/logo_top.png",List().add($000000, $ffffff)) // bg,color
.for (var s = 0; s < 3; s++)
{
	.for (var y=0; y<21; y++)
		.for (var x=0; x<3; x++)
			.byte logopic.getSinglecolorByte(x + s * 3,y) 
	.byte 0
}	

gameover_sprites:
.import binary "../sprites/gameover.bin"

note_sprites:
.import binary "../gfx/note.bin"

.pc = $3400 + 40 * 17 "credits"

.text "             Adaptation by              "
.text "                                        "
.text "         A. Savona : Code               "
.text "            S. Day : Graphics           "
.text "          S. Cross : Music, Sfx         "
.text "                                        "

.text "Joystick up / down : Selects stage -    "
.text "       Fire button : Starts game        "

.pc = $b400 "splash screen scr"
.import binary "../gfx/credits.scr"
.pc = $a000 "splash screen map"
.const scm = LoadBinary("../gfx/credits.map")
.fill 16 * 320, scm.get(i)

//black screen upon opening border
.pc = $7fff
.byte $ff


.const KOALA_TEMPLATE = "C64FILE, Bitmap=$0000, ScreenRam=$1f40, ColorRam=$2328, BackgroundColor = $2710"
.var kla = LoadBinary("../assets/loader.kla", KOALA_TEMPLATE)

.pc = $c000 "loader bmp"
.fill 8000, kla.getBitmap(i)
.pc = $b800 "loader col"
.fill 1000, kla.getColorRam(i)
.pc = $e000 "loader scr"
.fill 1000, kla.getScreenRam(i)