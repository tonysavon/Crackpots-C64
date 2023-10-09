//max three spiders at any time

.label STATUS_SPIDER_POSITIONING = 	1
.label STATUS_SPIDER_CLIMBING 	 = 	2
.label STATUS_SPIDER_DYING		 =	4
.label STATUS_SPIDER_DEAD		 =  8

//a dying spider flashes to disappearence, while a dead spider is invisible.
//we need these flags because a dead spider is just "invisible", but it still moves normally
//because spider paths are used to spawn more spiders

spider:
{
		init:
				lda #0
				sta status
				sta status + 1
				sta status + 2
				sta status + 3
				sta status + 4
				sta status + 5
				
				sta counter
				sta next
						
				rts
				
				
		update:
				ldx #4 //cycles on spiders
				
			!:	lda status,x
				bne !active+
				jmp !next_spider+
			!active:	
				
				//first let's see about the clock
				and #STATUS_SPIDER_DYING
				beq !skp+
				
				inc spider.clock,x
				lda spider.clock,x
				cmp #16
				bne !skp+
			
				lda status,x
				and #$ff-STATUS_SPIDER_DYING
				ora #STATUS_SPIDER_DEAD
				sta status,x

			!skp:	
			
				lda status,x
				and #STATUS_SPIDER_POSITIONING
				bne !positioning+
				
				//vertical climb
				lda ypos_sub,x
				sec
				sbc spider_speed
				sta ypos_sub,x
				lda ypos,x
				sbc spider_speed + 1
				sta ypos,x
				
	update_strategy:
				jsr update_black //!climbing+	//this is bespoke climbing strategy for each spider
				

				lda ypos,x
				
				lsr
				lsr
				anc #1
				
				adc #[spider_sprites & $3fff] / 64 + 2
				sta frame,x
				
				lda penalty
				asl
				asl
				asl
				adc #10 * 8 + 50
				cmp ypos,x
				bcc !next+
				
			//it reached the window.
			//update hud if the spider was alive	
				lda status,x
				and #STATUS_SPIDER_DYING | STATUS_SPIDER_DEAD
				bne !skp+
				
				lda hud_spiders
				beq !skp+
				
				dec hud_spiders
				
				txa
				pha
				
				:sfx(SFX_ENTER)
					
				jsr update_hud_spiders
				
				pla
				tax
					
			!skp:	
				
				lda #0
				sta status,x
				jmp !next_spider+
				
			!next:
				//let's se if we are in a position such that we must activate another spider	
				stx p0tmp
				ldy p0tmp
				dey
				bpl !skp+
				ldy #4
			!skp:	
				lda status,y 
				and #STATUS_SPIDER_POSITIONING | STATUS_SPIDER_CLIMBING
				bne !skp+
				
				lda ypos,x
				and #%11111000
				cmp #[50 + 18 * 8] & %11111000	
				bne !skp+
				
				//deploy!
				jsr deploy
				ldx p0tmp
				
			!skp:
				jmp !next_spider+
				
			!positioning:
				//the first, positioning state.
				//this, in turn, is made of two stages. first, we go vertically up to grown level.
				//then we just move horizontally
		
				lda ypos,x
				cmp #21*8 + 50
				bcc !second+
			//first:		
				sbc #1
				sta ypos,x
			
				lsr	
				anc #1
				adc #[spider_sprites & $3fff] / 64 + 2
				sta frame,x
					
				jmp !next_spider+
				
			!second:	
				//second, walks horizontally on the ground
				lda xpos_h,x
				lsr
				lda xpos_l,x
				ror
				
				cmp goal_bottom,x
				
				bcc !right+
				beq !reached+
				
			!left:
				lda xpos_l,x
				sec
				sbc #2
				sta xpos_l,x
				lda xpos_h,x
				sbc #0
				sta xpos_h,x
				jmp !next+
				
			!right:	
				lda xpos_l,x
				clc
				adc #2
				sta xpos_l,x
				lda xpos_h,x
				adc #0
				sta xpos_h,x
				jmp !next+
				
			!reached:	

				lda status,x
				and #$ff - STATUS_SPIDER_POSITIONING
				ora #STATUS_SPIDER_CLIMBING
				sta status,x //move to climbing status
				jmp !next_spider+
				//frame
			!next:
				 		
				lda xpos_l,x
				lsr	
				lsr
				anc #1
				adc #[spider_sprites & $3fff] / 64 + 0
				sta frame,x
					
				
			!next_spider:
				dex
				bmi !done+
				jmp !-	
			!done:
				rts

		deploy:
				lda counter
				cmp #12
				bcc !ok+
				rts
			
		//spawn
		!ok:
				:sfx(SFX_SEWER)
		
				inc counter
				jsr random_
				lda random_.random + 0
				//we have to select one of 6 windows. 
				//We can't divide by 6 (easily), so we just use ranges.
				ldy #0
				.for (var i = 1; i < 6; i++)	
				{	
					cmp #i * (255.0 / 6.0)
					bcc !next+
					iny
				}
				//y = random(0..5)
				
			!next:

				dec next
				bpl !skp+
				
				lda #4
				sta next
				
			!skp:	
				
				ldx next
				
				lda #[spider_sprites & $3fff] / 64 + 2
				sta frame,x
				
				lda #11 * 8 + 24
				sta xpos_l,x
				lda #0
				sta xpos_h,x
				
				sta xpos_sub,x
				sta ypos_sub,x
				
				lda #22 * 8 + 50
				sta ypos,x
				
				lda #STATUS_SPIDER_POSITIONING
				sta status,x

				tya
				sta goal_top,x
	deploy_strategy:						
				jmp deploy_black
				
			
//deployment routine.
//x is the spider id
//y is the target window				
deploy_black: 
				//tya
				lda column_to_x,y
				sta goal_bottom,x
				rts		
				
//x is the spider id
update_black:
				
				rts	
			
				
deploy_blue:

				lda penalty
				asl
				asl
				
				and #7
				sta p0tmp
				lda column_to_x,y
				sec
				sbc p0tmp
				clc
				adc #2
				sta goal_bottom,x
				
				lda column_to_x,y
				adc #4
				sta range_r,x
				sec
				sbc #8
				sta range_l,x
				lda #1
				sta dir,x
				rts				
				
update_blue:
				
				lda dir,x
				beq !right+
				
				//left	
				lda xpos_sub,x
				sec
				sbc spider_speed
				sta xpos_sub,x
				lda xpos_l,x
				sbc spider_speed + 1
				sta xpos_l,x
				lda xpos_h,x
				sbc #0
				sta xpos_h,x
				lsr
				lda xpos_l,x
				ror
				cmp range_l,x
				bcc !switch+
				jmp !done+
			!switch:
			compensate_underflow:	
				lda #0
				sta dir,x
				
				//compensate for the underflow
				lda range_l,x
				asl
				sta p0tmp + 0 //l0
				lda #0
				rol
				sta p0tmp + 1 //h0
				
				sec
				lda #0
				sbc xpos_sub,x
				sta p0tmp + 2 //s1
				lda p0tmp + 0 
				sbc xpos_l,x
				sta p0tmp + 3 //l1
				//no need to subtract high byte, as the difference can't be larger than a couple of pixels
				
				lda p0tmp + 2
				sta xpos_sub,x
				
				clc
				lda p0tmp + 3
				adc p0tmp + 0
				sta xpos_l,x
				
				lda #0
				adc p0tmp + 1
				sta xpos_h,x
				
				jmp !done+
				
			!right:
				lda xpos_sub,x
				clc
				adc spider_speed
				sta xpos_sub,x
				lda xpos_l,x
				adc spider_speed + 1
				sta xpos_l,x
				lda xpos_h,x
				adc #0
				sta xpos_h,x
				lsr
				lda xpos_l,x
				ror
				cmp range_r,x
				bcs !switch+
				jmp !done+
			!switch:
			compensate_overflow:	
				lda #1
				sta dir,x
				
				//compensate for the overflow
				lda range_r,x
				asl
				sta p0tmp + 0 //l0
				lda #0
				rol
				sta p0tmp + 1 //h0
				
				sec
				lda xpos_sub,x
				sbc #0
				sta p0tmp + 2 //s1
				lda xpos_l,x
				sbc p0tmp + 0 
				sta p0tmp + 3 //l1
				//no need to subtract high byte, as the difference can't be larger than a couple of pixels
				
				lda #0
				sec
				sbc p0tmp + 2
				sta xpos_sub,x
				
				lda p0tmp + 0
				sbc p0tmp + 3
				sta xpos_l,x
				
				lda p0tmp + 1
				sbc #0
				sta xpos_h,x
				
			!done:
				rts	
					
				

deploy_red: 

				lda penalty
				asl
				asl
				asl
				sta p0tmp + 3
				lda #[(21-10) * 8 ]
				sec
				sbc p0tmp + 3 //this is the horizontal gap

				lsr
				sta p0tmp + 3

				cpy #3
				bcs !goesright+
			
				//window on the left, goes left.
				lda #1
				sta dir,x
		
				lda column_to_x,y
				clc
				adc p0tmp + 3
				sta goal_bottom,x
				jmp !done+
				
			!goesright:
				lda #0
				sta dir,x
				
				lda column_to_x,y
				sec
				sbc p0tmp + 3
				sta goal_bottom,x
				
			!done:		
				rts		
				
//x is the spider id
update_red:
				lda dir,x
				beq !right+
				
				//left	
				lda xpos_sub,x
				sec
				sbc spider_speed
				sta xpos_sub,x
				lda xpos_l,x
				sbc spider_speed + 1
				sta xpos_l,x
				lda xpos_h,x
				sbc #0
				sta xpos_h,x
				
				jmp !done+
				
			!right:
				lda xpos_sub,x
				clc
				adc spider_speed
				sta xpos_sub,x
				lda xpos_l,x
				adc spider_speed + 1
				sta xpos_l,x
				lda xpos_h,x
				adc #0
				sta xpos_h,x
				
			!done:
				rts	
								

deploy_green:


				tya
				pha
				

				lda column_to_x,y
				sec
				sbc #8
				
				ldy penalty
				clc
				adc green_penalty_table,y
				
				sta goal_bottom,x

				pla
				tay
				
				lda column_to_x,y
				clc
				
				adc #8
				sta range_r,x
				sec
				sbc #16
				sta range_l,x
				lda #0
				sta dir,x
				rts				
				
	green_penalty_table:
	.byte 0,2,4,10,12,0			
				
				
update_green:
				
				lda dir,x
				beq !right+
				
				//left	
				lda xpos_sub,x
				sec
				sbc spider_speed
				sta xpos_sub,x
				lda xpos_l,x
				sbc spider_speed + 1
				sta xpos_l,x
				lda xpos_h,x
				sbc #0
				sta xpos_h,x
				lsr
				lda xpos_l,x
				ror
				cmp range_l,x
				bcs !done+
				
				jmp compensate_underflow
				
				
			!right:
				lda xpos_sub,x
				clc
				adc spider_speed
				sta xpos_sub,x
				lda xpos_l,x
				adc spider_speed + 1
				sta xpos_l,x
				lda xpos_h,x
				adc #0
				sta xpos_h,x
				lsr
				lda xpos_l,x
				ror
				cmp range_r,x
				bcc !done+
				jmp compensate_overflow
			!done:
				rts						
					
//maps a column index (0..5) to x offset in pixel pairs.
column_to_x:
.fill 6, (9 * 8 + 24 + i * 32) / 2				
								
//spider metadata. not every spider type uses every entry in this list
status: 		.byte 0,0,0,0,0
xpos_sub:		.byte 0,0,0,0,0
xpos_l: 		.byte 0,0,0,0,0
xpos_h: 		.byte 0,0,0,0,0
ypos_sub: 		.byte 0,0,0,0,0
ypos:	 		.byte 0,0,0,0,0

goal_top:		.byte 0,0,0,0,0	//target column/window number
goal_bottom:	.byte 0,0,0,0,0 //target bottom x position in pixel pair
dir:			.byte 0,0,0,0,0 //when zig-zag-ing indicates the current direction. 0 right, 1 left
range_l:		.byte 0,0,0,0,0 //when zig-zaging indicates the left boundary in pixel pairs
range_r:		.byte 0,0,0,0,0 

clock: 			.byte 0,0,0,0,0
frame:			.byte 0,0,0,0,0

counter:		.byte 0
next:			.byte 0		//circular counter.
}

.label STATUS_FLOWERS_FALLING = 	1
.label STATUS_FLOWERS_EXPLODING = 	2
flowers:
{

		init:
				lda #0
				sta status
				sta status + 1
				sta status + 2
	
				rts
				
		drop:
				lda nodrop
				beq !skp+
				lda #0
				rts
				
			!skp:	
				//check if we controls are not blocked
				lda hud_spiders
				bne !skp+
				
				//accumulator is already 0, so it will return pot not dropped
				rts
				
			!skp:	
				//check if we are positioned:
				stx p0tmp
				
				lda hero.xpos
				sec
				sbc #40
				lsr
				lsr
				
				//hero is well positioned for a drop if A is 
				tax
				ldy offset,x
				bpl !ok+
				//notpositioned
				ldx p0tmp
				lda #0
					
				rts
				
				
			!ok:
				//y contains the column
				lda environment.ledge,y
				bne !ok+
				
				ldx p0tmp
				lda #0
				rts
							
			!ok:
				//we can finally drop!	
				lda #0
				sta environment.ledge,y
				
				ldx next
				tya
				sta column,x
				
				lda #STATUS_FLOWERS_FALLING
				sta status,x	
			
				lda #0
				sta clock,x
				
				ldy penalty
				lda environment.penaltytoy0,y
				sta ypos,x
				
					
				lda #STATUS_HERO_PUSHING
				sta hero.status
				lda #0
				sta hero.clock
				
				dec next
				bpl !+
				lda #2
				sta next
			!:
				jsr environment.draw_ledge
				lda #1 //signal that we actually dropped
				rts
				
		update:
				ldx #2 //cycles on flowers
			!:	lda status,x
				beq !next+
				
				cmp #STATUS_FLOWERS_EXPLODING
				beq !exploding+
				//falling
				lda #[flowers_sprites & $3fff] / 64 + 0
				sta frame,x
								
				inc clock,x
				ldy clock,x
				lda trajectory,y
				ldy penalty
				clc
				adc environment.penaltytoy0,y
				sta ypos,x
				cmp #112 + 6 * 8 + 50
				bcc !next+
				inc status,x //now exploding
				lda #0
				sta clock,x
				lda #112 + 6 * 8 + 50
				sta ypos,x
				
				txa
				pha
				
				:sfx(SFX_SMASH)
				
				pla
				tax
				
				jmp !next+
			
			!exploding:
				//exploding
				lda clock,x

				lsr
			
				clc
				adc #[flowers_sprites & $3fff] / 64 + 1
				sta frame,x
				
				inc clock,x
				lda clock,x
				cmp #8
				beq !off+
				
				jmp !next+
				
			!off:	
						
				lda #0
				sta clock,x
				sta status,x
				
				lda #1
				ldy column,x
				sta environment.ledge,y
				jsr random_
				lda random_.random 
				and #3
				tay
				lda environment.flower_color_map,y
				ldy column,x
				sta environment.flower_color,y
				
				jsr environment.draw_ledge
				
			!next:	
				dex
				bpl !-
				rts
						
offset:
.for (var i = 0; i < 6; i++)
{
	.byte $ff,i,i,$ff
}
.byte $ff, $ff //for good measure


xoff:
.fill 6, 9 * 8 + 24 + 32 * i
			
trajectory:
.fill 64, pow((i / 64.0),1.5) * 112 // + 6 * 8 + 50
.fill 16, 112  //+ 6 * 8 + 50
	
status: .byte 0,0,0
column:	.byte 0,0,0
clock:	.byte 0,0,0
ypos:	.byte 0,0,0
frame:	.byte 0,0,0

next: .byte 0
}
