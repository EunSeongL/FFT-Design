`timescale 1ns / 10ps

module tb_fft_gate ();

  //──────────────────────────────────────────────────────────────────────────
  // Parameters
  //──────────────────────────────────────────────────────────────────────────
  parameter IN_WIDTH  = 9;
  parameter OUT_WIDTH = 13;
  parameter NUM       = 16;
  parameter N         = 512;

  //──────────────────────────────────────────────────────────────────────────
  // File I/O and storage
  //──────────────────────────────────────────────────────────────────────────
  integer file, r, out_file;
  integer i_blk, j_blk;
  logic signed [IN_WIDTH-1:0] din_i_data [0:N-1];
  logic signed [IN_WIDTH-1:0] din_q_data [0:N-1];

  //──────────────────────────────────────────────────────────────────────────
  // DUT I/O as flattened buses
  //──────────────────────────────────────────────────────────────────────────
  logic                   valid_in;
  logic                   valid_out;
  logic [IN_WIDTH*NUM-1:0]  din_i_bus, din_q_bus;
  logic [OUT_WIDTH*NUM-1:0] dout_i_bus, dout_q_bus;

  // unpacked outputs
  logic signed [OUT_WIDTH-1:0] dout_i [0:NUM-1];
  logic signed [OUT_WIDTH-1:0] dout_q [0:NUM-1];

  //──────────────────────────────────────────────────────────────────────────
  // Clock / Reset / Edge detection
  //──────────────────────────────────────────────────────────────────────────
  logic clk, rstn;
  logic prev_valid_out, falling_edge_detected;
  integer clk_count;

  // 100 MHz clock
  always #5 clk = ~clk;

  // detect falling edge of valid_out → posedge로 변경
  always @(negedge clk) begin
    prev_valid_out <= valid_out;
    if (prev_valid_out && !valid_out)
      falling_edge_detected <= 1;
    clk_count <= clk_count + 1;
  end

  //──────────────────────────────────────────────────────────────────────────
  // Stimulus & File writing
  //──────────────────────────────────────────────────────────────────────────
  initial begin
    // 1) load input vectors from file
    file = $fopen("../testbench/data_fixed.txt","r");
    if (!file) $fatal("Cannot open data_fixed.txt");
    for (i_blk = 0; i_blk < N; i_blk = i_blk + 1) begin
      r = $fscanf(file, "%d %d\n",
                  din_i_data[i_blk], din_q_data[i_blk]);
      if (r != 2) $fatal("Read error at line %0d", i_blk+1);
    end
    $fclose(file);

    // 2) open output file
    out_file = $fopen("fft_output.txt","w");
    if (!out_file) $fatal("Cannot open fft_output.txt");

    // 3) init
    clk    = 0;
    rstn   = 0;
    valid_in = 0;
    din_i_bus = 0;
    din_q_bus = 0;
    falling_edge_detected = 0;

    // release reset
    #15; rstn = 1;
    repeat(5) @(negedge clk);

    //────────────────────────────────────────────────────────────────────────
    // 4) first block: pack then assert at negedge
    //────────────────────────────────────────────────────────────────────────
    valid_in = 1;
    for (j_blk = 0; j_blk < NUM; j_blk = j_blk + 1) begin
      din_i_bus[j_blk*IN_WIDTH +: IN_WIDTH]
        = din_i_data[0*NUM + j_blk];
      din_q_bus[j_blk*IN_WIDTH +: IN_WIDTH]
        = din_q_data[0*NUM + j_blk];
    end

    $display("Block %0d din_i_bus = %b", 0, din_i_bus);
    @(negedge clk);
    
    //────────────────────────────────────────────────────────────────────────
    // 5) remaining 31 blocks
    //────────────────────────────────────────────────────────────────────────
    for (i_blk = 1; i_blk < N/NUM; i_blk = i_blk + 1) begin
      for (j_blk = 0; j_blk < NUM; j_blk = j_blk + 1) begin
        din_i_bus[j_blk*IN_WIDTH +: IN_WIDTH]
          = din_i_data[i_blk*NUM + j_blk];
        din_q_bus[j_blk*IN_WIDTH +: IN_WIDTH]
          = din_q_data[i_blk*NUM + j_blk];
      end
      @(negedge clk);
      $display("Block %0d din_i_bus = %b", i_blk, din_i_bus);
    end

    //────────────────────────────────────────────────────────────────────────
    // 6) deassert valid_in after all 32 blocks
    //────────────────────────────────────────────────────────────────────────
    valid_in = 0;

    //────────────────────────────────────────────────────────────────────────
    // 7) wait for end of output burst, then finish.
    //────────────────────────────────────────────────────────────────────────
    wait (falling_edge_detected);
    #100;
    $fclose(out_file);
    $stop;
  end

  //──────────────────────────────────────────────────────────────────────────
  // Collect outputs on each valid_out → posedge에서 캡처
  //──────────────────────────────────────────────────────────────────────────
  always @(negedge clk) if (valid_out) begin
    for (int j = 0; j < NUM; j = j + 1) begin
      dout_i[j] = $signed(dout_i_bus[j*OUT_WIDTH +: OUT_WIDTH]);
      dout_q[j] = $signed(dout_q_bus[j*OUT_WIDTH +: OUT_WIDTH]);
      $fwrite(out_file, "%0d %0d\n", dout_i[j], dout_q[j]);
    end
  end

  //──────────────────────────────────────────────────────────────────────────
  // DUT instantiation
  //──────────────────────────────────────────────────────────────────────────

  /*
  butterfly02 dut (
    .clk       (clk),
    .rstn      (rstn),
    .valid_in  (valid_in),
    .din_i     (din_i_bus),
    .din_q     (din_q_bus),
    .valid_out (valid_out),
    .do1_re    (dout_i_bus),
    .do1_im    (dout_q_bus)
  );
  */
  
  FFT dut (
    .clk       (clk),
    .rstn      (rstn),
    .valid_in  (valid_in),
    .din_i     (din_i_bus),
    .din_q     (din_q_bus),
    .valid_out (valid_out),
    .dout_i    (dout_i_bus),
    .dout_q    (dout_q_bus)
  );

endmodule
