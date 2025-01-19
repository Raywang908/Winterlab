module baud_rate_generator (
  input wire clk,                  // Clock signal
  input wire rst_n,                // Reset signal (active low)
  output reg baud_rate_signal      // Baud rate output signal
);

  parameter BAUD_RATE_NUMBER = 20; // Parameter for the baud rate timing
  reg baud_rate_next;              // Temporary storage for the next baud rate signal (combinational logic)
  reg [13:0] counter;              // Counter to track baud rate timing
  reg [13:0] next_counter;         // Temporary storage for the next counter value

  // Sequential logic: updates values driven by the clock
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      counter <= BAUD_RATE_NUMBER - 1; // Initialize the counter
      baud_rate_signal <= 1'b0;        // Initialize the baud rate signal to 0
    end else begin
      counter <= next_counter;         // Update the counter
      baud_rate_signal <= baud_rate_next; // Update the baud rate signal from combinational logic
    end
  end

  // Combinational logic: calculates the next state of baud_rate_signal
  always @(*) begin
    if (counter == 1) begin
      baud_rate_next = 1'b0;               // Prepare to reset baud rate signal
      next_counter = counter - 1;          // Decrement the counter
    end else if (counter == 0) begin
      baud_rate_next = 1'b1;               // Set baud rate signal high
      next_counter = BAUD_RATE_NUMBER - 1; // Reset the counter to the initial value
    end else begin
      baud_rate_next = 1'b0;               // Maintain baud rate signal as low
      next_counter = counter - 1;          // Decrement the counter
    end
  end

endmodule
