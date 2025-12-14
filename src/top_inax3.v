//`include "mod_inax3.v"
//`include "mod_lcd_x3.v"
module top_module_x3 (
    input wire clk,         
    input wire rst_n,  
	 output reg buzzer = 1'b1,
    
    // I2C
    inout wire sda1, output wire scl1,
    inout wire sda2, output wire scl2,
    inout wire sda3, output wire scl3,

    // LCD
    output wire lcd_rs,     
    output wire lcd_rw,     
    output wire lcd_en,     
    output wire [7:0] lcd_d,

    // RELÉS (Lógica Inversa: 1=Cerrado/Bien, 0=Abierto/Protección)
    output reg relay1,
    output reg relay2,
    output reg relay3
);

    wire [15:0] w_s1;
    wire [15:0] w_s2;
    wire [15:0] w_s3;

    // Sensores
    i2c_ina219_x3 #(.SENSOR_ADDR(8'h80)) U_SENSOR1 (.clk(clk),.reset(rst_n),.sda(sda1),.scl(scl1),.data_out(w_s1));
    i2c_ina219_x3 #(.SENSOR_ADDR(8'h82)) U_SENSOR2 (.clk(clk),.reset(rst_n),.sda(sda2),.scl(scl2),.data_out(w_s2));
    i2c_ina219_x3 #(.SENSOR_ADDR(8'h88)) U_SENSOR3 (.clk(clk),.reset(rst_n),.sda(sda3),.scl(scl3),.data_out(w_s3));

    // --- PROTECCIÓN ---
    reg [27:0] startup_timer;
    
    // Filtros de ruido
    reg [10:0] f1; 
    reg [10:0] f2;
    reg [10:0] f3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // RESET: Ponemos 1 para que el relé esté RELAJADO (Cerrado)
            relay1 <= 1; 
            relay2 <= 1; 
            relay3 <= 1;
				buzzer <= 1'b1;
            startup_timer <= 0;
            f1<=0; f2<=0; f3<=0;
        end else begin
            // 1. ESPERA 3 SEGUNDOS (Mantener relés cerrados/seguros)
            if (startup_timer < 150000000) begin
                startup_timer <= startup_timer + 1;
                relay1 <= 1; relay2 <= 1; relay3 <= 1; // 1 = Cerrado
            end 
            else begin
                // --- SENSOR 1 ---
                // Si corriente > 500 Y positivo normal
                if (w_s1 > 16'd500 && w_s1 < 16'd32000) begin
					     buzzer <= 1'b0;
                    if (f1 < 1000) f1 <= f1 + 1; 
                    else relay1 <= 0; // 0 = ACTIVAR PROTECCIÓN (Abrir)
                end else begin
                    f1 <= 0; 
                    // NO hay 'else relay1 <= 1'. Esto crea el ENCLAVAMIENTO.
                    // Solo el Reset puede volver a ponerlo en 1.
                end

                // --- SENSOR 2 ---
                if (w_s2 > 16'd500 && w_s2 < 16'd32000) begin
					     buzzer <= 1'b0;
                    if (f2 < 1000) f2 <= f2 + 1;
                    else relay2 <= 0; // 0 = Abrir
                end else f2 <= 0;

                // --- SENSOR 3 ---
                if (w_s3 > 16'd500 && w_s3 < 16'd32000) begin
					     buzzer <= 1'b0º;
                    if (f3 < 1000) f3 <= f3 + 1;
                    else relay3 <= 0; // 0 = Abrir
                end else f3 <= 0;
            end
        end
    end

    // LCD
    lcd_controller_x3 U_LCD (
        .clk(clk), .reset(rst_n),
        .val1(w_s1), .val2(w_s2), .val3(w_s3),
        .rs(lcd_rs), .rw(lcd_rw), .enable(lcd_en), .data(lcd_d)
    );

endmodule