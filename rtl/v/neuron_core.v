module neuron_core #(
    parameter NUM_AXONS = 256,
    parameter LEAK_WIDTH = 9,
    parameter WEIGHT_WIDTH = 2,
    parameter THRESHOLD_WIDTH = 9,
    parameter POTENTIAL_WIDTH = 9,
    parameter NUM_WEIGHTS = 4,
    parameter NUM_RESET_MODES = 2,

    parameter IMEM_BASE_0 = 32'h80000000,
    parameter IMEM_BASE_1 = 32'h80010000,

    parameter PARAM_BASE = 32'h80020000,
    parameter PARAM_JUMP = 32'h00000100,

    parameter OMEM_BASE_0 = 32'h80040000,
    parameter OMEM_BASE_1 = 32'h80050000
) (
    input wb_clk_i,             // Clock
    input wb_rst_i,             // Reset
    input wbs_cyc_i,            // Indicates an active Wishbone cycle
    input wbs_stb_i,            // Active during a valid address phase
    input wbs_we_i,             // Determines read or write operation
    input [3:0] wbs_sel_i,      // Byte lanes selector
    input [31:0] wbs_adr_i,     // Address input
    input [31:0] wbs_dat_i,     // Data input for writes
    output wbs_ack_o,       // Acknowledgment for data transfer
    output [31:0] wbs_dat_o, // Data output

    input calc_en_i,
    input param_in_en_i,
    input [255:0] spike_axon_i,

    output [255:0] spike_neuron_o
);


    generate
        for(genvar i = 0; i<NUM_AXONS;i=i+1)begin 
            wire [NUM_AXONS-1:0] connections;
            wire signed [LEAK_WIDTH-1:0] leak;
            wire signed [WEIGHT_WIDTH-1:0] weights_0;
            wire signed [WEIGHT_WIDTH-1:0] weights_1;
            wire signed [THRESHOLD_WIDTH-1:0] positive_threshold;
            wire signed [THRESHOLD_WIDTH-1:0] negative_threshold;
            wire signed [POTENTIAL_WIDTH-1:0] reset_potential;
            wire signed [POTENTIAL_WIDTH-1:0] current_potential;
            wire signed [$clog2(NUM_RESET_MODES)-1:0] reset_mode;
                        

            parameter_v #(
                .PARAM_BASE(PARAM_BASE + i*PARAM_JUMP)
            ) param (
                .wb_clk_i(wb_clk_i),
                .wb_rst_i(wb_rst_i),
                .wbs_cyc_i(wbs_cyc_i & param_in_en_i),
                .wbs_stb_i(wbs_stb_i & param_in_en_i),
                .wbs_we_i(wbs_we_i & param_in_en_i),
                .wbs_sel_i(wbs_sel_i),
                .wbs_adr_i(wbs_adr_i),
                .wbs_dat_i(wbs_dat_i),
                .wbs_ack_o(),
                .wbs_dat_o(),
                
                .enable_calc_i(calc_en_i),
                
                .connections_o(connections),
                .leak_o(leak),
                .weights_0_o(weights_0),
                .weights_1_o(weights_1),
                .positive_threshold_o(positive_threshold),
                .negative_threshold_o(negative_threshold),
                .reset_potential_o(reset_potential),
                .current_potential_o(current_potential),
                .reset_mode_o(reset_mode)
            );

            neuron_block #(
                //.NUM_AXONS(256),
                //.LEAK_WIDTH(9),
                //.WEIGHT_WIDTH(9),
                //.THRESHOLD_WIDTH(9),
                //.POTENTIAL_WIDTH(9),
                //.NUM_WEIGHTS(4),
                //.NUM_RESET_MODES(2)
            ) neuron_block (
                .leak_i(leak),
                .weights_0_i(weights_0),
                .weights_1_i(weights_1),
                .positive_threshold_i(positive_threshold),
                .negative_threshold_i(negative_threshold),
                .reset_potential_i(reset_potential),
                .current_potential_i(current_potential),
                .reset_mode_i(reset_mode),
                .synapses_in_i(connections),
                .axon_in_i(spike_axon_i),
                .write_potential_o(),
                .spike_o(spike_neuron_o[i])
            );
        end
    endgenerate

endmodule