`timescale 1ns/1ps

module tb_neuron_core_new;
    parameter NUM_OUTPUT = 250; // Number of spikes
    parameter NUM_PICTURE = 10000; // Number of test images
    parameter NUM_PACKET = 1600000; // Number of input packets in file
    
logic clk;
logic rst;

// Wishbone interface signals
logic wbs_cyc_i;
logic wbs_stb_i;
logic wbs_we_i;
logic [3:0] wbs_sel_i;
logic [31:0] wbs_adr_i;
logic [31:0] wbs_dat_i;
wire wbs_ack_o;
wire [31:0] wbs_dat_o;

neuron_network_sv uut_network_core(
    .wb_clk_i(clk),
    .wb_rst_i(rst),
    .wbs_cyc_i(wbs_cyc_i),
    .wbs_stb_i(wbs_stb_i),
    .wbs_we_i(wbs_we_i),
    .wbs_sel_i(wbs_sel_i),
    .wbs_adr_i(wbs_adr_i),
    .wbs_dat_i(wbs_dat_i),
    .wbs_ack_o(wbs_ack_o),
    .wbs_dat_o(wbs_dat_o)
);

initial clk = 0;
always #5 clk = ~clk;

task wishbone_write;
    input [31:0] address;
    input [31:0] data;
    begin
        @(negedge clk) begin
            wbs_cyc_i = 1'b1;
            wbs_stb_i = 1'b1;
            wbs_we_i = 1'b1;
            wbs_sel_i = 4'b1111;
            wbs_adr_i = address;
            wbs_dat_i = data;
        end
        @(negedge clk) begin
            wbs_cyc_i = 1'b0;
            wbs_stb_i = 1'b0;
            wbs_we_i = 1'b0;
            wbs_sel_i = 4'b0000;
        end
    end
endtask

task wishbone_read;
    input [31:0] address;
    output [31:0] data;
    begin
        @(negedge clk) begin
            wbs_cyc_i = 1'b1;
            wbs_stb_i = 1'b1;
            wbs_we_i = 1'b0;
            wbs_sel_i = 4'b0000;
            wbs_adr_i = address;
        end
        @(negedge clk) begin
            wbs_cyc_i = 1'b0;
            wbs_stb_i = 1'b0;
            data = wbs_dat_o;
        end
    end
endtask

logic [11:0] num_pic [0:NUM_PICTURE - 1];
initial $readmemh("D:/TaiLieu/k66/20241/da2/EDABK_NeuronScience-master/EDABK_NeuronScience-master/Architecture/HWSW/converter/new_mem/tb_num_inputs_hex.txt", num_pic);

logic [31:0] packet [0:NUM_PACKET-1];
initial $readmemb("D:/TaiLieu/k66/20241/da2/EDABK_NeuronScience-master/EDABK_NeuronScience-master/Architecture/HWSW/converter/new_mem/tb_input.txt", packet);

logic [367:0] param [5][256];
initial $readmemb("D:/TaiLieu/k66/20241/da2/EDABK_NeuronScience-master/EDABK_NeuronScience-master/Architecture/HWSW/converter/new_mem/csram_000.mem", param[0]);
initial $readmemb("D:/TaiLieu/k66/20241/da2/EDABK_NeuronScience-master/EDABK_NeuronScience-master/Architecture/HWSW/converter/new_mem/csram_001.mem", param[1]);
initial $readmemb("D:/TaiLieu/k66/20241/da2/EDABK_NeuronScience-master/EDABK_NeuronScience-master/Architecture/HWSW/converter/new_mem/csram_002.mem", param[2]);
initial $readmemb("D:/TaiLieu/k66/20241/da2/EDABK_NeuronScience-master/EDABK_NeuronScience-master/Architecture/HWSW/converter/new_mem/csram_003.mem", param[3]);
initial $readmemb("D:/TaiLieu/k66/20241/da2/EDABK_NeuronScience-master/EDABK_NeuronScience-master/Architecture/HWSW/converter/new_mem/csram_004.mem", param[4]);

logic [255:0] spike_in[NUM_PICTURE][5];
logic [255:0] spike_in_4 [NUM_PICTURE];
logic [255:0] spike_out[NUM_PICTURE][5];
logic [255:0] spike_result[NUM_PICTURE];

logic [8:0] dx, dy, axon_des;
int count = 0;
int spike_count[10];
int label_result[NUM_PICTURE];
int max_result;

initial begin
    dx = '0;
    dy = '0;
    axon_des = '0;
    for (int i_dx = 0; i_dx<4 ; i_dx++ ) begin
        for (int pic_idx = 0; pic_idx< NUM_PICTURE ; pic_idx ++) begin
            spike_in[pic_idx][i_dx] = '0;
        end
    end
end

int file, file1;

initial begin

end 

        logic [31:0] imem_base; // Base address for writing to the synapse_matrix
        logic [31:0] imem_offset;
        logic [31:0] param_base ; // Base address for Neuron Parameters
        logic [31:0] param_offset;
        logic [366:0] current_neuron_param;
        logic [31:0] omem_base;
    //logic [31:0] imem_base;

logic [31:0] un_use_data;

//assign spike_in[4]={spike_out[3][63:0], spike_out[2][63:0], spike_out[1][63:0], spike_out[0][63:0]};

initial begin
    file1 = $fopen("tb_spike_results.txt", "w");
        if (file1 == 0) begin
            $display("Lỗi: Không thể mở tệp!");
            $finish;
        end
    $display("%d %d %d %d %d %d %d %d %d %d", 0, 1, 2, 3, 4, 5, 6, 7, 8, 9);
    //#25
    rst = 1'b1; // Start with reset asserted
    wbs_cyc_i = 1'b0;
    wbs_stb_i = 1'b0;
    wbs_we_i = 1'b0;
    wbs_sel_i = 4'b0000;
    wbs_adr_i = 32'b0;
    wbs_dat_i = 32'b0;
    
    imem_base = 32'h80000000;
    param_base = 32'h80020000;
    omem_base = 32'h80040000;
    for(int j = 0 ; j < 10; j++)begin
        spike_count[j] = 0;
    end

    // Release the reset signal
    #1 rst = 1'b0;

    for (int i = 0;i < NUM_PICTURE ;i++ ) begin
        // for (int i_dx = 0; i_dx<4 ; i_dx++ ) begin
        //     spike_in[i_dx] = '0;
        // end
        for (int j = 0;j < num_pic[i] ;j++ ) begin
        //#10
            dx = packet[count][29:21];
            dy = packet[count][20:12];
            axon_des = packet[count][11:4];
            if(dy == '0)begin
                spike_in[i][dx][axon_des]=1; 
            end else begin
                spike_in[i][3][axon_des]=1;
            end
            count ++;
        end
    end

    
    
   

    ////////////////////////////////////////////////////////////////
    // Initialize variables for writing to Wishbone             //
    ////////////////////////////////////////////////////////////////
        // logic [31:0] imem_base; // Base address for writing to the synapse_matrix
        // logic [31:0] imem_offset;
        // logic [31:0] param_base ; // Base address for Neuron Parameters
        // logic [31:0] param_offset;
        // logic [366:0] current_neuron_param;
    //logic [31:0] imem_base;
    //imem_base = 32'h80000000;

    // loop for 2 core in each layer
    for(int idx = 0; idx < 2 ;idx++)begin
        rst = 1'b1; 
        #1 rst = 1'b0;
        //#20;
        //loop for set param for each neuron
        for(int core_idx=0;core_idx<2;core_idx++)begin
            for(int neuron_idx=0;neuron_idx<256;neuron_idx++)begin
                //#20
                current_neuron_param = param[core_idx+idx*2][neuron_idx];
                //#20
                wishbone_write(param_base + core_idx*32'h00010000 + neuron_idx*32'h00000100, param[core_idx+idx*2][neuron_idx][367-:32]);
                //#20
                wishbone_write(param_base + core_idx*32'h00010000 + neuron_idx*32'h00000100 + 4, current_neuron_param[335-:32]);
                //#20
                wishbone_write(param_base + core_idx*32'h00010000 + neuron_idx*32'h00000100 + 8, current_neuron_param[303-:32]);
                //#20
                wishbone_write(param_base + core_idx*32'h00010000 + neuron_idx*32'h00000100 + 12, current_neuron_param[271-:32]);
                //#20
                wishbone_write(param_base + core_idx*32'h00010000 + neuron_idx*32'h00000100 + 16, current_neuron_param[239-:32]);
                //#20
                wishbone_write(param_base + core_idx*32'h00010000 + neuron_idx*32'h00000100 + 20, current_neuron_param[207-:32]);
                //#20
                wishbone_write(param_base + core_idx*32'h00010000 + neuron_idx*32'h00000100 + 24, current_neuron_param[175-:32]);
                //#20
                wishbone_write(param_base + core_idx*32'h00010000 + neuron_idx*32'h00000100 + 28, current_neuron_param[143-:32]);
                //#20
                wishbone_write(param_base + core_idx*32'h00010000 + neuron_idx*32'h00000100 + 32, current_neuron_param[111-:32]);
                //#20
                wishbone_write(param_base + core_idx*32'h00010000 + neuron_idx*32'h00000100 + 36, current_neuron_param[79-:32]);
                //#20
                wishbone_write(param_base + core_idx*32'h00010000 + neuron_idx*32'h00000100 + 40, current_neuron_param[47-:32]);
                //#20
                wishbone_write(param_base + core_idx*32'h00010000 + neuron_idx*32'h00000100 + 44, {current_neuron_param[15:0],'0});
            end
            $display("intit param for core %d", core_idx+idx*2);
        end

        for(int pic_idx=0;pic_idx<NUM_PICTURE;pic_idx++)begin
            for(int core_idx=0;core_idx<2;core_idx=core_idx+1)begin
                //#20
                wishbone_write('0, '0);
                //#20
                wishbone_write(imem_base + core_idx*32'h00010000, spike_in[pic_idx][core_idx+idx*2][255-:32]);
                //wishbone_write(imem_base, spike_in[pic_idx][core_idx+idx*2][255-:32]); //-> this draft, comment this when running sti
                //#40
                wishbone_write(imem_base + core_idx*32'h00010000 + 4, spike_in[pic_idx][core_idx+idx*2][223-:32]);
                //#20
                wishbone_write(imem_base + core_idx*32'h00010000 + 8, spike_in[pic_idx][core_idx+idx*2][191-:32]);
                //#20
                wishbone_write(imem_base + core_idx*32'h00010000 + 12, spike_in[pic_idx][core_idx+idx*2][159-:32]);
                //#20
                wishbone_write(imem_base + core_idx*32'h00010000 + 16, spike_in[pic_idx][core_idx+idx*2][127-:32]);
                //#20
                wishbone_write(imem_base + core_idx*32'h00010000 + 20, spike_in[pic_idx][core_idx+idx*2][95-:32]);
                //#20
                wishbone_write(imem_base + core_idx*32'h00010000 + 24, spike_in[pic_idx][core_idx+idx*2][63-:32]);
                //#20
                wishbone_write(imem_base + core_idx*32'h00010000 + 28, spike_in[pic_idx][core_idx+idx*2][31-:32]);
                $display("intit spike for core %d, picture %d", core_idx+idx*2, pic_idx);
            end

            //#20;
            //#20; //enable calc
            wishbone_read(32'h80360000, un_use_data);
            $display("enable calc for picture %d", pic_idx);
            
            //#20;
            for(int core_idx=0;core_idx<2;core_idx=core_idx+1)begin
                //#20
                wishbone_read(omem_base + core_idx*32'h00010000, spike_out[pic_idx][core_idx+idx*2][255-:32]);
                //#20
                wishbone_read(omem_base + core_idx*32'h00010000 + 4, spike_out[pic_idx][core_idx+idx*2][223-:32]);
                //#20
                wishbone_read(omem_base + core_idx*32'h00010000 + 8, spike_out[pic_idx][core_idx+idx*2][191-:32]);
                //#20
                wishbone_read(omem_base + core_idx*32'h00010000 + 12, spike_out[pic_idx][core_idx+idx*2][159-:32]);
                //#20
                wishbone_read(omem_base + core_idx*32'h00010000 + 16, spike_out[pic_idx][core_idx+idx*2][127-:32]);
                //#20
                wishbone_read(omem_base + core_idx*32'h00010000 + 20, spike_out[pic_idx][core_idx+idx*2][95-:32]);
                //#20
                wishbone_read(omem_base + core_idx*32'h00010000 + 24, spike_out[pic_idx][core_idx+idx*2][63-:32]);
                //#20
                wishbone_read(omem_base + core_idx*32'h00010000 + 28, spike_out[pic_idx][core_idx+idx*2][31-:32]);
                $display("get spike for core %d, picture %d", core_idx+idx*2, pic_idx);
            end
        end 
    end

    for(int pic_idx = 0; pic_idx < NUM_PICTURE; pic_idx++)begin
        spike_in[pic_idx][4] = {spike_out[pic_idx][3][63:0], spike_out[pic_idx][2][63:0], spike_out[pic_idx][1][63:0], spike_out[pic_idx][0][63:0]};
    end

    ////////////////////////////////////////////////////////////////
    //last_core
    //#20;
    rst = 1'b1; 
    #1 rst = 1'b0;
    for(int neuron_idx=0;neuron_idx<256;neuron_idx++)begin
        //#20
        current_neuron_param = param[4][neuron_idx];
        //#20
        wishbone_write(param_base + neuron_idx*32'h00000100, param[4][neuron_idx][367-:32]);
        //#20
        wishbone_write(param_base + neuron_idx*32'h00000100 + 4, current_neuron_param[335-:32]);
        //#20
        wishbone_write(param_base + neuron_idx*32'h00000100 + 8, current_neuron_param[303-:32]);
        //#20
        wishbone_write(param_base + neuron_idx*32'h00000100 + 12, current_neuron_param[271-:32]);
        //#20
        wishbone_write(param_base + neuron_idx*32'h00000100 + 16, current_neuron_param[239-:32]);
        //#20
        wishbone_write(param_base + neuron_idx*32'h00000100 + 20, current_neuron_param[207-:32]);
        //#20
        wishbone_write(param_base + neuron_idx*32'h00000100 + 24, current_neuron_param[175-:32]);
        //#20
        wishbone_write(param_base + neuron_idx*32'h00000100 + 28, current_neuron_param[143-:32]);
        //#20
        wishbone_write(param_base + neuron_idx*32'h00000100 + 32, current_neuron_param[111-:32]);
        //#20
        wishbone_write(param_base + neuron_idx*32'h00000100 + 36, current_neuron_param[79-:32]);
        //#20
        wishbone_write(param_base + neuron_idx*32'h00000100 + 40, current_neuron_param[47-:32]);
        //#20
        wishbone_write(param_base + neuron_idx*32'h00000100 + 44, {current_neuron_param[15:0],'0});
    end
    $display("intit param for core %d", 4);
        //for(int core_idx=0;core_idx<2;core_idx=core_idx+1)begin
            //#20

    for(int pic_idx = 0; pic_idx < NUM_PICTURE; pic_idx++)begin
        for(int j = 0 ; j < 10; j++)begin
            spike_count[j] = 0;
        end
            wishbone_write('0, '0);
            //#20
            wishbone_write(imem_base, spike_in[pic_idx][4][255-:32]);
            //#20
            wishbone_write(imem_base + 4, spike_in[pic_idx][4][223-:32]);
            //#20
            wishbone_write(imem_base + 8, spike_in[pic_idx][4][191-:32]);
            //#20
            wishbone_write(imem_base + 12, spike_in[pic_idx][4][159-:32]);
            //#20
            wishbone_write(imem_base + 16, spike_in[pic_idx][4][127-:32]);
            //#20
            wishbone_write(imem_base + 20, spike_in[pic_idx][4][95-:32]);
            //#20
            wishbone_write(imem_base + 24, spike_in[pic_idx][4][63-:32]);
            //#20
            wishbone_write(imem_base + 28, spike_in[pic_idx][4][31-:32]);
            //$display("intit spike for core %d, picture %d", 4, pic_idx);
        //end

        //#20;
        //for(int core_idx=0;core_idx<2;core_idx++)begin
            
        //end

        //#20; //enable calc
            wishbone_read(32'h80360000, un_use_data);
            //$display("enable calc for picture %d", pic_idx);
        
        //#20;
        //for(int core_idx=0;core_idx<2;core_idx=core_idx+1)begin
            //#20
            wishbone_read(omem_base, spike_out[pic_idx][4][255-:32]);
            //#20
            wishbone_read(omem_base + 4, spike_out[pic_idx][4][223-:32]);
            //#20
            wishbone_read(omem_base + 8, spike_out[pic_idx][4][191-:32]);
            //#20
            wishbone_read(omem_base + 12, spike_out[pic_idx][4][159-:32]);
            //#20
            wishbone_read(omem_base + 16, spike_out[pic_idx][4][127-:32]);
            //#20
            wishbone_read(omem_base + 20, spike_out[pic_idx][4][95-:32]);
            //#20
            wishbone_read(omem_base + 24, spike_out[pic_idx][4][63-:32]);
            //#20
            wishbone_read(omem_base + 28, spike_out[pic_idx][4][31-:32]);
        //end
    
        spike_result[pic_idx]=spike_out[pic_idx][4];
        for(int j = 0; j<250; j++)begin
            if(spike_result[pic_idx][j]==1)begin
                spike_count[j%10]++;
            end
            $fwrite(file1, "%d", spike_result[pic_idx][j]);
        end
        $fwrite(file1, "\n");
        max_result = spike_count[0];
        label_result[pic_idx] = 0;
        for(int j = 1 ; j<10; j++)begin
            if(max_result < spike_count[j])begin
                max_result = spike_count[j];
                label_result[pic_idx] = j;
            end
        end
        $display("Result picture %d: %d, %8b", pic_idx, label_result[pic_idx], label_result[pic_idx]);
        //$display("%h, %b", spike_result[pic_idx], spike_result[pic_idx]);
        
        //$display("%d %d %d %d %d %d %d %d %d %d", spike_count[0], spike_count[1], spike_count[2], spike_count[3], spike_count[4], spike_count[5], spike_count[6], spike_count[7], spike_count[8], spike_count[9]);
    end
        
        file = $fopen("tb_spike_results.txt", "w");
        if (file == 0) begin
            $display("Lỗi: Không thể mở tệp!");
            $finish;
        end
        file1 = $fopen("tb_spike_results_bin.txt", "w");
        if (file1 == 0) begin
            $display("Lỗi: Không thể mở tệp!");
            $finish;
        end

        //Ghi từng hàng một
        for (int i = 0; i < NUM_PICTURE; i = i + 1) begin
            //for (int j = 0; j < 256; j = j + 1) begin
                //#2
                //$display("%b", spike_result[i]); // Ghi các phần tử trên cùng một dòng
            //end
            $fwrite(file, "%8b\n", label_result[i]); // Ghi các phần tử trên cùng một dòng
            $fwrite(file1, "%b\n", spike_result[i]);
            //#1;
            //$display("Done!");
            //$display("\n"); // Xuống dòng sau mỗi hàng

        end

        //Đóng tệp
        $display("Done!");
        $fclose(file);
        $fclose(file1);
        
        $finish;
end









endmodule