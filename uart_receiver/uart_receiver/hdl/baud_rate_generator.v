module baud_rate_generator (
  input wire clk,
  input wire rst_n,
  output reg baud_rate_signal
);

  parameter BAUD_RATE_NUMBER = 20;
  reg [13:0] counter;
  reg baud_rate_next; // 組合邏輯輸出暫存

  // 時序邏輯：只負責時鐘驅動的數值更新
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      counter <= BAUD_RATE_NUMBER - 1;
      baud_rate_signal <= 1'b0;
    end else begin
      counter <= (counter == 0) ? BAUD_RATE_NUMBER - 1 : counter - 1;
      baud_rate_signal <= baud_rate_next; // 從組合邏輯取得下一狀態
    end
  end

  // 組合邏輯：計算 baud_rate_signal 的下一狀態
  always @(*) begin
    if (counter == 1) begin
      baud_rate_next = 1'b0;
    end else if (counter == 0) begin
      baud_rate_next = 1'b1;
    end else begin
      baud_rate_next = 1'b0;
    end
  end

endmodule
