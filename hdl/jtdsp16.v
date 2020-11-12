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

module jtdsp16(
    input             rst,
    input             clk,
    input             clk_en,

    output            cen_cko,      // clock output, interpret as clock enable signal
    output     [15:0] ab,           // address bus
    input      [15:0] rb_din,       // ROM data bus
    input             ext_mode,     // EXM pin, when high internal ROM is disabled
    // Parallel I/O
    input      [15:0] pbus_in,
    output     [15:0] pbus_out,
    output            pods_n,        // parallel output data strobe
    output            pids_n,        // parallel input  data strobe
    output            psel,          // peripheral select
                                     // Unused by QSound firmware:
    // Serial output
    output            sdo,           // serial data output
    output            ock,           // output clock
    input             doen,          // data output enable
    output            sadd,          // serial address
    output            ose,           // output shift register empty
    output            old,           // output load
    output            ibf,           // input buffer full
    input             di,            // serial data input
    input             ick,           // serial data input clock
    input             ild,           // serial data input load
    // interrupts
    input             irq,           // interrupt
    output            iack,          // interrupt acknowledgement
    // ROM programming interface
    input      [12:0] prog_addr,
    input      [ 7:0] prog_data,
    input             prog_we,
    // Debug
    output            fault
    `ifdef JTDSP16_DEBUG
    ,
    // ROM AAU
    output [15:0]     debug_pc,
    output [15:0]     debug_pr,
    output [15:0]     debug_pi,
    output [15:0]     debug_pt,
    output [11:0]     debug_i,
    // RAM AAU
    output [15:0]     debug_re,
    output [15:0]     debug_rb,
    output [15:0]     debug_j,
    output [15:0]     debug_k,
    output [15:0]     debug_r0,
    output [15:0]     debug_r1,
    output [15:0]     debug_r2,
    output [15:0]     debug_r3,
    // DAU
    output [15:0]     debug_x,
    output [15:0]     debug_y,
    output [15:0]     debug_yl,
    output [ 7:0]     debug_c0,
    output [ 7:0]     debug_c1,
    output [ 7:0]     debug_c2,
    output [35:0]     debug_a0,
    output [35:0]     debug_a1,
    output [15:0]     debug_psw,
    output [ 6:0]     debug_auc,
    output [31:0]     debug_p,
    // SIO
    output [ 7:0]     debug_srta,
    output [ 9:0]     debug_sioc,
    // RAM programming
    input  [10:0]     debug_ram_addr,
    input  [15:0]     debug_ram_din,
    input             debug_ram_we
    `endif
);

`ifndef JTDSP16_DEBUG
wire [15:0] debug_pc, debug_pr, debug_pi, debug_pt,
            debug_re, debug_rb, debug_j,  debug_k,  debug_r0, debug_r1, debug_r2, debug_r3;
wire [15:0] debug_x,  debug_y,  debug_yl, debug_psw;
wire [11:0] debug_i;
wire [ 7:0] debug_c0, debug_c1, debug_c2, debug_srta;
wire [ 6:0] debug_auc;
wire [ 9:0] debug_sioc;
wire [35:0] debug_a1, debug_a0;
wire [31:0] debug_p;
`endif

wire        cen;   // cen divided by 2

wire [15:0] pt_dout;
wire [15:0] rom_addr;

wire [ 2:0] r_field;
wire [ 1:0] inc_sel;
wire        acc_sel;

// X-AAU
wire        goto_ja;
wire        goto_b;
wire        call_ja;
wire        icall;
wire [11:0] i_field, pt_addr;
wire        con_result, con_check;
wire        irq_latch;
wire        xaau_ram_load, xaau_imm_load, xaau_acc_load;
wire        do_start, do_flush;
wire [10:0] do_data;
wire        pt_read, xaau_istep;

// Y-AAU
wire [ 8:0] short_imm;
wire [15:0] long_imm;
wire [15:0] acc_dout;
wire [ 2:0] reg_sel_field;
wire        imm_type; // 0 for short, 1 for long
wire        imm_en;
wire        acc_en;
wire        pc_halt;
wire        ksel, step_sel;
wire        short_load, long_load, acc_load, post_load, ram_load;

// DAU
wire [ 4:0] t_field, c_field;
wire [ 5:0] dau_op_fields;
wire [ 1:0] y_field, a_field;
wire        dau_acc_load, dau_imm_load, dau_ram_load, dau_pt_load,
            dau_fully_load, dau_acc_ram;
wire        st_a0h, st_a1h;
wire        dau_dec_en, dau_rmux_load, dau_special;

wire [15:0] cache_dout;
wire [15:0] dau_dout;

// X load control
wire        up_xram;
wire        up_xrom;
wire        up_xext;
wire        up_xcache;

// RAM
wire [10:0] ram_addr;
wire [15:0] ram_dout, rom_dout;
wire        ram_we;

// Register mux
wire [15:0] r_xaau, r_yaau, r_dau, rmux;
wire [ 2:0] rsel;

// Serial I/O
wire        sio_imm_load, sio_acc_load, sio_ram_load, obe;
wire [15:0] r_sio;

// Parallel interface
wire        pdx_read, pio_imm_load;
wire [15:0] r_pio;

// interrupts
wire        no_int;


jtdsp16_div u_div(
    .clk            ( clk           ),
    .cen            ( clk_en        ),
    .cendiv         ( cen           )
);
assign cen_cko = cen ;  // clock output, input clock divided by 2

jtdsp16_rsel u_rsel(
    .r_xaau  ( r_xaau    ),
    .r_yaau  ( r_yaau    ),
    .r_dau   ( r_dau     ),
    .r_pio   ( r_pio     ),
    .r_sio   ( r_sio     ),
    .r_if    ( 16'd0     ),
    .r_acc   ( acc_dout  ),
    .rsel    ( rsel      ),
    .acc_sel ( acc_sel   ),
    .rmux    ( rmux      )
);

jtdsp16_ctrl u_ctrl(
    .rst            ( rst           ),
    .clk            ( clk           ),
    .cen            ( cen           ),
    .t_field        (               ),
    // ROM AAU - XAAU
    .goto_ja        ( goto_ja       ),
    .goto_b         ( goto_b        ),
    .call_ja        ( call_ja       ),
    .icall          ( icall         ),
    .i_field        ( i_field       ),
    .pc_halt        ( pc_halt       ),
    .xaau_ram_load  ( xaau_ram_load ),
    .xaau_imm_load  ( xaau_imm_load ),
    .xaau_acc_load  ( xaau_acc_load ),
    .do_start       ( do_start      ),
    .do_data        ( do_data       ),
    .do_flush       ( do_flush      ),
    // *pt++[i] reads
    .pt_read        ( pt_read       ),
    .xaau_istep     ( xaau_istep    ),
    // DAU
    .dau_dec_en     ( dau_dec_en    ),
    .dau_op_fields  ( dau_op_fields ),
    .a_field        ( a_field       ),
    .c_field        ( c_field       ),
    .dau_rmux_load  ( dau_rmux_load ),
    .dau_imm_load   ( dau_imm_load  ),
    .dau_ram_load   ( dau_ram_load  ),
    .dau_acc_load   ( dau_acc_load  ),
    .dau_pt_load    ( dau_pt_load   ),
    .dau_fully_load ( dau_fully_load),
    .dau_acc_ram    ( dau_acc_ram   ),
    .dau_special    ( dau_special   ),
    .st_a0h         ( st_a0h        ),
    .st_a1h         ( st_a1h        ),
    .con_result     ( con_result    ),
    .con_check      ( con_check     ),
    .acc_sel        ( acc_sel       ),
    // X load control
    .up_xram        ( up_xram       ),
    .up_xrom        ( up_xrom       ),
    .up_xext        ( up_xext       ),
    .up_xcache      ( up_xcache     ),
    // Y load control
    .r_field        ( r_field       ),
    .rsel           ( rsel          ),
    .y_field        ( y_field       ),
    .ram_we         ( ram_we        ),
    // Increment selection
    .inc_sel        ( inc_sel       ),
    .ksel           ( ksel          ),
    .step_sel       ( step_sel      ),
    // Load control
    .short_load     ( short_load    ),
    .long_load      ( long_load     ),
    .acc_load       ( acc_load      ),
    .ram_load       ( ram_load      ),
    .post_load      ( post_load     ),
    // interrupts
    .no_int         ( no_int        ),
    // register load inputs
    .short_imm      ( short_imm     ),
    .long_imm       ( long_imm      ),
    // Parallel port
    .pio_imm_load   ( pio_imm_load  ),
    .pdx_read       ( pdx_read      ),
    // Serial port
    .sio_imm_load   ( sio_imm_load  ),
    .sio_acc_load   ( sio_acc_load  ),
    .sio_ram_load   ( sio_ram_load  ),
    // Data buses
    .rom_dout       ( rom_dout      ),
    .cache_dout     ( cache_dout    ),
    .ext_dout       ( rb_din        ),
    // Debug
    .fault          ( fault         )
);

jtdsp16_rom u_rom(
    .clk        ( clk             ),
    .cen        ( cen             ),
    .addr       ( rom_addr        ),
    .pt         ( pt_addr         ),

    .dout       ( rom_dout        ),
    .pt_dout    ( pt_dout         ),

    .ext_mode   ( ext_mode        ),
    .ext_data   ( rb_din          ),
    .ext_addr   ( ab              ),
    // ROM programming interface
    .prog_addr  ( prog_addr       ),
    .prog_data  ( prog_data       ),
    .prog_we    ( prog_we         )
);

// ROM address arithmetic unit - XAAU
jtdsp16_rom_aau u_rom_aau(
    .rst        ( rst           ),
    .clk        ( clk           ),
    .cen        ( cen           ),
    // instruction types
    .goto_ja    ( goto_ja       ),
    .goto_b     ( goto_b        ),
    .call_ja    ( call_ja       ),
    .icall      ( icall         ),
    .pc_halt    ( pc_halt       ),
    .ram_load   ( xaau_ram_load ),
    .imm_load   ( xaau_imm_load ),
    .acc_load   ( xaau_acc_load ),
    // *pt++[i] reads
    .pt_addr    ( pt_addr       ),
    .pt_read    ( pt_read       ),
    .istep      ( xaau_istep    ),
    .pt_load    ( dau_pt_load   ),  // same as DAU's
    // Do loop
    .do_start   ( do_start      ),
    .do_data    ( do_data       ),
    .do_flush   ( do_flush      ),
    // instruction fields
    .r_field    ( r_field       ),
    .i_field    ( i_field       ),
    // Interruption
    .ext_irq    ( irq_latch     ),
    .no_int     ( no_int        ),
    .iack       ( iack          ),
    // Data buses
    .rom_dout   ( rom_dout      ),
    .ram_dout   ( ram_dout      ),
    .acc_dout   ( acc_dout      ),
    // ROM request
    .rom_addr   ( rom_addr      ),
    .reg_dout   ( r_xaau        ),
    // Debugging
    .debug_pc   ( debug_pc      ),
    .debug_pr   ( debug_pr      ),
    .debug_pi   ( debug_pi      ),
    .debug_pt   ( debug_pt      ),
    .debug_i    ( debug_i       )
);

jtdsp16_ram u_ram(
    .clk        ( clk           ),
    .addr       ( ram_addr      ),
    .din        ( rmux          ),
    .dout       ( ram_dout      ),
    .we         ( ram_we        )
    `ifdef JTDSP16_DEBUG
    ,
    .debug_ram_addr ( debug_ram_addr ),
    .debug_ram_din  ( debug_ram_din  ),
    .debug_ram_we   ( debug_ram_we   )
    `endif
);

jtdsp16_ram_aau u_ram_aau(
    .rst        ( rst           ),
    .clk        ( clk           ),
    .cen        ( cen           ),
    .r_field    ( r_field       ),
    .y_field    ( y_field       ),
    .rmux       ( rmux          ),
    // Increment selecction
    .inc_sel    ( inc_sel       ),
    .ksel       ( ksel          ),
    .step_sel   ( step_sel      ),
    // Load control
    .short_load ( short_load    ),
    .long_load  ( long_load     ),
    .acc_load   ( acc_load      ),
    .ram_load   ( ram_load      ),
    .post_load  ( post_load     ),
    // register load inputs
    .short_imm  ( short_imm     ),
    .long_imm   ( long_imm      ),
    .acc        ( acc_dout      ),
    .ram_dout   ( ram_dout      ),
    // outputs
    .ram_addr   ( ram_addr      ),
    .reg_dout   ( r_yaau        ),
    // Debug
    .debug_re   ( debug_re      ),
    .debug_rb   ( debug_rb      ),
    .debug_j    ( debug_j       ),
    .debug_k    ( debug_k       ),
    .debug_r0   ( debug_r0      ),
    .debug_r1   ( debug_r1      ),
    .debug_r2   ( debug_r2      ),
    .debug_r3   ( debug_r3      )
);

jtdsp16_dau u_dau(
    .rst            ( rst           ),
    .clk            ( clk           ),
    .cen            ( cen           ),
    .pc_halt        ( pc_halt       ),
    .con_check      ( con_check     ),
    // Decoder
    .dec_en         ( dau_dec_en    ),
    .special        ( dau_special   ),
    .r_field        ( r_field       ),
    .t_field        ( t_field       ),
    .a_field        ( a_field       ),
    .c_field        ( c_field       ),
    .op_fields      ( dau_op_fields ),
    .rmux           ( rmux          ),
    .alu_sel        ( 1'b1          ), // to do
    // Acc control
    .rmux_load      ( dau_rmux_load ),
    .imm_load       ( dau_imm_load  ),
    .ram_load       ( dau_ram_load  ),
    .acc_load       ( dau_acc_load  ),
    .acc_ram        ( dau_acc_ram   ),
    .fully_load     ( dau_fully_load),
    .pt_load        ( dau_pt_load   ),
    .st_a0h         ( st_a0h        ),
    .st_a1h         ( st_a1h        ),
    // Data buses
    .ram_dout       ( ram_dout      ),
    .rom_dout       ( rom_dout      ),
    .long_imm       ( long_imm      ),
    .cache_dout     ( cache_dout    ),
    .acc_dout       ( acc_dout      ),
    .reg_dout       ( r_dau         ),
    .pt_dout        ( pt_dout       ),
    .con_result     ( con_result    ),
    // Debug
    .debug_x        ( debug_x       ),
    .debug_y        ( debug_y       ),
    .debug_yl       ( debug_yl      ),
    .debug_c0       ( debug_c0      ),
    .debug_c1       ( debug_c1      ),
    .debug_c2       ( debug_c2      ),
    .debug_a0       ( debug_a0      ),
    .debug_a1       ( debug_a1      ),
    .debug_psw      ( debug_psw     ),
    .debug_auc      ( debug_auc     ),
    .debug_p        ( debug_p       )
);

jtdsp16_pio u_pio(
    .rst            ( rst           ),
    .clk            ( clk           ),
    .cen            ( cen           ),
    // Parallel I/O
    .pbus_in        ( pbus_in       ),
    .pbus_out       ( pbus_out      ),
    .pods_n         ( pods_n        ),
    .pids_n         ( pids_n        ),
    .psel           ( psel          ),
    // external interrupt request
    .irq            ( irq           ),
    // interface with CPU
    .pdx_read       ( pdx_read      ),
    .long_imm       ( long_imm      ),
    .pio_imm_load   ( pio_imm_load  ),
    .r_field        ( r_field       ),
    .pio_dout       ( r_pio         ),
    // Interrupts
    .iack           ( iack          ),
    .siord_full     ( ibf           ),
    .siowr_empty    ( obe           ),
    .irq_latch      ( irq_latch     )
);

jtdsp16_sio u_sio(
    .rst            ( rst           ),
    .clk            ( clk           ),
    .cen            ( cen           ),
    // DSP16 pins
    .ock            ( ock           ),  // serial output clock
    .sio_do         ( sdo           ),   // serial data output
    .sadd           ( sadd          ),
    .old            ( old           ),  // output load
    .ose            ( ose           ),  // output shift register empty
    .doen           ( doen          ),
    // interface with CPU
    .sio_imm_load   ( sio_imm_load  ),
    .sio_acc_load   ( sio_acc_load  ),
    .sio_ram_load   ( sio_ram_load  ),
    .r_field        ( r_field       ),
    // data bus
    .long_imm       ( long_imm      ),
    .acc_dout       ( acc_dout      ),
    .ram_dout       ( ram_dout      ),
    // status
    .obe            ( obe           ),
    .ibf            ( ibf           ),
    .r_sio          ( r_sio         ),
    // debug
    .debug_srta     ( debug_srta    ),
    .debug_sioc     ( debug_sioc    )
);

endmodule