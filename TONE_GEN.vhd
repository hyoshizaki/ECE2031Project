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
		L_DATA     : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		R_DATA     : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		IO_WRITE	  : IN STD_LOGIC;
		KEY2		  : IN STD_LOGIC; --Volume Down
		KEY3		  : IN STD_LOGIC  --Volume Up
	);
END TONE_GEN;

ARCHITECTURE gen OF TONE_GEN IS 

	SIGNAL phase_register : STD_LOGIC_VECTOR(15 DOWNTO 0); --changed, but may not compile
	SIGNAL tuning_word    : STD_LOGIC_VECTOR(12 DOWNTO 0); --changed to make it 7-bit tuning word
	SIGNAL sounddata      : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL KEY_PRESSED    : STD_LOGIC;
	SIGNAL R_DATA_SHIFT   : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL L_DATA_SHIFT   : STD_LOGIC_VECTOR(15 DOWNTO 0);
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
	

			
			
--R_DATA <= R_DATA_SHIFT WHEN (NOT(R_DATA_SHIFT = "ZZZZZZZZZZZZZZZZ")) ELSE 
--			sounddata(7)&sounddata(7)&sounddata(7)&sounddata(7)&sounddata&"0000";
--L_DATA <= L_DATA_SHIFT WHEN NOT(L_DATA_SHIFT = "ZZZZZZZZZZZZZZZZ") ELSE 
--			sounddata(7)&sounddata(7)&sounddata(7)&sounddata(7)&sounddata&"0000";
			
	-- 8-bit sound data is used as bits 12-5 of the 16-bit output.
	-- This is to prevent the output from being too loud.
	-- for volume control, shift left/right?
	-- for splitting, make a internal signal
	L_DATA(15 DOWNTO 12) <= sounddata(7)&sounddata(7)&sounddata(7)&sounddata(7); -- sign extend
	L_DATA(11 DOWNTO 4) <= sounddata;
	L_DATA(3 DOWNTO 0) <= "0000"; -- pad right side with 0s
	
	-- Right channel is the same.
	R_DATA(15 DOWNTO 12) <= sounddata(7)&sounddata(7)&sounddata(7)&sounddata(7); -- sign extend
	R_DATA(11 DOWNTO 4) <= sounddata;
	R_DATA(3 DOWNTO 0) <= "0000"; -- pad right side with 0s
	

--	PROCESS(KEY2,KEY3, KEY_PRESSED) BEGIN
--		if (KEY3 = '1') AND (KEY2 = '0') AND NOT(R_DATA_SHIFT = (sounddata(7 downto 0) & "00000000")) THEN 
--			R_DATA_SHIFT <= R_data_SHIFT(14 downto 0) & '0';
--			L_DATA_SHIFT <= L_data_SHIFT(14 downto 0) & '0';
--		ELSIF (kEY2 = '1') AND (KEY3 = '0')  AND NOT(R_DATA_SHIFT = (sounddata(7)&sounddata(7)&sounddata(7)&sounddata(7)&sounddata(7)&sounddata(7)&sounddata(7)&sounddata(7) & sounddata)) THEN
--			R_DATA_SHIFT <= sounddata(7) & R_DATA_SHIFT(15 downto 1);
--			L_DATA_SHIFT <= sounddata(7) & L_DATA_SHIFT(15 downto 1);
--		ELSIF (((kEY2 = '0') and (KEY3='0') AND (KEY_PRESSED = '1'))  OR ((KEY2 = '1') AND (KEY3 = '1'))) THEN --none of the buttons have been pressed or both volume control pressed
--			R_DATA_SHIFT <= R_DATA_SHIFT;
--			L_DATA_SHIFT <= L_DATA_SHIFT;
--		ELSE 	--first booted up
--			R_DATA_SHIFT <= "ZZZZZZZZZZZZZZZZ";
--			L_DATA_SHIFT <= "ZZZZZZZZZZZZZZZZ";
--		END IF;
--	END PROCESS;
 	
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
		ELSIF RISING_EDGE(CS) THEN
			IF IO_WRITE = '1' THEN
				tuning_word <= CONV_STD_LOGIC_VECTOR(CONV_INTEGER(CONV_INTEGER(CMD)*65536/48000), 13);
			END IF;
		END IF;
	END PROCESS;
	

		
END gen;
