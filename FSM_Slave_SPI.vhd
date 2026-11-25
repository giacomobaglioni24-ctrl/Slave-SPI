library IEEE;
use IEEE.STD_LOGIC_1164.ALL;



entity FSM_Slave_SPI is
Port ( 
    FSM_i_CLK: IN std_logic;
    FSM_i_RST: IN std_logic;
    
    FSM_i_nSS: 	IN std_logic;
	 FSM_i_HIT: 	IN std_logic;
	 FSM_i_FALL: 	IN std_logic;
	 FSM_i_RISE: 	IN std_logic;
	 FSM_i_RW_COMAND: 	IN std_logic;
    
    FSM_o_RD: 			OUT std_logic;
	 FSM_o_WR: 			OUT std_logic;
    FSM_o_CNT_CTRL: 	OUT std_logic_vector ( 1 downto 0 );
    FSM_o_SEL1: 		OUT std_logic;
	 FSM_o_SEL2: 		OUT std_logic_vector ( 1 downto 0 );
    FSM_o_OE: 			OUT std_logic
);
end FSM_Slave_SPI;



architecture Behavioral of FSM_Slave_SPI is

type t_state is (
        ST_RESET,
        ST_WAIT_FALL_CMD,
        ST_SAMPLE_CMD,
        ST_RST_CNT,
        ST_WAIT_FALL_DATA,
        ST_SAMPLE_DATA,
        ST_WRITE_REG,
        ST_READ_REG,
        ST_SAMPLE_READ,
        ST_WAIT_RISE_DATA,
        ST_TRANSMIT_DATA
);

signal sv_state: t_state := ST_RESET;
signal sv_next_state: t_state;



begin

STATE_UPDATE: process (FSM_i_CLK)
begin
    if rising_edge(FSM_i_CLK) then
        if FSM_i_RST = '1' then
            sv_state <= ST_RESET;
        else
            sv_state <= sv_next_state;
        end if;
    end if;
end process;



FSM: process(sv_state, FSM_i_nSS, FSM_i_HIT, FSM_i_FALL, FSM_i_RISE, FSM_i_RW_COMAND)
begin

    sv_next_state       <= sv_state;

	 FSM_o_RD 			<= '0';
	 FSM_o_WR 			<= '0';
    FSM_o_CNT_CTRL 	<= ( others => '0' );
    FSM_o_SEL1 		<= '0';
	 FSM_o_SEL2 		<= ( others => '0' );
    FSM_o_OE 			<= '0';
	 
	 if FSM_i_nSS = '1' and sv_state /= ST_WRITE_REG then -- Controllo del nSS, per evitare problemi durante lo stato di scrittura lo ignoro
		  sv_next_state <= ST_RESET;
	 else
		 case sv_state is

			  when ST_RESET =>  -- Reset FSM

					sv_next_state <= ST_WAIT_FALL_CMD;
					
			  when ST_WAIT_FALL_CMD =>  -- Idle per il falling edge
					
					FSM_o_CNT_CTRL <= "10";

					if FSM_i_FALL = '1' then
						 sv_next_state <= ST_SAMPLE_CMD;
					else
						 sv_next_state <= ST_WAIT_FALL_CMD;
					end if;

			  when ST_SAMPLE_CMD =>  -- Campionamento dato MOSI nello shift register

					FSM_o_CNT_CTRL <= "10";
					FSM_o_SEL1 <= '1';
					
					if FSM_i_HIT = '1' and FSM_i_RW_COMAND = '0' then     
						 sv_next_state <= ST_RST_CNT; 
					elsif FSM_i_HIT = '1' and FSM_i_RW_COMAND = '1' then
						 sv_next_state <= ST_READ_REG; 
					else
						 sv_next_state <= ST_WAIT_FALL_CMD;
					end if;

			  when ST_RST_CNT =>  -- Reset del Counter 
					
					FSM_o_CNT_CTRL <= "00";

					sv_next_state <= ST_WAIT_FALL_DATA;

			  when ST_WAIT_FALL_DATA =>  -- Idle per il falling edge
					
					FSM_o_CNT_CTRL <= "10";

					if FSM_i_FALL = '1' then
						 sv_next_state <= ST_SAMPLE_DATA;
					else
						 sv_next_state <= ST_WAIT_FALL_DATA;
					end if;


			  when ST_SAMPLE_DATA =>  -- Campionamento dato MOSI nello shift register

					FSM_o_CNT_CTRL <= "10";
					FSM_o_SEL2 <= "01";
					
					if FSM_i_HIT = '1' then     
						 sv_next_state <= ST_WRITE_REG; 
					else
						 sv_next_state <= ST_WAIT_FALL_DATA;
					end if;

			  when ST_WRITE_REG =>  -- Scrittura nel registro comunicante con la Slave SPI

					FSM_o_WR <= '1';

					sv_next_state <= ST_RESET;

			  when ST_READ_REG =>  -- Lettura dal registro comunicante con la Slave SPI

					FSM_o_RD <= '1';
			  
					sv_next_state <= ST_SAMPLE_READ;

			  when ST_SAMPLE_READ =>  -- Campionamento del dato proveniente dal registro nello shift register

					FSM_o_SEL2 <= "11";
					
					sv_next_state <= ST_WAIT_RISE_DATA;

			  when ST_WAIT_RISE_DATA =>  -- Idle per il rising edge

					FSM_o_CNT_CTRL <= "11";
					FSM_o_OE <= '1';

					if FSM_i_RISE = '1' then
						 sv_next_state <= ST_TRANSMIT_DATA;
					else
						 sv_next_state <= ST_WAIT_RISE_DATA;
					end if;

			  when ST_TRANSMIT_DATA =>  -- Trasmissione in uscita su MISO

					FSM_o_CNT_CTRL <= "11";
					FSM_o_SEL2 <= "01";
					FSM_o_OE <= '1';
							  
					if FSM_i_HIT = '1' then
						 sv_next_state <= ST_RESET;
					else
						 sv_next_state <= ST_WAIT_RISE_DATA;
					end if;

			  when others =>  -- Stato di default sicuro
			  
					sv_next_state <= ST_RESET; 

		 end case;
	 end if;
end process;

end Behavioral;