library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library lpm;
use lpm.lpm_components.all;
library altera_mf;
use altera_mf.altera_mf_components.all;

entity user is
	port
	(
		-- Main clock inputs
		mainClk	: in std_logic;
		slowClk	: in std_logic;
		-- Main reset input
		reset		: in std_logic;
		-- MCU interface (UART, I2C)
		mcuUartTx	: in std_logic;
		mcuUartRx	: out std_logic;
		mcuI2cScl	: in std_logic;
		mcuI2cSda	: inout std_logic;
		-- Logic state analyzer/stimulator
		lsasBus	: inout std_logic_vector( 31 downto 0 );
		-- Dip switches
		switches	: in std_logic_vector( 7 downto 0 );
		-- LEDs
		leds		: out std_logic_vector( 3 downto 0 )
	);
end user;

architecture behavioural of user is

	signal clk: std_logic;
	signal pllLock: std_logic;

	signal lsasBusIn: std_logic_vector( 31 downto 0 );
	signal lsasBusOut: std_logic_vector( 31 downto 0 );
	signal lsasBusEn: std_logic_vector( 31 downto 0 ) := ( others => '0' );

	signal mcuI2cDIn: std_logic;
	signal mcuI2CDOut: std_logic;
	signal mcuI2cEn: std_logic := '0';	

	component myAltPll
		PORT
		(
			areset		: IN STD_LOGIC  := '0';
			inclk0		: IN STD_LOGIC  := '0';
			c0		: OUT STD_LOGIC ;
			locked		: OUT STD_LOGIC 
		);
	end component;
	
	-- PARTE NOSTRA:
	
	component Slave_SPI
		port
		(
			-- Clock and Reset
			CLK		: in std_logic;
			RST		: in std_logic;

			-- SPI Interface
			nSS		: in std_logic;
			SCK		: in std_logic;
			MOSI	: in std_logic;
			MISO	: out std_logic;

			-- FPGA Interface
			RD		: out std_logic;
			WR		: out std_logic;
			ADDR	: out std_logic_vector(14 downto 0);
			DIN		: out std_logic_vector(15 downto 0);
			DOUT	: in std_logic_vector(15 downto 0)
		);
	end component;

	-- Segnali di interconnessione SPI <-> Banco Registri
	signal pll_areset : std_logic;
	signal rst_meta   : std_logic := '1';
	signal rst_spi    : std_logic := '1';
	signal miso_sig : std_logic;
	signal rd_sig   : std_logic;
	signal wr_sig   : std_logic;
	signal addr_bus : std_logic_vector(14 downto 0);
	signal din_bus  : std_logic_vector(15 downto 0);
	signal dout_bus : std_logic_vector(15 downto 0);

	-- Banco di 256 registri da 16 bit (indirizzi 0x00..0xFF)
	type reg_array_t is array (0 to 255) of std_logic_vector(15 downto 0);
	signal reg_bank : reg_array_t := (others => (others => '0'));
	
begin

--**********************************************************************************
--* Main clock PLL
--**********************************************************************************

	pll_areset <= not reset;

	myAltPll_inst : myAltPll PORT MAP (
		 areset => pll_areset,
		 inclk0 => mainClk,
		 c0     => clk,
		 locked => pllLock
	);

--**********************************************************************************
--* LEDs
--**********************************************************************************

	-- leds <= switches( 3 downto 0 );
	
--**********************************************************************************
--* 		lsasBus	: inout std_logic_vector( 31 downto 0 )
--**********************************************************************************

	lsasBusIn <= lsasBus;

	lsasBus_tristate:
	process( lsasBusEn, lsasBusOut ) is
	begin
		for index in 0 to 31 loop
			if lsasBusEn( index ) = '1'  then
				lsasBus( index ) <= lsasBusOut ( index );
			else
				lsasBus( index ) <= 'Z';
			end if;
		end loop;
	end process;
		
	-- ATTENZIONE: c'è un buffer tri state, quindi noi non comunichiamo direttamente lsasBus ma con lsasBusIn e lsasBusOut

	-- IO12: nSS --> lsasBus12 --> lsasBusIn(12)
	-- IO13: SCK --> lsasBus13 --> lsasBusIn(13)
	-- IO14: MISO --> lsasBus14 --> lsasBusOut(14)
	-- IO15: MOSI --> lsasBus15 --> lsasBusIn(15)
		
	-- Diagnostica LED (attivi alti):
	-- leds(0) [D104]: ACCESO = PLL agganciata (clock 10 MHz attivo)
	-- leds(1) [D103]: SPENTO = Slave_SPI uscito dal reset e pronto
	-- leds(2) [D102]: bit 0 del registro 0x00
	-- leds(3) [D101]: bit 1 del registro 0x00
	leds(0) <= pllLock;
	leds(1) <= rst_spi;
	leds(2) <= reg_bank(0)(0);
	leds(3) <= reg_bank(0)(1);

	-- Sincronizzatore di reset (2 FF): attivo alto su rst_spi finché reset='0' oppure pllLock='0'
	reset_sync_proc : process(clk, reset, pllLock)
	begin
		 if (reset = '0') or (pllLock = '0') then
			  rst_meta <= '1';
			  rst_spi  <= '1';
		 elsif rising_edge(clk) then
			  rst_meta <= '0';
			  rst_spi  <= rst_meta;
		 end if;
	end process;
	
	-- Controllo tri-state su IO14 (MISO): abilitato solo quando nSS (IO12) = '0'
	lsasBusOut(14) <= miso_sig;
	lsasBusEn(14)  <= not lsasBusIn(12);

	Slave_SPI_inst : Slave_SPI
    port map
    (
        -- Clock and Reset
        CLK  => clk,
        RST  => rst_spi,

        -- SPI Interface
        nSS  => lsasBusIn(12),
        SCK  => lsasBusIn(13),
        MOSI => lsasBusIn(15),
        MISO => miso_sig,

        -- FPGA Interface
        RD   => rd_sig,
        WR   => wr_sig,
        ADDR => addr_bus,
        DIN  => din_bus,
        DOUT => dout_bus
    );

	-- Banco registri sincrono (scrittura su WR, lettura su RD con 1 ciclo di latenza su DOUT)
	reg_bank_proc : process(clk)
	begin
		if rising_edge(clk) then
			if wr_sig = '1' then
				reg_bank(to_integer(unsigned(addr_bus(7 downto 0)))) <= din_bus;
			end if;
			if rd_sig = '1' then
				dout_bus <= reg_bank(to_integer(unsigned(addr_bus(7 downto 0))));
			end if;
		end if;
	end process;
	
end behavioural;
