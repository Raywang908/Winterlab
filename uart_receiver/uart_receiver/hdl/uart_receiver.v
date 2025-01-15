module uart_receiver (
  input wire uart_rx,             // UART 資料輸入
  input wire baud_rate_signal,    // Baud rate 驅動訊號
  input wire rst_n,               // 復位訊號（低有效）
  output reg [8:1] data,          // 接收的 8 位資料
  output reg valid_data           // 資料是否有效的標誌
);

  reg state, next_state;          // 狀態與下一狀態
  localparam IDLE = 1'b0;
  localparam RECEIVE = 1'b1;

  reg [3:0] bit_counter, next_bit_counter; // 位元計數器和下一值
  reg [8:1] next_data;                     // 資料暫存
  reg next_valid_data;                     // 有效標誌暫存器

  // 狀態切換邏輯（時序邏輯）
  always @(posedge baud_rate_signal or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      data <= 8'b00000000;
      valid_data <= 1'b0;
      bit_counter <= 8;
    end else begin
      state <= next_state;
      data <= next_data;
      valid_data <= next_valid_data;
      bit_counter <= next_bit_counter;
    end
  end

  // 組合邏輯：計算下一狀態和輸出
  always @(*) begin
    // 預設值
    next_state = state;
    next_data = data;
    next_bit_counter = bit_counter;
    next_valid_data = 1'b0;  // 預設為無效

    case (state)
      IDLE: begin
        if (uart_rx == 1'b0) begin
          next_state = RECEIVE;
          next_bit_counter = 8;
        end
      end

      RECEIVE: begin
        if (bit_counter == 0) begin
          if (uart_rx == 1'b1) begin
            next_valid_data = 1'b1; // 資料有效
          end
          next_state = IDLE; // 回到空閒狀態
        end else begin
          next_data[bit_counter] = uart_rx; // 接收資料位
          next_bit_counter = bit_counter - 1;
        end
      end

      default: begin
        next_state = IDLE;
      end
    endcase
  end

endmodule
