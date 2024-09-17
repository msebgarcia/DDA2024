## IIR Filter

### Equation:
$$y[n] = x[n] − x[n−1] + x[n−2] + x[n−3] + 0.5y[n−1] + 0.25y[n−2]$$

### Architecture:
![](./draw/draw.svg)

### Testcases:
- TC001: Constant input
- TC002: Change input every 5 clocks
- TC003: 50kHz sine wave 
- TC004: 1MHz sine wave
- TC005: 10MHz sine wave
- TC006: Reset and recovery with square wave
