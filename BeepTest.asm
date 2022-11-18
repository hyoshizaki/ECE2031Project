; BeepTest.asm
; Sends the value from the switches to the
; tone generator peripheral once per second.

ORG 0
	IN Switches
	JPOS SomeNote
	JNEG SomeNote
	LOADI 0
	OUT Beep
	IN Beep
	ADDI 0
	OUT Hex0
	JUMP 0
SomeNote:
	IN Switches
	AND Bit0
	JZERO NotC2
	LOAD C2
	STORE Note
	JUMP FindOctave
NotC2:
	IN Switches
	AND Bit1
	JZERO NotD2
	LOAD D2
	STORE Note
	JUMP FindOctave
NotD2:
	IN Switches
	AND Bit2
	JZERO NotE2
	LOAD E2
	STORE Note
	JUMP FindOctave
NotE2:
	IN Switches
	AND Bit3
	JZERO NotF2
	LOAD F2
	STORE Note
	JUMP FindOctave
NotF2:
	IN Switches
	AND Bit4
	JZERO NotG2
	LOAD G2
	STORE Note
	JUMP FindOctave
NotG2:
	IN Switches
	AND Bit5
	JZERO NotA2
	LOAD A2
	STORE Note
	JUMP FindOctave
NotA2:
	IN Switches
	AND Bit6
	JZERO 0
	LOAD B2
	STORE Note
	JUMP FindOctave

FindOctave:
	IN Switches
	AND Mask012
	JZERO FirstOctave
	ADDI -1
	JZERO SecondOctave
	ADDI -1
	JZERO ThirdOctave
	ADDI -1
	JZERO FourthOctave
	ADDI -1
	JZERO FifthOctave
	ADDI -1
	JZERO SixthOctave
	ADDI -1
	JZERO SeventhOctave
	ADDI -1
	JZERO EigthOctave
	JUMP 0

FirstOctave:
	LOAD Note
	OUT Beep
	JUMP End
SecondOctave:
	LOAD Note
	SHIFT 1
	STORE Note
	OUT Beep
	JUMP End
ThirdOctave:
	LOAD Note
	SHIFT 2
	STORE Note
	OUT Beep
	JUMP End
FourthOctave:
	LOAD Note
	SHIFT 3
	STORE Note
	OUT Beep
	JUMP End
FifthOctave:
	LOAD Note
	SHIFT 4
	STORE Note
	OUT Beep
	JUMP End
SixthOctave:
	LOAD Note
	SHIFT 5
	STORE Note
	OUT Beep
	JUMP End
SeventhOctave:
	LOAD Note
	SHIFT 6
	STORE Note
	OUT Beep
	JUMP End
EigthOctave:
	LOAD Note
	SHIFT 7
	STORE Note
	OUT Beep

	JUMP End
End:
	IN Beep	
	SUB Note
	OUT Hex0 ;REMOVED RN FOR DEBUGGING
	JUMP 0
	


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
Beep:      EQU &H40

C2:  	   DW 65
D2:        DW 73
E2:  	   DW 82
F2:        DW 87
G2:   	   DW 98
A2:   	   DW 110
B2:   	   DW 123

Note:	   DW 0

Bit0:      DW &B0000001000
Bit1:      DW &B0000010000
Bit2:      DW &B0000100000
Bit3:      DW &B0001000000
Bit4:      DW &B0010000000
Bit5:      DW &B0100000000
Bit6:      DW &B1000000000
Mask012:   DW &B111