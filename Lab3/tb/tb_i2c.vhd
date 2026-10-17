--------------------------------------------------------------------------------
-- Тестбенч  : tb_i2c
-- Опис      : Функціональна верифікація пари i2c_master + i2c_slave.
--             Імітує зовнішнє середовище: генерує CLK і RESET, моделює шину
--             I2C з підтягувальними резисторами (сигнал 'H'), подає тестові
--             дані на Master (Tx) і перевіряє, що Slave (Rx) їх прийняв.
--   Тест 1: запис 0xA5 у Slave 0x55              -> rx_data = 0xA5, ACK
--   Тест 2: читання з Slave 0x55 (tx_data=0x3C)  -> data_rd = 0x3C
--   Тест 3: запис у неіснуючу адресу 0x23        -> ack_error = 1
--   Тест 4: запис 0x05 (номер варіанта)          -> rx_data = 0x05
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_i2c is
end entity tb_i2c;

architecture sim of tb_i2c is

  constant CLK_PERIOD : time    := 20 ns;       -- 50 МГц
  constant CLK_FREQ   : natural := 50_000_000;
  constant I2C_FREQ   : natural := 100_000;     -- 100 кГц

  signal clk       : std_logic := '0';
  signal rst       : std_logic := '1';

  -- шина I2C (open-drain + pull-up)
  signal scl       : std_logic;
  signal sda       : std_logic;

  -- сигнали Master
  signal start     : std_logic := '0';
  signal addr      : std_logic_vector(6 downto 0) := (others => '0');
  signal rw        : std_logic := '0';
  signal data_wr   : std_logic_vector(7 downto 0) := (others => '0');
  signal data_rd   : std_logic_vector(7 downto 0);
  signal busy      : std_logic;
  signal done      : std_logic;
  signal ack_error : std_logic;
  signal m_scl_oe  : std_logic;
  signal m_sda_oe  : std_logic;

  -- сигнали Slave
  signal s_sda_oe  : std_logic;
  signal rx_data   : std_logic_vector(7 downto 0);
  signal rx_valid  : std_logic;
  signal tx_data   : std_logic_vector(7 downto 0) := x"3C";
  signal addr_hit  : std_logic;

  signal sim_end   : boolean := false;
  signal errors    : natural := 0;

begin

  -- генератор тактового сигналу
  clk <= not clk after CLK_PERIOD / 2 when not sim_end;

  -- модель шини: кожен пристрій може лише тягнути лінію до 0,
  -- 'H' - слабка 1 від підтягувального резистора
  scl <= 'H';
  sda <= 'H';
  scl <= '0' when m_scl_oe = '1' else 'Z';
  sda <= '0' when m_sda_oe = '1' else 'Z';
  sda <= '0' when s_sda_oe = '1' else 'Z';

  u_master : entity work.i2c_master
    generic map (CLK_FREQ => CLK_FREQ, I2C_FREQ => I2C_FREQ)
    port map (
      clk => clk, rst => rst,
      start => start, addr => addr, rw => rw,
      data_wr => data_wr, data_rd => data_rd,
      busy => busy, done => done, ack_error => ack_error,
      scl_i => to_x01(scl), scl_oe => m_scl_oe,
      sda_i => to_x01(sda), sda_oe => m_sda_oe);

  u_slave : entity work.i2c_slave
    generic map (SLAVE_ADDR => "1010101")      -- 0x55
    port map (
      clk => clk, rst => rst,
      scl_i => to_x01(scl), sda_i => to_x01(sda), sda_oe => s_sda_oe,
      rx_data => rx_data, rx_valid => rx_valid,
      tx_data => tx_data, addr_hit => addr_hit);

  ------------------------------------------------------------------------------
  -- Сценарій тестування
  ------------------------------------------------------------------------------
  p_stim : process

    -- запуск однієї транзакції та очікування її завершення
    procedure i2c_xfer (a : std_logic_vector(6 downto 0);
                        r : std_logic;
                        d : std_logic_vector(7 downto 0)) is
    begin
      wait until rising_edge(clk);
      addr    <= a;
      rw      <= r;
      data_wr <= d;
      start   <= '1';
      wait until rising_edge(clk);
      start   <= '0';
      wait until rising_edge(clk) and done = '1';
      wait for 20 us;                          -- пауза між транзакціями
    end procedure;

    procedure check (cond : boolean; msg : string) is
    begin
      if cond then
        report "PASS: " & msg severity note;
      else
        report "FAIL: " & msg severity error;
        errors <= errors + 1;
      end if;
    end procedure;

  begin
    rst <= '1';
    wait for 200 ns;
    rst <= '0';
    wait for 2 us;

    -- Тест 1: запис 0xA5 за адресою 0x55
    i2c_xfer("1010101", '0', x"A5");
    check(ack_error = '0', "T1 write 0x55: ACK received");
    check(rx_data = x"A5", "T1 slave rx_data = 0xA5");

    -- Тест 2: читання з адреси 0x55
    i2c_xfer("1010101", '1', x"00");
    check(ack_error = '0', "T2 read 0x55: ACK received");
    check(data_rd = x"3C", "T2 master data_rd = 0x3C");

    -- Тест 3: звернення до відсутнього пристрою 0x23
    i2c_xfer("0100011", '0', x"5A");
    check(ack_error = '1', "T3 write 0x23: NACK detected (ack_error=1)");
    check(rx_data = x"A5", "T3 slave rx_data unchanged");

    -- Тест 4: запис номера варіанта 0x05
    i2c_xfer("1010101", '0', x"05");
    check(ack_error = '0', "T4 write 0x55: ACK received");
    check(rx_data = x"05", "T4 slave rx_data = 0x05");

    wait for 1 ns;
    if errors = 0 then
      report "=== ALL TESTS PASSED ===" severity note;
    else
      report "=== TESTS FAILED: " & integer'image(errors) & " ===" severity error;
    end if;
    sim_end <= true;
    wait;
  end process;

end architecture sim;
