`include "mod_ina.v"
`include "mod_lcd.v"

module top_module (
    input wire clk,         // 50 MHz
    input wire rst_n,       // Botón Reset (0 = Reset)
    inout wire sda,         // A pin SDA del INA219
    output wire scl,        // A pin SCL del INA219
    output wire lcd_rs,     // A pin RS LCD
    output wire lcd_rw,     // A pin RW LCD
    output wire lcd_en,     // A pin E LCD
    output wire [7:0] lcd_d // A pines D0-D7 LCD
);

    wire [15:0] raw_data;
    reg [9:0] display_data;

    // Instancia del I2C
    i2c_ina219 sensor (
        .clk(clk),
        .reset(rst_n),
        .sda(sda),
        .scl(scl),
        .data_out(raw_data)
    );

    // Ajuste de escala simple
    // El INA219 suele devolver valores pequeños en los bits bajos.
    always @(posedge clk) begin
        display_data <= raw_data[9:0]; 
    end

    // Instancia de la LCD
    lcd_controller pantalla (
        .clk(clk),
        .reset(rst_n),
        .sensor_val(display_data),
        .rs(lcd_rs),
        .rw(lcd_rw),
        .enable(lcd_en),
        .data(lcd_d)
    );

endmodule
