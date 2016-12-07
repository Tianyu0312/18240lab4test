        ; add32.asm
        ; {R0, R1} = {R0, R1} + {R6, R7}

        .ORG $0
        
        LDI R2, $0003   ;
start1  LDA R0, $2000   ;
        AND R2, R0      ;
        CMI R2, $0      ;
        BRZ start2      ;
        BRA start1      ;
        
start2  LDI R2, $0003   ;
        LDA R1, $2000   ;
        AND R2, R1      ;
        CMI R2, $1      ;
        BRZ start3      ;
        BRA start2      ;
        
start3  LDI R2, $0003   ;
        LDA R6, $2000   ;
        AND R2, R6      ;
        CMI R2, $2      ;
        BRZ start4      ;
        BRA start3      ;
        
start4  LDI R2, $0003   ;
        LDA R7, $2000   ;
        AND R2, R7      ;
        CMI R2, $3      ;
        BRZ done        ;
        BRA start4      ;
        
done    .DW $3106       ;  
        STA $2000, R0   ;
        MOV R4, R1      ;
        BRA start1      ;
