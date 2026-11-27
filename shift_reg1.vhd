LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY shift_reg1 IS
	PORT (
		MOSI, Shift, Clock, Resetn: IN STD_LOGIC; -- Shift segnale di selezione del mux a 2 vie
		Q: OUT STD_LOGIC_VECTOR(14 downto 0); -- uscita dei bit di indirizzo
		RW: OUT STD_LOGIC -- uscita del segnale RW
	);
END shift_reg1;

ARCHITECTURE Behavior OF shift_reg1 IS

	-- importo i componenti
	COMPONENT mux2 IS
		PORT (
			in0, in1, sel: IN STD_LOGIC;
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

	-- Replicazione dei 16 stadi (mux2 + flipflop) in cascata da 0 verso 15
	gen_shift: FOR i IN 0 TO 15 GENERATE
		mux_inst: mux2 PORT MAP (
			shift_chain(i + 1), -- ingresso 0: mantiene il valore attuale del registro
			shift_chain(i),     -- ingresso 1: preleva il bit dallo stadio precedente
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
	RW <= shift_chain(1);
	Q <= shift_chain(16 downto 2);

END Behavior;
