# jtdsp16

Verilog core compatible with ATT WE DSP16, famous for being the heart of CAPCOM Q-Sound games

# Macros

Macro              | Effect
-------------------|---------------
SIMULATION         | Avoids some initial X's in sims
JTDSP16_FWLOAD     | Firmware load from files (see below)
JTDSP16_DEBUG      | Output ports with internal signals are available at the top level

# Supported Instructions

All the instructions needed by QSound firmware are supported.

The instructions not used by QSound are listed below.

  T    |   Operation      | Remarks
-------|------------------|------------
00101  | Z:aT     F1      | Unsupported
01101  | Z:R              | Unsupported
10010  | ifc CON  F2      | Unsupported
10101  | Z:y      F1      | Used by firmware but only the *rNzp case
11101  | Z:y x=X  F1      | Unsupported
110101 | icall            | Unsupported

Long immediate loads in the cache are not tested in the random tests, but they are supported.

# ROM load during simulation

ROM can be loaded using the ports for that purpose or if the **JTDSP16_FWLOAD** macro is declared, the ROM will be loaded from two hexadecimal files.

File             | Contents
-----------------|---------------------
dsp16fw_msb.hex  | MSB part of the ROM
dsp16fw_lsb.hex  | LSB part of the ROM

The files must be in the simulation directory.

# Instruction Details

Nemonic            |  T    | Cacheable   | Cycles
-------------------|-------|-------------|---------
goto JA            | 0/1   | No          |  2
R=M (short)        | 2/3   | Yes         |  1
F1 Y = a1[l]       | 4     | Yes         |  2
F1 Z:aT[l]         | 5     | Yes         |  2
F1 Y               | 6     | Yes         |  1
F1 aT[l]=Y         | 7     | Yes         |  1
at=R               | 8     | Yes         |  2
R=aS               | 9/11  | Yes         |  2
R=N (long)         | 10    | Yes         |  2
Y=R                | 12    | Yes         |  2
Z:R                | 13    | Yes         |  2
do/redo            | 14    | No          |  1
R=Y                | 15    | Yes         |  2
call JA            | 16/17 | No          |  2
ifc CON F2         | 18    | Yes         |  1
if  CON F2         | 19    | Yes         |  1
F1 Y=y[l]          | 20    | Yes         |  2
F1 Z:y[l]          | 21    | Yes         |  2
F1 x=Y             | 22    | Yes         |  1
F1 y[l]=Y          | 23    | Yes         |  1
goto B             | 24    | No          |  2
F1 y=a0 x=*pt++[i] | 25    | Yes         |  2 / 1 in cache
if CON goto        | 26    | No          |  1+2
F1 y=a1 x=*pt++[i] | 27    | Yes         |  2 / 1 in cache
F1 Y = a0[l]       | 28    | Yes         |  2
F1 Z:y  x=*pt++[i] | 29    | Yes         |  2
Reserved           | 30    |             |
F1 y=Y  x=*pt++[i] | 31    | Yes         |  2 / 1 in cache
