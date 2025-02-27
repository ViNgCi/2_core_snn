`timescale 1ns / 1ps

(*use_dsp = "yes" *)
module ReconfigurableAdder #(parameter N = 2)(
    input signed [N-1:0] A, B,
    input enable_i,
    //output reg valid_o,
    output reg signed [N:0] SUM,
    input clk
);
    
    always @(posedge clk) begin
        //valid_o <= enable_i;
        if (enable_i) begin
            SUM <= A + B;
        end
    end
    
endmodule

module reconfig_adder_tree #(parameter N = 2, parameter NUM_INPUTS = 256, parameter OUT_WIDTH = 9)(
    input signed [N*NUM_INPUTS-1:0] inputs_i,
    input clk,
    input enable_calc_i,
    output signed [OUT_WIDTH-1:0] sum_out,
    output valid_o
);
    wire signed [N-1:0] inputs [NUM_INPUTS-1:0];

    for (genvar i = 0; i < NUM_INPUTS; i = i + 1) begin : init
        assign inputs[i] = inputs_i[(i+1)*N-1:i*N];
    end

    localparam STAGES = $clog2(NUM_INPUTS);
    reg [STAGES-1:0] valid_pipeline;
    
    wire signed [N+STAGES-1:0] adder_tree [STAGES-1:0][NUM_INPUTS/2-1:0];
    //reg [STAGES:0] valid_pipeline;

    always @(posedge clk) begin
        valid_pipeline[0] <= enable_calc_i;
    end

    // initial begin
    //     //valid_pipeline[0] <= 1'b0;
    //     for (genvar i = 1; i < STAGES; i = i + 1) begin
    //         valid_pipeline[i] == 1'b0;
    //     end
    //     for (genvar stage = 1; stage < STAGES; stage = stage + 1) begin : adder_stages
    //         for (i = 0; i < (NUM_INPUTS >> (stage+1)); i = i + 1) begin : adders
    //             adder_tree[stage][i] = 0;
    //         end
    //     end
    // end
    
    genvar i, stage;
    generate
        // Tầng đầu tiên luôn tính toán
        for (i = 0; i < NUM_INPUTS/2; i = i + 1) begin : first_stage
            ReconfigurableAdder #(N) adder (
                .A(inputs[2*i]),
                .B(inputs[2*i+1]),
                .enable_i(enable_calc_i),
                //.valid_o(valid_pipeline[0]),
                .SUM(adder_tree[0][i][N:0]),
                .clk(clk)
            );
        end


        
        // Các tầng tiếp theo chỉ tính toán khi enable_calc_i được kích hoạt
        for (stage = 1; stage < STAGES; stage = stage + 1) begin : adder_stages
            always @(posedge clk ) begin
                valid_pipeline[stage] <= valid_pipeline[stage-1];
            end
            for (i = 0; i < (NUM_INPUTS >> (stage+1)); i = i + 1) begin : adders
                ReconfigurableAdder #(N+stage) adder (
                    .A(adder_tree[stage-1][2*i][N+stage-1:0]),
                    .B(adder_tree[stage-1][2*i+1][N+stage-1:0]),
                    .enable_i(valid_pipeline[stage-1]),
                    //.valid_o(valid_pipeline[stage]),
                    .SUM(adder_tree[stage][i][N+stage:0]),
                    .clk(clk)
                );
            end
        end
    endgenerate
    
    //integer stage_current;

    assign valid_o = valid_pipeline[STAGES-1];
    assign sum_out = adder_tree[STAGES-1][0][OUT_WIDTH-1:0];
    
    // always @(posedge clk) begin
    //     if (enable_calc_i) begin
    //         valid_pipeline[0] <= 1'b1;
    //     end

    //     for (stage_current = 1; stage_current < STAGES; stage_current = stage_current + 1) begin
    //         if (valid_pipeline[stage_current-1]) begin
    //             valid_pipeline[stage_current] <= 1'b1;
    //         end
    //     end
        
    //     if (valid_pipeline[STAGES-1]) begin
    //         sum_out <= adder_tree[0];
    //         valid_o <= 1'b1;
    //     end else begin
    //         valid_o <= 1'b0;
    //     end
    // end
    
endmodule


// module AdderTree #(parameter N = 2, parameter NUM_INPUTS = 256, parameter OUT_WIDTH = 9)(
//     input signed [N*NUM_INPUTS-1:0] inputs_i,
//     input clk,
//     output reg signed [OUT_WIDTH-1:0] sum_out
// );
    
//     localparam STAGES = $clog2(NUM_INPUTS);
    
//     wire signed [OUT_WIDTH-1:0] adder_tree [NUM_INPUTS-1:0];
//     wire signed [N-1:0] inputs [NUM_INPUTS-1:0];

//     for (genvar i = 0; i < NUM_INPUTS; i = i + 1) begin : init
//         assign inputs[i] = inputs_i[(i+1)*N-1:i*N];
//     end
    
//     genvar i, stage;
//     generate
//         // Tầng đầu tiên
//         for (i = 0; i < NUM_INPUTS/2; i = i + 1) begin : first_stage
//             ReconfigurableAdder #(N) adder (
//                 .A(inputs[2*i]),
//                 .B(inputs[2*i+1]),
//                 .SUM(adder_tree[i]),
//                 .clk(clk)
//             );
//         end
        
//         // Các tầng tiếp theo
//         for (stage = 1; stage < STAGES; stage = stage + 1) begin : stages
//             for (i = 0; i < (NUM_INPUTS >> (stage + 1)); i = i + 1) begin : stage_level
//                 ReconfigurableAdder #(N+stage) adder (
//                     .A(adder_tree[2*i]),
//                     .B(adder_tree[2*i+1]),
//                     .SUM(adder_tree[i]),
//                     .clk(clk)
//                 );
//             end
//         end
//     endgenerate
    
//     always @(posedge clk) begin
//         sum_out <= adder_tree[0];
//     end
    
// endmodule
