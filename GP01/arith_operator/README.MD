## Arithmetic operator

### RTL Describes the following operations:
- o_dataC = i_dataA + i_dataB
- o_dataC = i_dataA − i_dataB
- o_dataC = i_dataA & i_dataB
- o_dataC = i_dataA | i_dataB
Where i_dataA, i_dataB and o_dataC are 16b signed. Also there is another input (i_sel) used to choose between the operations

### Testplan is as follow:
- TC001: Sum with random data inputs
- TC002: Substraction with random data inputs
- TC003: And with random data inputs
- TC004: Or with random data inputs
- TC005: Randomizing all inputs
