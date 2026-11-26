LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY testbench IS
END testbench;

ARCHITECTURE Behavior OF testbench IS

	-- importo il componente principale da testare (DUT)
	COMPONENT Lab2 IS
		PORT (
			MOSI, CLK_FPGA, OUT_EN, SEL1, RESET: IN STD_LOGIC;
			MISO, RW: OUT STD_LOGIC;
			SEL2: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
			ADDR: OUT STD_LOGIC_VECTOR(0 TO 14);
			DIN: OUT STD_LOGIC_VECTOR(0 TO 15);
			DOUT: IN STD_LOGIC_VECTOR(0 TO 15)
		);
	END COMPONENT;

	-- periodo del clock a 10 MHz (1 / 10 MHz = 100 ns)
	CONSTANT clk_period: TIME := 200 ps;

	-- vettori di test (15 bit indirizzo + 1 bit RW; 16 bit dato)
	CONSTANT cmd_write: STD_LOGIC_VECTOR(0 TO 15) := "1010101010101010"; -- RW = '0'
	CONSTANT data_write: STD_LOGIC_VECTOR(0 TO 15) := "1100110010101010";
	CONSTANT cmd_read: STD_LOGIC_VECTOR(0 TO 15) := "0101010101010101";  -- RW = '1'

	-- segnali collegati alle porte del DUT
	SIGNAL MOSI: STD_LOGIC := '0';
	SIGNAL CLK_FPGA: STD_LOGIC := '0';
	SIGNAL OUT_EN: STD_LOGIC := '0';
	SIGNAL SEL1: STD_LOGIC := '0';
	SIGNAL RESET: STD_LOGIC := '0';
	SIGNAL MISO: STD_LOGIC;
	SIGNAL RW: STD_LOGIC;
	SIGNAL SEL2: STD_LOGIC_VECTOR(1 DOWNTO 0) := "00";
	SIGNAL ADDR: STD_LOGIC_VECTOR(0 TO 14);
	SIGNAL DIN: STD_LOGIC_VECTOR(0 TO 15);
	SIGNAL DOUT: STD_LOGIC_VECTOR(0 TO 15) := (OTHERS => '0');

BEGIN

	-- istanziazione posizionale del sistema completo
	DUT: Lab2 PORT MAP (MOSI, CLK_FPGA, OUT_EN, SEL1, RESET, MISO, RW, SEL2, ADDR, DIN, DOUT);

	-- generazione clock continuo a 10 MHz (fronti di salita a 50 ns, 150 ns, 250 ns...)
	clk_process: PROCESS
	BEGIN
		CLK_FPGA <= '0';
		WAIT FOR clk_period / 2;
		CLK_FPGA <= '1';
		WAIT FOR clk_period / 2;
	END PROCESS;

	-- generazione degli stimoli
	stim_process: PROCESS
	BEGIN
		-- 1. RESET SINCRONO (attivo basso: deve attraversare almeno un fronte di salita)
		RESET <= '0';
		OUT_EN <= '0';
		SEL1 <= '0';
		SEL2 <= "00";
		MOSI <= '0';
		DOUT <= (OTHERS => '0');
		WAIT FOR clk_period; -- fronte di salita a 50 ns azzera tutti i flip-flop

		-- rilascio del reset sul fronte di discesa (t = 100 ns)
		RESET <= '1';

		-- 2. TRANSAZIONE DI SCRITTURA: invio 15 bit indirizzo + RW='0' in SR1 (voglio scrivere)
		SEL1 <= '1';
		FOR i IN 0 TO 15 LOOP
			MOSI <= cmd_write(i);
			WAIT FOR clk_period;
		END LOOP;
		SEL1 <= '0'; -- congela ADDR e RW

		-- 3. SCRITTURA DATO: invio 16 bit seriali da MOSI in SR2
		OUT_EN <= '0';
		SEL2 <= "01"; -- shift seriale
		FOR i IN 0 TO 15 LOOP
			MOSI <= data_write(i);
			WAIT FOR clk_period;
		END LOOP;
		SEL2 <= "00"; -- hold: DIN mostra il dato parallelo verso la memoria
		MOSI <= '0';
		WAIT FOR 2 * clk_period;

		-- 4. TRANSAZIONE DI LETTURA: invio nuovo indirizzo + RW='1' in SR1
		SEL1 <= '1';
		FOR i IN 0 TO 15 LOOP
			MOSI <= cmd_read(i);
			WAIT FOR clk_period;
		END LOOP;
		SEL1 <= '0';
		MOSI <= '0';

		-- 5. CARICAMENTO PARALLELO DA MEMORIA (DOUT -> SR2)
		DOUT <= "1111000010100101";
		SEL2 <= "11"; -- parallel load
		WAIT FOR clk_period;

		-- 6. LETTURA SERIALE VERSO IL MASTER (SR2 -> MISO)
		OUT_EN <= '1'; -- disconnette MOSI e abilita il buffer verso MISO
		SEL2 <= "01";  -- shift seriale verso destra per 16 cicli
		WAIT FOR 16 * clk_period;

		-- 7. FINE TRANSAZIONE: ritorno in alta impedenza
		OUT_EN <= '0';
		SEL2 <= "00";
		WAIT;
	END PROCESS;

END Behavior;