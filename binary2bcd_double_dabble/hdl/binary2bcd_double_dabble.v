module binary2bcd_double_dabble (
  input wire [7:0]binary_in,
  input clk,
  input rst_n,
  output reg [19:0]unpacked_bcd,
  output reg [11:0]packed_bcd
);

wire [3:0]zero_4 = 4'b0000;
reg [19:0] scratch_pad;
reg [19:0] scratch_pad_temp;
localparam FOUR = 4;
localparam THREE = 3;
integer i, j;


always @(negedge rst_n) begin
  scratch_pad = {zero_4, zero_4, zero_4, binary_in};
  scratch_pad_temp = scratch_pad;
  scratch_pad = scratch_pad_temp << 1;
  for (i = 0; i < 7; i = i + 1) begin
    for (j = 0; j < 3; j = j + 1) begin
      case (j) 
        2'b00: begin
          if (scratch_pad[19:16] > FOUR) begin
            scratch_pad_temp[19:16] = scratch_pad[19:16];
            scratch_pad[19:16] = scratch_pad_temp[19:16] + THREE;
          end else begin
            scratch_pad_temp = scratch_pad;
          end
        end
        2'b01: begin
          if (scratch_pad[15:12] > FOUR) begin
            scratch_pad_temp[15:12] = scratch_pad[15:12];
            scratch_pad[15:12] = scratch_pad_temp[15:12] + THREE;
          end else begin
            scratch_pad_temp = scratch_pad;
          end
        end
        2'b10: begin
          if (scratch_pad[11:8] > FOUR) begin
            scratch_pad_temp[11:8] = scratch_pad[11:8];
            scratch_pad[11:8] = scratch_pad_temp[11:8] + THREE;
          end else begin
            scratch_pad_temp = scratch_pad;
          end
        end
        default: scratch_pad_temp = scratch_pad;
      endcase
    end
    scratch_pad_temp = scratch_pad;
    scratch_pad = scratch_pad_temp << 1;
  end
  packed_bcd = scratch_pad[19:8];
  unpacked_bcd = {scratch_pad[19:16], zero_4, scratch_pad[15:12], zero_4, scratch_pad[11:8]};
end


endmodule