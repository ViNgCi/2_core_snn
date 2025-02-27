(* use_dsp =  "yes" *)
module neuron_block #(
    parameter NUM_AXONS = 256,
    parameter LEAK_WIDTH = 9,
    parameter WEIGHT_WIDTH = 2,
    parameter THRESHOLD_WIDTH = 9,
    parameter POTENTIAL_WIDTH = 9,
    parameter NUM_WEIGHTS = 4,
    parameter NUM_RESET_MODES = 2 
) (
    input clk_i,
    input rst_n_i,
    input enable_calc_i,
    input signed [LEAK_WIDTH-1:0] leak_i,
    input signed [WEIGHT_WIDTH-1:0] weights_0_i,
    input signed [WEIGHT_WIDTH-1:0] weights_1_i,
    input signed [THRESHOLD_WIDTH-1:0] positive_threshold_i,
    input signed [THRESHOLD_WIDTH-1:0] negative_threshold_i,
    input signed [POTENTIAL_WIDTH-1:0] reset_potential_i,
    input signed [POTENTIAL_WIDTH-1:0] current_potential_i,
    input signed [$clog2(NUM_RESET_MODES)-1:0] reset_mode_i,
    input signed [NUM_AXONS-1:0] synapses_in_i,
    input signed [NUM_AXONS-1:0] axon_in_i,

    output reg signed [POTENTIAL_WIDTH-1:0] write_potential_o,
    output spike_valid_o,
    output reg spike_o
);

    reg signed [POTENTIAL_WIDTH-1:0] calc_leak_potential;
    reg signed [POTENTIAL_WIDTH-1:0] pre_calc_leak_potential;
    reg signed lower_neg_threshold;
    reg signed upper_pos_threshold;
    reg signed [WEIGHT_WIDTH-1:0] axon_calc_potential [NUM_AXONS-1:0] ;
    wire signed [POTENTIAL_WIDTH-1:0] calc_potential;
    wire signed [WEIGHT_WIDTH-1:0] selected_weight [NUM_AXONS-1:0];
    //logic signed [WEIGHT_WIDTH-1:0] pre_selected_weight [NUM_AXONS];

    reg [NUM_AXONS-1:0] enable_synapse;


    generate
        genvar i;
        for (i = 0;i<NUM_AXONS/2 ; i=i+1) begin
            assign selected_weight[i*2] = weights_0_i;
            assign selected_weight[i*2+1] = weights_1_i;
        end
        // for (i = 0;i<NUM_AXONS ; i=i+1) begin
        //     assign enable_synapse[i] = synapses_in_i[i]&axon_in_i[i];
        // end
    endgenerate
    
    wire signed [(WEIGHT_WIDTH*NUM_AXONS-1):0] calc_potential_data;

    generate
        //genvar i;
        for (i = 0; i < NUM_AXONS; i=i+1) begin
            always @(*) begin
                enable_synapse[i] = synapses_in_i[i] & axon_in_i[i];
                if(enable_synapse[i]) begin
                    axon_calc_potential[i] = selected_weight[i];
                end else begin
                    axon_calc_potential[i] = 2'b00;
                end

                //axon_calc = enable_synapse & selected_weight + ~enable_synapse & 2'b00;

                // axon_calc_potential[i] = (enable_synapse[i]) ? selected_weight[i] : 2'b00;
            end
            assign calc_potential_data[(i+1)*WEIGHT_WIDTH-1:i*WEIGHT_WIDTH] = axon_calc_potential[i];
        end
    endgenerate    
    

    reconfig_adder_tree adder_tree_inst (
        .clk(clk_i),
        //.rst_n(rst_n_i),
        .enable_calc_i(enable_calc_i),
        .inputs_i(calc_potential_data),
        .sum_out(calc_potential),
        .valid_o(spike_valid_o)
    );

    reg spike_check;

    always @(*) begin : potential_calc
        pre_calc_leak_potential = current_potential_i + leak_i;
        calc_leak_potential = calc_potential + pre_calc_leak_potential;
        lower_neg_threshold = (calc_leak_potential < negative_threshold_i) ? 1'b1 : 1'b0;
        upper_pos_threshold = (calc_leak_potential > positive_threshold_i) ? 1'b1 : 1'b0; 
        spike_check = (upper_pos_threshold || lower_neg_threshold);      
        spike_o = upper_pos_threshold;
        write_potential_o =(spike_check) ? reset_potential_i : calc_leak_potential;
    end
endmodule