# JTDSP16

Verilog core compatible with ATT WE DSP16, famous for being the heart of CAPCOM Q-Sound games. Unless explicitely stated, the design follows the official documentation from ATT.

Designed by Jose Tejada (aka jotego).

You can show your appreciation through
* [Patreon](https://patreon.com/topapate), by supporting releases
* [Paypal](https://paypal.me/topapate), with a donation

You can contact the author via Twitter at @topapate.


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

Nemonic            |  T    | Cacheable   | Interruptable | Cycles
-------------------|-------|-------------|---------------|---------
goto JA            | 0/1   |      No     |         No    |   2
R=M (short)        | 2/3   | Yes         |   Yes         |   1
F1 Y = a1[l]       | 4     | Yes         |   Yes         |   2
F1 Z:aT[l]         | 5     | Yes         |   Yes         |   2
F1 Y               | 6     | Yes         |   Yes         |   1
F1 aT[l]=Y         | 7     | Yes         |   Yes         |   1
at=R               | 8     | Yes         |   Yes         |   2
R=aS               | 9/11  | Yes         |   Yes         |   2
R=N (long)         | 10    |       No    |   Yes         |   2
Y=R                | 12    | Yes         |   Yes         |   2
Z:R                | 13    | Yes         |   Yes         |   2
do/redo            | 14    |       No    |         No    |   1
R=Y                | 15    | Yes         |   Yes         |   2
call JA            | 16/17 |       No    |         No    |   2
ifc CON F2         | 18    | Yes         |   Yes         |   1
if  CON F2         | 19    | Yes         |   Yes         |   1
F1 Y=y[l]          | 20    | Yes         |   Yes         |   2
F1 Z:y[l]          | 21    | Yes         |   Yes         |   2
F1 x=Y             | 22    | Yes         |   Yes         |   1
F1 y[l]=Y          | 23    | Yes         |   Yes         |   1
goto B             | 24    |       No    |         No    |   2
F1 y=a0 x=*pt++[i] | 25    | Yes         |   Yes         |   2 / 1 in cache
if CON goto        | 26    |       No    |         No    |   1+2
icall              | 26*   |       No    |         No    |   3
F1 y=a1 x=*pt++[i] | 27    | Yes         |   Yes         |   2 / 1 in cache
F1 Y = a0[l]       | 28    | Yes         |   Yes         |   2
F1 Z:y  x=*pt++[i] | 29    | Yes         |   Yes         |   2
Reserved           | 30    |             |   Yes         |
F1 y=Y  x=*pt++[i] | 31    | Yes         |   Yes         |   2 / 1 in cache

# The External Memory

External memory cannot be used to execute a program. It can only be used to access data via the pt register.

# The Cache

The cache does not accept instructions that alter the program flow or that take two memory words (i.e. the long immediate instruction).

The cache cannot be used on external memory. This might be different on original hardware.

## Cache tests

Cache loop is tricky because of

* Double cycle instructions may affect the loop control
* Single instruction loops are an exception (NI=1)
* Output PC value may be altered when the instruction before the loop start takes two cycles

Item        | Values         | Meaning
------------|----------------|----------------------------------
NI          | 1,2 or 15      | number of instructions
K           | 2 or 127       | number of loops
Ticks       | odd or even    | count of clock cycles needed for instructions in the loop
Out Double  | yes or no      | first instruction out of the loop take two cycles
Redo        | yes or no      | the loop is executed as a do or as a redo

NI | K | Ticks | Out Double
---|---|-------|------------
1  | 1 |  Odd  | No
1  | 1 |  Odd  | No

# Resource Usage

This is a comparison done for MiST (Altera V).

Module  | Logic cells | Registers | M9K
--------|-------------|-----------|-------
JTDSP16 |   2471      |   612     | 12
Z80     |   2450      |   357     |  0
JT51    |   3572      |   1652    | 12


# Related Projects

Other sound chips from the same author

Chip                   | Repository
-----------------------|------------
YM2203, YM2612, YM2610 | [JT12](https://github.com/jotego/jt12)
YM2151                 | [JT51](https://github.com/jotego/jt51)
YM3526                 | [JTOPL](https://github.com/jotego/jtopl)
YM2149                 | [JT49](https://github.com/jotego/jt49)
sn76489an              | [JT89](https://github.com/jotego/jt89)
OKI 6295               | [JT6295](https://github.com/jotego/jt6295)
OKI MSM5205            | [JT5205](https://github.com/jotego/jt5205)