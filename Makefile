TOP = top_hc_sr04
TB  = tb_top_hc_sr04

# --- Configuración del Programador JTAG (FT232RL) ---
CABLE       ?= -c ft232RL
# Mapeo de pines FT232RL (TDI:TDO:TCK:TMS -> TXD=0 : CTS=3 : DTR=4 : RXD=1)
CABLE_PINES ?= 0:3:4:1
FREQ        ?= 3000000

.PHONY: all sim rtl syn conf detect clean

all: sim

sim:
	mkdir -p sim
	iverilog -o sim/$(TB).vvp -s $(TB) $(TB).v $(TOP).v
	vvp sim/$(TB).vvp
	gtkwave $(TB).vcd &

rtl:
	mkdir -p build
	yosys -p "read_verilog $(TOP).v; prep -top $(TOP); write_json build/$(TOP).json"
	netlistsvg build/$(TOP).json -o build/$(TOP).svg
	eog build/$(TOP).svg &

syn:
	mkdir -p build
	yosys -p "synth_ecp5 -top $(TOP) -json build/$(TOP).json" $(TOP).v
	nextpnr-ecp5 --25k --package CABGA256 --speed 6 --json build/$(TOP).json --lpf $(TOP).lpf --textcfg build/$(TOP).config
	ecppack build/$(TOP).config build/$(TOP).bit

# --- Regla para detectar la FPGA ---
detect:
	openFPGALoader $(CABLE) --pins=$(CABLE_PINES) --freq $(FREQ) --detect

# --- Cargar el diseño en la FPGA ---
conf:
	openFPGALoader $(CABLE) --pins=$(CABLE_PINES) --freq $(FREQ) build/$(TOP).bit

clean:
	rm -rf build/ sim/ *.vcd *.vvp
