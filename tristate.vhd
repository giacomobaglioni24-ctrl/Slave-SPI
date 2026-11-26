LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY tristate IS
	PORT (
		input, enable: IN STD_LOGIC;
		output: OUT STD_LOGIC
	);
END tristate;

ARCHITECTURE Behavior OF tristate IS
BEGIN
	output <= input WHEN (enable = '1') ELSE 'Z';
END Behavior;
