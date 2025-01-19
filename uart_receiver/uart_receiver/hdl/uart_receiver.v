module uart_receiver (
  input wire uart_rx,             // UART data input
  input wire baud_rate_signal,    // Baud rate clock signal
  input wire rst_n,               // Reset signal (active low)
  output reg [8:1] data,          // 8-bit received data output
  output reg valid_data           // Valid data flag
);

  reg state, next_state;          // Current and next state
  localparam IDLE = 1'b0;         // Idle state
  localparam RECEIVE = 1'b1;      // Receive state

  reg [3:0] bit_counter, next_bit_counter; // Bit counter and next value
  reg [8:1] next_data;                     // Data buffer for next state
  reg next_valid_data;                     // Valid data flag for next state

  // Sequential logic: State transition and register updates
  always @(posedge baud_rate_signal or negedge rst_n) begin
    if (!rst_n) begin
      // Reset all registers when reset signal is active (low)
      state <= IDLE;
      data <= 8'b00000000;
      valid_data <= 1'b0;
      bit_counter <= 8;
    end else begin
      // Update registers with next state values
      state <= next_state;
      data <= next_data;
      valid_data <= next_valid_data;
      bit_counter <= next_bit_counter;
    end
  end

  // Combinational logic: Compute next state and outputs
  always @(*) begin
    case (state)
      IDLE: begin
        // If start bit (uart_rx == 0) is detected, transition to RECEIVE state
        if (uart_rx == 1'b0) begin
          next_state = RECEIVE;
          next_bit_counter = 8;       // Initialize bit counter
          next_data = data;           // Keep current data
          next_valid_data = 1'b0;     // Data is not valid yet
        end else begin
          // Remain in IDLE state if no start bit is detected
          next_state = IDLE;
          next_bit_counter = bit_counter;
          next_data = data;
          next_valid_data = 1'b0;     // Data is not valid
        end
      end

      RECEIVE: begin
        if (bit_counter == 0) begin
          // If all bits have been received
          if (uart_rx == 1'b1) begin
            // Validate data if stop bit (uart_rx == 1) is correct
            next_valid_data = 1'b1;
          end else begin
            // Data is invalid if stop bit is incorrect
            next_valid_data = 1'b0;
          end
          next_state = IDLE;          // Transition back to IDLE state
          next_data = data;           // Keep current data
          next_bit_counter = bit_counter; // No changes to bit counter
        end else begin
          // Shift received bit into the data buffer
          next_data[bit_counter] = uart_rx;
          next_bit_counter = bit_counter - 1; // Decrement bit counter
          next_state = state;                 // Remain in RECEIVE state
          next_valid_data = 1'b0;             // Data is not valid yet
        end
      end

      default: begin
        // Default case: Keep current state and values
        next_state = state;
        next_data = data;
        next_bit_counter = bit_counter;
        next_valid_data = 1'b0;  // Data is not valid
      end
    endcase
  end

endmodule
