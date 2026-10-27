# Medición de Distancia con Sensor Ultrasónico HC-SR04 en FPGA Colorlight 5A-75E v8.2

Este repositorio contiene la implementación en Verilog de un controlador para el sensor ultrasónico **HC-SR04** montado sobre la tarjeta de desarrollo **Colorlight 5A-75E (v8.2)**. El sistema calcula la distancia mediante el tiempo de vuelo del eco y visualiza la lectura en una barra de 8 LEDs utilizando formato de **código termómetro**.

---

## 🛠️ Especificaciones del Hardware y Periféricos

- **FPGA:** Lattice ECP5 (Colorlight 5A-75E v8.2).
- **Reloj del Sistema:** 25 MHz integrados en la tarjeta (Pin `P6`).
- **Sensor de Distancia:** HC-SR04 (Alimentado a 5 V)
- **Protección de Entrada (ECHO):** Divisor de voltaje resistivo ($R_1 = 1\,\text{k}\Omega$, $R_2 = 2\,\text{k}\Omega$) para atenuar el nivel lógico de 5 V a 3.3 V permitidos por la FPGA
- **Salida:** Barra de 8 LEDs con resistencias limitadoras de $220\,\Omega$ a $330\,\Omega$

---

## 📌 Asignación de Pines (`top_hc_sr04.lpf`)

| Señal en Verilog | Pin FPGA | Descripción / Componente Conectado |
| :--- | :--- | :--- |
| `clk` | **P6** | Reloj principal de 25 MHz |
| `rst_n` | **M13** | Pulsador de Reset (activo en bajo) |
| `trig` | **F5** | Salida de disparo de 10 µs hacia el sensor HC-SR04 |
| `echo` | **E4** | Entrada de pulso de eco (mediante divisor de voltaje a 3.3 V) |
| `leds[0]` | **C4** | Ánodo LED 0 (Bit menor peso) |
| `leds[1]` | **D4** | Ánodo LED 1 |
| `leds[2]` | **D3** | Ánodo LED 2 |
| `leds[3]` | **E3** | Ánodo LED 3 |
| `leds[4]` | **F3** | Ánodo LED 4 |
| `leds[5]` | **G3** | Ánodo LED 5 |
| `leds[6]` | **G4** | Ánodo LED 6 |
| `leds[7]` | **H3** | Ánodo LED 7 (Bit mayor peso) |

---

## ⚙️ Arquitectura del Sistema y FSM

El módulo principal (`top_hc_sr04.v`) gestiona la medición mediante una Máquina de Estados Finitos (FSM) sincrónica compuesta por los siguientes estados:

1. **`ST_TRIG`:** Genera un pulso en la línea `trig` con una duración de 10 µs
2. **`ST_WAIT`:** Aguarda la llegada del flanco de subida en la señal `echo` de respuesta
3. **`ST_MEASURE`:** Cuenta los ciclos del temporizador mientras `echo` permanezca en nivel alto
4. **`ST_UPDATE`:** Mapea la distancia calculada en cm hacia la salida combinacional de los LEDs
5. **`ST_REST`:** Cumple el periodo de reposo entre mediciones (60 ms) para evitar ecos cruzados

---
## ⚠️ Dificultades Técnicas y Reprocesos en la Implementación

Durante la fase de diseño, configuración física y pruebas de laboratorio se presentaron los siguientes inconvenientes y reprocesos técnicos:

### 1. Incompatibilidad en el Archivo de Restricciones (`.lpf`) y Pinout
* **Selección incorrecta de la versión de la placa:** Inicialmente se configuraron las restricciones de pines considerando una versión distinta de la FPGA Colorlight (v7.0 en lugar de v8.2), provocando que los pines asignados no correspondieran con los conectores físicos de la tarjeta.
* **Errores de límites en el encapsulado:** Durante el proceso de sintaxis y ruteo con `nextpnr-ecp5`, se asignaron pines inexistentes en el paquete `CABGA256` (por ejemplo, pines fuera del rango de 16 columnas), lo cual abortó la compilación del *bitstream*.
* **Mapeo de periféricos internos:** Se asignaron por error señales de la barra de LEDs externa a pines reservados para el LED *onboard* (`T6`) y el botón de usuario (`R7`) de la propia placa.

### 2. Omisión de la Red de Masa Común (GND) en la Protoboard
* **Circuito abierto en la barra de LEDs:** Al realizar el cableado en la protoboard, la atención se centró exclusivamente en conectar los nodos positivos (ánodos) de los LEDs a las salidas I/O correspondientes de la FPGA.
* **Falta de referencia de retorno:** Se omitió conectar la línea de masa (GND) de la FPGA hacia el bus azul de la protoboard. Sin una referencia de $0\text{ V}$ común, la corriente no podía retornar a la tarjeta y la barra de LEDs no encendió.

### 3. Inconvenientes en Laboratorio y Práctica Libre
* **Falta de tiempo en sesión presencial:** Debido al tiempo dedicado a la corrección del archivo de restricciones y al ajuste de las conexiones físicas, no se alcanzó a validar el funcionamiento dinámico del sensor en la sesión oficial de laboratorio.
* **Fallo de hardware en práctica libre:** Al intentar validar el circuito en el espacio de práctica libre, la tarjeta FPGA asignada presentaba un fallo físico (tarjeta quemada/dañada), impidiendo realizar la carga del *bitstream* y la prueba en protoboard.

> **Nota:** A pesar de los contratiempos con el montaje y el hardware físico en el laboratorio, el diseño lógico de la máquina de estados y el control del sensor en Verilog se verificaron y validaron al 100% mediante simulación con Icarus Verilog y visualización de ondas en GTKWave.

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

