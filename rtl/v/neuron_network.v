(* use_dsp =  "yes" *)module neuron_network #(
    parameter NUM_AXONS = 256,
    parameter LEAK_WIDTH = 9,
    parameter WEIGHT_WIDTH = 9,
    parameter THRESHOLD_WIDTH = 9,
    parameter POTENTIAL_WIDTH = 9,
    parameter NUM_WEIGHTS = 4,
    parameter NUM_RESET_MODES = 2,
    parameter NUM_CORE = 2,

    parameter IMEM_BASE_0 = 32'h80000000,
    parameter IMEM_BASE_1 = 32'h80010000,

    parameter PARAM_BASES = 32'h80020000,
    parameter PARAM_JUMP = 32'h00010000,
    //parameter PARAM_BASE_1 = 32'h80030000,

    parameter OMEM_BASE_0 = 32'h80040000,
    parameter OMEM_BASE_1 = 32'h80050000

) (
    input clk_i,             // Clock
    input wb_rst_i,             // Reset
    input wbs_cyc_i,            // Indicates an active Wishbone cycle
    input wbs_stb_i,            // Active during a valid address phase
    input wbs_we_i,             // Determines read or write operation
    input [3:0] wbs_sel_i,      // Byte lanes selector
    input [31:0] wbs_adr_i,     // Address input
    input [31:0] wbs_dat_i,     // Data input for writes
    output wbs_ack_o,       // Acknowledgment for data transfer
    output [31:0] wbs_dat_o // Data output
);

    wire [1:0] core_en;
    wire spike_in_en;
    wire param_in_en;
    wire spike_out_en;
    wire [1:0] calc_en;

    wire [255:0] spike_axon [1:0];
    wire [255:0] spike_neuron [1:0];
    reg [1:0] neuron_calc_en;
    
    decoder #(
        
    ) decoder (
        .addr_i(wbs_adr_i),
        .core_0_en_o(core_en[0]),
        .core_1_en_o(core_en[1]),
        .spike_in_en_o(spike_in_en),
        .param_in_en_o(param_in_en),
        .spike_out_en_o(spike_out_en),
        .enable_calc_o(calc_en)
    );


    /////////////////////////////
    ///////      IMEM    ////////
    /////////////////////////////
    imem #(
        .NUM_AXONS(256),
        .IMEM_BASE_0(IMEM_BASE_0),
        .IMEM_BASE_1(IMEM_BASE_1)
    ) imem (
        .wb_clk_i(clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_cyc_i(wbs_cyc_i & spike_in_en),
        .wbs_stb_i(wbs_stb_i & spike_in_en),
        .wbs_we_i(wbs_we_i & spike_in_en),
        .wbs_sel_i(wbs_sel_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_ack_o(),
        .wbs_dat_o(),
        //.calc_en_i(calc_en),
        .core_en_i(core_en),
        .spike_axon_0_o(spike_axon[0]),
        .spike_axon_1_o(spike_axon[1])
    );

    generate
        genvar i;
        for(genvar i = 0 ; i < NUM_CORE ; i = i+ 1)begin
            neuron_core #(
 //               .NUM_AXONS(NUM_AXONS),
 //               .LEAK_WIDTH(LEAK_WIDTH),
 //               .WEIGHT_WIDTH(WEIGHT_WIDTH),
 //               .THRESHOLD_WIDTH(THRESHOLD_WIDTH),
 //               .POTENTIAL_WIDTH(POTENTIAL_WIDTH),
//                .NUM_WEIGHTS(NUM_WEIGHTS),
 //               .NUM_RESET_MODES(NUM_RESET_MODES),
                .PARAM_BASE(PARAM_BASES + i*PARAM_JUMP)
            ) neuron_core (
                .wb_clk_i(clk_i),
                .wb_rst_i(wb_rst_i),
                .wbs_cyc_i(wbs_cyc_i),
                .wbs_stb_i(wbs_stb_i),
                .wbs_we_i(wbs_we_i),
                .wbs_sel_i(wbs_sel_i),
                .wbs_adr_i(wbs_adr_i),
                .wbs_dat_i(wbs_dat_i),
                .wbs_ack_o(),
                .wbs_dat_o(),

                .param_in_en_i(param_in_en),
                .spike_axon_i(spike_axon[i]),
                .spike_neuron_o(spike_neuron[i])
            );
        end
    endgenerate

    /////////////////////////////
    ///////      OMEM    ////////
    /////////////////////////////    
    omem #(
        .NUM_AXONS(256),
        .OMEM_BASE_0(OMEM_BASE_0),
        .OMEM_BASE_1(OMEM_BASE_1)
    ) omem (
        .wb_clk_i(clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_cyc_i(wbs_cyc_i & spike_out_en),
        .wbs_stb_i(wbs_stb_i & spike_out_en),
        .wbs_we_i(wbs_we_i & spike_out_en),
        .wbs_sel_i(wbs_sel_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_ack_o(wbs_ack_o),
        .wbs_dat_o(wbs_dat_o),

        .enable_calc_i(calc_en),
        .core_en_i(core_en),
        .spike_neuron_0_i(spike_neuron[0]),
        .spike_neuron_1_i(spike_neuron[1])
    );



endmodule