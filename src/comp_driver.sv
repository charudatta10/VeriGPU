`timescale 1ns/10ps

module comp_driver(
);
    reg rst;
    reg clk;

    wire [31:0] out;
    wire outen;
    wire outflen;

    wire [31:0] pc;
    wire [6:0] op;
    wire [4:0] rd;
    wire [6:0] imm1;
    wire [31:0] x1;
    wire [4:0] state;

    reg [31:0] oob_wr_addr;
    reg [31:0] oob_wr_data;
    reg oob_wen;

    reg [31:0] mem_load [256];

    reg [31:0] outmem [32];
    reg [32]outtype ;
    reg [4:0] outpos;
    reg halt;

    reg [63:0] double;

    comp comp1(
        .clk(clk), .rst(rst),
        .pc(pc), .op(op), .rd(rd),
        .x1(x1), .imm1(imm1), .state(state),
        .out(out), .outen(outen), .outflen(outflen),
        .oob_wr_addr(oob_wr_addr),
        .oob_wr_data(oob_wr_data),
        .oob_wen(oob_wen),
        .halt(halt)
    );

    initial begin
        clk = 1;
        forever #0.5 clk = ~clk;
    end
    always @(posedge clk) begin
        if (outen | outflen) begin
            outmem[outpos] <= out;
            outtype[outpos] <= outflen;
            outpos <= outpos + 1;
        end
    end

    function [63:0] bitstosingle(input [31:0] s);
        bitstosingle = { s[31], s[30], {3{~s[30]}}, s[29:23], s[22:0], {29{1'b0}} };
    endfunction

    initial begin
        $readmemh("build/{PROG}.hex", mem_load);
        for(int i = 0; i < 255; i++) begin
            #1
            oob_wen = 1;
            oob_wr_addr = i;
            oob_wr_data = mem_load[i];
        end
        #1
        oob_wen = 0;
        outpos = 0;
        #1

        $monitor(
            "t=%d rst=%b pc=%0h, out=%h op=%h imm1=%h %0d rd=%0d x1=%h state=%d",
            $time(), rst, pc, out,  op,   imm1, imm1,   rd, x1, state);
        rst = 1;
        #1 rst = 0;

        while(~halt && clk < 100) begin
            #1;
        end

        for(int i = 0; i < outpos; i++) begin
            if (outtype[i]) begin
                double = bitstosingle(outmem[i]);
                $display("out.s %0d %b %f", i, outmem[i], $bitstoreal(double));
            end else begin
                $display("out %0d %h %0d", i, outmem[i], outmem[i]);
            end
        end
        $finish();
    end
endmodule
