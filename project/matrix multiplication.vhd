library ieee;
use ieee.std_logic_1164.all;

package matrix_pkg is
    type integer_matrix is array (natural range <>, natural range <>) of integer;
    type integer_array  is array (natural range <>) of integer;  -- ✅ New type
end package;

package body matrix_pkg is
end package body;


library ieee;
use ieee.std_logic_1164.all;

entity counter is
    generic (
        MAX_VAL : integer := 3
    );
    port (
        clk  : in  std_logic;
        rst  : in  std_logic;
        en   : in  std_logic;
        clr  : in  std_logic;
        val  : out integer;
        last : out std_logic
    );
end counter;

architecture rtl of counter is
    signal cnt : integer := 0;
begin
    process(clk, rst)
    begin
        if rst = '1' then
            cnt <= 0;
        elsif rising_edge(clk) then
            if clr = '1' then
                cnt <= 0;
            elsif en = '1' then
                if cnt < MAX_VAL-1 then
                    cnt <= cnt + 1;
                else
                    cnt <= 0;
                end if;
            end if;
        end if;
    end process;

    val  <= cnt;
    last <= '1' when cnt = MAX_VAL-1 else '0';
end rtl;





library ieee;
use ieee.std_logic_1164.all;

entity mac is
    port (
        clk : in std_logic;
        rst : in std_logic;
        en  : in std_logic;
        clr : in std_logic;
        a   : in integer;
        b   : in integer;
        acc : out integer
    );
end mac;

architecture rtl of mac is
    signal acc_reg : integer := 0;
begin
    process(clk, rst)
    begin
        if rst = '1' then
            acc_reg <= 0;
        elsif rising_edge(clk) then
            if clr = '1' then
                acc_reg <= 0;
            elsif en = '1' then
                acc_reg <= acc_reg + (a * b);
            end if;
        end if;
    end process;

    acc <= acc_reg;
end rtl;





library ieee;
use ieee.std_logic_1164.all;

entity controller is
    port (
        clk          : in  std_logic;
        rst          : in  std_logic;
        start        : in  std_logic;
        k_last       : in  std_logic;
        j_last       : in  std_logic;
        i_last       : in  std_logic;

        en_i         : out std_logic;
        en_j         : out std_logic;
        en_k         : out std_logic;
        clr_k        : out std_logic;
        clr_j        : out std_logic;
        clr_mac      : out std_logic;
        write_result : out std_logic;
        done         : out std_logic
    );
end controller;

architecture rtl of controller is
    type state_type is (IDLE, INIT, CALC, NEXTT, FINISH);
    signal state : state_type := IDLE;
begin
    process(clk, rst)
    begin
        if rst = '1' then
            state <= IDLE;
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    if start = '1' then
                        state <= INIT;
                    end if;

                when INIT =>
                    state <= CALC;

                when CALC =>
                    if k_last = '1' then
                        state <= NEXTT;
                    end if;

                when NEXTT =>
                    if i_last = '1' and j_last = '1' then
                        state <= FINISH;
                    else
                        state <= INIT;
                    end if;

                when FINISH =>
                    state <= IDLE;
            end case;
        end if;
    end process;

    en_k        <= '1' when state = CALC else '0';
    clr_k      <= '1' when state = INIT else '0';
    clr_mac    <= '1' when state = INIT else '0';
    write_result <= '1' when state = NEXTT else '0';
    done       <= '1' when state = FINISH else '0';

    en_j  <= '1' when state = NEXTT and j_last = '0' else '0';
    en_i  <= '1' when state = NEXTT and j_last = '1' else '0';
    clr_j <= '1' when state = NEXTT and j_last = '1' else '0';
end rtl;






library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;   -- ✅ REQUIRED
use work.matrix_pkg.all;

entity MatrixMul is
    generic (
        R : integer := 2;
        N : integer := 3;
        C : integer := 2;
        DATA_WIDTH : integer := 16
    );
    port (
        clk          : in  std_logic;
        rst          : in  std_logic;
        start        : in  std_logic;
        A            : in  integer_matrix(0 to R-1, 0 to N-1);
        B            : in  integer_matrix(0 to N-1, 0 to C-1);
        result       : out integer_matrix(0 to R-1, 0 to C-1);
        done         : out std_logic;
        final_result : out std_logic_vector(R*C*DATA_WIDTH-1 downto 0)
    );
end MatrixMul;

architecture structural of MatrixMul is
    signal i, j, k : integer := 0;
    signal i_last, j_last, k_last : std_logic;
    signal mac_out : integer;
    signal a_sig, b_sig : integer;
    signal en_i, en_j, en_k : std_logic;
    signal clr_k, clr_j, clr_mac, write_result : std_logic;
    signal res_sig : integer_matrix(0 to R-1, 0 to C-1);
begin

    process(i, j, k, en_k)
    begin
        if en_k = '1' then
            a_sig <= A(i, k);
            b_sig <= B(k, j);
        else
            a_sig <= 0;
            b_sig <= 0;
        end if;
    end process;

    I_CNT : entity work.counter generic map (MAX_VAL => R)
        port map (clk, rst, en_i, '0', i, i_last);

    J_CNT : entity work.counter generic map (MAX_VAL => C)
        port map (clk, rst, en_j, clr_j, j, j_last);

    K_CNT : entity work.counter generic map (MAX_VAL => N)
        port map (clk, rst, en_k, clr_k, k, k_last);

    MAC_U : entity work.mac
        port map (clk, rst, en_k, clr_mac, a_sig, b_sig, mac_out);

    CTRL : entity work.controller
        port map (
            clk, rst, start,
            k_last, j_last, i_last,
            en_i, en_j, en_k,
            clr_k, clr_j, clr_mac,
            write_result, done
        );

    -- Store result
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                res_sig <= (others => (others => 0));
            elsif write_result = '1' then
                res_sig(i, j) <= mac_out;
            end if;
        end if;
    end process;

    -- Flatten matrix
    process(res_sig)
        variable idx  : integer;
        variable temp : std_logic_vector(R*C*DATA_WIDTH-1 downto 0);
    begin
        idx  := 0;
        temp := (others => '0');

        for r in 0 to R-1 loop
            for c in 0 to C-1 loop
                temp((idx+1)*DATA_WIDTH-1 downto idx*DATA_WIDTH) :=
                    std_logic_vector(to_signed(res_sig(r,c), DATA_WIDTH));
                idx := idx + 1;
            end loop;
            final_result <= temp;
        end loop;

        
    end process;

    result <= res_sig;
end structural;
