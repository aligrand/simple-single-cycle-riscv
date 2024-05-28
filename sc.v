module signextend (in, out);
    parameter n = 31;
    input [n-1:0]in;
    output [31:0] out;
    assign out = {{32-n{in[n-1]}}, in};
endmodule

module alu (input [3:0] control, input [31:0] a, input [31:0] b, output reg [31:0] c, output zero);
    assign zero = (c == 32'd0 ? 1'b1 : 1'b0);
    
    always @(*)
        case (control)
            0: c = a & b;
            1: c = a | b;
            2: c = a + b;
            3: c = a ^ b;
            4: c = a << b;
            5: c = a >> b;
            6: c = a - b;
            7: c = $signed(a) >>> b;
        endcase
endmodule

module sc (
    input clk, rst
);
    // 10 bit is enogh but for avoid sign extending for pc and imm and immPlus, add 3bit to pc
    reg [12:0] pc = 13'b0;

    reg [6:0] opcode = 7'b0;
    reg [2:0] func3 = 7'b0;
    reg [4:0] rs1 = 5'b0, rs2 = 5'b0, rd = 5'b0;
    reg signed [11:0] imm = 12'b0;
    reg signed [12:0] immPlus = 13'b0;

    wire hole;

    reg write = 1'b0;
    reg [4:0] wraddr = 5'b0, rdaddr1 = 5'b1, rdaddr2 = 5'b10;
    reg [31:0] wrdata = 32'b0;
    wire [31:0] rddata1, rddata2;

    reg imWrite = 1'b0, imRead = 1'b0;
    reg [9:0] imAddress = 10'b0;
    reg [31:0] imWriteData = 32'b0;
    wire [31:0] imReadData;

    reg dmWrite = 1'b0, dmRead = 1'b0;
    reg [9:0] dmAddress = 10'b0;
    reg [31:0] dmWriteData = 32'b0;
    wire [31:0] dmReadData;

    reg [3:0] control = 4'b0;
    reg [31:0] a = 32'b0, b = 32'b0;
    wire [31:0] c;

    reg [11: 0] seIn = 12'b0;
    wire [31:0] seOut;

    regfile rf(clk, write, rdaddr1, rdaddr2, wraddr, wrdata, rddata1, rddata2);
    mem im(clk, imWrite, imRead, imAddress, imWriteData, imReadData);
    mem dm(clk, dmWrite, dmRead, dmAddress, dmWriteData, dmReadData);

    alu mALU(control, a, b, c, hole);

    signextend #(.n(12)) sExtend(seIn, seOut);

    always @(posedge rst) begin
        pc = 13'b0;
    end

    always @(posedge clk) begin
        if (!rst) begin
            write = 1'b0;
            imWrite = 1'b0;
            dmWrite = 1'b0;
            imRead = 1'b0;
            dmRead = 1'b0;

            imAddress = pc;
            imRead = 1'b1;

            #1

            opcode = imReadData[6:0];

            case (opcode)
                // and, or, xor, sll (R)
                7'b0110011: begin
                    func3 = imReadData[14:12];

                    case (func3)
                        // and
                        3'b111: control = 4'b0000;
                        // or
                        3'b110: control = 4'b0001;
                        // xor
                        3'b100: control = 4'b0011;
                        // sll
                        3'b001: control = 4'b0100;
                    endcase

                    rs1 = imReadData[19:15];
                    rs2 = imReadData[24:20];
                    rd = imReadData[11:7];

                    rdaddr1 = rs1;
                    rdaddr2 = rs2;
                    wraddr = rd;

                    #1;

                    a = rddata1;
                    b = rdaddr2;

                    #1;

                    wrdata = c;

                    #1;

                    write = 1'b1;

                    pc = pc + 4;
                end
                // srai, addi (I)
                7'b0010011: begin
                    func3 = imReadData[14:12];

                    case (func3)
                        // srai
                        3'b101: control = 4'b0111;
                        // addi
                        3'b000: control = 4'b0010;
                    endcase

                    rs1 = imReadData[19:15];
                    imm = imReadData[31:20];
                    rd = imReadData[11:7];

                    rdaddr1 = rs1;
                    wraddr = rd;

                    #1;

                    a = rddata1;

                    seIn = imm;

                    #1;

                    b = seOut;

                    #1;

                    wrdata = c;

                    #1;

                    write = 1'b1;

                    pc = pc + 4;
                end
                // lw (I)
                7'b0000011: begin
                    rs1 = imReadData[19:15];
                    imm = imReadData[31:20];
                    rd = imReadData[11:7];

                    rdaddr1 = rs1;

                    #1;

                    a = rddata1;
                    
                    seIn = imm;

                    #1;

                    b = seOut;

                    #1;

                    dmAddress = c - 32'd1024;
                    dmRead = 1'b1;

                    #1

                    wraddr = rd;
                    wrdata = dmReadData;

                    #1;

                    write = 1'b1;

                    pc = pc + 4;
                end
                // jalr (I)
                7'b1100111: begin
                    rs1 = imReadData[19:15];
                    imm = imReadData[31:20];
                    rd = imReadData[11:7];

                    wraddr = rd;
                    wrdata = pc + 4;

                    write = 1'b1;

                    rdaddr1 = rs1;

                    #1;

                    a = rddata1;
                    
                    seIn = imm;

                    #1;

                    b = seOut;

                    #1;

                    pc = c;
                end
                // sw (S)
                7'b0100011: begin
                    rs1 = imReadData[19:15];
                    imm = {imReadData[31:25], imReadData[11:7]};
                    rs2 = imReadData[24:20];

                    rdaddr1 = rs1;
                    rdaddr2 = rs2;

                    #1;

                    a = rddata1;
                    
                    seIn = imm;

                    #1;

                    b = seOut;

                    #1;

                    dmAddress = c - 32'd1024;
                    dmWriteData = rddata2;

                    #1;

                    dmWrite = 1'b1;

                    pc = pc + 4;
                end
                // bltu, beq (SB) 
                7'b1100011: begin
                    func3 = imReadData[14:12];

                    rs1 = imReadData[19:15];
                    immPlus = {imReadData[31], imReadData[7], imReadData[30:25], imReadData[11:8], 1'b0};
                    rs2 = imReadData[24:20];

                    rdaddr1 = rs1;
                    rdaddr2 = rs2;

                    #1;

                    case (func3)
                        // bltu
                        3'b110: begin
                            if ($signed(rddata1) < $signed(rddata2)) begin
                                pc = pc + immPlus;
                            end
                            else begin
                                pc = pc + 4;
                            end
                        end
                        // beq
                        3'b000: begin
                            if (rddata1 == rddata2) begin
                                pc = pc + immPlus;
                            end
                            else begin
                                pc = pc + 4;
                            end
                        end
                    endcase
                end
            endcase
        end
    end
endmodule