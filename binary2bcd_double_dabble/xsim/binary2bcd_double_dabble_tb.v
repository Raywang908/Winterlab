// Set the timescale for the simulation
`timescale 1ns/1ps 

module testbench;  // Testbench module for simulation

// Local parameters
localparam N = 256;    // Define the number of test patterns
localparam CYCLE = 10; // Define the clock cycle period in ns

// Input signal: binary input (8 bits)
reg [7:0] binary_in; 

// Output signals: BCD outputs
wire [19:0] unpacked_bcd;  // Unpacked BCD output (20 bits)
wire [11:0] packed_bcd;    // Packed BCD output (12 bits)

// Integer variables for error counting and loop iteration
integer j, error;

// Instantiate the binary to BCD conversion module (double-dabble method)
binary2bcd_double_dabble binary2bcd_double_dabble(
  .binary_in(binary_in),     // 8-bit binary input
  .unpacked_bcd(unpacked_bcd), // 20-bit unpacked BCD output
  .packed_bcd(packed_bcd)      // 12-bit packed BCD output
);

// Dump waveform of the simulation for VCD (Value Change Dump) file
initial begin
  $dumpfile("testbench.vcd");  // Set output VCD file
  $dumpvars("+mda");           // Dump all variables for waveform visualization
end

// Declare a register array to store golden values (expected results)
reg [39:0] golden [0:N];

// Initialize the golden values from a file
initial begin
  $readmemb("golden.dat", golden);  // Read golden values from file (binary format)
end

// Output result checking block to verify the correctness of the conversion
integer fp_w;  // File pointer for writing the results to a file
reg [11:0] correct_data_packed;   // Correct packed BCD data for comparison
reg [19:0] correct_data_unpacked; // Correct unpacked BCD data for comparison

initial begin
  // Initialize error count to 0
  error = 0;

  // Open a file to store the results for comparison
  fp_w = $fopen("answer.txt");

  // Loop through each pattern from the golden array
  for (j = 0; j < N; j = j + 1) begin
    // Extract the binary input and the expected packed and unpacked BCD results
    binary_in = golden[j][39:32];            // Extract 8-bit binary input
    correct_data_packed = golden[j][31:20];  // Extract expected packed BCD (12 bits)
    correct_data_unpacked = golden[j][19:0]; // Extract expected unpacked BCD (20 bits)

    // Wait for the next cycle to allow the DUT (Device Under Test) to process the input
    #(CYCLE);

    // Compare the generated packed and unpacked BCD outputs with the expected values
    if (packed_bcd !== correct_data_packed || unpacked_bcd !== correct_data_unpacked) begin
      error = error + 1;  // Increment error count if the outputs do not match
      // Display error message with pattern number, input, and expected vs actual outputs
      $display("************* Pattern No.%d is wrong at %t ************", j, $time);
      $display("signal_in = %b, correct packed data is %b, correct unpacked data is %b,", binary_in, correct_data_packed, correct_data_unpacked);
      $display("but your result is %b and %b !!", packed_bcd, unpacked_bcd);
    end

    // Write the results to the output file for further analysis
    $fdisplay(fp_w, "%b  %b___%b %b___%b", binary_in, correct_data_packed, packed_bcd, correct_data_unpacked, unpacked_bcd);
  end

  // Close the result file after all patterns are checked
  $fclose(fp_w);

  // Final message based on whether there were errors or not
  if (error == 0) begin
    $display("Congratulations!! The functionality of your binary2bcd is correct!!");
  end else begin
    $display("error !!");
  end

  // End the simulation after all tests
  #(CYCLE) $finish; 
end

endmodule
