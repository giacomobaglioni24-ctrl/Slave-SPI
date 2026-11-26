library ieee;
use ieee.std_logic_1164.all;

entity tb_SYNCHRONIZER_Slave_SPI is
-- Il testbench non ha porte esterne
end entity tb_SYNCHRONIZER_Slave_SPI;

architecture sim of tb_SYNCHRONIZER_Slave_SPI is

    -- Costanti temporali: FPGA a 100 MHz (10 ns), SPI a 10 MHz (100 ns)
    -- Rapporto 10:1 (ideale per campionare agevolmente i fronti)
    constant CLK_FPGA_PERIOD : time := 10 ns;
    constant CLK_SPI_PERIOD  : time := 100 ns;

    -- Segnali di collegamento al DUT (Device Under Test)
    signal tb_i_CLK      : std_logic := '0';
    signal tb_i_CLK_FPGA : std_logic := '0';
    signal tb_i_RST      : std_logic := '0';
    signal tb_O_RISE     : std_logic;
    signal tb_O_FALL     : std_logic;

begin

    -- 1. Istanziazione del modulo da testare (DUT)
    DUT: entity work.SYNCHRONIZER_Slave_SPI
        port map (
            SYNCHRONIZER_i_CLK      => tb_i_CLK,
            SYNCHRONIZER_i_CLK_FPGA => tb_i_CLK_FPGA,
            SYNCHRONIZER_i_RST      => tb_i_RST,
            SYNCHRONIZER_O_RISE     => tb_O_RISE,
            SYNCHRONIZER_O_FALL     => tb_O_FALL
        );

    -- 2. Generatore continuo del clock veloce della FPGA (100 MHz)
    clk_fpga_gen: process
    begin
        while true loop
            tb_i_CLK_FPGA <= '0';
            wait for CLK_FPGA_PERIOD / 2;
            tb_i_CLK_FPGA <= '1';
            wait for CLK_FPGA_PERIOD / 2;
        end loop;
    end process clk_fpga_gen;

    -- 3. Processo degli stimoli (Reset e Clock SPI)
    stim_proc: process
    begin
        -- =====================================================================
        -- FASE 1: Reset iniziale
        -- =====================================================================
        tb_i_RST <= '1';
        tb_i_CLK <= '0';
        wait for 35 ns; -- Mantieni il reset per qualche ciclo di clock FPGA

        -- =====================================================================
        -- FASE 2: Tolgo il reset e simulo 3 colpi di clock SPI regolari
        -- =====================================================================
        tb_i_RST <= '0';
        wait for 25 ns; -- Pausa iniziale con SCLK a 0

        for i in 1 to 3 loop
            tb_i_CLK <= '1';
            wait for CLK_SPI_PERIOD / 2;
            tb_i_CLK <= '0';
            wait for CLK_SPI_PERIOD / 2;
        end loop;

        -- =====================================================================
        -- FASE 3: Rimetto il reset "a caso" nel bel mezzo di un impulso SPI
        -- =====================================================================
        tb_i_CLK <= '1';
        -- Aspetto 18 ns: esattamente il momento in cui O_RISE sta andando a '1'
        -- (latenza di campionamento + transizione di stato)
        wait for 18 ns; 

        tb_i_RST <= '1'; -- Interrompo brutalmente la FSM!
        wait for 42 ns;  -- Tengo il reset attivo mentre SCLK continua a muoversi
        tb_i_CLK <= '0';
        wait for 30 ns;

        -- =====================================================================
        -- FASE 4: Ritolgo il reset e verifico che riparta da zero
        -- =====================================================================
        tb_i_RST <= '0';
        wait for 20 ns;

        -- Altri 2 colpi di clock SPI completi
        for i in 1 to 2 loop
            tb_i_CLK <= '1';
            wait for CLK_SPI_PERIOD / 2;
            tb_i_CLK <= '0';
            wait for CLK_SPI_PERIOD / 2;
        end loop;

        -- Fine simulazione
        wait for 50 ns;
        assert false report "Simulazione completata con successo!" severity failure;
        wait;
    end process stim_proc;

end architecture sim;