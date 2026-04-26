

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.matrix_pkg.all;

entity tb_MatrixMul is
end tb_MatrixMul;

architecture behavior of tb_MatrixMul is

    constant R          : integer := 5;  -- Rows of A
    constant N          : integer := 5;  -- Columns of A / Rows of B
    constant C          : integer := 5;  -- Columns of B
    constant DATA_WIDTH : integer := 16;

    signal clk    : std_logic := '0';
    signal rst    : std_logic := '1';
    signal start  : std_logic := '0';
    signal done   : std_logic;

    signal A : integer_matrix(0 to R-1, 0 to N-1);
    signal B : integer_matrix(0 to N-1, 0 to C-1);
    signal result : integer_matrix(0 to R-1, 0 to C-1);
    signal final_result : std_logic_vector(R*C*DATA_WIDTH-1 downto 0);

    constant CLK_PERIOD : time := 10 ns;

begin

    -- Clock generation
    clk <= not clk after CLK_PERIOD/2;

    -- Instantiate DUT
    DUT : entity work.MatrixMul
        generic map (R, N, C, DATA_WIDTH)
        port map (
            clk, rst, start,
            A, B,
            result, done,
            final_result
        );

    -- Stimulus process
    process
    begin
        -- Reset
        rst <= '1';
        wait for 20 ns;
        rst <= '0';

        -- Initialize A (5x5 example values)
        A(0,0) <= 1;  A(0,1) <= 2;  A(0,2) <= 3;  A(0,3) <= 4;  A(0,4) <= 5;
        A(1,0) <= 6;  A(1,1) <= 7;  A(1,2) <= 8;  A(1,3) <= 9;  A(1,4) <= 10;
        A(2,0) <= 11; A(2,1) <= 12; A(2,2) <= 13; A(2,3) <= 14; A(2,4) <= 15;
        A(3,0) <= 16; A(3,1) <= 17; A(3,2) <= 18; A(3,3) <= 19; A(3,4) <= 20;
        A(4,0) <= 21; A(4,1) <= 22; A(4,2) <= 23; A(4,3) <= 24; A(4,4) <= 25;

        -- Initialize B (5x5 example values)
        B(0,0) <= 1;  B(0,1) <= 2;  B(0,2) <= 3;  B(0,3) <= 4;  B(0,4) <= 5;
        B(1,0) <= 6;  B(1,1) <= 7;  B(1,2) <= 8;  B(1,3) <= 9;  B(1,4) <= 10;
        B(2,0) <= 11; B(2,1) <= 12; B(2,2) <= 13; B(2,3) <= 14; B(2,4) <= 15;
        B(3,0) <= 16; B(3,1) <= 17; B(3,2) <= 18; B(3,3) <= 19; B(3,4) <= 20;
        B(4,0) <= 21; B(4,1) <= 22; B(4,2) <= 23; B(4,3) <= 24; B(4,4) <= 25;

        wait for 20 ns;

        -- Start multiplication
        start <= '1';
        wait for CLK_PERIOD;
        start <= '0';

        -- Wait for done
        wait until done = '1';
        wait;

    end process;

end behavior;

