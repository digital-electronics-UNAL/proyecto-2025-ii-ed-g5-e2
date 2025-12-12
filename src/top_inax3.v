//`include "mod_inax3.v"
//`include "mod_lcd_x3.v"
module top_module_x3 (
    input wire clk,         
    input wire rst_n,       
    
    // 3 Buses I2C Separados
    inout wire sda1, output wire scl1,
    inout wire sda2, output wire scl2,
    inout wire sda3, output wire scl3,

    // LCD
    output wire lcd_rs,     
    output wire lcd_rw,     
    output wire lcd_en,     
    output wire [7:0] lcd_d,

    // SALIDAS A RELÉS (1 = Abrir circuito/Proteger)
    output reg relay1,
    output reg relay2,
    output reg relay3
);

    wire [15:0] w_s1;
    wire [15:0] w_s2;
    wire [15:0] w_s3;

    // --- SENSORES ---
    // SENSOR 1 (0x40)
    i2c_ina219_x3 #(.SENSOR_ADDR(8'h80)) U_SENSOR1 (
        .clk(clk), .reset(rst_n),
        .sda(sda1), .scl(scl1), 
        .data_out(w_s1)
    );

    // SENSOR 2 (0x41 -> Write 0x82)
    i2c_ina219_x3 #(.SENSOR_ADDR(8'h82)) U_SENSOR2 (
        .clk(clk), .reset(rst_n),
        .sda(sda2), .scl(scl2), 
        .data_out(w_s2)
    );

    // SENSOR 3 (0x44 -> Write 0x88)
    i2c_ina219_x3 #(.SENSOR_ADDR(8'h88)) U_SENSOR3 (
        .clk(clk), .reset(rst_n),
        .sda(sda3), .scl(scl3), 
        .data_out(w_s3)
    );

    // --- LÓGICA DE PROTECCIÓN (RELÉS) ---
    // Umbral de 300 mA. Asumimos que el dato crudo 300 equivale a 300mA 
    // (Ajustar según calibración real si es necesario).
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            relay1 <= 0; // Reset: Relés desactivados (Circuito cerrado)
            relay2 <= 0;
            relay3 <= 0;
        end else begin
            // Si supera 300, activamos relé (1) para abrir el circuito
            if (w_s1 > 16'h258) relay1 <= 1; else relay1 <= 0;
            
            if (w_s2 > 16'h258) relay2 <= 1; else relay2 <= 0;
            
            if (w_s3 > 16'h258) relay3 <= 1; else relay3 <= 0;
        end
    end

    // --- LCD ---
    lcd_controller_x3 U_LCD (
        .clk(clk),
        .reset(rst_n),
        .val1(w_s1),
        .val2(w_s2),
        .val3(w_s3),
        .rs(lcd_rs),
        .rw(lcd_rw),
        .enable(lcd_en),
        .data(lcd_d)
    );

endmodule