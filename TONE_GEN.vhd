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

LIBRARY ALTERA_MF;
USE ALTERA_MF.ALTERA_MF_COMPONENTS.ALL;


ENTITY TONE_GEN IS 
	PORT
	(
		CMD        : IN  STD_LOGIC_VECTOR(15 DOWNTO 0); --IO data
		CS         : IN  STD_LOGIC;
		SAMPLE_CLK : IN  STD_LOGIC;
		RESETN     : IN  STD_LOGIC;
		L_DATA     : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		R_DATA     : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
	);
END TONE_GEN;

ARCHITECTURE gen OF TONE_GEN IS 

	SIGNAL phase_register : STD_LOGIC_VECTOR(12 DOWNTO 0); --changed, but may not compile
	SIGNAL tuning_word    : STD_LOGIC_VECTOR(6 DOWNTO 0); --changed to make it 7-bit tuning word
	SIGNAL sounddata      : STD_LOGIC_VECTOR(7 DOWNTO 0);
	
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
		address_a => phase_register(12 downto 5),
		q_a => sounddata -- output is amplitude
	);
	
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
	
	-- process to perform DDS
	PROCESS(RESETN, SAMPLE_CLK) BEGIN
		IF RESETN = '0' THEN
			phase_register <= "0000000000000";
		ELSIF RISING_EDGE(SAMPLE_CLK) THEN
			IF tuning_word = "0000000" THEN  -- if command is 0, return to 0 output.
				phase_register <= "0000000000000";
			ELSE
				-- Increment the phase register by the tuning word. 
				--**CHANGE HERE
				CASE tuning_word is
					WHEN "0000001" =>
						phase_register <= phase_register + "0000000010010";
					WHEN "0000010" =>
						phase_register <= phase_register + "0000000010011";
					WHEN "0000011" =>
						phase_register <= phase_register + "0000000010100";
					WHEN "0000100" =>
						phase_register <= phase_register + "0000000010101";
					WHEN "0000101" =>
						phase_register <= phase_register + "0000000010110";
					WHEN "0000110" =>
						phase_register <= phase_register + "0000000011000";
					WHEN "0000111" =>
						phase_register <= phase_register + "0000000011001";--25
					WHEN "0001000" =>
						phase_register <= phase_register + "0000000011011";
					WHEN "0001001" =>
						phase_register <= phase_register + "0000000011100";--28
					WHEN "0001010" =>
						phase_register <= phase_register + "0000000011110";--30
					WHEN "0001011" =>
						phase_register <= phase_register + "0000000100000"; --32
					WHEN "0001100" =>
						phase_register <= phase_register + "0000000100001";
					WHEN "0001101" =>
						phase_register <= phase_register + "0000000100011";--35
					WHEN "0001110" =>
						phase_register <= phase_register + "0000000100110";
					WHEN "0001111" =>
						phase_register <= phase_register + "0000000101000";
					WHEN "0010000" =>
						phase_register <= phase_register + "0000000101010";
					WHEN "0010001" =>
						phase_register <= phase_register + "0000000101101";
					WHEN "0010010" =>
						phase_register <= phase_register + "0000000101111";
					WHEN "0010011" =>
						phase_register <= phase_register + "0000000110010";--22
					WHEN "0010100" =>
						phase_register <= phase_register + "0000000110101";--53
					WHEN "0010101" =>
						phase_register <= phase_register + "0000000111000";--56
					WHEN "0010110" =>
						phase_register <= phase_register + "0000000111100";--60
					WHEN "0010111" =>
						phase_register <= phase_register + "0000000111111";--63
					WHEN "0011000" =>
						phase_register <= phase_register + "0000001000011";
					WHEN "0011001" =>
						phase_register <= phase_register + "0000001000111";--32
					WHEN "0011010" =>
						phase_register <= phase_register + "0000001001011";
					WHEN "0011011" =>
						phase_register <= phase_register + "0000001010000";--35
					WHEN "0011100" =>
						phase_register <= phase_register + "0000001010100";
					WHEN "0011101" =>
						phase_register <= phase_register + "0000001011001";--40
					WHEN "0011110" =>
						phase_register <= phase_register + "0000001011111";
					WHEN "0011111" =>
						phase_register <= phase_register + "0000001100100";--45
					WHEN "0100000" =>
						phase_register <= phase_register + "0000001101010";
					WHEN "0100001" =>
						phase_register <= phase_register + "0000001110001";--50
					WHEN "0100010" =>
						phase_register <= phase_register + "0000001110111";
					WHEN "0100011" =>
						phase_register <= phase_register + "0000001111110";--56
					WHEN "0100100" =>
						phase_register <= phase_register + "0000010000110";--60
					WHEN "0100101" =>
						phase_register <= phase_register + "0000010001110";
					WHEN "0100110" =>
						phase_register <= phase_register + "0000010010110"; --67
					WHEN "0100111" =>
						phase_register <= phase_register + "0000010011111";
					WHEN "0101000" =>
						phase_register <= phase_register + "0000010101001";--75
					WHEN "0101001" =>
						phase_register <= phase_register + "0000010110011";--80
					WHEN "0101010" =>
						phase_register <= phase_register + "0000010111101";
					WHEN "0101011" =>
						phase_register <= phase_register + "0000011001000";
					WHEN "0101100" =>
						phase_register <= phase_register + "0000011010100";
					WHEN "0101101" =>
						phase_register <= phase_register + "0000011100001";--100
					WHEN "0101110" =>
						phase_register <= phase_register + "0000011101110";
					WHEN "0101111" =>
						phase_register <= phase_register + "0000011111101";--113
					WHEN "0110000" =>
						phase_register <= phase_register + "0000100001100";--119
					WHEN "0110001" =>
						phase_register <= phase_register + "0000100011100";--126
					WHEN "0110010" =>
						phase_register <= phase_register + "0000100101100";--134
					WHEN "0110011" =>
						phase_register <= phase_register + "0000100111110";--142
					WHEN "0110100" =>
						phase_register <= phase_register + "0000101010001";--150
					WHEN "0110101" =>
						phase_register <= phase_register + "0000101100101";--159
					WHEN "0110110" =>
						phase_register <= phase_register + "0000101111010";
					WHEN "0110111" =>
						phase_register <= phase_register + "0000110010001";
					WHEN "0111000" =>
						phase_register <= phase_register + "0000110101001";--189
					WHEN "0111001" =>
						phase_register <= phase_register + "0000111000010";
					WHEN "0111010" =>
						phase_register <= phase_register + "0000111011101";--477
					WHEN "0111011" =>
						phase_register <= phase_register + "0000111111001";
					WHEN "0111100" =>
						phase_register <= phase_register + "0001000010111";
					WHEN "0111101" =>
						phase_register <= phase_register + "0001000110111";
					WHEN "0111110" =>
						phase_register <= phase_register + "0001001011001";
					WHEN "0111111" =>
						phase_register <= phase_register + "0001001111100";
					WHEN "1000000" =>
						phase_register <= phase_register + "0001010100010";
					WHEN "1000001" =>
						phase_register <= phase_register + "0001011001010";
					WHEN "1000010" =>
						phase_register <= phase_register + "0001011110101";
					WHEN "1000011" =>
						phase_register <= phase_register + "0001100100010";
					WHEN "1000100" =>
						phase_register <= phase_register + "0001101010010";
					WHEN OTHERS =>
						phase_register <= "0000000000000";
				END CASE;
			END IF;
		END IF;
	END PROCESS;

	-- process to latch command data from SCOMP
	PROCESS(RESETN, CS) BEGIN
		IF RESETN = '0' THEN
			tuning_word <= "0000000";
		ELSIF RISING_EDGE(CS) THEN
			tuning_word <= CMD(6 DOWNTO 0);
		END IF;
	END PROCESS;
END gen;