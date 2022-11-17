ORG 0
      IN Switches
      JZERO 0

SomeNote:
      IN Switches
      AND Bit0
      JZERO NotC4
      LOAD C4
      STORE Temp
      JUMP FindOctave
NotC4:
      IN Switches
      AND Bit1
      JZERO NotD4
      LOAD D4
      STORE Temp
      JUMP FindOctave
NotD4:
      IN Switches
      AND Bit2
      JZERO NotE4
      LOAD E4
      STORE Temp
      JUMP FindOctave
NotE4:
      IN Switches
      AND Bit3
      JZERO NotF4
      LOAD F4
      STORE Temp
      JUMP FindOctave
NotF4:
      IN Switches
      AND Bit4
      JZERO NotG4
      LOAD G4
      STORE Temp
      JUMP FindOctave
NotG4:
      IN Switches
      AND Bit5
      JZERO NotA4
      LOAD A4
      STORE Temp
      JUMP FindOctave
NotA4:
      IN Switches
      AND Bit6
      JZERO 0
      LOAD B4
      STORE Temp
      JUMP FindOctave

FindOctave:
      IN Switches
      SHIFT -7
      AND Mask012
      JZERO FirstOctave
      SUB 1
      JZERO SecondOctave
      SUB 1
      JZERO ThirdOctave
      SUB 1
      JZERO FourthOctave
      SUB 1
      JZERO FifthOctave
      SUB 1
      JZERO SixthOctave
      SUB 1
      JZERO SeventhOctave
      SUB 1
      JZERO EigthOctave
      JUMP 0

FirstOctave:
      LOAD Temp
      Out Beep
      CALL Delay
      JUMP 0
SecondOctave:
      LOAD Temp
      SHIFT 1
      OUT Beep
      CALL Delay
      JUMP 0
ThirdOctave:
      LOAD Temp
      SHIFT 2
      OUT Beep
      CALL Delay
      JUMP 0
FourthOctave:
      LOAD Temp
      SHIFT 3
      OUT Beep
      CALL Delay
      JUMP 0
FifthOctave:
      LOAD Temp
      SHIFT 4
      OUT Beep
      CALL Delay
      JUMP 0      
SixthOctave:
      LOAD Temp
      SHIFT 5
      OUT Beep
      CALL Delay
      JUMP 0
SeventhOctave:
      LOAD Temp
      SHIFT 6
      OUT Beep
      CALL Delay
      JUMP 0
EigthOctave:
      LOAD Temp
      SHIFT 7
      OUT Beep
      CALL Delay
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
Temp:    EQU 006


Mask012:   DW &B0000000111


C4:            DW 65
D4:              DW 73
E4:            DW 82
F4:              DW 87
G4:            DW 98
A4:            DW 110
B4:            DW 123


Bit0:      DW &B0000000001
Bit1:      DW &B0000000010
Bit2:      DW &B0000000100
Bit3:      DW &B0000001000
Bit4:      DW &B0000010000
Bit5:      DW &B0000100000
Bit6:      DW &B0001000000
