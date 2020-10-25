module test;

reg         clk;
wire        rst, cen, iack;

wire [15:0] ext_addr;
reg  [15:0] ext_data;
reg  [12:0] prog_addr;
wire [15:0] prog_data16;
wire [ 7:0] prog_data;
reg         prog_we;
reg  [15:0] rom[0:8191];

assign      cen = 1;
assign      rst = prog_we;
assign      prog_data16 = rom[ prog_addr[12:1] ];
assign      prog_data   = prog_addr[0] ? prog_data16[15:8] : prog_data16[7:0];

integer f, fcnt;

initial begin
    f = $fopen("test.bin","rb");
    fcnt=$fread( rom, f);
    $fclose(f);
end

initial begin
    clk = 0;
    forever #15 clk=~clk;
end

initial begin
    prog_addr = 0;
    prog_we   = 1;
    #45_000;
    // YAAU
    $display("r0=0x%04X", UUT.u_ram_aau.r0);
    $display("r1=0x%04X", UUT.u_ram_aau.r1);
    $display("r2=0x%04X", UUT.u_ram_aau.r2);
    $display("r3=0x%04X", UUT.u_ram_aau.r3);
    $display("rb=0x%04X", UUT.u_ram_aau.rb);
    $display("re=0x%04X", UUT.u_ram_aau.re);
    $display("j =0x%04X", UUT.u_ram_aau.j);
    $display("k =0x%04X", UUT.u_ram_aau.k);
    // XAUU
    $display("pr=0x%04X", UUT.u_rom_aau.pr);
    $display("pt=0x%04X", UUT.u_rom_aau.pt);
    $display("i =0x%04X", UUT.u_rom_aau.i);
    $display("pi=0x%04X", UUT.u_rom_aau.pi);
    $display("pc=0x%04X", UUT.u_rom_aau.pc);
    // DAU
    $display("a0=0x%04X", UUT.u_dau.a0);
    $display("a1=0x%04X", UUT.u_dau.a1);
    $display("x=0x%04X", UUT.u_dau.x);
    $display("y=0x%04X", UUT.u_dau.y);
    $display("p=0x%08X", UUT.u_dau.p);
    $display("c0=0x%04X", UUT.u_dau.c0);
    $display("c1=0x%04X", UUT.u_dau.c1);
    $display("c2=0x%04X", UUT.u_dau.c2);
    $display("auc=0x%04X", UUT.u_dau.auc);
    $display("psw=0x%04X", UUT.u_dau.psw);
    $finish;
end

always @(posedge clk) begin
    if( prog_addr < 13'd512 ) begin
        prog_addr <= prog_addr + 1'd1;
    end else begin
        prog_we <= 0;
    end
end

jtdsp16 UUT(
    .rst        ( rst       ),
    .clk        ( clk       ),
    .cen        ( cen       ),
    .ext_mode   ( 1'b0      ),
    // interrupts
    .irq        ( 1'b0      ),
    .iack       ( iack      ),
    // ROM programming interface
    .prog_addr  ( prog_addr ),
    .prog_data  ( prog_data ),
    .prog_we    ( prog_we   )
);

`ifndef NODUMP
always @(negedge prog_we) begin
    $dumpfile("test.lxt");
    $dumpvars;
end
`endif

endmodule