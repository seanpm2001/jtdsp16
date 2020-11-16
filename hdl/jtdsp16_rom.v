/*  This file is part of JTDSP16.
    JTDSP16 program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JTDSP16 program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JTDSP16.  If not, see <http://www.gnu.org/licenses/>.

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 15-7-2020 */

// ROM is used as dual port to allow for dual access in cache mode
// Original hardware must have used two different memories for this
// each one using only a single port
// Note that one port is used for programming too
// rst should be set high during programming
// during rst the ROM will continuously output the data for address 0

module jtdsp16_rom(
    input             clk,
    input             cen,
    input      [15:0] addr,
    input      [11:0] pt,
    output     [15:0] dout,     // first 4kB of memory comes from internal ROM
                                // the rest is read from the external memory
    output     [15:0] pt_dout,  // ROM reads by PT pointer
    // External ROM
    input             ext_mode,
    output            ext_rq,
    input      [15:0] ext_data,
    output     [15:0] ext_addr,
    // ROM programming interface
    input      [12:0] prog_addr,
    input      [ 7:0] prog_data,
    input             prog_we
);

wire [ 7:0] rom_msb, rom_lsb, pt_msb, pt_lsb;
wire [15:0] rom_dout;
wire [11:0] rom_addr;
wire        prog_msb, prog_lsb;

assign     rom_dout  = {rom_msb, rom_lsb};
assign     pt_dout   = {pt_msb, pt_lsb};

assign     ext_addr  = addr;
assign     ext_rq    = addr[15:12]!=4'd0 || ext_mode;
assign     dout      = ext_rq ? ext_data : rom_dout;
//assign     read_addr = cen ? pt[11:0] : addr[11:0];

assign     rom_addr  = prog_we ? prog_addr[12:1] : pt;
assign     prog_msb  = prog_we &  prog_addr[0];
assign     prog_lsb  = prog_we & ~prog_addr[0];
/*
always @(posedge clk) begin
    if(prog_we && !prog_addr[0]) rom_lsb[ prog_addr[12:1] ] <= prog_data;
    if(prog_we &&  prog_addr[0]) rom_msb[ prog_addr[12:1] ] <= prog_data;
    rom_dout <= { rom_msb[ read_addr ], rom_lsb[ read_addr ] };
end
*/

jtdsp16_dualport #(1) u_msb(
    .clk    ( clk       ),
    // PT and programming
    .addr_A ( rom_addr  ),
    .we_A   ( prog_msb  ),
    .din_A  ( prog_data ),
    .dout_A ( pt_msb    ),
    // PC
    .addr_B ( addr[11:0]),
    .dout_B ( rom_msb   )
);

jtdsp16_dualport #(0) u_lsb(
    .clk    ( clk       ),
    // PT and programming
    .addr_A ( rom_addr  ),
    .we_A   ( prog_lsb  ),
    .din_A  ( prog_data ),
    .dout_A ( pt_lsb    ),
    // PC
    .addr_B ( addr[11:0]),
    .dout_B ( rom_lsb   )
);

endmodule

module jtdsp16_dualport(
    input              clk,
    input       [11:0] addr_A,
    input       [11:0] addr_B,
    input              we_A,
    input       [ 7:0] din_A,
    output reg  [ 7:0] dout_A,
    output reg  [ 7:0] dout_B
);

parameter MSB=0;

reg  [ 7:0] mem[0:4095];

`ifdef JTDSP16_FWLOAD
initial begin
    if( MSB==0 )
        $readmemh( "dsp16fw_lsb.hex", mem );
    else
        $readmemh( "dsp16fw_msb.hex", mem );
end
`endif

// Port A
always @(posedge clk) begin
    if( we_A ) mem[addr_A] <= din_A;
    dout_A <= mem[addr_A];
end

// Port B
always @(posedge clk) begin
    dout_B <= mem[addr_B];
end

endmodule