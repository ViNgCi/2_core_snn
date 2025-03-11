module integrator_sv #(
    parameter NUM_AXONS = 256,
    parameter LEAK_WIDTH = 9,
    parameter WEIGHT_WIDTH = 9,
    parameter THRESHOLD_WIDTH = 9,
    parameter POTENTIAL_WIDTH = 9,
    parameter NUM_WEIGHTS = 4,
    parameter NUM_RESET_MODES = 2 
) (
    input logic signed [WEIGHT_WIDTH-1:0] weights_i,
    input logic axon_in_i,
    input logic synapses_in_i,

    output logic [THRESHOLD_WIDTH-1:0] axon_calc_potential_o
);

    always_comb begin : integrator_cal
        axon_calc_potential_o = (axon_in_i&synapses_in_i) ? selected_weight : 9'b000000000;
    end
    
endmodule