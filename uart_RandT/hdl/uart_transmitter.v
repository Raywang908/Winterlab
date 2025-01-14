module uart_transmitter(
  input wire [7:0]data,
  input wire baud_rate_signal,
  input wire start,
  input wire rst_n,
  input wire clk,
  output reg uart_tx
);
  reg [10:1] packed_data;
  reg state;
  reg [3:0]bit_counter;
  localparam IDLE = 1'b0;
  localparam TRANSMIT = 1'b1;
  //localparam TRANSMIT_NUMBER = 10;
  localparam ZER0 = 0;
  localparam ONE = 1;
  localparam TEN = 10;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      uart_tx <= ZER0;
      state <= IDLE;
      bit_counter <= TEN;
    end else begin
      packed_data <= {1'b0, data, 1'b1};
      case (state) 
        IDLE: begin
          if (start == ONE) begin
            state <= TRANSMIT;
            uart_tx <= ONE;
            bit_counter <= TEN;
          end else begin
            state <= IDLE;
            uart_tx <= ONE;
            bit_counter <= TEN;
          end
        end
        TRANSMIT: begin
          if (baud_rate_signal == ONE) begin
            if (bit_counter == ZER0) begin
              state <= IDLE;
              uart_tx <= ONE;
              bit_counter <= TEN;
            end else begin
              state <= TRANSMIT;
              uart_tx <= packed_data[bit_counter];
              bit_counter <= bit_counter - 1;
            end
          end else begin
            /*
            if (bit_counter == ZER0) begin
              uart_tx <= ONE;
            end else begin
              uart_tx <= packed_data[bit_counter - 1];
            end
            */
            state <= TRANSMIT;
          end
        end
        default: state <= IDLE;
      endcase
    end 
  end
endmodule
