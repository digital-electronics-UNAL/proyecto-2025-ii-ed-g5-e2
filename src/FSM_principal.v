`include "FSM_individual.v"
module FSM_principal (
    input clk,
    input wire rst,
    input wire enable,
    
    // Entradas Sensor 1
    input wire [16-1:0] sen_1,
    output wire relay_1,

    // Entradas Sensor 2
    input wire [16-1:0] sen_2,
    output wire relay_2,

    // Entradas Sensor 3
    input wire [16-1:0] sen_3,
    output wire relay_3
);

    // --- FSM para Sensor 1 ---
    FSM_individual fsm_sensor_1 (
        .clk    (clk ),
        .rst        (rst),
        .enable     (enable),
        .sen        (sen_1), // Corregido: sen1 -> sen_1
        .relay_out  (relay_1) // Corregido: relay1 -> relay_1
    );

    // --- FSM para Sensor 2 ---
    FSM_individual fsm_sensor_2 (
        .clk    (clk ),
        .rst        (rst),
        .enable     (enable),
        .sen        (sen_2), // Corregido: sen2 -> sen_2
        .relay_out  (relay_2) // Corregido: relay2 -> relay_2
    );

    // --- FSM para Sensor 3 ---
    FSM_individual fsm_sensor_3 (
        .clk    (clk ),
        .rst        (rst),
        .enable     (enable),
        .sen        (sen_3), // Corregido: sen3 -> sen_3
        .relay_out  (relay_3) // Corregido: relay3 -> relay_3
    );

endmodule