LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY shift_reg2 IS
	PORT (
		MOSI, Clock, Resetn: IN STD_LOGIC; 
		Shift: IN STD_LOGIC_VECTOR(1 downto 0);
		DOUT: IN STD_LOGIC_VECTOR(15 downto 0);
		MISO: OUT STD_LOGIC;
		Q: OUT STD_LOGIC_VECTOR(15 downto 0) -- uscita dei bit di dato
	);
END shift_reg2;

ARCHITECTURE Behavior OF shift_reg2 IS

	-- importo i componenti
	COMPONENT mux4 IS
		PORT (
			input1, input2, input3, input4: IN STD_LOGIC;
			sel: IN STD_LOGIC_VECTOR(1 downto 0);
			output: OUT STD_LOGIC
		);
	END COMPONENT;

	COMPONENT flipflop IS
		PORT (
			D, Clock, Resetn: IN STD_LOGIC;
			Q: OUT STD_LOGIC
		);
	END COMPONENT;

	-- d_mux: collega l'uscita del mux all'ingresso del FF
	SIGNAL d_mux: STD_LOGIC_VECTOR(15 downto 0);
	-- shift_chain: collega l'uscita del FF all'ingresso 0 del mux
	SIGNAL shift_chain: STD_LOGIC_VECTOR(16 downto 0);

BEGIN

	-- Il bit seriale in ingresso entra in testa allo stadio 0
	shift_chain(0) <= MOSI;

	-- Replicazione dei 16 stadi (mux4 + flipflop) in cascata da 0 verso 15
	gen_shift: FOR i IN 0 TO 15 GENERATE
		mux_inst: mux4 PORT MAP (
			shift_chain(i + 1), -- ingresso 00: mantiene il valore attuale del registro
			shift_chain(i), -- ingresso 01: preleva il bit dallo stadio precedente
			shift_chain(i + 1), -- ingresso 10: mantiene il valore attuale (stato sicuro)
			DOUT(i), -- ingresso 11
			Shift,
			d_mux(i)
		);

		ff_inst: flipflop PORT MAP (
			d_mux(i),
			Clock,
			Resetn,
			shift_chain(i + 1)
		);
	END GENERATE;

	-- Uscita parallela collegata ai 16 flip-flop
	Q <= shift_chain(16 downto 1);
	MISO <= shift_chain(16);

END Behavior;
