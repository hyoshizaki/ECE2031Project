; BeepTest.asm
; Sends the value from the switches to the
; tone generator peripheral once per second.

ORG 0

; Get the switch values
	IN Switches
	JPOS SomeNote
	
	LOADI 0
	STORE Temp
	OUT Beep
	CALL Delay
	JUMP End

SomeNote:
	IN Switches
	AND Bit0
	JZERO NotC4
	LOAD C4
	STORE Temp
	OUT Beep
	CALL Delay
	JUMP End
NotC4:
	IN Switches
	AND Bit1
	JZERO NotD4
	LOAD D4
	STORE Temp
	OUT Beep
	CALL Delay
	JUMP End
NotD4:
	IN Switches
	AND Bit2
	JZERO NotE4
	LOAD E4
	STORE Temp
	OUT Beep
	CALL Delay
	JUMP End
NotE4:
	IN Switches
	AND Bit3
	JZERO NotF4
	LOAD F4
	STORE Temp
	OUT Beep
	CALL Delay
	JUMP End
NotF4:
	IN Switches
	AND Bit4
	JZERO NotG4
	LOAD G4
	STORE Temp
	OUT Beep
	CALL Delay
	JUMP End
NotG4:
	IN Switches
	AND Bit5
	JZERO NotA4
	LOAD A4
	STORE Temp
	OUT Beep
	CALL Delay
	JUMP End
NotA4:
	IN Switches
	AND Bit6
	JZERO 0
	LOAD B4
	STORE Temp
	OUT Beep
	CALL Delay
	JUMP End

End:
	IN Beep
	STORE Note
	LOAD Temp
	SUB Note
	OUT Hex0
	Jump 0


	
	

	
; Subroutine to delay for 0.2 seconds.
Delay:
	OUT    Timer
WaitingLoop:
	IN     Timer
	ADDI   -2
	JNEG   WaitingLoop
	RETURN

; IO address constants
Switches:  EQU 000
LEDs:      EQU 001
Timer:     EQU 002
Hex0:      EQU 004
Hex1:      EQU 005
Temp:	   EQU 006
Beep:      EQU &H40
Note:      EQU 007


C4:		   DW 65
D4: 	   DW 73
E4:		   DW 82
F4:  	   DW 87
G4:		   DW 98
A4:		   DW 110
B4:		   DW 123


Bit0:      DW &B0000000001
Bit1:      DW &B0000000010
Bit2:      DW &B0000000100
Bit3:      DW &B0000001000
Bit4:      DW &B0000010000
Bit5:      DW &B0000100000
Bit6:      DW &B0001000000
AbsoluteValue:	DW &B0111111111