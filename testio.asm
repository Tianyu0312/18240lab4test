        .ORG $0000
        LDI R0, $ABCD
        STA $2000, R0
        LDA R0, $2000
        STOP
        
