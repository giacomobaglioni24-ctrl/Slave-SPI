LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY mux4 IS
	PORT (
		input1, input2, input3, input4: IN STD_LOGIC;
		sel: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
		output: OUT STD_LOGIC
	);
END mux4;

ARCHITECTURE Behavior OF mux4 IS
BEGIN
	WITH sel SELECT
		output <= 
			input1 WHEN "00",
			input2 WHEN "01",
			input3 WHEN "10",
			input4 WHEN "11",
			input1 WHEN OTHERS;
END Behavior;
