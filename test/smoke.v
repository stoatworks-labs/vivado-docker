// Trivial design to prove the toolchain can synthesize for a target part.
module smoke(input clk, rst, output reg [31:0] cnt);
  always @(posedge clk) if (rst) cnt <= 0; else cnt <= cnt + 1;
endmodule
