`timescale 1ns/1ps

module tb_neuron_core;
    parameter NUM_OUTPUT = 250; // Number of spikes
    parameter NUM_PICTURE = 50; // Number of test images
    parameter NUM_PACKET = 1444; // Number of input packets in file
    
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

neuron_core_sv uut_neuron_core(
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

logic [7:0] num_pic [0:NUM_PICTURE - 1];
initial $readmemh("tb_num_inputs_hex.txt", num_pic);

logic [31:0] packet [0:NUM_PACKET-1];
initial $readmemb("tb_input.txt", packet);

logic [367:0] param [5][256];
initial $readmemb("csram_000.mem", param[0]);
initial $readmemb("csram_001.mem", param[1]);
initial $readmemb("csram_002.mem", param[2]);
initial $readmemb("csram_003.mem", param[3]);
initial $readmemb("csram_004.mem", param[4]);

logic [255:0] spike_in[5];
logic [8:0] dx, dy, axon_des;
int count = 0;

initial begin
    dx = '0;
    dy = '0;
    axon_des = '0;
    for (int i_dx = 0; i_dx<5 ; i_dx++ ) begin
        spike_in[i_dx] = '0;
    end
end

        logic [31:0] imem_base; // Base address for writing to the synapse_matrix
        logic [31:0] imem_offset;
        logic [31:0] param_base ; // Base address for Neuron Parameters
        logic [31:0] param_offset;
        logic [366:0] current_neuron_param;
        logic [31:0] omem_base;
    //logic [31:0] imem_base;

logic [31:0] un_use_data;

initial begin
    #25
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

    // Release the reset signal
    #20 rst = 1'b0;

    for (int i = 0;i < 10 ;i++ ) begin
        for (int i_dx = 0; i_dx<5 ; i_dx++ ) begin
            spike_in[i_dx] = '0;
        end
        for (int j = 0;j < num_pic[i] ;j++ ) begin
        #10
            dx = packet[count][29:21];
            dy = packet[count][20:12];
            axon_des = packet[count][11:4];
            spike_in[dx][axon_des]=1; 
            count ++;
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



    #20;
    for(int core_idx=0;core_idx<2;core_idx=core_idx+1)begin
        #20
        wishbone_write('0, '0);
        #20
        wishbone_write(imem_base + core_idx*32'h00010000, spike_in[core_idx][255-:32]);
        #20
        wishbone_write(imem_base + core_idx*32'h00010000 + 4, spike_in[core_idx][223-:32]);
        #20
        wishbone_write(imem_base + core_idx*32'h00010000 + 8, spike_in[core_idx][191-:32]);
        #20
        wishbone_write(imem_base + core_idx*32'h00010000 + 12, spike_in[core_idx][159-:32]);
        #20
        wishbone_write(imem_base + core_idx*32'h00010000 + 16, spike_in[core_idx][127-:32]);
        #20
        wishbone_write(imem_base + core_idx*32'h00010000 + 20, spike_in[core_idx][95-:32]);
        #20
        wishbone_write(imem_base + core_idx*32'h00010000 + 24, spike_in[core_idx][63-:32]);
        #20
        wishbone_write(imem_base + core_idx*32'h00010000 + 28, spike_in[core_idx][31-:32]);
    end

    #20;
    for(int core_idx=0;core_idx<2;core_idx++)begin
        for(int neuron_idx=0;neuron_idx<256;neuron_idx++)begin
            #20
            current_neuron_param = param[core_idx][neuron_idx];
            #20
            wishbone_write(param_base + core_idx*32'h00010000 + neuron_idx*32'h00000100, param[core_idx][neuron_idx][367-:32]);
            #20
            wishbone_write(param_base + core_idx*32'h00010000 + neuron_idx*32'h00000100 + 4, current_neuron_param[335-:32]);
            #20
            wishbone_write(param_base + core_idx*32'h00010000 + neuron_idx*32'h00000100 + 8, current_neuron_param[303-:32]);
            #20
            wishbone_write(param_base + core_idx*32'h00010000 + neuron_idx*32'h00000100 + 12, current_neuron_param[271-:32]);
            #20
            wishbone_write(param_base + core_idx*32'h00010000 + neuron_idx*32'h00000100 + 16, current_neuron_param[239-:32]);
            #20
            wishbone_write(param_base + core_idx*32'h00010000 + neuron_idx*32'h00000100 + 20, current_neuron_param[207-:32]);
            #20
            wishbone_write(param_base + core_idx*32'h00010000 + neuron_idx*32'h00000100 + 24, current_neuron_param[175-:32]);
            #20
            wishbone_write(param_base + core_idx*32'h00010000 + neuron_idx*32'h00000100 + 28, current_neuron_param[143-:32]);
            #20
            wishbone_write(param_base + core_idx*32'h00010000 + neuron_idx*32'h00000100 + 32, current_neuron_param[111-:32]);
            #20
            wishbone_write(param_base + core_idx*32'h00010000 + neuron_idx*32'h00000100 + 36, current_neuron_param[79-:32]);
            #20
            wishbone_write(param_base + core_idx*32'h00010000 + neuron_idx*32'h00000100 + 40, current_neuron_param[47-:32]);
            #20
            wishbone_write(param_base + core_idx*32'h00010000 + neuron_idx*32'h00000100 + 44, {current_neuron_param[15:0],'0});
        end
    end

    #20; //enable calc
    wishbone_read(32'h80360000, un_use_data);
    
    #20;
    for(int core_idx=0;core_idx<2;core_idx=core_idx+1)begin
        #20
        wishbone_read(omem_base + core_idx*32'h00010000, spike_in[core_idx][255-:32]);
        #20
        wishbone_read(omem_base + core_idx*32'h00010000 + 4, spike_in[core_idx][223-:32]);
        #20
        wishbone_read(omem_base + core_idx*32'h00010000 + 8, spike_in[core_idx][191-:32]);
        #20
        wishbone_read(omem_base + core_idx*32'h00010000 + 12, spike_in[core_idx][159-:32]);
        #20
        wishbone_read(omem_base + core_idx*32'h00010000 + 16, spike_in[core_idx][127-:32]);
        #20
        wishbone_read(omem_base + core_idx*32'h00010000 + 20, spike_in[core_idx][95-:32]);
        #20
        wishbone_read(omem_base + core_idx*32'h00010000 + 24, spike_in[core_idx][63-:32]);
        #20
        wishbone_read(omem_base + core_idx*32'h00010000 + 28, spike_in[core_idx][31-:32]);
    end
    

    end
end









endmodule