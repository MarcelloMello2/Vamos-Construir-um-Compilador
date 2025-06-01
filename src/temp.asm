include \masm32\include\masm32rt.inc
.686

.data
B1 DD 0
T DD -1
F DD 0


.code
START:
    MOV EAX, 11
    MOV B1, EAX
    MOV EAX, B1
    PUSH EAX
    MOV EAX, 13
    POP EDX
    CMP EDX, EAX
    CMOVE EAX, T
    CMOVNE EAX, F
    TEST EAX, -1
    JE @L0
    MOV EAX, B1
    print str$(EAX)
    print " ", 13, 10
    JMP @L1
    
@L0:
    MOV EAX, 2
    print str$(EAX)
    print " ", 13, 10
    
@L1:
    exit
END START
