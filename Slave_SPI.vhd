library IEEE;
use IEEE.STD_LOGIC_1164.ALL;



entity Slave_SPI is
Port ( 
    
    -- Clock and Reset
    CLK: IN std_logic;
    RST: IN std_logic;
    
    -- SPI Interface
	 nSS		: IN std_logic;
	 SCK		: IN std_logic;
	 MOSI		: IN std_logic;
	 MISO		: OUT std_logic;
	 
    -- FPGA Interface
    RD		: OUT std_logic;
    WR      : OUT std_logic;
    ADDR    : OUT std_logic_vector(14 downto 0);
    DIN     : OUT std_logic_vector(15 downto 0);
    DOUT    : IN std_logic_vector(15 downto 0)
    
);
end Slave_SPI;



architecture Behavioral of Slave_SPI is

-- Sincronizzatore
component KeyExpansionTop
Port (

);
end component;

-- Contatore
component Counter
Port (

);
end component;

-- FSM
component AESEngine
Port (

);
end component;


-- Datapath
component AESEngine
Port (

);
end component;



-- Sincronizzatore
signal sv_rise 	: std_logic;
signal sv_fall		: std_logic;

-- Counter
signal sv_hit		: std_logic;

-- FSM
signal sv_cnt_ctrl	: std_logic_vector(1 downto 0);
signal sv_sel1			: std_logic;
signal sv_sel2			: std_logic_vector(1 downto 0);
signal sv_oe			: std_logic;

-- Datapath
signal sv_rw		: std_logic;




begin

-- Per rendere la logica di reset low-active   
sv_reset <= not rst_n;

-- Key Expansion
KEYEXPANSION_Inst : KeyExpansionTop
port map (
    KEYEXPASIONTOP_i_CLK       => clk,
    KEYEXPASIONTOP_i_RST       => sv_reset,
    KEYEXPASIONTOP_i_KEYNUMBER => sv_keynumber,
    KEYEXPASIONTOP_o_READY     => sv_key_ready,
    KEYEXPASIONTOP_o_KEY       => sv_key
);

-- Counter
COUNTER_Inst : Counter
port map (
    COUNTER_i_CLK    => clk,
    COUNTER_i_RST    => sv_reset,
    COUNTER_i_INC    => sv_counter_inc,
    COUNTER_o_OUTPUT => sv_counter_out
);

-- AES Engine
AESENGINE_Inst : AESEngine
port map (
    AESENGINE_i_INPUT  => sv_aes_input,
    AESENGINE_i_KEY    => sv_key, 
    AESENGINE_i_BLOCK  => sv_fsm_block,
    AESENGINE_o_OUTPUT => sv_aes_output
);

-- AES FSM
AESFSM_Inst : AESFSM_Decrypter
port map (
    AESFSM_i_CLK         => clk,
    AESFSM_i_RST         => sv_reset,
    AESFSM_i_KEYREADY    => sv_key_ready,
    AESFSM_o_COUNTERINC  => sv_counter_inc,
    AESFSM_o_KEYNUMBER   => sv_keynumber,
    AESFSM_o_BLOCK       => sv_fsm_block,
    AESFSM_o_LOADNONCE   => sv_fsm_loadnonce,
    AESFSM_o_LOADINPUT   => sv_fsm_loadinput,
    AESFSM_o_LOADOUTPUT  => sv_fsm_loadoutput,
    s_axis_tready        => s_axis_tready,
    s_axis_tvalid        => s_axis_tvalid,
    s_axis_tlast         => s_axis_tlast,
    m_axis_tready        => m_axis_tready,
    m_axis_tvalid        => m_axis_tvalid,
    m_axis_tlast         => m_axis_tlast
);

-- Input Big-Little Endian Converter
INPUT_CONV_Inst: Big_Little_Indian_Converter
port map (
    BIGLITTLEINDIANCONVERTER_i_INPUT  => s_axis_tdata,
    BIGLITTLEINDIANCONVERTER_o_OUTPUT => sv_s_axis_tdata_conv
);

-- Output Big-Little Endian Converter
OUTPUT_CONV_Inst: Big_Little_Indian_Converter
port map (
    BIGLITTLEINDIANCONVERTER_i_INPUT  => sv_m_axis_tdata,
    BIGLITTLEINDIANCONVERTER_o_OUTPUT => sv_m_axis_tdata_conv
);

end Behavioral;