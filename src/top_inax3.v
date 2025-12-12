`include "mod_inax3.v"
`include "mod_lcd_x3.v"

module top_module (
    input wire clk,         
    input wire rst_n,       
    
    // --- TRES PARES DE PINES I2C ---
    inout wire sda1, output wire scl1,
    inout wire sda2, output wire scl2,
    inout wire sda3, output wire scl3,

    // LCD
    output wire lcd_rs,     
    output wire lcd_rw,     
    output wire lcd_en,     
    output wire [7:0] lcd_d 
);

    wire [15:0] w_s1;
    wire [15:0] w_s2;
    wire [15:0] w_s3;

    // --- INSTANCIA 1: Sensor 0x40 ---
    i2c_ina219_x3 #(.SENSOR_ADDR(7'h40)) U_SENSOR1 (
        .clk(clk), .reset(rst_n),
        .sda(sda1), .scl(scl1), // Pines Grupo 1
        .data_out(w_s1)
    );

    // --- INSTANCIA 2: Sensor 0x41 ---
    i2c_ina219_x3 #(.SENSOR_ADDR(7'h41)) U_SENSOR2 (
        .clk(clk), .reset(rst_n),
        .sda(sda2), .scl(scl2), // Pines Grupo 2
        .data_out(w_s2)
    );

    // --- INSTANCIA 3: Sensor 0x44 ---
    i2c_ina219_x3 #(.SENSOR_ADDR(7'h44)) U_SENSOR3 (
        .clk(clk), .reset(rst_n),
        .sda(sda3), .scl(scl3), // Pines Grupo 3
        .data_out(w_s3)
    );

    // --- LCD (La que ya funcionó) ---
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