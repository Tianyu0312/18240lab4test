          ; add32.asm
          ; {R0, R1} = {R0, R1} + {R6, R7}

          .ORG $100
start     LDA R0, first      ; most significant value
          LDA R1, second
          LDA R6, third      ; momst significant value
          LDA R7, fourth
          ADD R0, R6         ; add the most significant words
          ADD R1, R7
          BRC addcarry
          BRA done
addcarry  INCR R0
done      STOP

          .ORG $2000
first     .DW  $1987
second    .DW  $CAFE
third     .DW  $DEAD
fourth    .DW  $BEEF
