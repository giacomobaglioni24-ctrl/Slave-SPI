library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity COUNTER_Slave_SPI is
    port (
        COUNTER_i_CLK_FPGA  : in std_logic;
        COUNTER_i_RST      : in std_logic;
        COUNTER_i_RISE : in std_logic;
        COUNTER_i_FALL : in std_logic;
        COUNTER_i_CTRL : in std_logic_vector(1 downto 0);

        COUNTER_o_HIT : out std_logic
    );
end entity;

architecture behavior of COUNTER_Slave_SPI is

signal cnt : unsigned(4 downto 0) := (others => '0');

begin

    counter: process(COUNTER_i_CLK_FPGA, COUNTER_i_RST)
    begin
        if COUNTER_i_RST = '1' then
            cnt <= (others => '0');
        elsif rising_edge(COUNTER_i_CLK_FPGA) or falling_edge(COUNTER_i_CLK_FPGA) then
            case COUNTER_i_CTRL is
                when "00" => -- Reset
                    cnt <= (others => '0');
                when "01" => -- Hold
                    cnt <= cnt;
                when "10" => -- Count on falling edge pulse
                    if COUNTER_i_FALL = '1' then
                        cnt <= cnt + 1;
                    end if;
                when "11" => -- Count on rising edge pulse
                    if COUNTER_i_RISE = '1' then
                        cnt <= cnt + 1;
                    end if;
                when others =>
                    cnt <= (others => '0');
            end case;
        end if;
    end process counter;

    COUNTER_o_HIT <= '1' when cnt = 16 else '0';

end architecture;