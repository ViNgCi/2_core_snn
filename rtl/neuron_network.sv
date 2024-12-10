module neuron_network_sv #(
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

    parameter PARAM_BASE = 32'h80020000,

    parameter OMEM_BASE_0 = 32'h80040000,
    parameter OMEM_BASE_1 = 32'h80050000

) (
    input logic wb_clk_i,             // Clock
    input logic wb_rst_i,             // Reset
    input logic wbs_cyc_i,            // Indicates an active Wishbone cycle
    input logic wbs_stb_i,            // Active during a valid address phase
    input logic wbs_we_i,             // Determines read or write operation
    input logic [3:0] wbs_sel_i,      // Byte lanes selector
    input logic [31:0] wbs_adr_i,     // Address input
    input logic [31:0] wbs_dat_i,     // Data input for writes
    output logic wbs_ack_o,       // Acknowledgment for data transfer
    output logic [31:0] wbs_dat_o // Data output
);

    logic [1:0] core_en;
    logic spike_in_en;
    logic param_in_en;
    logic spike_out_en;
    logic [1:0] calc_en;

    logic [255:0] spike_axon [1:0];
    logic [255:0] spike_neuron [1:0];
    
    decoder_sv #(
        
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
    imem_sv #(
        .NUM_AXONS(256),
        .IMEM_BASE_0(IMEM_BASE_0),
        .IMEM_BASE_1(IMEM_BASE_1)
    ) imem (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_cyc_i(wbs_cyc_i & spike_in_en),
        .wbs_stb_i(wbs_stb_i & spike_in_en),
        .wbs_we_i(wbs_we_i & spike_in_en),
        .wbs_sel_i(wbs_sel_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_ack_o(),
        .wbs_dat_o(),
        .core_en_i(core_en),
        .spike_axon_0_o(spike_axon[0]),
        .spike_axon_1_o(spike_axon[1])
    );


generate
    for(genvar i = 0 ; i < NUM_CORE ; i = i+ 1)begin
        neuron_core_sv #(
            .NUM_AXONS(NUM_AXONS),
            .LEAK_WIDTH(LEAK_WIDTH),
            .WEIGHT_WIDTH(WEIGHT_WIDTH),
            .THRESHOLD_WIDTH(THRESHOLD_WIDTH),
            .POTENTIAL_WIDTH(POTENTIAL_WIDTH),
            .NUM_WEIGHTS(NUM_WEIGHTS),
            .NUM_RESET_MODES(NUM_RESET_MODES),
            .PARAM_BASE(PARAM_BASE + i*32'h00010000)
        ) neuron_core (
            .wb_clk_i(wb_clk_i),
            .wb_rst_i(wb_rst_i),
            .wbs_cyc_i(wbs_cyc_i),
            .wbs_stb_i(wbs_stb_i),
            .wbs_we_i(wbs_we_i),
            .wbs_sel_i(wbs_sel_i),
            .wbs_adr_i(wbs_adr_i),
            .wbs_dat_i(wbs_dat_i),
            .wbs_ack_o(),
            .wbs_dat_o(),

            .calc_en_i(calc_en[i]),
            .param_in_en_i(param_in_en),
            .spike_axon_i(spike_axon[i]),

            .spike_neuron_o(spike_neuron[i])
        );
    end
endgenerate

///////////////////////////////////////////
//  OLD CODE FOR GENERATE NEURON BLOCK   //
///////////////////////////////////////////
//           UNUSED CODE                 //
///////////////////////////////////////////

// generate
//     for (genvar ij_index = 0; ij_index < 512; ij_index++) begin
//         localparam int i = ij_index / 256;
//         localparam int j = ij_index % 256;
//     //neuron_block
//         // genvar i;
//         // genvar j;
//     //genvar ij;
//     //generate
//         //for (i = 0; i < 512 ; i = i+1 ) begin
//         // for(genvar ij=0; ij<512; ij++) begin
//         //     localparam int i = ij / 256;
//         //     localparam int j = ij % 256;
//             // localparam int i = i_j/256;
//             // localparam int j = i_j%256;
//             //for (j = 0; j < 256; j=j+1) begin
//                 logic [NUM_AXONS-1:0] connections;
//                 logic signed [LEAK_WIDTH-1:0] leak;
//                 logic signed [WEIGHT_WIDTH-1:0] weights_0;
//                 logic signed [WEIGHT_WIDTH-1:0] weights_1;
//                 logic signed [THRESHOLD_WIDTH-1:0] positive_threshold;
//                 logic signed [THRESHOLD_WIDTH-1:0] negative_threshold;
//                 logic signed [POTENTIAL_WIDTH-1:0] reset_potential;
//                 logic signed [POTENTIAL_WIDTH-1:0] current_potential;
//                 logic signed [$clog2(NUM_RESET_MODES)-1:0] reset_mode;
                
//                 //localparam NEURON_PARAM_BASE = PARAM_BASE + (i<<16)+j;
            
//                 parameter_sv #(
//                     .NUM_RESET_MODES(2),
//                     .PARAM_BASE(PARAM_BASE + i*32'h00010000 +j*32'h00000100)
//                 ) param (
//                     .wb_clk_i(wb_clk_i),
//                     .wb_rst_i(wb_rst_i),
//                     .wbs_cyc_i(wbs_cyc_i & param_in_en),
//                     .wbs_stb_i(wbs_stb_i & param_in_en),
//                     .wbs_we_i(wbs_we_i & param_in_en),
//                     .wbs_sel_i(wbs_sel_i),
//                     .wbs_adr_i(wbs_adr_i),
//                     .wbs_dat_i(wbs_dat_i),
//                     .wbs_ack_o(),
//                     .wbs_dat_o(),
                    
//                     .enable_calc_i(calc_en[i]),
                    
//                     .connections_o(connections),
//                     .leak_o(leak),
//                     .weights_0_o(weights_0),
//                     .weights_1_o(weights_1),
//                     .positive_threshold_o(positive_threshold),
//                     .negative_threshold_o(negative_threshold),
//                     .reset_potential_o(reset_potential),
//                     .current_potential_o(current_potential),
//                     .reset_mode_o(reset_mode)
//                 );

//                 neuron_block_sv #(
//                     //.NUM_AXONS(256),
//                     //.LEAK_WIDTH(9),
//                     //.WEIGHT_WIDTH(9),
//                     //.THRESHOLD_WIDTH(9),
//                     //.POTENTIAL_WIDTH(9),
//                     //.NUM_WEIGHTS(4),
//                     //.NUM_RESET_MODES(2)
//                 ) neuron_block (
//                     .clk_i(wb_clk_i),
//                     .rst_n_i(wb_rst_i),
//                     .leak_i(leak),
//                     .weights_0_i(weights_0),
//                     .weights_1_i(weights_1),
//                     .positive_threshold_i(positive_threshold),
//                     .negative_threshold_i(negative_threshold),
//                     .reset_potential_i(reset_potential),
//                     .current_potential_i(current_potential),
//                     .reset_mode_i(reset_mode),
//                     .synapses_in_i(connections),
//                     .axon_in_i(spike_axon[i]),
//                     .write_potential_o(ext_current_potential),
//                     .spike_o(spike_neuron[i][j])
//                 );
//             //end   
//         end
        
//     endgenerate

    /////////////////////////////
    ///////      OMEM    ////////
    /////////////////////////////    
    omem_sv #(
        .NUM_AXONS(256),
        .OMEM_BASE_0(OMEM_BASE_0),
        .OMEM_BASE_1(OMEM_BASE_1)
    ) omem (
        .wb_clk_i(wb_clk_i),
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