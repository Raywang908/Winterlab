module uart_receiver (
  input wire uart_rx,             // UART 資料輸入
  input wire baud_rate_signal,    // Baud rate 驅動訊號
  input wire rst_n,               // 復位訊號（低有效）
  output reg [8:1] data,          // 接收的 8 位資料
  output reg valid_data           // 資料是否有效的標誌
);

  reg state;
  localparam IDLE = 1'b0;
  localparam RECEIVE = 1'b1;

  reg [3:0] bit_counter;          // 位元計數器 (8 bits)

  always @(posedge baud_rate_signal or negedge rst_n) begin
    if (!rst_n) begin
      // 復位時初始化所有狀態與訊號
      state <= IDLE;
      data <= 8'b00000000;
      valid_data <= 1'b0;
      bit_counter <= 8;
    end else begin
      // 更新狀態機的當前狀態
      case (state)
        IDLE: begin
          if (uart_rx == 1'b0) begin
            state <= RECEIVE;
            bit_counter <= 8;
          end else begin
            state <= IDLE;
          end
          valid_data <= 1'b0;       // 清除有效標誌
        end

        RECEIVE: begin
          if (bit_counter == 0) begin
            if (uart_rx == 1'b1) begin
              valid_data <= 1'b1;   // 資料有效
            end else begin
              valid_data <= 1'b0;   // 停止位錯誤
            end
            state <= IDLE;     // 回到空閒狀態
            bit_counter <= 8;
          end else begin
            data[bit_counter] <= uart_rx;  // 接收資料位
            bit_counter <= bit_counter - 1;
          end
        end

        default: begin
          state <= IDLE;
        end
      endcase
    end
  end

endmodule
