module binary2bcd_double_dabble (
  input wire [7:0] binary_in,
  output reg [19:0] unpacked_bcd,
  output reg [11:0] packed_bcd
);

  // 定義常數
  localparam FOUR = 4;
  localparam THREE = 3;
  localparam ZERO = 4'b0000;

  // 暫存變數
  reg [19:0] scratch_pad;
  reg [19:0] scratch_pad_temp;
  integer i, j;

  // 組合邏輯
  always @(*) begin
    // 初始化暫存器
    scratch_pad = {12'b0, binary_in};
    scratch_pad_temp = 20'b0;

    // Double Dabble 演算法
    for (i = 0; i < 8; i = i + 1) begin
      // 每次迴圈，檢查每個 BCD 的 4-bit 區塊
      for (j = 0; j < 3; j = j + 1) begin
        case (j)
          2'b00: if (scratch_pad[19:16] > FOUR) scratch_pad[19:16] = scratch_pad[19:16] + THREE;
          2'b01: if (scratch_pad[15:12] > FOUR) scratch_pad[15:12] = scratch_pad[15:12] + THREE;
          2'b10: if (scratch_pad[11:8] > FOUR)  scratch_pad[11:8]  = scratch_pad[11:8]  + THREE;
        endcase
      end

      // 將數值左移一位
      scratch_pad = scratch_pad << 1;
    end

    // 生成輸出
    packed_bcd = scratch_pad[19:8];
    unpacked_bcd = {scratch_pad[19:16], ZERO, scratch_pad[15:12], ZERO, scratch_pad[11:8]};
  end

endmodule

