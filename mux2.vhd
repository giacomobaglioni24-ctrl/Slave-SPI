LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY mux2 IS
	PORT (
		in0, in1, sel: IN STD_LOGIC;
		output: OUT STD_LOGIC
	);
END mux2;

ARCHITECTURE Behavior OF mux2 IS
BEGIN
	WITH sel SELECT
		output <= 
			in0 WHEN '0',
			in1 WHEN '1',
			in0 WHEN OTHERS;
END Behavior;
