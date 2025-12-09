module FSM_individual #(
)(
    input clk_16ms,
    input rst,
    input enable,              
    input [werwerewrwerwe-1:0] sen,
    input [werwerwerweewrw-1:0] sen_ref,
    input [wrwerwerwerwr-1:0] threshold,
    output reg relay_out,  
);

// Estados
localparam STATE_IDLE = 2'd0;
localparam STATE_HEAR_SENSOR = 2'd1;
localparam STATE_OPEN = ;
localparam STATE_WAIT_5S = ;
localparam STATE_DEFINITIVE_FAIL = ;

//Variables internas del programa
reg [3:0] fsm_state;
reg [3:0] next_state;
reg [--------:0] diff_sen;
reg [1:0] state, next_state;
reg [1:0] retry_cnt;
reg [8:0] timer;

// Lógica de Comparación
wire fail_sen;
reg [--------------:0] sen_diff;
    
always @(*) begin
    sen_diff = (sen > sen_ref) ? (sen - sen_ref) : (sen - sen_val);
    assign fail_sen = (sen_diff > threshold);
end

// Lógica de la FSM
always @(posedge clk_16ms or posedge rst) begin
    if (rst) begin
        fsm_state <= STATE_IDLE;
        relay_out <= 1'b0;
        retry_cnt <= 2'b00;
        timer <= 9'b0;
    end else if (enable) begin
        fsm_state <= next_state;
        case (fsm_state)
            STATE_IDLE: begin
                relay_out <= 1'b0;
                retry_cnt <= 2'b00;
                timer <= 9'b0;
            end
            STATE_HEAT_SENSOR: begin
                if (fail_sen) begin
                    next_state <= STATE_OPEN;
                end else begin
                    next_state <= STATE_HEAR_SENSOR;
                end
            end
            STATE_OPEN: begin
                relay_out <= 1'b1;
            end
        endcase
    end
end
            
endmodule