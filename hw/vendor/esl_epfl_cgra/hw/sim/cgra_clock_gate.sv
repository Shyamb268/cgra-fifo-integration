module cgra_clock_gate (
  input  wire clk_i,
  input  wire en_i,
  output wire clk_o
);

  reg clk_en;

  always @(clk_i or en_i) begin
    if (!clk_i)
      clk_en <= en_i;
  end

  assign clk_o = clk_i & clk_en;

endmodule 