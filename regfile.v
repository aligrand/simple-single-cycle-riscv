module regfile (
    input clk, write, 
    input [4:0] rdaddr1, rdaddr2, wraddr, 
    input [31:0] wrdata, 
    output [31:0] rddata1, rddata2
);
    reg [31:0] registerBank [31:0];

    integer index;
    initial begin
        for (index = 0; index < 32; index = index + 1) begin
            registerBank[index] = 32'd0; 
        end
    end

    always @ (posedge clk) begin
        if (write) begin
            registerBank[wraddr] <= wrdata;
        end
    end

    assign rddata1 = registerBank[rdaddr1];
    assign rddata2 = registerBank[rdaddr2];
endmodule
