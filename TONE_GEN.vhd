-- Simple DDS tone generator.
-- 5-bit tuning word
-- 9-bit phase register
-- 256 x 8-bit ROM.


-- want: 13-bit phase register
-- 7-bit tuning word
--probably need to expand the ROM

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE ieee.numeric_std.all;

LIBRARY ALTERA_MF;
USE ALTERA_MF.ALTERA_MF_COMPONENTS.ALL;


ENTITY TONE_GEN IS 
	PORT
	(
		CMD        : INOUT  STD_LOGIC_VECTOR(15 DOWNTO 0); --IO data
		CS         : IN  STD_LOGIC;
		SAMPLE_CLK : IN  STD_LOGIC;
		RESETN     : IN  STD_LOGIC;
		L_DATA     : INOUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		R_DATA     : INOUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		IO_WRITE	  : IN STD_LOGIC;
		KEY2		  : IN STD_LOGIC; --Volume Down
		KEY3		  : IN STD_LOGIC  --Volume Up
	);
END TONE_GEN;

ARCHITECTURE gen OF TONE_GEN IS 

	TYPE VOL_STATE_TYPE IS (WantNoUp, WantOneUp, WantTwoUp, WantThreeUp,
									WantFourUp, WantOneDown, WantTwoDown,
									WantThreeDown, WantFourDown, NoUp, OneUp,
									TwoUp, ThreeUp, FourUp, OneDown,
									TwoDown, ThreeDown, FourDown);
	SIGNAL vol_state : VOL_STATE_TYPE;
	
	TYPE INTERVAL_STATE_TYPE IS (NoSound, Playing, TimeUp);
	SIGNAL interval_state : INTERVAL_STATE_TYPE;
	SIGNAL previousTuningWord : STD_LOGIC_VECTOR(12 downto 0);

	SIGNAL phase_register : STD_LOGIC_VECTOR(15 DOWNTO 0); --changed, but may not compile
	SIGNAL tuning_word    : STD_LOGIC_VECTOR(12 DOWNTO 0); --changed to make it 7-bit tuning word
	SIGNAL sounddata      : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL KEY_PRESSED    : STD_LOGIC;
	SIGNAL prev_RL_DATA   : STD_LOGIC_VECTOR(15 downto 0);
	SIGNAL counter 		 : STD_LOGIC_VECTOR(31 DOWNTO 0);
	
BEGIN

	-- ROM to hold the waveform
	SOUND_LUT : altsyncram
	GENERIC MAP (
		lpm_type => "altsyncram",
		width_a => 8,
		widthad_a => 8,
		numwords_a => 256,
		init_file => "SOUND_SINE.mif",
		intended_device_family => "Cyclone II",
		lpm_hint => "ENABLE_RUNTIME_MOD=NO",
		operation_mode => "ROM",
		outdata_aclr_a => "NONE",
		outdata_reg_a => "UNREGISTERED",
		power_up_uninitialized => "FALSE"
	)
	PORT MAP (
		clock0 => NOT(SAMPLE_CLK),
		-- In this design, one bit of the phase register is a fractional bit
		-- will need to expand this part but will need to check how to...can i put in more bits into address_a?
		address_a => phase_register(15 downto 8),
		q_a => sounddata -- output is amplitude
	);
	
	CMD <=  CONV_STD_LOGIC_VECTOR(CONV_INTEGER(CONV_INTEGER("000" & tuning_word)*48000/65536),16) when
			((CS = '1') AND (IO_WRITE = '0'))
			ELSE "ZZZZZZZZZZZZZZZZ";
	
	KEY_PRESSED <= '1' WHEN (KEY2 = '1' OR KEY3 = '1') ELSE 
						'0';
	


	-- 8-bit sound data is used as bits 12-5 of the 16-bit output.
	-- This is to prevent the output from being too loud.
	-- for volume control, shift left/right?
	-- for splitting, make a internal signal
		-- process to perform DDS
	PROCESS(RESETN, SAMPLE_CLK) BEGIN
		IF RESETN = '0' THEN
			phase_register <= "0000000000000000";
			counter <= x"00000000";
		ELSIF RISING_EDGE(SAMPLE_CLK) THEN
			if (counter = x"0EE6B280") OR (tuning_word = "0000000000000") then  -- if command is 0, return to 0 output.
				phase_register <= "0000000000000000";
				counter <= x"00000000";
			ELSE
				-- Increment the phase register by the tuning word. 
				--**CHANGE HERE
				phase_register <= phase_register + tuning_word;
				counter <= counter + 1;
			END IF;
		END IF;
	END PROCESS;

	-- process to latch command data from SCOMP
	PROCESS(RESETN, CS) BEGIN
		IF RESETN = '0' THEN
			tuning_word <= "0000000000000";
			previousTuningWord <= tuning_word;
		ELSIF RISING_EDGE(CS) THEN
			IF IO_WRITE = '1' THEN
				tuning_word <= CONV_STD_LOGIC_VECTOR(CONV_INTEGER(CONV_INTEGER(CMD)*65536/48000), 13);
			END IF;
		END IF;
	END PROCESS;
	
	--PROCESS statement to control volume
	PROCESS(KEY2, KEY3, resetn, SAMPLE_CLK) BEGIN
		if(resetn = '0') then
			vol_state <= NoUp;
		elsif(RISING_EDGE(SAMPLE_CLK)) THEN
			IF ((KEY3 = '0') AND (KEY2 = '1')) THEN --KEY3 PRESSED and released so volume up
				CASE vol_state IS
					WHEN FourDown => vol_state <= WantThreeDown;
					WHEN ThreeDown => vol_state <= WantTwoDown;
					WHEN TwoDown => vol_state <= WantOneDown;
					WHEN OneDown => vol_state <= WantNoUp;
					WHEN NoUp => vol_state <= WantOneUp;
					WHEN OneUp => vol_state <= WantTwoUp;
					WHEN TwoUp => vol_state <= WantThreeUp;
					WHEN ThreeUp => vol_state <= WantFourUp;
					WHEN OTHERS => vol_state <= vol_state;
				END Case;
				prev_RL_DATA <= R_DATA;
			elsif ((KEY2 = '0') AND (KEY3 = '1')) THEN --KEY2 pressed and released so volume down
				CASE vol_state is
					WHEN FourUp => vol_state <= WantThreeUp;
					WHEN ThreeUp => vol_state <= WantTwoUp;
					WHEN TwoUp => vol_state <= WantOneUp;
					WHEN OneUp => vol_state <= WantNoUp;
					WHEN NoUp => vol_state <= WantOneDown;
					WHEN OneDown => vol_state <= WantTwoDown;
					WHEN TwoDown => vol_state <= WantThreeDown;
					WHEN ThreeDown => vol_state <= WantFourDown;
					WHEN OTHERS => vol_state <= vol_state;
				END CASE;
				prev_RL_DATA <= R_DATA;
			elsif ((KEY2 = '1') AND (KEY3 = '1')) THEN
				CASE vol_state is
					WHEN WantFourDown => vol_state <= FourDown;
					WHEN WantThreeDown => vol_state <= ThreeDown;
					WHEN WantTwoDown => vol_state <= TwoDown;
					WHEN WantOneDown => vol_state <= OneDown;
					WHEN WantNoUp => vol_state <= NoUp;
					WHEN WantOneUp => vol_state <= OneUp;
					WHEN WantTwoUp => vol_state <= TwoUp;
					WHEN WantThreeUp => vol_state <= ThreeUp;
					WHEN WantFourUp => vol_state <= FourUp;
					WHEN OTHERS => vol_state <= vol_state;
				END CASE;
			END IF;
		END IF;
	end process;
 	
	WITH vol_state SELECT R_DATA <=
		sounddata&"00000000" WHEN FourUp,
		sounddata(7)&sounddata&"0000000" WHEN ThreeUp,
		sounddata(7)&sounddata(7)&sounddata&"000000" WHEN TwoUp,
		sounddata(7)&sounddata(7)&sounddata(7)&sounddata&"00000" WHEN OneUp,
		sounddata(7)&sounddata(7)&sounddata(7)&sounddata(7)&sounddata&"0000" WHEN NoUp,
		sounddata(7)&sounddata(7)&sounddata(7)&sounddata(7)&sounddata(7)&sounddata&"000" WHEN OneDown,
		sounddata(7)&sounddata(7)&sounddata(7)&sounddata(7)&sounddata(7)&sounddata(7)&sounddata&"00" WHEN TwoDown,
		sounddata(7)&sounddata(7)&sounddata(7)&sounddata(7)&sounddata(7)&sounddata(7)&sounddata(7)&sounddata&"0" WHEN ThreeDown,
		sounddata(7)&sounddata(7)&sounddata(7)&sounddata(7)&sounddata(7)&sounddata(7)&sounddata(7)&sounddata(7)&sounddata WHEN FourDown,
		prev_RL_DATA WHEN OTHERS;
	WITH vol_state SELECT L_DATA <=
		sounddata&"00000000" WHEN FourUp,
		sounddata(7)&sounddata&"0000000" WHEN ThreeUp,
		sounddata(7)&sounddata(7)&sounddata&"000000" WHEN TwoUp,
		sounddata(7)&sounddata(7)&sounddata(7)&sounddata&"00000" WHEN OneUp,
		sounddata(7)&sounddata(7)&sounddata(7)&sounddata(7)&sounddata&"0000" WHEN NoUp,
		sounddata(7)&sounddata(7)&sounddata(7)&sounddata(7)&sounddata(7)&sounddata&"000" WHEN OneDown,
		sounddata(7)&sounddata(7)&sounddata(7)&sounddata(7)&sounddata(7)&sounddata(7)&sounddata&"00" WHEN TwoDown,
		sounddata(7)&sounddata(7)&sounddata(7)&sounddata(7)&sounddata(7)&sounddata(7)&sounddata(7)&sounddata&"0" WHEN ThreeDown,
		sounddata(7)&sounddata(7)&sounddata(7)&sounddata(7)&sounddata(7)&sounddata(7)&sounddata(7)&sounddata(7)&sounddata WHEN FourDown,
		prev_RL_DATA WHEN OTHERS;
	

		
END gen;