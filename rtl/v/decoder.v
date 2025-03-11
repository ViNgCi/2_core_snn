module decoder #(
    
) (
    input [31:0] addr_i,

    output reg core_0_en_o,
    output reg core_1_en_o,
    output reg spike_in_en_o,
    output reg param_in_en_o,
    output reg spike_out_en_o,
    output reg [1:0] enable_calc_o 
);

    always @(addr_i) begin
        case (addr_i[16])
            1'b0: begin
                core_0_en_o = 1;
                core_1_en_o = 0;
            end
            1'b1: begin
                core_0_en_o = 0;
                core_1_en_o = 1;
            end
            default: begin
                core_0_en_o = 0;
                core_1_en_o = 0;
            end
        endcase
        case (addr_i[18:17])
            2'b00: begin
                spike_in_en_o = 1;
                param_in_en_o = 0;
                spike_out_en_o = 0;
            end
            2'b01: begin
                spike_in_en_o = 0;
                param_in_en_o = 1;
                spike_out_en_o = 0;
            end
            2'b10: begin
                spike_in_en_o = 0;
                param_in_en_o = 0;
                spike_out_en_o = 1;
            end
            //2'b11: enable_calc_o = 1; 
            default: begin
                spike_in_en_o = 0;
                param_in_en_o = 0;
                spike_out_en_o = 0;
            end
        endcase
        
        case (addr_i[21:20])
            2'b00: enable_calc_o = 2'b00;
            2'b01: enable_calc_o = 2'b01;
            2'b10: enable_calc_o = 2'b10;
            2'b11: enable_calc_o = 2'b11;
            default: enable_calc_o = 2'b00;
        endcase
    end
    
endmodule