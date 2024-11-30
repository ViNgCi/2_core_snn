module decoder_sv #(
    
) (
    input logic [31:0] addr_i,

    output logic core_0_en_o,
    output logic core_1_en_o,
    output logic spike_in_en_o,
    output logic param_in_en_o,
    output logic spike_out_en_o,
    output logic [1:0] enable_calc_o 
);

    always @(addr_i) begin
        core_0_en_o = 0;
        core_1_en_o = 0;
        spike_in_en_o = 0;
        param_in_en_o = 0;
        spike_out_en_o = 0;
        enable_calc_o = 2'b00;
        case (addr_i[16])
            1'b0: begin
                core_0_en_o = 1;
                core_1_en_o = 0;
            end
            1'b1: begin
                core_0_en_o = 0;
                core_1_en_o = 1;
            end
            default: ;
        endcase
        case (addr_i[18:17])
            2'b00: spike_in_en_o = 1;
            2'b01: param_in_en_o = 1;
            2'b10: spike_out_en_o = 1;
            //2'b11: enable_calc_o = 1; 
            default: ;
        endcase
        
        case (addr_i[21:20])
            2'b00: enable_calc_o = 2'b00;
            2'b01: enable_calc_o[0] = 1;
            2'b10: enable_calc_o[1] = 1;
            2'b11: enable_calc_o = 2'b11;
            default: ;
        endcase
    end
    
endmodule