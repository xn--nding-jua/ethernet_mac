-- This file is part of the ethernet_mac project.
--
-- For the full copyright and license information, please read the
-- LICENSE.md file that was distributed with this source code.
--
-- Device-specific IO setup needed for communicating with the PHY
--
-- Copyright (c) 2015, Philipp Kerling
-- All rights reserved.
-- 
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are met:
-- 
-- * Redistributions of source code must retain the above copyright notice, this
--   list of conditions and the following disclaimer.
-- 
-- * Redistributions in binary form must reproduce the above copyright notice,
--   this list of conditions and the following disclaimer in the documentation
--   and/or other materials provided with the distribution.
-- 
-- * Neither the name of ethernet\_mac nor the names of its
--   contributors may be used to endorse or promote products derived from
--   this software without specific prior written permission.
-- 
-- * Neither the source code, nor any derivative product, may be used for military
--   purposes.
-- 
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
-- IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
-- DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
-- FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
-- DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
-- SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
-- CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
-- OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
-- OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--

library ieee;
use ieee.std_logic_1164.all;

use work.ethernet_types.all;

entity rmii_io is
	port(
		-- RX and TX clocks
		clock_tx_o       : out std_ulogic;
		clock_rx_o       : out std_ulogic;

		-- Signals connected directly to external ports
		-- RMII
		rmii_clk_i       : in  std_ulogic;
		rmii_tx_en_o     : out std_ulogic;
		rmii_txd_o       : out std_ulogic_vector(1 downto 0);
		rmii_rx_er_i     : in  std_ulogic;
		rmii_rx_crs_dv_i : in  std_ulogic;
		rmii_rxd_i       : in  std_ulogic_vector(1 downto 0);

		-- Signals connected to the mii_gmii module
		int_rmii_tx_en_i : in  std_ulogic;
		int_rmii_txd_i   : in  std_ulogic_vector(1 downto 0);
		int_rmii_rx_er_o : out std_ulogic;
		int_rmii_rx_crs_dv_o : out std_ulogic;
		int_rmii_rxd_o   : out std_ulogic_vector(1 downto 0)
	);
end entity;

architecture Behavioral of rmii_io is
	signal clock        : std_ulogic := '0';
begin
	-- set rx/tx-clock
	--clock <= rmii_clk_i;
		
	-- output rx/tx-clocks
	clock_tx_o <= rmii_clk_i; -- clock;
	clock_rx_o <= rmii_clk_i; -- clock;

	process (rmii_clk_i) -- clock
	begin
		if rising_edge(rmii_clk_i) then -- clock
			-- output data to PHY
			rmii_tx_en_o <= int_rmii_tx_en_i;
			rmii_txd_o <= int_rmii_txd_i;

			-- receive data from PHY
			int_rmii_rx_crs_dv_o <= rmii_rx_crs_dv_i;
			int_rmii_rx_er_o <= rmii_rx_er_i;
			int_rmii_rxd_o <= rmii_rxd_i;
		end if;
	end process;
end architecture;
