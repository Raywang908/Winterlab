// set the timescale for the simulation
`timescale 1ns/1ps  // Defines the time units for the simulation (1ns for time, 1ps for precision)

module testbench;  // Define the testbench module

// Parameter definitions
parameter CYCLE = 10;  // Defines the clock period (in ns)
parameter BAUD_RATE_NUMBER_R = 2000;  // Defines the baud rate for the receiver (the number of clock cycles per bit)

// Local parameters
localparam N = 256;  // Defines the number of test patterns (256 test cases in this case)


// Input signals defined as reg (registers are used for signals that change in time)
reg clk_R;  // Clock signal for receiver
reg clk_T;  // Clock signal for transmitter
reg rst_n;  // Active-low reset signal
reg start;  // Start signal to begin the transmission
reg [7:0] data;  // Data to be transmitted

// Output signals defined as wire (wires are used for continuously driven signals)
wire baud_rate_signal_R, baud_rate_signal_T;  // Baud rate signals for receiver and transmitter
wire uart_tx;  // UART transmit signal
wire [8:1] result;  // Result of the received data
wire valid_data;  // Signal indicating if the received data is valid

// Integer variables for error checking and iteration
integer j, error;

// Instantiate the modules (module_name instance_name)
baud_rate_generator_T baud_rate_generator_T(
  .clk(clk_T),  // Transmitter clock
  .rst_n(rst_n),
  .baud_rate_signal(baud_rate_signal_T)  // Baud rate signal for transmitter
);

uart_transmitter uart_transmitter(
  .data(data),  // Data to be transmitted
  .baud_rate_signal(baud_rate_signal_T),  // Baud rate signal for transmitter
  .start(start),  // Start transmission signal
  .rst_n(rst_n),
  .clk(clk_T),  // Transmitter clock
  .uart_tx(uart_tx)  // UART transmit signal
);

baud_rate_generator_R baud_rate_generator_R(
  .clk(clk_R),  // Receiver clock
  .rst_n(rst_n),
  .baud_rate_signal(baud_rate_signal_R)  // Baud rate signal for receiver
);

uart_receiver uart_receiver(
  .uart_rx(uart_tx),  // UART receive signal (connected to uart_tx from transmitter)
  .baud_rate_signal(baud_rate_signal_R),  // Baud rate signal for receiver
  .rst_n(rst_n),
  .data(result),  // Received data
  .valid_data(valid_data)  // Signal indicating valid received data
);

// Dump waveform data to a VCD file for simulation visualization
initial begin
  $dumpfile("testbench.vcd");  // Output file for waveform
  $dumpvars("+mda");  // Dump all variables for the simulation
end

// Read the test data from a file and store it in the 'golden' array
reg [15:0] golden [0:N];  // Array to store test patterns
initial begin
  $readmemb("golden.dat", golden);  // Read binary data from file "golden.dat"
end

// Generate clock signals (clk_R and clk_T)
// The receiver clock (clk_R) has a period defined by the parameter CYCLE
always #(CYCLE/2) clk_R = ~clk_R;  // Toggle receiver clock every CYCLE/2
// The transmitter clock (clk_T) has a period defined by the parameter CYCLE
always #(CYCLE) clk_T = ~clk_T;  // Toggle transmitter clock every CYCLE

// Initial system setup (reset signals and start signal)
initial begin
  clk_R = 1;  // Set initial value of clk_R
  clk_T = 1;  // Set initial value of clk_T
  rst_n = 1;  // Set reset signal high (inactive)
  start = 0;  // Set start signal low (inactive)
  
  // System reset
  #(CYCLE/2) rst_n = 0;  // Apply reset (low) for one clock cycle
  #(CYCLE) rst_n = 1;  // Release reset (high)
  
  #(CYCLE*2) start = 1;  // Start the transmission after two clock cycles
end

// Output result checking block: sample the output and verify results
integer fp_w;  // File pointer for writing results to file
reg [7:0] correct_data;  // Register for storing expected data
integer debug = 0;  // Debug flag for toggling in the loop

initial begin
  error = 0;  // Initialize error count to 0
  // Wait for the reset to be completed
  wait(rst_n == 0);
  wait(rst_n == 1);
  
  // Open file for writing the results
  fp_w = $fopen("answer.txt");  // Open "answer.txt" for writing results
  
  // Loop through all test patterns
  for (j = 0; j < N; j = j + 1) begin
    @(posedge clk_R);  // Wait for a rising edge of receiver clock
    data = golden[j][15:8];  // Assign upper byte of golden data to data
    correct_data = golden[j][7:0];  // Assign lower byte of golden data to correct_data
    
    #(CYCLE * BAUD_RATE_NUMBER_R * 11);  // Wait for the transmission to complete (11 bit time per character)
    debug = ~debug;  // Toggle debug flag (for debugging purposes)
    
    // Check if the received data matches the expected data
    if(result !== correct_data) begin
      error = error + 1;  // Increment error count if data does not match
      $display("************* Pattern No.%d is wrong at %t ************", j, $time);  // Display error message
      $display("signal_in = %b, correct data is %b,", data, correct_data);  // Display input data and expected correct data
      $display("but your result is %b !!", result);  // Display the actual result from receiver
    end
    
    // Write the result, expected data, and valid data to the file
    $fdisplay(fp_w, "%b  %b_%b_%b", data, correct_data, result, valid_data);
  end
  
  // Close the result file
  $fclose(fp_w);
  
  // Display the final message based on the error count
  if(error == 0) begin
    $display("Congratulations!! The functionality of your receiver and transmitter is correct!!");
  end
  else begin
    $display("error !!");
  end
  
  #(CYCLE) $finish;  // End the simulation
end

endmodule  // End of testbench module
