module test;

reg         clk;
wire        rst, cen;

wire [15:0] ext_addr;
reg  [15:0] ext_data;
reg  [11:0] prog_addr;
wire [15:0] prog_data;
reg         prog_we;
reg  [15:0] rom[0:8191];

assign      cen = 1;
assign      rst = prog_we;
assign      prog_data = rom[ prog_addr ];

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
    #50_000 $finish;
end

always @(posedge clk) begin
    if( prog_addr < 12'd512 ) begin
        prog_addr <= prog_addr + 1'd1;
    end else begin
        prog_we <= 0;
    end
end

jtdsp16 UUT(
    .rst        ( rst       ),
    .clk        ( clk       ),
    .cen        ( cen       ),
    .ext_addr   ( ext_addr  ),
    .ext_data   ( ext_data  ),
    .prog_addr  ( prog_addr ),
    .prog_data  ( prog_data ),
    .prog_we    ( prog_we   )
);

initial begin
    $dumpfile("test.lxt");  
    $dumpvars;  
end

endmodule