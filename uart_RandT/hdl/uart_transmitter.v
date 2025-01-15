module uart_transmitter (
  input wire [7:0] data,            // 輸入的 8-bit 資料
  input wire baud_rate_signal,      // 波特率訊號
  input wire start,                 // 傳輸開始訊號
  input wire rst_n,                 // 復位訊號（低有效）
  input wire clk,                   // 時鐘訊號
  output reg uart_tx                // UART 資料輸出
);

  reg [10:0] packed_data;           // 打包的 10-bit 資料（起始位、數據位、停止位）
  reg state, next_state;            // 狀態與下一狀態
  reg [3:0] bit_counter, next_bit_counter; // 位元計數器和下一值
  reg next_uart_tx;                 // 下一時鐘週期的輸出狀態
  localparam IDLE = 1'b0;
  localparam TRANSMIT = 1'b1;

  // 狀態切換與資料更新邏輯（時序邏輯）
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      bit_counter <= 4'd10;
      uart_tx <= 1'b1;              // 默認為高電平
      packed_data <= 11'b0;         // 默認為空
    end else begin
      state <= next_state;
      bit_counter <= next_bit_counter;
      uart_tx <= next_uart_tx;
      if (start && state == IDLE) begin
        packed_data <= {1'b0, data, 1'b1}; // 起始位（0）+ 資料 + 停止位（1）
      end
    end
  end

  // 組合邏輯：計算下一狀態與輸出
  always @(*) begin
    // 預設值
    next_state = state;
    next_bit_counter = bit_counter;
    next_uart_tx = uart_tx;

    case (state)
      IDLE: begin
        next_uart_tx = 1'b1;        // 默認為高電平
        if (start) begin
          next_state = TRANSMIT;
          next_bit_counter = 4'd10;
        end
      end

      TRANSMIT: begin
        if (baud_rate_signal) begin
          if (bit_counter == 0) begin
            next_state = IDLE;      // 傳輸完成，回到空閒狀態
            next_uart_tx = 1'b1;    // 停止位為高電平
          end else begin
            next_bit_counter = bit_counter - 1;
            next_uart_tx = packed_data[bit_counter - 1]; // 輸出當前位元
          end
        end
      end

      default: begin
        next_state = IDLE;
      end
    endcase
  end

endmodule
