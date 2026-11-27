library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;



entity tb_Slave_SPI is
end tb_Slave_SPI;



architecture Behavioral of tb_Slave_SPI is

    -- Costanti temporali (CLK = 10 MHz -> 100 ns; SCK = 500 kHz <= 1 MHz -> 2000 ns)
    constant C_CLK_PERIOD      : time := 100 ns;
    constant C_SCK_HALF_PERIOD : time := 1000 ns;

	 
	 
    -- Segnali verso il DUT (Slave_SPI)
    signal CLK  : std_logic := '0';
    signal RST  : std_logic := '1';
    signal nSS  : std_logic := '1';
    signal SCK  : std_logic := '0';
    signal MOSI : std_logic := '0';
    signal MISO : std_logic;

    signal RD   : std_logic;
    signal WR   : std_logic;
    signal ADDR : std_logic_vector(14 downto 0);
    signal DIN  : std_logic_vector(15 downto 0);
    signal DOUT : std_logic_vector(15 downto 0) := (others => '0');
	 
    -- Segnali di osservazione per il debug su Wave
    signal tb_last_wr_addr : std_logic_vector(14 downto 0) := (others => '0');
    signal tb_last_wr_data : std_logic_vector(15 downto 0) := (others => '0');
    signal tb_master_rx    : std_logic_vector(15 downto 0) := (others => '0');
    signal tb_sim_done     : boolean := false;

    -- Dato di prova restituito dal registro esterno in lettura
    constant C_TEST_READ_DATA : std_logic_vector(15 downto 0) := x"A53C";

	 
	 
begin

    -- Istanza della Top-Level Entity
    DUT: entity work.Slave_SPI
        port map (
            CLK  => CLK,
            RST  => RST,
            nSS  => nSS,
            SCK  => SCK,
            MOSI => MOSI,
            MISO => MISO,
            RD   => RD,
            WR   => WR,
            ADDR => ADDR,
            DIN  => DIN,
            DOUT => DOUT
        );

    -- Generatore Clock FPGA a 10 MHz (si ferma automaticamente a fine test)
    CLK_GEN: process
    begin
        while not tb_sim_done loop
            CLK <= '0';
            wait for C_CLK_PERIOD / 2;
            CLK <= '1';
            wait for C_CLK_PERIOD / 2;
        end loop;
        wait;
    end process;

    -- Modello sincrono dei registri esterni (gestisce WR/DIN e RD/DOUT)
    EXT_REG_MODEL: process(CLK)
    begin
        if rising_edge(CLK) then
            if RST = '1' then
                DOUT            <= (others => '0');
                tb_last_wr_addr <= (others => '0');
                tb_last_wr_data <= (others => '0');
            else
                -- Default: azzera DOUT in modo che resti valido SOLO 1 ciclo dopo RD
                DOUT <= (others => '0');

                -- Cattura indirizzo e dato scritto dal Master quando WR = '1'
                if WR = '1' then
                    tb_last_wr_addr <= ADDR;
                    tb_last_wr_data <= DIN;
                    report "SCRITTURA RILEVATA -> ADDR = " & integer'image(to_integer(unsigned(ADDR))) &
                           " | DIN (dec) = " & integer'image(to_integer(unsigned(DIN)));
                end if;

                -- Quando RD = '1', presenta il dato su DOUT al colpo di clock successivo
                if RD = '1' then
                    DOUT <= C_TEST_READ_DATA;
                end if;
					 
            end if;
        end if;
    end process;

    -- Processo Master SPI (CPOL = 0, CPHA = 1, MSB first)
    SPI_MASTER_STIM: process

        -- Procedura per eseguire una transazione SPI completa a 32 bit
        procedure spi_transfer (
            constant p_addr    : in  std_logic_vector(14 downto 0);
            constant p_rw      : in  std_logic; -- '0' = Write, '1' = Read
            constant p_wr_data : in  std_logic_vector(15 downto 0);
            variable p_rd_data : out std_logic_vector(15 downto 0)
        ) is
            variable v_tx_frame : std_logic_vector(31 downto 0);
            variable v_rx_frame : std_logic_vector(31 downto 0) := (others => '0');
        begin
            -- Composizione frame: [31..17] ADDR | [16] R/W | [15..0] DATA
            v_tx_frame := p_addr & p_rw & p_wr_data;

            -- 1. Selezione Slave (nSS attivo basso) + tempo di setup
            nSS <= '0';
            wait for C_SCK_HALF_PERIOD;

            -- 2. Trasmissione/Ricezione 32 bit (CPOL=0, CPHA=1)
            for i in 31 downto 0 loop
                -- Fronte di salita SCK: Master aggiorna MOSI, Slave aggiorna MISO
                SCK  <= '1';
                MOSI <= v_tx_frame(i);
                wait for C_SCK_HALF_PERIOD;

                -- Fronte di discesa SCK: Slave campiona MOSI, Master campiona MISO
                SCK  <= '0';
                v_rx_frame(i) := MISO;
                wait for C_SCK_HALF_PERIOD;
            end loop;

            -- 3. Tempo di hold + deselezione Slave (MISO deve tornare in alta impedenza 'Z')
            MOSI <= '0';
            wait for C_SCK_HALF_PERIOD;
            nSS <= '1';
            wait for 2 * C_SCK_HALF_PERIOD;

            p_rd_data := v_rx_frame(15 downto 0);
        end procedure;

        variable v_received : std_logic_vector(15 downto 0);
        constant C_ADDR_TEST : std_logic_vector(14 downto 0) := "000000000001111"; -- Indirizzo 5
        constant C_DATA_WR   : std_logic_vector(15 downto 0) := x"CAFE";

    begin
        -- Reset iniziale sincrono
        RST <= '1';
        nSS <= '1';
        SCK <= '0';
        wait for 3 * C_CLK_PERIOD;
        wait until rising_edge(CLK);
        RST <= '0';
        wait for 5 * C_CLK_PERIOD;

        -- TEST 1: Operazione di SCRITTURA (R/W = '0') di 0xCAFE all'indirizzo 5
        spi_transfer(
            p_addr    => C_ADDR_TEST,
            p_rw      => '0',
            p_wr_data => C_DATA_WR,
            p_rd_data => v_received
        );

        assert tb_last_wr_addr = C_ADDR_TEST and tb_last_wr_data = C_DATA_WR
            report "ERRORE SCRITTURA: ADDR o DIN non corrispondono al dato inviato!"
            severity error;

        wait for 10 * C_CLK_PERIOD;

        -- TEST 2: Operazione di LETTURA (R/W = '1') dall'indirizzo 5
        spi_transfer(
            p_addr    => C_ADDR_TEST,
            p_rw      => '1',
            p_wr_data => x"0000",
            p_rd_data => v_received
        );

        tb_master_rx <= v_received;
        wait for C_CLK_PERIOD;

        assert v_received = C_TEST_READ_DATA
            report "ERRORE LETTURA: il Master non ha ricevuto 0xA53C su MISO!"
            severity error;

        -- Fine simulazione (Run -All si fermerà automaticamente qui)
        report "SIMULAZIONE COMPLETATA CON SUCCESSO!" severity note;
        tb_sim_done <= true;
        wait;
    end process;

end Behavioral;