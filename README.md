[![License](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

# BlackParrot in LiteX

This repository presents necessary steps to run Linux on FPGA and simulation level using BP core integrated into LiteX.

> **Note:** Running Linux does not work currently. However, it is possible to enter the LiteX bios.


## Prerequisites

```
$ sudo apt-get install wget build-essential python3 verilator libevent-dev libjson-c-dev device-tree-compiler make openocd
$ pip3 install setuptools requests pexpect
$ git clone https://github.com/scanakci/linux-on-litex-blackparrot
$ cd linux-on-litex-blackparrot
$ git submodule update --init --recursive
```
## Installing LiteX

```
$ cd linux-on-litex-blackparrot/litex
$ python3 litex_setup.py init install --user --config=full
```

Additionally, the version of the BlackParrot unicore lite used here requires some hotfixes:
```
$ cd linux-on-litex-blackparrot
$ sed -i "s:localparam dram_base_addr_gp         = 40'h00_8000_0000;:localparam dram_base_addr_gp         = 40'h00_7000_0000;:" pythondata-cpu-blackparrot/pythondata_cpu_blackparrot/system_verilog/black-parrot/bp_common/src/include/bp_common_addr_pkgdef.svh
$ sed -i "s:fsm_ready_and_o = (fsm_v_i & ~fsm_last_o) | msg_ready_and_i;:fsm_ready_and_o = ~fsm_last_o | msg_ready_and_i;:" pythondata-cpu-blackparrot/pythondata_cpu_blackparrot/system_verilog/black-parrot/bp_me/src/v/network/bp_me_stream_pump_out.sv
```

## Installing RISC-V toolchain
```
$ cd linux-on-litex-blackparrot/litex
$ pip3 install meson ninja
$ python3 litex_setup.py gcc
```
Do not forget to add RISC-V toolchain binary path to your PATH.


## Pre-built Bitstream and BBL
Pre-built bistream for the Arty and pre-built Berkeley boot loader (bbl) can be found in the prebuilt folder.

## Running Linux 


### Simulation
Using make to:
```
$ cd linux-on-litex-blackparrot
$ make simulation
```

Alternatively manually launch simulation.
```
$ cd linux-on-litex-blackparrot
$ litex_sim --threads 4 --opt-level Ofast --cpu-type blackparrot --cpu-variant sim --with-sdram --sdram-init prebuilt/simulation/boot_simulation.bin
```

### FPGA
Using make to build the bits:
```
$ cd linux-on-litex-blackparrot
$ make arty
```

Alternatively manually generate the bitstream for the Arty:
```
$ cd litex
$ litex-boards/litex_boards/targets/digilent_arty.py --build --sys-clk-freq 20e6 --cpu-type blackparrot --cpu-variant standard --variant=a7-100 --csr-csv "csr-arty.csv"
```


Manually load the FPGA bitstream to the Arty:
```
$ cd litex
$ litex-boards/litex_boards/targets/digilent_arty.py --load --sys-clk-freq 20e6 --cpu-type blackparrot --cpu-variant standard --variant=a7-100 --csr-csv "csr-arty.csv"
```

You can also find the bitfile `digilent_arty.bit` in the `build/gateware` folder and upload it using vivado hardware manager.

In another terminal, launch LiteX terminal.
```
$ cd linux-on-litex-blackparrot
$ litex_term /dev/ttyUSB* --kernel prebuilt/fpga/Arty/boot_digilent_arty.bin --kernel-adr 0x80000000 --speed=115200
```

If the memory test fails you might need to adjust the [DRAM CL](https://github.com/enjoy-digital/litex/issues/933#issuecomment-873638621).

This step will boot up LinuX after copying bbl to DRAM through UART. The whole process will take roughly 20 minutes. You can login with username `root` and password `blackparrot`.



## Generating the BBL manually 
Using make:
```
$ cd linux-on-litex-blackparrot
$ make prebuilt/fpga/Arty/digilent_arty.bit
```

If you need to generate a BBL from scratch, please follow these steps.

Make sure to adjust the memory capacity in the [device_litex.dts](https://github.com/developandplay/riscv-pk/blob/f18ec2bcccb4273b06f22b2813912933b959ae1d/device_litex.dts#L29) file.
After initial generation if you want to adjust the dts make sure to `rm riscv-pk/machine/device.dtb` first.

Additionally adjust the location of the [UART CSR](https://github.com/developandplay/riscv-pk/blob/f18ec2bcccb4273b06f22b2813912933b959ae1d/machine/uart_lr.c#L9) to match the output of `csr-arty.csv`.

```sh
$ cd freedom-u-sdk
$ git checkout blackparrot_mods
$ git submodule update --init --recursive
# The BBL is located in work/riscv-pk/
$ make bbl LITEX_MODE=-DLITEX_MODE
# Final bbl that needs to be loaded in DRAM
$ riscv64-unknown-elf-objcopy -O binary work/riscv-pk/bbl boot.bin
```
