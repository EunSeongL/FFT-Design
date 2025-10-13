`timescale 1ns/1ps

module tb_fft ();
    parameter IN_BIT = 9;
    parameter OUT_BIT = 13;
    parameter N = 512;
    integer file, out_file, r, i, j, i_blk, j_blk;
    integer clk_count;
    logic signed [IN_BIT-1:0] din_i_data [0:N-1];  // 3.6 포맷이면 총 9비트 필요 (부호 포함)
    logic signed [IN_BIT-1:0] din_q_data[0:N-1];
    logic signed [IN_BIT-1:0] din_i[0:15];
    logic signed [IN_BIT-1:0] din_q[0:15];
    logic valid_in;
    logic signed [OUT_BIT-1:0] do1_re[0:15];
    logic signed [OUT_BIT-1:0] do1_im[0:15];
    logic valid_out;
    logic clk;
    logic rstn;

    logic [4:0] index_out [0:15];

    logic prev_valid_out;
    logic falling_edge_detected;

    always #5 clk = ~clk;

    initial begin
        file = $fopen("/home/aedu30/fft/testbench/data_fixed.txt","r");
        if (file == 0) begin
            $display("파일 열기 실패");
            $finish;
        end

        for (i = 0; i < N; i = i + 1) begin
            r = $fscanf(file, "%d %d\n", din_i_data[i],
                        din_q_data[i]);  // 보통 앞에서부터 읽기
            if (r != 2) begin
                $display("파일 읽기 오류 at line %0d", i + 1);
                $finish;
            end
        end
        $fclose(file);

        clk = 0;
        rstn = 0;
        valid_in = 0;
        clk_count = 0;
        prev_valid_out = 0;
        falling_edge_detected = 0;

        out_file = $fopen("./fft_rtl_output.txt", "w");
        if (out_file == 0) begin
            $display("출력 파일 열기 실패");
            $finish;
        end

        #15; rstn = 1;


	i_blk = 0; j_blk = 0;
       
	for (i_blk = 0; i_blk < N / 16; i_blk = i_blk + 1) begin
    		@(negedge clk); // 1. 데이터 준비 전에 대기
    		for (j_blk = 0; j_blk < 16; j_blk = j_blk + 1) begin
        		din_i[j_blk] = din_i_data[(i_blk*16)+j_blk];
        		din_q[j_blk] = din_q_data[(i_blk*16)+j_blk];
    		end
    		valid_in = 1;  // 2. valid 활성화
    		#1; // 3. 모듈에서 샘플링
	end
	@(negedge clk);
        valid_in = 0;

        // 🔹 wait for falling edge of valid_out
        wait (falling_edge_detected == 1);

        // 🔹 1클럭 쉬고 다음 데이터
        @(negedge clk);
        @(negedge clk); 
        
        
        #10000;
        $fclose(out_file);
        $stop;
    end

    // 🔸 valid_out falling edge 감지
    always @(negedge clk) begin
        prev_valid_out <= valid_out;
        if (prev_valid_out == 1 && valid_out == 0 && !falling_edge_detected) begin
            falling_edge_detected <= 1;
        end
    end

    // clk count 및 출력 저장
    always @(negedge clk) begin
        clk_count <= clk_count + 1;

        if (valid_out) begin
            for (j = 0; j < 16; j = j + 1) begin
                $fwrite(out_file, "%0d %0d\n",
                    do1_re[j], do1_im[j]);
            end
        end
    end

    FFT # (
    .IN_WIDTH          (9),   //<3.6>format
    .OUT_WIDTH         (13),  //<9.4> foramt 
    .NUM               (16),  //묶음 수
    .MODULE0_OUT_WIDTH (11),
    .MODULE1_OUT_WIDTH (12),
    .MODULE2_OUT_WIDTH (13)
  ) DUT(
    .clk       (clk),
    .rstn      (rstn),
    .valid_in  (valid_in),
    .din_i     (din_i),
    .din_q     (din_q),
    .valid_out (valid_out),
    .dout_i    (do1_re),
    .dout_q    (do1_im)
  );


endmodule
