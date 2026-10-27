`timescale 1ns/1ps

module tb_top_hc_sr04;

    // Parámetros de simulación acelerada
    localparam CLK_FREQ_TB = 25_000_000;
    localparam T_CLK       = 40; // Periodo de 40 ns (25 MHz)S

    reg        clk   = 1'b0;
    reg        rst_n = 1'b0;
    reg        echo  = 1'b0;
    wire       trig;
    wire [7:0] leds;

    // Generador de reloj
    always #(T_CLK/2) clk = ~clk;

    // Instancia del diseño bajo prueba (DUT)
    top_hc_sr04 #(.CLK_FREQ(CLK_FREQ_TB)) dut (
        .clk  (clk),
        .rst_n(rst_n),
        .echo (echo),
        .trig (trig),
        .leds (leds)
    );

    // Secuencia de estímulos
    initial begin
        $dumpfile("tb_top_hc_sr04.vcd");
        $dumpvars(0, tb_top_hc_sr04);

        // Reset inicial
        #(10*T_CLK) rst_n = 1'b1;
        // Espera a que termine el pulso Trig
        @(negedge trig);
        // Simulación de eco para 15 cm (15 * 58 us = 870 us = 870,000 ns)
        #5000;
        echo = 1'b1;
        #870000;
        echo = 1'b0;

        // Espera al siguiente disparo
        @(negedge trig);
        #5000;
        // Simulación de respuesta fuera de rango (>40 cm)
        echo = 1'b1;
        #2500000;
        echo = 1'b0;

        #1000000;
        $finish;
    end

endmodule
