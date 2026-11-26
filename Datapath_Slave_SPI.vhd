LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY Datapath_Slave_SPI IS
	PORT (
		MOSI, CLK_FPGA, OUT_EN, SEL1, RESET: IN STD_LOGIC;
		MISO, RW: OUT STD_LOGIC;
		SEL2: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
		ADDR: OUT STD_LOGIC_VECTOR(0 TO 14);
		DIN: OUT STD_LOGIC_VECTOR(0 TO 15);
		DOUT: IN STD_LOGIC_VECTOR(0 TO 15)
	);
END Datapath_Slave_SPI;

ARCHITECTURE Behavior OF Datapath_Slave_SPI IS
	-- importo i componenti
	-- primo shift register
	COMPONENT shift_reg1 IS
		PORT (
			MOSI, Shift, Clock, Resetn: IN STD_LOGIC; -- Shift segnale di selezione del mux a 2 vie
			Q: OUT STD_LOGIC_VECTOR(0 TO 14); -- uscita dei bit di indirizzo
			RW: OUT STD_LOGIC -- uscita del segnale RW
		);
	END COMPONENT;
	-- secondo shift register
	COMPONENT shift_reg2 IS
		PORT (
			MOSI, Clock, Resetn: IN STD_LOGIC; 
			Shift: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
			DOUT: IN STD_LOGIC_VECTOR(0 TO 15);
			MISO: OUT STD_LOGIC;
			Q: OUT STD_LOGIC_VECTOR(0 TO 15) -- uscita dei bit di dato
		);
	END COMPONENT;
	-- buffer tri-state
	COMPONENT tristate IS
		PORT (
			input, enable: IN STD_LOGIC;
			output: OUT STD_LOGIC
		);
	END COMPONENT;

	-- segnali utili per le interconnessioni
	SIGNAL mosi_out_buf1: STD_LOGIC;
	SIGNAL miso_sr2: STD_LOGIC;
	SIGNAL not_out_en: STD_LOGIC;

BEGIN

	not_out_en <= NOT OUT_EN;

	-- componenti
	buf1: tristate PORT MAP (MOSI, not_out_en, mosi_out_buf1);
	buf2: tristate PORT MAP (miso_sr2, OUT_EN, MISO);

	sr1: shift_reg1 PORT MAP (MOSI, SEL1, CLK_FPGA, RESET, ADDR, RW);
	sr2: shift_reg2 PORT MAP (mosi_out_buf1, CLK_FPGA, RESET, SEL2, DOUT, miso_sr2, DIN);

END Behavior;