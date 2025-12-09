/*
Aquí se va a encontrar la FSM principal que contiene toda la lógico de switcheo de los reles,
y de la información que va a mostrar la lcd
*/

module FMS_principal #(parameter COUNT_MAX = 800000)(
    input clk,
    input rst,
    input [------:0] sen_1,  
    input [------:0] sen_2, 
    input [-------:0] sen_3,
    //Salidas
    output reg relay_1,
    output reg relay_2,
    output reg relay_3
);

//Estados de la FSM
localparam STATE_IDLE = 4'd0;
localparam STATE_HEAR_SENSOR = 4'd1;
localparam STATE_OPEN_1 = 4'd2;
localparam STATE_OPEN_2 = 4'd3;
localparam STATE_OPEN_3 = 4'd4;
localparam STATE_CLOSE_1 = 4'd5;
localparam STATE_CLOSE_2 = 4'd6;
localparam STATE_CLOSE_3 = 4'd7;
localparam STATE_DEFINITIVE_FAIL_1 = 4'd8;
localparam STATE_DEFINITIVE_FAIL_2 = 4'd9;
localparam STATE_DEFINITIVE_FAIL_3 = 4'd10;
localparam STATE_WAIT_5S           = 4'd11;

//Variables internas del programa
reg [3:0] fsm_state;
reg [3:0] next_state;
reg clk_16ms;
reg [--------:0] diff_sen_1;
reg [---------:0] diff_sen_2;
reg [--------:0] diff_sen_3;
// Generación de reloj lento
reg [$clog2(COUNT_MAX):0] clk_counter;
reg clk_16ms;
    
// Lógica de sensores
reg [n:0] diff_sen_1;
reg [n:0] diff_sen_2;
reg [n:0] diff_sen_3;
reg fail_sen_1, fail_sen_2, fail_sen_3;

// Contadores de intentos y temporizador
reg [1:0] retry_rele_1;
reg [1:0] retry_rele_2;
reg [1:0] retry_rele_3;  
reg [8:0] timer_counter; 
reg timer_enable;
reg timer_done;
    
// Variable auxiliar para recordar qué sensor estamos esperando
reg [1:0] current_sensor_wait; // 1, 2 o 3









//Divisor de Frecuencia 
always @(posedge clk) begin
    if (clk_counter == COUNT_MAX-1) begin
        clk_16ms <= ~clk_16ms;
        clk_counter <= 'b0;
    end else begin
        clk_counter <= clk_counter + 1;
    end
end


//Comparador diferencial para cada sensor
always @(*) begin
    diff_sen_1 = (sen_1 > sen_ref) ? (sen_1 - sen_ref) : (sen_ref - sen_1);
    diff_sen_2 = (sen_2 > sen_ref) ? (sen_2 - sen_ref) : (sen_ref - sen_2);
    diff_sen_3 = (sen_3 > sen_ref) ? (sen_3 - sen_ref) : (sen_ref - sen_3);
        
    fail_sen_1 = (diff_sen_1 > threshold_sen);
    fail_sen_2 = (diff_sen_2 > threshold_sen);
    fail_sen_3 = (diff_sen_3 > threshold_sen);
end


//Activación de reles
always @(*) begin
        relay_1 = 1'b0;
        relay_2 = 1'b0;
        relay_3 = 1'b0;
        case (fsm_state)
            STATE_IDLE, STATE_HEAR_SENSOR: begin
                relay_1 = 1'b0; relay_2 = 1'b0; relay_3 = 1'b0;
            end
            STATE_OPEN_1, STATE_WAIT_5S: begin
                if (current_sensor_wait == 1) relay_1 = 1'b1; 
            end
            STATE_CLOSE_1: begin
                relay_1 = 1'b0; 
            end
            STATE_DEFINITIVE_FAIL_1: begin
                relay_1 = 1'b1; 
            end
            STATE_OPEN_2, STATE_WAIT_5S: begin
                if (current_sensor_wait == 2) relay_2 = 1'b1;
            end
            STATE_CLOSE_2: begin
                relay_2 = 1'b0;       
            end 
            STATE_DEFINITIVE_FAIL_2: begin
                relay_2 = 1'b1;
            end
            STATE_OPEN_3, STATE_WAIT_5S: begin
               if (current_sensor_wait == 3) relay_3 = 1'b1;
            end
            STATE_CLOSE_3: begin
                relay_3 = 1'b0;       
            end
            STATE_DEFINITIVE_FAIL_3: begin
                relay_3 = 1'b1;
            end            
        endcase
    end

//Las transiciones de la FSM
always @(*) begin
    case(fsm_state)
        IDLE: begin
            next_state <= (ready_i)? STATE_HEAR_SENSOR : IDLE;
        end
        STATE_HEAR_SENSOR: begin 
            if (fail_sen_1 <= 1'b1) begin
                next_state <= STATE_OPEN_1;
            end else if (fail_sen_2 <= 1'b1) begin
                next_state <= STATE_OPEN_2;
            end else if (fail_sen_3 <= 1'b1) begin
                next_state <= STATE_OPEN_3;
            end else begin
                next_state <= STATE_HEAR_SENSOR;
            end
        end
        STATE_OPEN_1:begin
			next_state <= 
        end
        STATE_OPEN_2: begin 
            next_state <= 
        end
	    STATE_OPEN_3: begin
			next_state <= 
        end
        STATE_CLOSE_1: begin
            next_state <= STATE_HEAR_SENSOR; 
		end
        STATE_CLOSE_2: begin
            next_state <= STATE_HEAR_SENSOR;     
        end         
        STATE_CLOSE_3: begin
            next_state <= STATE_HEAR_SENSOR;
        end
        STATE_DEFINITIVE_FAIL_1: begin
            next_state <=       
        end
        STATE_DEFINITIVE_FAIL_2: begin
            next_state <=       
        end
        STATE_DEFINITIVE_FAIL_3: begin
            next_state <=       
        end
        default: begin
            next_state <= IDLE;
        end

    endcase
end







endmodule