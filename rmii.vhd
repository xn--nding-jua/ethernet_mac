-- This file is part of the ethernet_mac project.
--
-- For the full copyright and license information, please read the
-- LICENSE.md file that was distributed with this source code.

-- Adaption layer for data transfer with RMII

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.framing_common.all;
use work.ethernet_types.all;

entity rmii is
	port(
		tx_reset_i         : in  std_ulogic;
		tx_clock_i         : in  std_ulogic;
		rx_reset_i         : in  std_ulogic;
		rx_clock_i         : in  std_ulogic;

		-- RMII (Reduced-Media-independent interface)
		rmii_tx_en_o       : out std_ulogic;
		rmii_txd_o         : out std_ulogic_vector(1 downto 0);
		rmii_rx_er_i       : in  std_ulogic;
		rmii_rx_crs_dv_i   : in  std_ulogic;
		rmii_rxd_i         : in  std_ulogic_vector(1 downto 0);

		-- TX/RX control
		-- TX signals synchronous to tx_clock
		tx_enable_i        : in  std_ulogic;
		-- When asserted together with tx_enable_i, tx_byte_sent_o works as normal, but no data is actually
		-- put onto the media-independent interface (for IPG transmission)
		tx_gap_i           : in  std_ulogic;
		tx_data_i          : in  t_ethernet_data;
		-- Put next data byte on tx_data_i when asserted
		tx_byte_sent_o     : out std_ulogic;

		-- RX signals synchronous to rx_clock
		-- Asserted as long as one continuous frame is being received
		rx_frame_o         : out std_ulogic;
		-- Valid when rx_byte_received_o is asserted
		rx_data_o          : out t_ethernet_data;
		rx_byte_received_o : out std_ulogic;
		rx_error_o         : out std_ulogic
	);
end entity;

architecture rtl of rmii is
	-- Transmission
	type t_rmii_tx_state is (
		TX_INIT,
		TX_DIBIT_0, -- Bits 1:0
		TX_DIBIT_1, -- Bits 3:2
		TX_DIBIT_2, -- Bits 5:4
		TX_DIBIT_3  -- Bits 7:6
	);
	signal tx_state : t_rmii_tx_state := TX_INIT;

	-- Reception
	type t_rmii_rx_state is (
		RX_INIT,
		RX_DIBIT_0, -- Bits 1:0
		RX_DIBIT_1, -- Bits 3:2
		RX_DIBIT_2, -- Bits 5:4
		RX_DIBIT_3  -- Bits 7:6
	);
	signal rx_state : t_rmii_rx_state := RX_INIT;

	signal tx_data_reg : t_ethernet_data := (others => '0');
	signal tx_gap_reg  : std_ulogic := '0';
begin

	-- TX FSM is split into this synchronous process and the output process for tx_byte_sent_o
	-- A strictly one-process FSM is impractical for MII transmission: Wait states would be needed
	-- to correctly generate tx_byte_sent_o for GMII. 
	rmii_tx_sync : process(tx_reset_i, tx_clock_i)
	begin
		-- Use asynchronous reset, clock_tx is not guaranteed to be running during system initialization
		if tx_reset_i = '1' then
			tx_state    <= TX_INIT;
			tx_data_reg  <= (others => '0');
         tx_gap_reg   <= '0';
			rmii_tx_en_o <= '0';
			rmii_txd_o <= (others => '0');
		elsif rising_edge(tx_clock_i) then
			rmii_tx_en_o <= '0';
			rmii_txd_o   <= (others => '0');

			case tx_state is
				when TX_INIT =>
					tx_state <= TX_DIBIT_0;
				when TX_DIBIT_0 =>
					if tx_enable_i = '1' then
						tx_data_reg <= tx_data_i;
						tx_gap_reg  <= tx_gap_i;
							  
						rmii_tx_en_o <= not tx_gap_i;
						rmii_txd_o   <= tx_data_i(1 downto 0);
						tx_state <= TX_DIBIT_1;
					end if;
				when TX_DIBIT_1 =>
					rmii_tx_en_o <= not tx_gap_reg;
					rmii_txd_o   <= tx_data_reg(3 downto 2);
					tx_state <= TX_DIBIT_2;
				when TX_DIBIT_2 =>
					rmii_tx_en_o <= not tx_gap_reg;
					rmii_txd_o   <= tx_data_reg(5 downto 4);
					tx_state <= TX_DIBIT_3;
				when TX_DIBIT_3 =>
					rmii_tx_en_o <= not tx_gap_reg;
					rmii_txd_o   <= tx_data_reg(7 downto 6);
					tx_state    <= TX_DIBIT_0;
			end case;
		end if;
	end process;

	-- TX output process
	-- Generates only the tx_byte_sent_o output
	rmii_tx_output : process(tx_state)
	begin
		-- Default output value
		tx_byte_sent_o <= '0';

		case tx_state is
			when TX_DIBIT_3 =>
				tx_byte_sent_o <= '1';
         when others =>
            null;
		end case;
	end process;

	-- RMII packet reception
	rmii_rx_fsm : process(rx_clock_i, rx_reset_i)
	begin
		if rx_reset_i = '1' then
			rx_state           <= RX_INIT;
			rx_byte_received_o <= '0';

			rx_frame_o         <= '0';
			rx_data_o          <= (others => '0');
			rx_error_o         <= '0';
		elsif rising_edge(rx_clock_i) then
			-- Default output values
			rx_frame_o         <= '0';
			rx_byte_received_o <= '0';
			rx_error_o         <= '0';

			if rx_state /= RX_INIT then
				-- Hand indicators through
				rx_error_o <= rmii_rx_er_i;
				rx_frame_o <= rmii_rx_crs_dv_i;
			end if;

			case rx_state is
				when RX_INIT =>
					-- Wait for a pause in reception
					if rmii_rx_crs_dv_i = '0' then
						rx_state <= RX_DIBIT_0;
					end if;
				when RX_DIBIT_0 =>
					-- Wait until start of reception
					if rmii_rx_crs_dv_i = '1' then
						rx_state <= RX_DIBIT_1;
					end if;
					-- Capture first two bits
					rx_data_o(1 downto 0) <= rmii_rxd_i(1 downto 0);
				when RX_DIBIT_1 =>
					-- Wait until start of reception
					if rmii_rx_crs_dv_i = '1' then
						-- Capture second two bits
						rx_data_o(3 downto 2) <= rmii_rxd_i(1 downto 0);
						rx_state <= RX_DIBIT_2;
					else
						rx_error_o <= '1';
						rx_state <= RX_DIBIT_0;
					end if;
				when RX_DIBIT_2 =>
					-- Wait until start of reception
					if rmii_rx_crs_dv_i = '1' then
						-- Capture third two bits
						rx_data_o(5 downto 4) <= rmii_rxd_i(1 downto 0);
						rx_state <= RX_DIBIT_3;
					else
						rx_error_o <= '1';
						rx_state <= RX_DIBIT_0;
					end if;
				when RX_DIBIT_3 =>
					if rmii_rx_crs_dv_i = '1' then
						-- Capture last two bits and mark it valid
						rx_data_o(7 downto 6) <= rmii_rxd_i(1 downto 0);
						rx_byte_received_o    <= '1';
						rx_frame_o            <= '1';
					else
						-- Frame ended prematurely
						rx_error_o <= '1';
					end if;
					rx_state <= RX_DIBIT_0;
			end case;
		end if;
	end process;

end architecture;
