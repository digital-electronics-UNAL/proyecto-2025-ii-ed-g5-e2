module FSM_principal #(
    
)(
    input wire clk_16ms,
    input wire rst,
    input wire enable,
    input wire [n:0] threshold,
    
    // Entradas Sensor 1
    input wire [valor_por_poner-1:0] sen_1,
    input wire [valor_por_poner-1:0] ref_1,
    output wire relay_1,

    // Entradas Sensor 2
    input wire [valor_por_poner-1:0] sen_2,
    input wire [valor_por_poner-1:0] ref_2,
    output wire relay_2,

    // Entradas Sensor 3
    input wire [valor_por_poner-1:0] sen_3,
    input wire [valor_por_poner-1:0] ref_3,
    output wire relay_3
);

    // --- FSM para Sensor 1 ---
    FSM_individual #(
        .W(valor_por_poner)
    ) fsm_sensor_1 (
        .clk_16ms   (clk_16ms),
        .rst        (rst),
        .enable     (enable),
        .sen        (sen1),
        .sen_ref    (ref1),
        .threshold  (threshold),
        .relay_out  (relay1)
    );

    // --- FSM para Sensor 2 ---
    FSM_individual #(
        .W(valor_por_poner)
    ) fsm_sensor_2 (
        .clk_16ms   (clk_16ms),
        .rst        (rst),
        .enable     (enable),
        .sen        (sen2),
        .sen_ref    (ref2),
        .threshold  (threshold),
        .relay_out  (relay2)
    );

    // --- FSM para Sensor 3 ---
    FSM_individual #(
        .W(valor_por_poner)
    ) fsm_sensor_3 (
        .clk_16ms   (clk_16ms),
        .rst        (rst),
        .enable     (enable),
        .sen        (sen3),
        .sen_ref    (ref3),
        .threshold  (threshold),
        .relay_out  (relay3)
    );

endmodule