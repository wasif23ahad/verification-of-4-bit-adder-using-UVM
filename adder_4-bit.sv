// 4-bit Adder Design
// This module implements a simple 4-bit adder with carry input and output

module adder_4bit (
    input  logic [3:0] a,      // First 4-bit operand
    input  logic [3:0] b,      // Second 4-bit operand
    input  logic       cin,    // Carry input
    output logic [3:0] sum,    // 4-bit sum output
    output logic       cout    // Carry output
);

    logic [4:0] result;
    
    // Perform addition
    assign result = a + b + cin;
    
    // Split result into sum and carry out
    assign sum  = result[3:0];
    assign cout = result[4];

endmodule
