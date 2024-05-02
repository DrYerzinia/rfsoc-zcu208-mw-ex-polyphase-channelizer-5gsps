# Tool Versions

This tutorial was run using Matlab 2024a and Vivado 2023.1

# Model Changes

The model had issues with how it was simulating the AXI stream.  An extra delay was removed from the AXI Ready.  And the randomly generated TReady signal was anded with the TValid so itw would work correctly.

The channelizer block cannot take in non-power of 2 sample blocks, and the ADC Tiles max out at 12 wide sample blocks.  So sets of 12x4 samples are remapped into sets of 16x3 to pass ot the channelizer.  The clock rate is not changed.

Because of the obtuse nature of the FIFO serialize it was re-designed which lead to the discovery of the AXI issues.  This was changed from 4-fifos to 16 to handle the additonal steps.

The AXI stream reader was changed to use TLast.

# RFSoC Image Setup

## SD Flash

To flash the Mathworks Linux image to the SD Card run the following code in matlab with `mmcblck0` set to be the block device representing the SDCard you want to flash.

```Matlab
imagePath = socSDCardImage('Xilinx Zynq UltraScale+ RFSoC ZCU208 Evaluation Kit')
socWriteSDCardImage(imagePath, 'SDCardDrive', '/dev/mmcblk0')
```

## Network Config

In the writen image it can be useful to update the interface's file to a static IP to know where the device will com up on the network.

```sh
iface eth0 inet static
	address 10.118.183.151
	netmask 255.255.255.0
	gateway 10.118.183.1
```

## Device Tree

The default deviec tree for the RFSoC ZCU208 does not have IIO support in the device tree.  To enable it for 64-bit wide transfers activate the image run the following on the board.

```sh
cp /mnt/devicetree_adi_axistream_64.dtb /mnt/devicetree.dtb
```

# Running Code

## Generate .bit and Config

Make sure that rfsoc-zcu208-mw-ex-polyphase-channelizer-5gsps is the current directory in Matlab.

Open the model `rfsocChannelizer.slx`.

In the `Modeling` tab in the `Setup` section select `Model Settings`.

Under `Hardware Implementation` set `Hardware board` to `Xilinx Zynq UltraScale+ RFSoC ZCU208 Evaluation kit` and click apply.  In the same section under `Hardware board settings` set `Processing Unit` to `FPGA` and click apply.

Under `Code Generation > Optimization` set `Default parameter behaviour` to `Inlined` and click apply.

Under `HDL Coder Generation > Target` ensure `Target platform` is set to `Xilinx Zynq UltraScale+ RFSoC ZCU208 Evaluation kit` and click apply.

Right click on the ADCDataCapture block and select `HDL Code > HDL Workflow Advisor`.

In step 1.1 set `Target platform` is set to `Xilinx Zynq UltraScale+ RFSoC ZCU208 Evaluation kit` and click `Run This Task`.

In step 1.2 set `Reference design` is set to `Generic Design with real DAC/ADC and real-time interfaces` and click `Run This Task` and set the parameters as follows:


| Parameter                   | Value |
|-----------------------------|-------|
| ADC Sampling Rate (MHz)     | 5000  |
| ADC Decimation Rate (xN)    | 1     |
| ADC Samples Per Clock Cycle | 12    |
| DAC Sampling Rate (MHz)     | 5000  |
| DAC Decimation Rate (xN)    | 1     |
| DAC Samples Per Clock Cycle | 12    |


In step 1.3 set the options below in the table and then click `Run This Task`.

| Port Name          | Target Platform Interface       | Interface Mapping |
|--------------------|---------------------------------|-------------------|
| MM2S_Valid         | Software to AXI Stream Slave    | Valid             |
| MM2S_Data          | Software to AXI Stream Slave    | Data              |
| MM2S_TLAST         | Software to AXI Stream Slave    | TLAST (optional)  |
| SS2M_TReady        | AXI Stream to Software Master   | Ready (optional)  |
| Tile0 ADC Ch0 Data | RFDC ADC Tile0 Ch0 Data [0:191] | [0:191]           |
| Tile0 ADC Ch0 Data | RFDC ADC Tile0 Ch0 Valid        | [0]               |
| S2MM_Valid         | AXI Stream to Software Master   | Valid             |
| S2MM_Data          | AXI Stream to Software Master   | Data              |
| S2MM_TLast         | AXI Stream to Software Master   | TLAST (optional)  |
| MM2S_Ready         | Software to AXI Stream Slave    | Ready (optional)  |
| Tile1 DAC Ch3 Data | RFDC DAC Tile0 Ch0 Data [0:191] | [0:191]           |
| Tile1 DAC Ch3 Data | RFDC DAC Tile0 Ch0 Valid        | [0]               |

Select step 4.1 and then right lick on step 4.1 and select `Run to Selected Task`.

It can be useful to read the `IP Core Generation Report` section of the `Code Generation Report` that pops up.

In the result section open the Vivado Project by clicking `hdl_prj/vivado_ip_prj/vivado_prj.xpr` on the 4th line.

You will need to go into the address editor and fix the addresses as shown below.  The generated block design will have different addresses than the default image device tree.

| Device          | DTB Address |
|-----------------|-------------|
| mm2s0           | 0xA0020000  |
| s2mm0           | 0xA0030000  |
| RFDataConverter | 0xA0040000  |

Under `PROGRAM AND DEBUG` select `Generate Bitstream`.  This will take about 15 minutes.

Once the bitstream is generated the files need to be copied over.

## Bit File

The generated bit file is at `hdl_prj/vivado_ip_prj/vivado_prj.runs/impl_1/system_wrapper.bit` and needs to be copied to `/mnt/system.bit`.

After updating the bit file reboot the system.

## RF-Init

The `rf-init` executable uses the the `RF_init.conf` generated in `hdl_prj/vivado_ip_prj` to configure the DAC/ADC Tiles and clocks of the RFSoC.

To use it place the `RF_init.conf` in `/mnt/hdlcoder_rd`.  After booting the board just run `/mnt/rf-init` to setup the DAC/ADC Tiles and clocks for the new bistream.

# Running the code

Artifacts are provided for the bistream and converter config to allow you to skip strait to this step.  They can be retrived from the github releases.

On the RFSoC run the `rf-init` to setup the RFDataConverter and the clocks.

```sh
/mnt/rf-init
```

In matlab open and run `hostIO_rfsocChannelizer_interface.m`.
