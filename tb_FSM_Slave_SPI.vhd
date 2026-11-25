library IEEE;
use IEEE.STD_LOGIC_1164.ALL;



entity tb_FSM_Slave_SPI is
--  Port ( );
end tb_FSM_Slave_SPI;



architecture Behavioral of tb_FSM_Slave_SPI is

-- Component Declaration
component FSM_Slave_SPI is
Port ( 
    FSM_i_CLK: IN std_logic;
    FSM_i_RST: IN std_logic;
    
    FSM_i_nSS: 			IN std_logic;
	FSM_i_HIT: 			IN std_logic;
	FSM_i_FALL: 			IN std_logic;
	FSM_i_RISE: 			IN std_logic;
	FSM_i_RW_COMAND: 	IN std_logic;
    
    FSM_o_RD: 			OUT std_logic;
	FSM_o_WR: 			OUT std_logic;
    FSM_o_CNT_CTRL: 	OUT std_logic_vector ( 1 downto 0 );
    FSM_o_SEL1: 		OUT std_logic;
	FSM_o_SEL2: 		OUT std_logic_vector ( 1 downto 0 );
    FSM_o_OE: 			OUT std_logic
);
end component;



-- Signal Declaration
signal sv_clk	: std_logic;
signal sv_rst  : std_logic;

-- Input to FMS
signal sv_nSS     		: std_logic;
signal sv_hit      		: std_logic;
signal sv_fall      		: std_logic;
signal sv_rise     		: std_logic;
signal sv_rw_comand     : std_logic;

-- Output from FMS
signal sv_rd			: std_logic;
signal sv_wd			: std_logic;
signal sv_cnt_ctrl   : std_logic_vector ( 1 downto 0 );
signal sv_sel1 		: std_logic;
signal sv_sel2 		: std_logic_vector ( 1 downto 0 );
signal sv_oe 			: std_logic;


begin


-- Port Map FSM
FSM_Slave_SPI_inst : FSM_Slave_SPI
port map (
    FSM_i_CLK => sv_clk,
    FSM_i_RST => sv_rst,
    
    FSM_i_nSS => sv_nSS,
    FSM_i_HIT => sv_hit,
    FSM_i_FALL => sv_fall,
    FSM_i_RISE => sv_rise,
    FSM_i_RW_COMAND => sv_rw_comand,
    
    FSM_o_RD => sv_rd,
    FSM_o_WR => sv_wd,
    FSM_o_CNT_CTRL => sv_cnt_ctrl,
    FSM_o_SEL1 => sv_sel1,
    FSM_o_SEL2 => sv_sel2,
    FSM_o_OE => sv_oe
);

    -- Clock Generation
    clk_process : process
    begin
        sv_clk <= '1';
        wait for 10 ns;
        sv_clk <= '0';
        wait for 10 ns;
    end process;

    rise_process : process
    begin
        sv_rise <= '0';
        wait for 40 ns;
        sv_rise <= '1';
        wait for 20 ns;
    end process;

    fall_process : process
    begin
        sv_fall <= '0';
        wait for 40 ns;
        sv_fall <= '1';
        wait for 20 ns;
    end process;

    hit_process : process
    begin
        sv_hit <= '0';
        wait for 300 ns;
        sv_hit <= '1';
        wait for 60 ns;
    end process;

    sv_rst <= '1', '0' after 20 ns;

    sv_nSS <= '1', '0' after 100 ns, '1' after 3000 ns;

    sv_rw_comand <= '0', '1' after 1800 ns;

end Behavioral;
