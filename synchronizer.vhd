library ieee;
use ieee.std_logic_1164.all;

entity SYNCHRONIZER_Slave_SPI is
    port (
        SYNCHRONIZER_i_CLK  : in std_logic;
        SYNCHRONIZER_i_CLK_FPGA  : in std_logic;
        SYNCHRONIZER_i_RST  : in std_logic;

        SYNCHRONIZER_O_RISE : out std_logic;
        SYNCHRONIZER_O_FALL : out std_logic
    );
end entity;

architecture behavior of SYNCHRONIZER_Slave_SPI is
    
TYPE State_type IS (S0, S1, S2, S3);
SIGNAL st_state, st_next_state : State_type;
SIGNAL s_clk_sample : std_logic;

BEGIN

--FSM table
state_table: PROCESS(st_state, s_clk_sample)
BEGIN
	CASE st_state  IS
		WHEN S0 => IF (s_clk_sample = '1') THEN st_next_state <= S1;
			ELSE st_next_state <= S0;
			END IF;
		WHEN S1 =>  st_next_state <= S2;
        WHEN S2 => IF (s_clk_sample = '0') THEN st_next_state <= S3;
            ELSE st_next_state <= S2;
			END IF;
        WHEN S3 =>  st_next_state <= S0;
		WHEN OTHERS => st_next_state <= S0; --stato di default
	END CASE;
END PROCESS state_table;

--passaggio di stato
state: PROCESS (SYNCHRONIZER_i_CLK_FPGA)
BEGIN
	IF rising_edge(SYNCHRONIZER_i_CLK_FPGA) THEN
        IF SYNCHRONIZER_i_RST = '1' THEN --reset sincrono
            st_state <= S0;
            s_clk_sample <= '0';
        ELSE
            st_state <= st_next_state;
            s_clk_sample <= SYNCHRONIZER_i_CLK;
        END IF;
	END IF;
END PROCESS state;

--table dei comandi
state_command: PROCESS(st_state)
BEGIN
    CASE st_state IS
		WHEN S0 => SYNCHRONIZER_O_RISE<='0'; SYNCHRONIZER_O_FALL<='0';
        WHEN S1 => SYNCHRONIZER_O_RISE<='1'; SYNCHRONIZER_O_FALL<='0';
        WHEN S2 => SYNCHRONIZER_O_RISE<='0'; SYNCHRONIZER_O_FALL<='0';
        WHEN S3 => SYNCHRONIZER_O_RISE<='0'; SYNCHRONIZER_O_FALL<='1';
        WHEN OTHERS => SYNCHRONIZER_O_RISE<='0'; SYNCHRONIZER_O_FALL<='0'; -- valori di default delle uscite
    END CASE;
END PROCESS state_command;

END ARCHITECTURE;