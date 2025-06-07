//////////////////////////////////////////////////////////////////////////////
/*
 Module name:   bin2bcd
 Author:        Wojciech Miskowicz
 Description:   Binary to BCD encoder.
 */
//////////////////////////////////////////////////////////////////////////////

module bin2bcd(
  input wire [7:0] bin,
  output reg [7:0] bcd
);

reg [15:0] shift_reg;
integer i;

always_comb begin
  shift_reg = {8'b0, bin};
  
  for(i = 0; i < 8; i = i + 1) begin
    if(shift_reg[11:8] >= 5)
      shift_reg[11:8] = shift_reg[11:8] + 3;
    
    if(shift_reg[15:12] >= 5)
      shift_reg[15:12] = shift_reg[15:12] + 3;
    
    shift_reg = shift_reg << 1;
  end
  
  bcd = shift_reg[15:8];
end

endmodule
