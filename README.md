Test ROM to find initial parameters for Gameboy games (in particular for
Pokemon RNG manip searching). The ROM will output values that look like this:

```
1100 1500 0008 007C
Div: 2E
subDiv (/4): 1A
LY: 93
subLy (/4): 6C
Passed
```

All of these values should be for when the game gets control with `PC = 0100`.
The first line is the registers: `AF BC DE HL`.
After that are the values of the divider register and the number of
(machine) cycles toward the next divider increment. To convert to a clock cycle
number, multiply `Div` by 256 and `subDiv` by 4 before adding.
So in this case, `0x2E * 256 + 0x1A * 4`

Finally, there are the LY values, which work very similarly to the divider values,
except that LY is on a 456 clock cycle pattern. So you want to multiply LY by
456 instead of 256. In this case: `0x93 * 456 + 0x6C * 4`.

Note that the bootrom inspects the ROM header, so ensure that the header matches
the game that you want parameters for.

# Known Hardware Outputs

So far the RNG for 3DSVC and SGB has not been replicated with these parameters.

## Pokemon Red

### GBA

```
1100 1500 0008 007C
Div: 2E
subDiv (/4): 1A
LY: 93
subLY (/4): 6C
Passed
```

### GBC

```
1180 1400 0008 007C
Div: 2E
subDiv (/4): 19
LY: 93
subLy (/4): 6B
Passed
```

### DMG

```
0190 0013 00D8 014D
Div: AB
subDiv (/4): 33
LY: 99
subLy (/4): 64
Passed
```

### MGB

```
FF90 0013 00D8 014D
Div: AB
subDiv (/4): 33
LY: 99
subLy (/4): 64
Passed
```

### SGB

```
0100 0014 0000 C060
Div: D8
subDiv (/4): 13
LY: 99
subLY (/4): 25
Passed
```

### 3DS VC

```
01B0 0013 00D8 014D
Div: 26
subDiv (/4): 1C
LY: 93
subLY (/4): 70
Passed
```

## Pokemon Blue

### GBA

```
1100 6200 0008 007C
Div: 37
subDiv (/4): 1C
LY: 93
subLY (/4): 44
Passed
```

### GBC

```
1180 6100 0008 007C
Div: 37
subDiv (/4): 1B
LY: 93
subLY (/4): 43
Passed
```

### DMG

```
01B0 0013 00D8 014D
Div: AB
subDiv (/4): 33
LY: 99
subLY (/4): 64
Passed
```

### MGB

```
FFB0 0013 00D8 014D
Div: AB
subDiv (/4): 33
LY: 99
subLY (/4): 64
Passed
```

### SGB

```
0100 0014 0000 C060
Div: D8
subDiv (/4): 17
LY: 99
subLY (/4): 29
Passed
```

### 3DS VC

```
01B0 0013 00D8 014D
Div: 26
subDiv (/4): 1C
LY: 93
subLY (/4): 70
Passed
```
