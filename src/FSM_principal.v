/*
Aquí se va a encontrar la FSM principal que contiene toda la lógico de switcheo de los reles,
y de la información que va a mostrar la lcd
*/

module FMS_principal(
    input clk,
    input rst,
    input [7:0] sen_1,  
    input [7:0] sen_2, 
    input [7:0] sen_3, 
    output reg [3:0] state_out,
    output reg [7:0] output_signal
);


//Estados de la FSM
localparam STATE_IDLE    = 4'b0000;
localparam STATE_HEAR_DETECTION = 4'b0001;
localparam STATE_FAIL_DETECTED = 4'b0010;
localparam STATE_DONE    = 4'b0011;










endmodule