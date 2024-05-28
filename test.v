module test;
	reg clk = 0, rst = 0;
	integer i;

	sc cpu(clk, rst);

	always #(50) clk = ~clk;

	initial $readmemh("program.hex", cpu.im.memory);

	initial begin
		clk = 1;
		
		for (i = 0; i < 32; i = i + 1) begin
			cpu.rf.registerBank[i] = 32'b0;
		end
	end
endmodule