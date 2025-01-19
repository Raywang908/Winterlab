// Set the timescale for the simulation
`timescale 1ns/1ps

module testbench;  // Testbench module definition

// Parameter definitions
parameter CYCLE = 10; // Clock period in nanoseconds
parameter BAUD_RATE_NUMBER = 20; // Baud rate scaling factor

// Local parameter definition
localparam N = 256; // Number of test patterns

// Input signals (declared as `reg`)
reg clk;             // Clock signal
reg rst_n;           // Reset signal (active low)
reg start;           // Signal to start transmission
reg [7:0] data;      // 8-bit input data

// Output signals (declared as `wire`)
wire baud_rate_signal; // Baud rate signal
wire uart_tx;          // UART transmitted output signal

// Integer variables
integer j, error; // Loop counter `j` and error counter

// Instantiate modules to be tested
// Instantiate the baud rate generator module
baud_rate_generator baud_rate_generator(
  .clk(clk),
  .rst_n(rst_n),
  .baud_rate_signal(baud_rate_signal)
);

// Instantiate the UART transmitter module
uart_transmitter uart_transmitter(
  .data(data),
  .baud_rate_signal(baud_rate_signal),
  .start(start),
  .rst_n(rst_n),
  .clk(clk),
  .uart_tx(uart_tx)
);

// Dump the waveform of the simulation in VCD format
initial begin
  $dumpfile("testbench.vcd");      // Specify the output VCD file
  $dumpvars("+mda");               // Dump all module variables
end

// Load test patterns from a file into a register array
reg [17:0] golden [0:N]; // Array to store golden patterns
initial begin
  $readmemb("golden.dat", golden); // Read binary patterns from "golden.dat"
end

// Generate the clock signal
always #(CYCLE/2) clk = ~clk; // Toggle clock every half cycle

// System initialization block
initial begin
  clk = 1;        // Initialize clock to 1
  rst_n = 1;      // Initialize reset to active high
  start = 0;      // Set start signal to inactive
  #(CYCLE/2) rst_n = 0;  // Assert reset (active low)
  #(CYCLE) rst_n = 1;    // Deassert reset
  #(CYCLE*2) start = 1;  // Activate start signal after 2 clock cycles
end

// Task to capture UART output bit-by-bit
integer k; // Loop counter for task
task send_uarttx (output reg [9:0] pattern_out);
  begin
    for (k = 9; k >= 0; k = k - 1) begin
      @(posedge baud_rate_signal); // Wait for baud rate signal edge
      #(CYCLE*2);                  // Add delay to synchronize
      pattern_out[k] = uart_tx;    // Capture UART output bit-by-bit
    end
  end
endtask

// Block to verify results and log output
integer fp_w;           // File pointer for writing results
reg [9:0] correct_data; // Expected correct data
reg [9:0] result;       // Captured result from UART output

initial begin
  error = 0; // Initialize error counter

  // Wait for reset to complete
  wait(rst_n == 0);
  wait(rst_n == 1);

  // Open a file to log the output results
  fp_w = $fopen("answer.txt");

  // Loop through all test patterns
  for (j = 0; j < N; j = j + 1) begin
    @(posedge clk); // Wait for the clock edge
    data = golden[j][17:10];      // Extract input data from golden pattern
    correct_data = golden[j][9:0]; // Extract expected output data

    send_uarttx(result);          // Capture the UART output

    // Check if the captured result matches the expected data
    if (result !== correct_data) begin
      error = error + 1; // Increment error counter if mismatch
      $display("************* Pattern No.%d is wrong at %t ************", j, $time);
      $display("signal_in = %b, correct data is %b,", data, correct_data);
      $display("but your result is %b !!", result);
    end

    // Write results to the output file
    $fdisplay(fp_w, "%b  %b_%b", data, correct_data, result);

    #(CYCLE*20); // Wait for baud rate signal to propagate
  end

  $fclose(fp_w); // Close the output file

  // Display final results
  if (error == 0) begin
    $display("Congratulations!! The functionality of your transmitter is correct!!");
  end else begin
    $display("Error detected!!");
  end

  #(CYCLE) $finish; // End the simulation
end

endmodule
