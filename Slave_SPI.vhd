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

-- Datapath
component Datapath_Slave_SPI
Port (
    MOSI, CLK_FPGA, OUT_EN, SEL1, RESET: IN STD_LOGIC;
    MISO, RW: OUT STD_LOGIC;
    SEL2: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    ADDR: OUT STD_LOGIC_VECTOR(0 TO 14);
    DIN: OUT STD_LOGIC_VECTOR(0 TO 15);
    DOUT: IN STD_LOGIC_VECTOR(0 TO 15)
);
end component;

-- Contatore
component Counter_Slave_SPI
Port (
    COUNTER_i_CLK_FPGA  : in std_logic;
    COUNTER_i_RST      : in std_logic;
    COUNTER_i_RISE : in std_logic;
    COUNTER_i_FALL : in std_logic;
    COUNTER_i_CTRL : in std_logic_vector(1 downto 0);
    COUNTER_o_HIT : out std_logic
);
end component;

-- FSM
component FSM_Slave_SPI
Port (
    FSM_i_CLK: IN std_logic;
    FSM_i_RST: IN std_logic;
    FSM_i_nSS: 	IN std_logic;
    FSM_i_HIT: 	IN std_logic;
    FSM_i_FALL: IN std_logic;
    FSM_i_RISE: 	IN std_logic;
    FSM_i_RW_COMAND: 	IN std_logic;
    FSM_o_RD: 			OUT std_logic;
    FSM_o_WR: 			OUT std_logic;
    FSM_o_CNT_CTRL: 	OUT std_logic_vector ( 1 downto 0 );
    FSM_o_SEL1: 		OUT std_logic;
    FSM_o_SEL2: 		OUT std_logic_vector ( 1 downto 0 );
    FSM_o_OE: 			OUT std_logic
);
end component;


-- Sincronizzatore
component Synchronizer_Slave_SPI
Port (
    SYNCHRONIZER_i_CLK  : in std_logic;
    SYNCHRONIZER_i_CLK_FPGA  : in std_logic;
    SYNCHRONIZER_i_RST  : in std_logic;
    SYNCHRONIZER_O_RISE : out std_logic;
    SYNCHRONIZER_O_FALL : out std_logic
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
signal sv_reset		: std_logic;




begin

-- Per rendere la logica di reset low-active   
sv_reset <= not RST;

-- Key Expansion
Datapath_Inst : Datapath_Slave_SPI
port map (
    MOSI		=> MOSI,
    CLK_FPGA	=> CLK,
    OUT_EN		=> sv_oe,
    SEL1		=> sv_sel1,
    RESET		=> sv_reset,
    MISO		=> MISO,
    RW			=> sv_rw,
    SEL2		=> sv_sel2,
    ADDR		=> ADDR,
    DIN			=> DIN,
    DOUT		=> DOUT
);

-- Counter
Counter_Inst : Counter_Slave_SPI
port map (
    COUNTER_i_CLK_FPGA  => CLK,
    COUNTER_i_RST      => RST,
    COUNTER_i_RISE => sv_rise,
    COUNTER_i_FALL => sv_fall,
    COUNTER_i_CTRL => sv_cnt_ctrl,
    COUNTER_o_HIT => sv_hit
);

-- Sincronizer
Synchronizer_Inst : Synchronizer_Slave_SPI
port map (
    SYNCHRONIZER_i_CLK  => SCK,
    SYNCHRONIZER_i_CLK_FPGA  => CLK,
    SYNCHRONIZER_i_RST  => RST,
    SYNCHRONIZER_O_RISE => sv_rise,
    SYNCHRONIZER_O_FALL => sv_fall
);

-- FSM
FSM_Inst : FSM_Slave_SPI
port map (
    FSM_i_CLK => CLK,
    FSM_i_RST => RST,
    FSM_i_nSS => nSS,
    FSM_i_HIT => sv_hit,
    FSM_i_FALL => sv_fall,
    FSM_i_RISE => sv_rise,
    FSM_i_RW_COMAND => sv_rw,
    FSM_o_RD => RD,
    FSM_o_WR => WR,
    FSM_o_CNT_CTRL => sv_cnt_ctrl,
    FSM_o_SEL1 => sv_sel1,
    FSM_o_SEL2 => sv_sel2,
    FSM_o_OE => sv_oe
);

end Behavioral;