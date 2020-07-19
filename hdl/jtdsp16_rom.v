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

// ROM. Not clocked

module jtdsp16_rom(
    input             clk,
    input      [15:0] addr,
    output     [15:0] dout,
    // External ROM
    input             ext_mode,
    input      [15:0] ext_data,
    output     [15:0] ext_addr,
    // ROM programming interface
    input      [11:0] prog_addr,
    input      [15:0] prog_data,
    input             prog_we
);

reg [15:0] rom[0:4095];
reg [15:0] rom_dout;

assign     ext_addr = addr;
assign     dout     = ext_mode ? ext_data : (addr[15:12]==4'd0? rom_dout : ext_data);

always @(posedge clk) begin
    if(prog_we) rom[ prog_addr ] <= prog_data;
    rom_dout <= rom[ addr[11:0] ];
end


endmodule