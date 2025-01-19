// Set the timescale for the simulation
`timescale 1ns/1ps 

module testbench; // Testbench module

// Parameter definitions
parameter CYCLE = 10;              // Clock period in nanoseconds
parameter BAUD_RATE_NUMBER = 20;   // Baud rate interval multiplier

// Local parameter definition
localparam N = 256;                // Number of test patterns

// Input signals (declared as reg for driving signals)
reg clk;            // Clock signal
reg rst_n;          // Reset signal (active low)
reg uart_rx;        // UART receive input signal

// Output signals (declared as wire for observed signals)
wire baud_rate_signal; // Baud rate clock signal
wire [8:1] data;       // 8-bit received data output
wire valid_data;       // Valid data output flag

// Integer variables for loops and error counting
integer j, error; // Loop counters and error counter

///// Module Instantiations /////

// Instantiate the baud rate generator module
baud_rate_generator baud_rate_generator(
  .clk(clk),                   // Clock input
  .rst_n(rst_n),               // Reset signal input
  .baud_rate_signal(baud_rate_signal) // Generated baud rate signal
);

// Instantiate the UART receiver module
uart_receiver uart_receiver(
  .uart_rx(uart_rx),           // UART receive input
  .baud_rate_signal(baud_rate_signal), // Baud rate clock signal
  .rst_n(rst_n),               // Reset signal
  .data(data),                 // 8-bit data output
  .valid_data(valid_data)      // Valid data output flag
);

// Dump waveform for simulation analysis
initial begin
  $dumpfile("testbench.vcd");  // Generate VCD file for waveform viewing
  $dumpvars("+mda");           // Dump all module variables to VCD file
end

// Load test patterns into an array
reg [18:0] golden [0:N]; // Array to store test patterns (signal + expected outputs)
initial begin
  $readmemb("golden.dat", golden); // Read test patterns from "golden.dat" file
end

// Clock generation
always #(CYCLE/2) clk = ~clk; // Toggle clock every half cycle

// System initialization block
initial begin
  clk = 1;        // Initialize clock signal
  rst_n = 1;      // Deassert reset initially

  // Apply system reset
  #(CYCLE/2) rst_n = 0; // Assert reset (active low)
  #(CYCLE) rst_n = 1;   // Deassert reset
end

// Task to send UART data bit by bit
integer k; // Loop variable for bit transmission
task send_uartrx (input reg [9:0] pattern_in); // Task to send a UART data frame
  begin
    for (k = 9; k >= 0; k = k - 1) begin
      @(posedge baud_rate_signal); // Wait for the baud rate signal's positive edge
      #(CYCLE);                    // Add delay to account for timing dependencies between combinational and sequential logic updates
      uart_rx = pattern_in[k];     // Assign one bit from the input pattern
    end
  end
endtask

// Block to check the output and compare it with expected results
integer fp_w; // File pointer for writing results
reg [9:0] signal_in;        // UART input signal (start, data, stop bits)
reg [7:0] correct_data;     // Expected data output
reg correct_valid;          // Expected valid_data output
reg debug = 0;              // Debugging flag

initial begin
  error = 0; // Initialize error counter

  // Wait for reset completion
  wait(rst_n == 0); // Wait until reset is active
  wait(rst_n == 1); // Wait until reset is released

  // Open a file to log the output results
  fp_w = $fopen("answer.txt");

  // Iterate through all test patterns
  for (j = 0; j < N; j = j + 1) begin
    @(posedge clk); // Wait for clock's positive edge
    signal_in = golden[j][18:9]; // Extract the UART input pattern
    correct_data = golden[j][8:1]; // Extract expected 8-bit data
    correct_valid = golden[j][0]; // Extract expected valid flag

    send_uartrx(signal_in); // Send the UART input pattern bit by bit

    #(CYCLE * 20); // Wait for sufficient time for data processing (based on BAUD_RATE_NUMBER)

    debug = 1; // Optional debug signal
    // Compare the observed outputs with the expected results
    if ({data, valid_data} !== {correct_data, correct_valid}) begin
      error = error + 1; // Increment error counter on mismatch
      $display("************* Pattern No.%d is wrong at %t ************", j, $time);
      $display("uart_rx = %b, correct data and correct valid_data are %b and %b,", signal_in, correct_data, correct_valid);
      $display("but your data and valid_data are %b and %b !!", data, valid_data);
    end

    // Log results to the output file
    $fdisplay(fp_w, "%b_%b_%b_%b_%b", signal_in, data, valid_data, correct_data, correct_valid);
  end

  $fclose(fp_w); // Close the output file

  // Display simulation results
  if (error == 0) begin
    $display("Congratulations!! The functionality of your receiver is correct!!");
  end else begin
    $display("Error detected!!");
  end 

  #(CYCLE) $finish; // End the simulation
end

endmodule
