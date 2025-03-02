module cross_buffer (
  input  logic clk40MHz,
  input  logic rst,
  input  logic clk100MHz,
  input  logic [11:0] xpos_in,
  input  logic [11:0] ypos_in,
  output logic [11:0] xpos_out,
  output logic [11:0] ypos_out
);

logic [11:0] xpos_mid, ypos_mid;
logic        sync_req_100, sync_req_40, sync_ack_40;


always_ff @(posedge clk100MHz or posedge rst) begin
  if (rst)
    sync_req_100 <= 1'b0;
  else
    sync_req_100 <= ~sync_req_100;
end

always_ff @(posedge clk40MHz or posedge rst) begin
  if (rst) begin
    sync_req_40 <= 1'b0;
    sync_ack_40 <= 1'b0;
  end
  else begin
    sync_req_40 <= sync_req_100;  
    sync_ack_40 <= sync_req_40;  
  end
end

always_ff @(posedge clk40MHz or posedge rst) begin
  if (rst) begin
    xpos_out <= 12'd0;
    ypos_out <= 12'd0;
  end
  else if (sync_req_40 ^ sync_ack_40) begin
    xpos_out <= xpos_in;
    ypos_out <= ypos_in;
  end
end

endmodule
