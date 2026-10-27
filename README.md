# Medición de Distancia con Sensor Ultrasónico HC-SR04 en FPGA Colorlight 5A-75E v8.2

Este repositorio contiene la implementación en Verilog de un controlador para el sensor ultrasónico **HC-SR04** montado sobre la tarjeta de desarrollo **Colorlight 5A-75E (v8.2)**[cite: 1, 2]. El sistema calcula la distancia mediante el tiempo de vuelo del eco y visualiza la lectura en una barra de 8 LEDs utilizando formato de **código termómetro**.

---

## 🛠️ Especificaciones del Hardware y Periféricos

- **FPGA:** Lattice ECP5 (Colorlight 5A-75E v8.2)[cite: 1, 2].
- **Reloj del Sistema:** 25 MHz integrados en la tarjeta (Pin `P6`)[cite: 1, 2].
- **Sensor de Distancia:** HC-SR04 (Alimentado a 5 V)[cite: 1].
- **Protección de Entrada (ECHO):** Divisor de voltaje resistivo ($R_1 = 1\,\text{k}\Omega$, $R_2 = 2\,\text{k}\Omega$) para atenuar el nivel lógico de 5 V a 3.3 V permitidos por la FPGA[cite: 1].
- **Salida:** Barra de 8 LEDs con resistencias limitadoras de $220\,\Omega$ a $330\,\Omega$[cite: 1].

---

## 📌 Asignación de Pines (`top_hc_sr04.lpf`)

| Señal en Verilog | Pin FPGA | Descripción / Componente Conectado |
| :--- | :--- | :--- |
| `clk` | **P6** | Reloj principal de 25 MHz[cite: 1, 2] |
| `rst_n` | **M13** | Pulsador de Reset (activo en bajo)[cite: 1, 2] |
| `trig` | **F5** | Salida de disparo de 10 µs hacia el sensor HC-SR04[cite: 1, 2] |
| `echo` | **E4** | Entrada de pulso de eco (mediante divisor de voltaje a 3.3 V)[cite: 1, 2] |
| `leds[0]` | **C4** | Ánodo LED 0 (Bit menor peso)[cite: 1, 2] |
| `leds[1]` | **D4** | Ánodo LED 1[cite: 1, 2] |
| `leds[2]` | **D3** | Ánodo LED 2[cite: 1, 2] |
| `leds[3]` | **E3** | Ánodo LED 3[cite: 1, 2] |
| `leds[4]` | **F3** | Ánodo LED 4[cite: 1, 2] |
| `leds[5]` | **G3** | Ánodo LED 5[cite: 1, 2] |
| `leds[6]` | **G4** | Ánodo LED 6[cite: 1, 2] |
| `leds[7]` | **H3** | Ánodo LED 7 (Bit mayor peso)[cite: 1, 2] |

---

## ⚙️ Arquitectura del Sistema y FSM

El módulo principal (`top_hc_sr04.v`) gestiona la medición mediante una Máquina de Estados Finitos (FSM) sincrónica compuesta por los siguientes estados[cite: 1]:

1. **`ST_TRIG`:** Genera un pulso en la línea `trig` con una duración de 10 µs[cite: 1].
2. **`ST_WAIT`:** Aguarda la llegada del flanco de subida en la señal `echo` de respuesta[cite: 1].
3. **`ST_MEASURE`:** Cuenta los ciclos del temporizador mientras `echo` permanezca en nivel alto[cite: 1].
4. **`ST_UPDATE`:** Mapea la distancia calculada en cm hacia la salida combinacional de los LEDs[cite: 1].
5. **`ST_REST`:** Cumple el periodo de reposo entre mediciones (60 ms) para evitar ecos cruzados[cite: 1].

---

## 📊 Simulación

La verificación funcional se llevó a cabo simulando la prueba de banco (`tb_top_hc_sr04.v`) mediante **Icarus Verilog** e inspeccionando las formas de onda extraídas en el archivo `.vcd`:

```bash
# Compilar la simulación
iverilog -o sim_hc_sr04.vvp tb_top_hc_sr04.v top_hc_sr04.v

# Ejecutar y generar el archivo VCD
vvp sim_hc_sr04.vvp

# Visualizar ondas en GTKWave
gtkwave tb_top_hc_sr04.vcd
