// Set the timescale for the simulation
`timescale 1ns/1ps 

module testbench;  // Testbench module

// Parameter definitions
parameter CYCLE = 10; // Clock period
parameter LARGE_NUMBER = 10500; // Maximum cycle time for timeout

// Local parameter definition
localparam N = 10417; // BAUD_RATE_NUMBER + 1: Ensures the correctness of the first data in the next round

// Input signals (declared as reg)
reg clk;      // Clock signal
reg rst_n;    // Reset signal (active low)

// Output signals (declared as wire)
wire baud_rate_out; // Baud rate output signal
wire [13:0] counter; // Counter value from the module

// Integer variables
integer i, j, error; // Loop variables and error counter

///// Instantiate modules /////
// Instantiate the `baud_rate_generator` module
baud_rate_generator baud_rate_generator(
  .clk(clk),
  .rst_n(rst_n),
  .baud_rate_signal(baud_rate_out),
  .counter(counter)
);

// Dump the waveform for simulation analysis
initial begin
  $dumpfile("testbench.vcd"); // Create a VCD file to store simulation waveforms
  $dumpvars("+mda");          // Dump all module variables for waveform analysis
end

// Generate the clock signal
always #(CYCLE / 2) clk = ~clk; // Toggle clock signal every half cycle

// System block: Initialize signals and handle timeout for the simulation
initial begin
  clk = 1;
  rst_n = 1;
  // Apply system reset
  #(CYCLE / 2) rst_n = 0; // Assert reset
  #(CYCLE) rst_n = 1;     // Deassert reset

  // Timeout: End the simulation after a predefined number of cycles
  #(CYCLE * LARGE_NUMBER) $finish;
end

// Output result checking block: Verify the results and handle error reporting
integer fp_w; // File pointer for writing results
initial begin
  error = 0; // Initialize the error counter

  // Wait for reset to complete
  wait(rst_n == 0);
  wait(rst_n == 1);

  // Open a file to write the output results
  fp_w = $fopen("answer.txt");

  // Iterate through all test patterns
  for (j = 0; j < N; j = j + 1) begin
    @(posedge clk); // Wait for the clock edge

    // For all cycles except the last one
    if (j != 10416) begin
      // Verify that the baud rate output is 0
      if (baud_rate_out != 0) begin
        error = error + 1; // Increment error counter if mismatch
        $display("************* Pattern No.%d is wrong at %t ************", j, $time);
        $display("Expected Output = 0, but your answer is %b", baud_rate_out);
      end
      // Log results to the output file
      $fdisplay(fp_w, "0_%b %d", baud_rate_out, counter);
    end else begin
      // For the last cycle, verify that the baud rate output is 1
      if (baud_rate_out != 1) begin
        error = error + 1; // Increment error counter if mismatch
        $display("************* Pattern No.%d is wrong at %t ************", j, $time);
        $display("Expected Output = 1, but your answer is %b", baud_rate_out);
      end
      // Log results to the output file
      $fdisplay(fp_w, "1_%b %d", baud_rate_out, counter);
    end
  end

  $fclose(fp_w); // Close the output file

  // Check the error count and display results
  if (error == 0) begin
    $display("Congratulations!! The functionality of your baud_rate_generator is correct!!");
  end else begin
    $display("Errors detected!!");
  end

  #(CYCLE) $finish; // End the simulation
end

endmodule
