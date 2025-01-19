module uart_transmitter (
  input wire [7:0] data,            // Input 8-bit data to be transmitted
  input wire baud_rate_signal,      // Baud rate signal to synchronize transmission
  input wire start,                 // Signal to start the transmission
  input wire rst_n,                 // Reset signal (active low)
  input wire clk,                   // Clock signal
  output reg uart_tx                // UART data output
);

  reg [10:1] packed_data;           // Packed 10-bit data (start bit, 8 data bits, stop bit)
  reg state, next_state;            // Current state and next state
  reg [3:0] bit_counter, next_bit_counter; // Counter to track the current bit and its next value
  reg next_uart_tx;                 // Output for the next clock cycle
  localparam IDLE = 1'b0;           // Idle state
  localparam TRANSMIT = 1'b1;       // Transmit state

  // Sequential logic: state transition and data updates
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;                // Initialize to IDLE state on reset
      bit_counter <= 4'd10;         // Default bit counter to 10 bits
      uart_tx <= 1'b1;              // Default UART output is high (idle state)
      packed_data <= 11'b0;         // Clear packed data
    end else begin
      state <= next_state;          // Update to the next state
      bit_counter <= next_bit_counter; // Update bit counter
      uart_tx <= next_uart_tx;      // Update UART output
    end
  end

  // Combinational logic: calculate next state and outputs
  always @(*) begin
    packed_data = {1'b0, data, 1'b1}; // Pack the data with start and stop bits
    case (state)
      IDLE: begin
        next_uart_tx = 1'b1;        // Default to high (idle state)
        if (start) begin
          next_state = TRANSMIT;   // Transition to TRANSMIT state on start signal
          next_bit_counter = 4'd10; // Reset bit counter to 10 bits
        end else begin
          next_state = IDLE;       // Remain in IDLE state
          next_bit_counter = bit_counter; // Keep current bit counter
        end
      end

      TRANSMIT: begin
        if (baud_rate_signal) begin // Check baud rate signal for synchronization
          if (bit_counter == 0) begin
            next_state = IDLE;     // Transmission complete, go to IDLE state
            next_bit_counter = bit_counter; // Keep current bit counter
            next_uart_tx = uart_tx; // Maintain current output
          end else begin
            next_uart_tx = packed_data[bit_counter]; // Output the current bit
            next_bit_counter = bit_counter - 1; // Decrement bit counter
            next_state = TRANSMIT; // Remain in TRANSMIT state
          end
        end else begin
          next_state = state;      // Keep current state if no baud rate signal
          next_bit_counter = bit_counter; // Keep current bit counter
          next_uart_tx = uart_tx;  // Maintain current output
        end
      end

      default: begin
        next_state = state;        // Default to current state
        next_bit_counter = bit_counter; // Default to current bit counter
        next_uart_tx = uart_tx;    // Default to current output
      end
    endcase
  end

endmodule
