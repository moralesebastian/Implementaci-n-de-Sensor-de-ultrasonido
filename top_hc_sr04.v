module top_hc_sr04 #(
    parameter CLK_FREQ = 25_000_000 // 25 MHz (Colorlight 5A-75E v8.2)
)(
    input  wire       clk,        // Reloj principal de la tarjeta
    input  wire       rst_n,      // Reset activo en bajo
    input  wire       echo,       // Entrada del sensor (3.3V)
    output reg        trig,       // Salida de disparo al sensor
    output reg  [7:0] leds        // Salida a la barra de LEDs (código termómetro)
);

    // --- Constantes Temporales Parametrizadas ---
    localparam N_TRIG    = (CLK_FREQ / 1_000_000) * 10; // 250 ciclos (10 us)
    localparam N_1CM     = (CLK_FREQ / 1_000_000) * 58; // 1450 ciclos (58 us = 1 cm)
    localparam N_TIMEOUT = (CLK_FREQ / 1_000) * 38;     // 950,000 ciclos (38 ms)
    localparam N_REPOSO  = (CLK_FREQ / 1_000) * 60;     // 1,500,000 ciclos (60 ms)

    // --- Definición de Estados de la FSM ---
    localparam ST_TRIG    = 3'b000,
               ST_WAIT    = 3'b001,
               ST_MEASURE = 3'b010,
               ST_UPDATE  = 3'b011,
               ST_REST    = 3'b100;

    reg [2:0] state;

    // --- Sincronizador de Entrada (Anti-Metaestabilidad) ---
    reg echo_f1, echo_sync;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            echo_f1   <= 1'b0;
            echo_sync <= 1'b0;
        end else begin
            echo_f1   <= echo;
            echo_sync <= echo_f1;
        end
    end

    // --- Registros de Conteo Internos ---
    reg [20:0] cnt_trig;      // Temporizador de disparo y reposo (60 ms)
    reg [10:0] cnt_prescaler; // Presescalador de 1 cm (1450 ciclos)
    reg [8:0]  dist_cm;       // Contador de distancia acumulada en cm
    reg [20:0] cnt_echo;      // Temporizador de timeout de eco (38 ms)

    // --- Lógica Combinacional: Decodificador a Código Termómetro ---
    reg [7:0] termometro_comb;
    always @(*) begin
        if (dist_cm < 9'd5)       termometro_comb = 8'b0000_0001; // 1 LED encendido para < 5 cm
        else if (dist_cm < 9'd10) termometro_comb = 8'b0000_0011; // 2 LEDs
        else if (dist_cm < 9'd15) termometro_comb = 8'b0000_0111; // 3 LEDs
        else if (dist_cm < 9'd20) termometro_comb = 8'b0000_1111; // 4 LEDs
        else if (dist_cm < 9'd25) termometro_comb = 8'b0001_1111; // 5 LEDs
        else if (dist_cm < 9'd30) termometro_comb = 8'b0011_1111; // 6 LEDs
        else if (dist_cm < 9'd35) termometro_comb = 8'b0111_1111; // 7 LEDs
        else                      termometro_comb = 8'b1111_1111; // 8 LEDs
    end

    // --- Máquina de Estados y Lógica Secuencial ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= ST_TRIG;
            trig          <= 1'b0;
            cnt_trig      <= 21'd0;
            cnt_prescaler <= 11'd0;
            dist_cm       <= 9'd0;
            cnt_echo      <= 21'd0;
            leds          <= 8'b0000_0000;
        end else begin
            case (state)
                ST_TRIG: begin
                    trig <= 1'b1;
                    cnt_trig <= cnt_trig + 1'b1;
                    if (cnt_trig >= N_TRIG - 1) begin
                        trig  <= 1'b0;
                        state <= ST_WAIT;
                    end
                end

                ST_WAIT: begin
                    trig <= 1'b0;
                    if (echo_sync) begin
                        cnt_prescaler <= 11'd0;
                        dist_cm       <= 9'd0;
                        cnt_echo      <= 21'd0;
                        state         <= ST_MEASURE;
                    end
                end

                ST_MEASURE: begin
                    cnt_trig <= cnt_trig + 1'b1;
                    cnt_echo <= cnt_echo + 1'b1;

                    // Conteo presescalado en cm
                    if (cnt_prescaler >= N_1CM - 1) begin
                        cnt_prescaler <= 11'd0;
                        dist_cm       <= dist_cm + 1'b1;
                    end else begin
                        cnt_prescaler <= cnt_prescaler + 1'b1;
                    end

                    // Evaluación de fin de pulso o timeout
                    if (!echo_sync || (cnt_echo >= N_TIMEOUT - 1)) begin
                        state <= ST_UPDATE;
                    end
                end
            ST_UPDATE: begin
                    cnt_trig <= cnt_trig + 1'b1;                    
                    if (cnt_echo >= N_TIMEOUT) begin
                        // Caso 1: Sin eco / Timeout (Error de lectura)
                        leds <= 8'b1000_0001; // Extremos encendidos
                    end else if (dist_cm > 9'd40) begin
                        // Caso 2: Distancia mayor a 40 cm (Fuera de rango)
                        leds <= 8'b1000_0000; // Solo el LED más significativo
                    end else begin
                        // Caso 3: Distancia válida (incluye < 5 cm)
                        leds <= termometro_comb;
                    end
                    state <= ST_REST;
                end

                ST_REST: begin
                    cnt_trig <= cnt_trig + 1'b1;
                    if (cnt_trig >= N_REPOSO - 1) begin
                        cnt_trig <= 21'd0;
                        state    <= ST_TRIG;
                    end
                end

                default: state <= ST_TRIG;
            endcase
        end
    end

endmodule
