-- This file is part of the ethernet_mac project.
--
-- For the full copyright and license information, please read the
-- LICENSE.md file that was distributed with this source code.

-- Device-specific IO setup needed for communicating with the PHY

library ieee;
use ieee.std_logic_1164.all;

use work.ethernet_types.all;

entity rmii_io is
	port(
		-- RX and TX clocks
		clock_tx_o      : out std_ulogic;
		clock_rx_o      : out std_ulogic;

		-- Signals connected directly to external ports
		-- RMII
		rmii_clk_i       : in  std_ulogic;
		rmii_tx_en_o     : out std_ulogic;
		rmii_txd_o       : out t_ethernet_data;
		rmii_rx_er_i     : in  std_ulogic;
		rmii_rx_crs_dv_i : in  std_ulogic;
		rmii_rxd_i       : in  t_ethernet_data;

		-- Signals connected to the mii_gmii module
		int_rmii_tx_en_i : in  std_ulogic;
		int_rmii_txd_i   : in  t_ethernet_data;
		int_rmii_rx_er_o : out std_ulogic;
		int_rmii_rx_crs_dv_o : out std_ulogic;
		int_rmii_rxd_o   : out t_ethernet_data
	);
end entity;

