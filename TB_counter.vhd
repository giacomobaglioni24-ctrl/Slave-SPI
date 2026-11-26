library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_COUNTER_Slave_SPI is
    -- Un testbench non ha porte di I/O
end entity;

architecture sim of tb_COUNTER_Slave_SPI is

    -- Costante per il periodo del clock FPGA (es. 100 MHz -> 10 ns)
    constant CLK_PERIOD : time := 10 ns;

    -- Segnali di collegamento al DUT (Device Under Test)
    signal tb_CLK_FPGA : std_logic := '0';
    signal tb_RST      : std_logic := '0';
    signal tb_RISE     : std_logic := '0';
    signal tb_FALL     : std_logic := '0';
    signal tb_CTRL     : std_logic_vector(1 downto 0) := "00";
    signal tb_HIT      : std_logic;

begin

    -- Istanziazione del DUT
    uut: entity work.COUNTER_Slave_SPI
        port map (
            COUNTER_i_CLK_FPGA => tb_CLK_FPGA,
            COUNTER_i_RST      => tb_RST,
            COUNTER_i_RISE     => tb_RISE,
            COUNTER_i_FALL     => tb_FALL,
            COUNTER_i_CTRL     => tb_CTRL,
            COUNTER_o_HIT      => tb_HIT
        );

    -- Generazione del clock FPGA
    clk_gen: process
    begin
        while true loop
            tb_CLK_FPGA <= '0';
            wait for CLK_PERIOD / 2;
            tb_CLK_FPGA <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
    end process;

    -- Processo di stimolo e verifica delle casistiche
    stim_proc: process
    begin
        -- =========================================================
        -- CASO 1: Reset asincrono iniziale
        -- =========================================================
        tb_RST  <= '1';
        tb_CTRL <= "00";
        tb_RISE <= '0';
        tb_FALL <= '0';
        wait for 25 ns;
        assert tb_HIT = '0' report "Errore Caso 1: HIT deve essere 0 dopo reset" severity error;

        tb_RST <= '0';
        wait for CLK_PERIOD;

        -- =========================================================
        -- CASO 2: Conteggio su FALLING EDGE (CTRL = "10") fino a HIT = 1
        -- =========================================================
        tb_CTRL <= "10";
        for i in 1 to 16 loop
            -- Simula un impulso di 1 ciclo di clock su FALL
            wait until falling_edge(tb_CLK_FPGA);
            tb_FALL <= '1';
            -- Inseriamo un falso impulso su RISE al ciclo 5 per verificare che venga ignorato
            if i = 5 then
                tb_RISE <= '1';
            end if;
            wait for CLK_PERIOD;
            tb_FALL <= '0';
            tb_RISE <= '0';
            -- Aspetta 2 cicli FPGA (simula clock SPI più lento dell'FPGA)
            wait for 2 * CLK_PERIOD;
        end loop;

        -- Ora cnt dovrebbe essere 16 -> COUNTER_o_HIT deve essere '1'
        assert tb_HIT = '1' report "Errore Caso 2: HIT non attivo a cnt = 16" severity error;

        -- =========================================================
        -- CASO 3: Modalità HOLD (CTRL = "01")
        -- =========================================================
        tb_CTRL <= "01";
        -- Mandiamo impulsi su RISE e FALL: il contatore non deve muoversi da 16
        wait until falling_edge(tb_CLK_FPGA);
        tb_RISE <= '1';
        tb_FALL <= '1';
        wait for CLK_PERIOD;
        tb_RISE <= '0';
        tb_FALL <= '0';
        wait for 2 * CLK_PERIOD;

        assert tb_HIT = '1' report "Errore Caso 3: cnt ha cambiato valore durante HOLD" severity error;

        -- =========================================================
        -- CASO 4: Conteggio su RISING EDGE (CTRL = "11") oltre 16
        -- =========================================================
        tb_CTRL <= "11";
        -- Un impulso su RISE porta cnt da 16 a 17 -> HIT deve tornare a '0'
        wait until falling_edge(tb_CLK_FPGA);
        tb_RISE <= '1';
        wait for CLK_PERIOD;
        tb_RISE <= '0';
        wait for CLK_PERIOD;

        assert tb_HIT = '0' report "Errore Caso 4: HIT rimasto a 1 oltre cnt = 16" severity error;

        -- =========================================================
        -- CASO 5: Reset sincrono tramite CTRL = "00"
        -- =========================================================
        tb_CTRL <= "00";
        wait for 2 * CLK_PERIOD;
        assert tb_HIT = '0' report "Errore Caso 5: HIT deve essere 0 dopo reset sincrono" severity error;

        -- =========================================================
        -- CASO 6: Verifica Overflow (da 0 a 31 e ritorno a 0) e Reset Asincrono
        -- =========================================================
        tb_CTRL <= "11";
        for i in 1 to 35 loop
            wait until falling_edge(tb_CLK_FPGA);
            tb_RISE <= '1';
            wait for CLK_PERIOD;
            tb_RISE <= '0';
            wait for CLK_PERIOD;
        end loop;
        -- Dopo 32 impulsi su un contatore a 5 bit, cnt è tornato a 0

        -- Test reset asincrono a metà ciclo di clock
        tb_CTRL <= "10";
        wait until falling_edge(tb_CLK_FPGA);
        tb_FALL <= '1';
        wait for CLK_PERIOD;
        tb_FALL <= '0';
        wait for 3 ns;
        tb_RST <= '1'; -- Attivazione asincrona
        wait for 15 ns;
        tb_RST <= '0';

        -- Fine simulazione
        report "Simulazione completata con successo!" severity note;
        wait;
    end process;

end architecture;