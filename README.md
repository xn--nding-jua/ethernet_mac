# 10/100/1000 VHDL Ethernet MAC

This tri-mode full-duplex Ethernet MAC sublayer was developed in VHDL as an alternative to both commercial and free implementations for usage on FPGAs. Its main distinction is the focus on simplicity both in the external user interface and internal operation. Only essential Ethernet functionality is supported.

The core fully works on Xilinx Spartan 6 family FPGAs only at the moment. It was verified on hardware on a Trenz Electronic GmbH TE0600 GigaBee micromodule with a TE0603 baseboard.

The user interface is comprised of two FIFOs with a 8-bit data bus for packet transmission and reception, respectively.

This page is a short overview of the features and usage of the MAC. More information on the design and implementation can be found in the design document at <https://github.com/yol/ethernet_mac_doc/raw/master/Thesis.pdf>.

Features
-------
Finished:

 - **Full-duplex IEEE 802.3 communication** on copper at 10 (10BASE-T), 100 (100BASE-TX), and 1000 (1000BASE-T) Mb/s physical link speed
 - Achievable **data rate very close to theoretical maximum**
 - Generation of Ethernet preamble and frame check sequence on transmission
 - Verification of received packets (preamble, size, frame check sequence)
 - Filtering received packets by destination MAC address
 - MAC address insertion into source address of outgoing packets (only when the first source address byte in the packet stream is `0xFF`)
 - **Simple 8 bit wide FIFO user interface** with arbitrary clock domains for packet transmission and reception
 - **Media-independent interface (MII)** for 10/100 Mb/s and **gigabit media-independent interface (GMII)** connectivity
	 - MII/GMII hardware I/O setup for Xilinx Spartan 6 family FPGAs
 - Basic **media-independent interface management (MIIM) interface support** that:
	 - Configures the PHY auto-negotiation to use full-duplex modes only
	 - Polls the current PHY link state and speed by reading the status and auto-negotiation registers

Decisively not supported:

 - CSMA/CD (which effectively means **no half-duplex connections**)
 - Flow control with PAUSE frames
 - Energy-efficient Ethernet
 - Multicast reception filter
 - On-chip buses (can be integrated with custom code if needed)
 - Runtime configuration of core features and parameters
 - Manual link speed configuration via MIIM
 - Packet counters/statistics

Ideas for the future:

 - Replacement of the TX FIFO that is currently generated by the Xilinx core generator with a custom VHDL implementation
 - Reduced gigabit media-independent interface (RGMII) support

Preparation
-------
Using the core currently requires an installation of Xilinx ISE 14.7 (WebPack will work) for the TX FIFO generation.
In preparation for both running the testbench and using the MAC in a project, please follow these steps:

 - Open the project file `ethernet_mac.xise` in the ISE project navigator
 - Select the root node "xc6slx45-2fgg484" in the hierarchy view
 - Run the "Regenerate All Cores" process under "Design Utilities"

Verifying the design
-------
The source code includes the self-checking testbench entity `ethernet_mac_tb`. 

If you have [GHDL](http://ghdl.free.fr/) and make installed, you can start a basic functional verification in a behavioral simulation of the core by simply running

    $ make prepare ISE_DIR=/path/to/14.7/ISE_DS/ISE
    $ make check 
If everything works as expected, the last output line should read `MAC functional check ended OK`. Note that by default only a reduced set of tests is performed, you can modify the `TEST_THOROUGH` generic in `ethernet_mac_tb.vhd` to run the full test suite.
ModelSim also works fine when you have the Xilinx libraries correctly imported. ISim will not unfortunately as it needs excessive amounts of system RAM when running the testbench. 

Post-synthesis verification is also supported with the XC6SLX45-2FGG484 FPGA as sample target device. To get the simulation model, select the `test_instance_spartan6` top module in the ISE hierarchy view and run the "Generate Post-Place & Route Simulation Model" process under "Implement Design" / "Place & Route" (or Post-Translate/Post-Map if desired). It was only tested in ModelSim, but other simulators are expected to work as well. You only need the following files for post-synthesis simulation (and a correctly linked Xilinx ISE `simprim` VHDL library):

 - `crc.vhd`
 - `crc32.vhd`
 - `ethernet_mac_tb.vhd`
 - `ethernet_types.vhd`
 - `framing_common.vhd`
 - `test/test_common.vhd`
 - `utility.vhd`
 - `xilinx/test/test_configuration_spartan6.vhd`
 - `xilinx/test/test_wrapper_spartan6.vhd`
 - `netgen/par/test_instance_spartan6_timesim.vhd`

Start the `work.post_synthesis_spartan6` configuration then (*not* `work.ethernet_mac_tb`). When using ModelSim, you must set the time resolution to ps or finer. You might also want to set the `TEST_MII_SETUPHOLD` generic to `TRUE` for additional setup/hold time simulation. If you use the SDF file at `netgen/par/test_instance_spartan6_timesim.sdf` for delay modeling, apply it to the region `/ethernet_mac_inst/test_instance_inst`.

To test the design on actual hardware, follow the instructions in the [ethernet\_mac\_test](https://github.com/yol/ethernet_mac_test) (benchmark) or [Chips-Demo](https://github.com/yol/Chips-Demo) (example webserver user application) project.

**Please note that while this design includes a testbench for most functionality and is proven in practice, it is still the result of a Bachelor's thesis and not a professional product. As such, all usage is at your own responsibility. This is especially true if you use the source code or any derivative product to operate nuclear facilities, life support, or other mission critical applications where human life or property may be at stake or endangered. See also the [license and disclaimer](LICENSE.md).**

Using the MAC
-------------
Basic project setup with Xilinx ISE 14.7:

 - Open your own project in the ISE project navigator
 - Open the Libraries panel
 - Right-click and select "New VHDL Library"
 - Enter `ethernet_mac` as the "New VHDL Library Name" and select the folder you cloned this repository to as "Library Files Location"
 - Click "OK" in the dialog and the one popping up directly after it
 - Right-click on the newly added library, select "Add Source", and add the following files from the repository (always click "OK" in the "Adding Source Files" dialog without changing anything):
	 - All `.vhd` files in the `xilinx` directory
	 - `xilinx/ipcore_dir/ethernet_mac_tx_fifo_xilinx.xco`
 - Add the timing constraints found in `xilinx/test/test_instance_spartan6.ucf` to your own constraints file. You might need to adapt the pin names to your design.

The entity you will usually want to instantiate is `ethernet_with_fifos`. It includes all modules relevant for Ethernet operation and FIFOs for packet TX and RX. You need to include the following code in the head of your VHDL file to use the custom data types:

    library ethernet_mac;
    use ethernet_mac.ethernet_types.all;

The ports are as follows:

Port     | Function
-------- | ---
`clock_125_i` | 125 MHz *unbuffered* reference clock for GMII TX operation
`reset_i`  | Active-high asynchronous reset for the whole core
`mac_address_i` | MAC address of the local entity, should not change after `reset_i` is deasserted
`mii_tx_clk_i` | MII `TX_CLK`
`mii_tx_er_o` | MII `TX_ER`
`mii_tx_en_o` | MII `TX_EN`
`mii_txd_o` | MII `TXD`
`mii_rx_clk_i` | MII `RX_CLK`
`mii_rx_er_i` | MII `RX_ER`
`mii_rx_dv_i` | MII `RX_DV`
`mii_rxd_i` | MII `RXD`
`gmii_gtx_clk_o` | GMII `GTX_CLK`
`miim_clock_i` | Clock used for MIIM operation
`mdc_o` | MIIM `MDC`
`mdio_io` | MIIM `MDIO`
`link_up_o` | Link status indicator synchronous to `miim_clock_i`
`speed_o` | Link speed indicator synchronous to `miim_clock_i`
`speed_override_i` | Overrides the speed detected via MIIM if supplied, must be synchronous to `miim_clock_i`
`tx_clock_i` | TX FIFO clock
`tx_reset_o` | Synchronous reset for all logic using the TX FIFO
`tx_data_i` | TX FIFO data
`tx_wr_en_i` | TX FIFO write enable
`tx_full_o` | TX FIFO full indication
`rx_clock_i` | RX FIFO clock
`rx_reset_o` | Synchronous reset for all logic using the RX FIFO
`rx_empty_o` | RX FIFO empty indication
`rx_rd_en_i` | RX FIFO read enable
`rx_data_o` | RX FIFO data

The generics:

Generic | Function
------- | ------
`MIIM_PHY_ADDRESS` | MIIM address of the PHY (refer to its data sheet to see how this is configured on the PHY side)
`MIIM_RESET_WAIT_TICKS ` | Number of `miim_clock_i` cycles to wait until accessing registers after reset is deasserted
`MIIM_POLL_WAIT_TICKS` | Number of `miim_clock_i` cycles to wait between polling the status and auto-negotiation registers
`MIIM_CLOCK_DIVIDER` | Clock divider between `miim_clock_i` and `mdc_o`. Make sure that the frequency of `mdc_o` is at most 2.5 MHz for IEEE 802.3 compatibility.
`MIIM_DISABLE` | Completely disable MIIM functionality when `TRUE`. You *have* to supply the current link speed on `speed_override_i` then!
`RX_FIFO_SIZE_BITS` | Set the size of the RX FIFO in powers of 2 by overriding the number of size bits

Connect all MII, GMII, and MIIM pins directly to the pads. `miim_clock_i`, `rx_clock_i` and `tx_clock_i` can be identical if desired. The default values for `MIIM_CLOCK_DIVIDER` and `MIIM_POLL_WAIT_TICKS` are calculated for a MIIM clock of 125 MHz.

Both the TX and the RX FIFO have a simple communication scheme. A packet unit on the FIFO interface consists of: 2 bytes of size information, most significant byte first, and then exactly as many bytes of data as were indicated. The data includes all Ethernet MAC headers (destination address, source address, and length/type) in the exact same order as defined in the standard, but not the frame check sequence trailer. The exact timing follows the interface of first-word-fall-through FIFOs generated by the Xilinx core generator but is generally not different from a "normal" FIFO interface. Refer to the FIFO generator user guide for details.
You can take a look at the [Chips-Demo file `chips_mac_adaptor.vhd`](https://github.com/yol/Chips-Demo/blob/master/source/chips_mac_adaptor.vhd) for an example of how an application might use the core.

Note that you might have to override the default input delays on the GMII RX path to your device in the constraints file e.g. using PlanAhead. It is expected that the strict GMII timing constraints can not be met completely under all circumstances.

> Written with [StackEdit](https://stackedit.io/).
