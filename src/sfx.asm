.macro sfx(sfx_id)
{
			ldx #sfx_id
			jsr sfx_play
}


// Switches music on or off, sets the SFX handler accordingly
toggle_music:
{

				lda key_clock
				beq !skp+
				rts
				
			!skp:
				
				lda #$3f
				sta key_clock
					
				jsr erase_sid

	
				lda #1
				sta irq_00.note_display + 1
				
				lda music_on 
				beq !switch_on+
				
				//switch off
				
				lda #0
				sta music_on
				
				lda #4	//mute tune
				jsr sid.init 
				
				lda #[note_sprites & $3fff] / 64 + 1 // crossed note
				
				jmp !next+
			!switch_on:	
			
				lda #1
				sta music_on
			
				lda #$0f
				sta $d418
				
				lda #2 //music on, no level-start
				jsr sid.init
				
				lda #[note_sprites & $3fff] / 64 //full note
				
			!next:	
				sta irq_00.note_sprf + 1
				lda #127
				sta hud_clock

				//jsr set_sfx_routine
				rts
				
}


sfx_play:
{			
	sfx_routine:
			jmp play_with_music
}

erase_sid:
{
			ldx #$1f
			lda #0
		!:	sta $d400,x
			dex
			bpl !-
			rts
}

play_with_music:
{
			lda channel
			eor #1
			sta channel

			lda wavetable.lo,x
			ldy wavetable.hi,x

			ldx channel
			inx			
			
			pha
			
			lda times7,x
			
			tax
			pla
			jmp sid.init + 6		
			
times7:
.fill 3, 7 * i
	
channel:
.byte 0	
}


// Only 7 different effects, but let's make them count :-)
.label SFX_BONUS = 0
.label SFX_CRASH = 1
.label SFX_ENTER = 2
.label SFX_MUNCH = 3
.label SFX_SEWER = 4
.label SFX_SMASH = 5
.label SFX_SQUASH = 6

sfx_bonus:
.import binary "../sfx/bonus.snd"


sfx_crash:
.import binary "../sfx/crash.snd"


sfx_enter:
.import binary "../sfx/enter.snd"


sfx_munch:
.import binary "../sfx/munch.snd"


sfx_sewer:
.import binary "../sfx/sewer.snd"


sfx_smash:
.import binary "../sfx/smash.snd"

sfx_squash:
.import binary "../sfx/squash.snd"


.const wavetable_list = List().add(sfx_bonus,sfx_crash,sfx_enter,sfx_munch,sfx_sewer,sfx_smash,sfx_squash)
wavetable:
.lohifill wavetable_list.size(), wavetable_list.get(i)
