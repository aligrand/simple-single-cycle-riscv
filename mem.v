module mem (
    input clk, write, read, 
    input [9:0] addr, 
    input [31:0] wrdata, 
    output [31:0] rddata
);
    reg [7:0] memory [1023:0];
    reg [31:0] out;

    assign rddata = out;

    always @(posedge clk) begin
        if (write == 1'b1 && read == 1'b0) begin
            memory[addr] = wrdata[7:0];
            memory[addr + 1] = wrdata[15:8];
            memory[addr + 2] = wrdata[23:16];
            memory[addr + 3] = wrdata[31:24];
        end 
    end

    always @(read, addr) begin
        if (read == 1'b1 && write == 1'b0) begin
            out[7:0] = memory[addr];
            out[15:8] = memory[addr + 1];
            out[23:16] = memory[addr + 2];
            out[31:24] = memory[addr + 3];
        end
    end

    always @(read, write) begin
        if ((read == 1'b0 && write == 1'b0) || (read == 1'b1 && write == 1'b1)) begin
            out = 32'd0;
        end
    end

endmodule
