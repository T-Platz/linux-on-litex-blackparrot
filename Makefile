export PATH := $(wildcard $(PWD)/riscv64-*/bin/):$(PATH)

# Digilent Arty
prebuilt/fpga/Arty/digilent_arty.bit:
	litex-boards/litex_boards/targets/digilent_arty.py --build \
		--sys-clk-freq 20e6 --cpu-type blackparrot --cpu-variant standard \
		--variant=a7-100 --csr-csv "csr-arty.csv"
	cp build/digilent_arty/gateware/digilent_arty.bit prebuilt/fpga/Arty/digilent_arty.bit

prebuilt/fpga/boot_digilent_arty.bin:
	cd freedom-u-sdk && \
	git submodule update --init --recursive
	$(MAKE) -C freedom-u-sdk bbl LITEX_MODE=-DLITEX_MODE
	riscv64-unknown-elf-objcopy -O binary freedom-u-sdk/work/riscv-pk/bbl prebuilt/fpga/Arty/boot_digilent_arty.bin

arty: prebuilt/fpga/Arty/digilent_arty.bit prebuilt/fpga/Arty/boot_digilent_arty.bin
	mkdir -p build/digilent_arty/gateware
	cp prebuilt/fpga/Arty/digilent_arty.bit build/digilent_arty/gateware
	litex-boards/litex_boards/targets/digilent_arty.py --load \
		--sys-clk-freq 20e6 --cpu-type blackparrot --cpu-variant standard \
		--variant=a7-100 --csr-csv "csr-arty.csv"
	lxterm /dev/ttyUSB* --kernel prebuilt/fpga/Arty/boot_digilent_arty.bin --kernel-adr 0x80000000 --speed=115200


# Qmtech Wukong
prebuilt/fpga/Wukong/qmtech_wukong.bit:
	litex-boards/litex_boards/targets/qmtech_wukong.py --build \
		--sys-clk-freq 20e6 --cpu-type blackparrot --cpu-variant standard \
		--board-version=2 --csr-csv "csr-wukong.csv"
	cp build/qmtech_wukong/gateware/qmtech_wukong.bit prebuilt/fpga/Wukong/qmtech_wukong.bit

prebuilt/fpga/boot_qmtech_wukong.bin:
	cd freedom-u-sdk && \
	git submodule update --init --recursive
	$(MAKE) -C freedom-u-sdk bbl LITEX_MODE=-DLITEX_MODE
	riscv64-unknown-elf-objcopy -O binary freedom-u-sdk/work/riscv-pk/bbl prebuilt/fpga/Wukong/boot_qmtech_wukong.bin

wukong: prebuilt/fpga/Wukong/qmtech_wukong.bit prebuilt/fpga/Wukong/boot_qmtech_wukong.bin
	mkdir -p build/qmtech_wukong/gateware
	cp prebuilt/fpga/Wukong/qmtech_wukong.bit build/qmtech_wukong/gateware
	litex-boards/litex_boards/targets/qmtech_wukong.py --load \
		--sys-clk-freq 20e6 --cpu-type blackparrot --cpu-variant standard \
		--board-version=2 --csr-csv "csr-wukong.csv"
	lxterm /dev/ttyUSB* --kernel prebuilt/fpga/Wukong/boot_qmtech_wukong.bin --kernel-adr 0x80000000 --speed=115200


# Simulation
prebuilt/simulation/boot_simulation.bin:
	cd freedom-u-sdk && \
	git submodule update --init --recursive && \
	$(MAKE) -C freedom-u-sdk bbl LITEX_MODE=-DLITEX_MODE
	riscv64-unknown-elf-objcopy -O binary freedom-u-sdk/work/riscv-pk/bbl prebuilt/simulation/boot_simulation.bin

simulation: prebuilt/simulation/boot_simulation.bin
	litex_sim --threads 4 \
		--opt-level Ofast \
		--cpu-type blackparrot \
		--cpu-variant sim \
		--with-sdram \
		--sdram-init prebuilt/simulation/boot_simulation.bin

simulation-non-interactive: prebuilt/simulation/boot_simulation.bin
	litex_sim --threads 4 \
		--opt-level Ofast \
		--cpu-type blackparrot \
		--cpu-variant sim \
		--with-sdram \
		--sdram-init prebuilt/simulation/boot_simulation.bin \
		--non-interactive
