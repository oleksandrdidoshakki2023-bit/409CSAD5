--------------------------------------------------------------------------------
-- Модуль    : i2c_master
-- Опис      : Master-пристрій шини I2C (передавач / Tx-частина протоколу).
--             Генерує тактовий сигнал SCL, умови START / STOP, передає
--             7-бітну адресу + біт R/W, після чого записує або читає 1 байт.
--             Лінії SCL і SDA - open-drain: модуль або притягує лінію до 0,
--             або відпускає її (логічну 1 формує підтягувальний резистор).
--             Підтримується розтягування такту (clock stretching) з боку Slave.
-- Мова      : VHDL-2008
-- Варіант   : 5 (I2C, VHDL)
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2c_master is
  generic (
    CLK_FREQ : natural := 50_000_000;  -- системна тактова частота, Гц
    I2C_FREQ : natural := 100_000      -- частота SCL, Гц (Standard-mode)
  );
  port (
    clk       : in  std_logic;                     -- системний такт
    rst       : in  std_logic;                     -- синхронне скидання, активний 1
    -- інтерфейс користувача
    start     : in  std_logic;                     -- імпульс запуску транзакції
    addr      : in  std_logic_vector(6 downto 0);  -- 7-бітна адреса Slave
    rw        : in  std_logic;                     -- 0 = запис, 1 = читання
    data_wr   : in  std_logic_vector(7 downto 0);  -- байт для запису
    data_rd   : out std_logic_vector(7 downto 0);  -- прочитаний байт
    busy      : out std_logic;                     -- 1 = транзакція триває
    done      : out std_logic;                     -- імпульс (1 такт) - кінець
    ack_error : out std_logic;                     -- 1 = Slave не дав ACK
    -- фізичні лінії шини (open-drain)
    scl_i     : in  std_logic;                     -- поточний рівень SCL
    scl_oe    : out std_logic;                     -- 1 = притягнути SCL до 0
    sda_i     : in  std_logic;                     -- поточний рівень SDA
    sda_oe    : out std_logic                      -- 1 = притягнути SDA до 0
  );
end entity i2c_master;

architecture rtl of i2c_master is

  -- Один біт I2C розбито на 4 чверті періоду SCL (фази 0..3):
  --   фаза 0: SCL = 0, виставляємо SDA
  --   фаза 1: відпускаємо SCL (фронт)
  --   фаза 2: SCL = 1, зчитуємо SDA
  --   фаза 3: притягуємо SCL до 0 (спад)
  constant DIV : natural := CLK_FREQ / (4 * I2C_FREQ);  -- 125 для 50 МГц/100 кГц

  type state_t is (
    S_IDLE,      -- шина вільна, очікування start
    S_START,     -- формування умови START
    S_ADDR,      -- передача адреси + R/W (8 біт)
    S_ACK_ADDR,  -- прийом ACK на адресу
    S_WRITE,     -- передача байта даних
    S_ACK_DATA,  -- прийом ACK на дані
    S_READ,      -- прийом байта від Slave
    S_MACK,      -- Master надсилає NACK (кінець читання)
    S_STOP       -- формування умови STOP
  );
  signal state    : state_t := S_IDLE;

  signal clk_cnt  : natural range 0 to DIV - 1 := 0;  -- дільник частоти
  signal tick     : std_logic;                         -- строб чверті періоду
  signal phase    : unsigned(1 downto 0) := "00";      -- номер чверті біта
  signal bit_cnt  : natural range 0 to 7 := 7;         -- номер поточного біта

  signal shreg    : std_logic_vector(7 downto 0) := (others => '0'); -- зсувний регістр
  signal dreg     : std_logic_vector(7 downto 0) := (others => '0'); -- копія data_wr
  signal rw_r     : std_logic := '0';
  signal err_r    : std_logic := '0';
  signal rd_r     : std_logic_vector(7 downto 0) := (others => '0');
  signal done_r   : std_logic := '0';
  signal scl_oe_r : std_logic := '0';
  signal sda_oe_r : std_logic := '0';

  -- синхронізатори вхідних ліній (2 тригери - захист від метастабільності)
  signal scl_s    : std_logic_vector(1 downto 0) := "11";
  signal sda_s    : std_logic_vector(1 downto 0) := "11";
  signal scl_in   : std_logic;
  signal sda_in   : std_logic;
  signal stretch  : std_logic;

begin

  --------------------------------------------------------------------------
  -- Синхронізація входів SCL/SDA з системним тактом
  --------------------------------------------------------------------------
  p_sync : process (clk)
  begin
    if rising_edge(clk) then
      scl_s <= scl_s(0) & scl_i;
      sda_s <= sda_s(0) & sda_i;
    end if;
  end process;
  scl_in <= scl_s(1);
  sda_in <= sda_s(1);

  -- Clock stretching: Master відпустив SCL, а лінія все ще в 0 -> Slave
  -- утримує такт, тому лічильник дільника "заморожується".
  stretch <= '1' when scl_oe_r = '0' and scl_in = '0' and state /= S_IDLE else '0';

  --------------------------------------------------------------------------
  -- Дільник тактової частоти: tick = 1 раз на чверть періоду SCL
  --------------------------------------------------------------------------
  p_div : process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' or state = S_IDLE then
        clk_cnt <= 0;
      elsif stretch = '0' then
        if clk_cnt = DIV - 1 then
          clk_cnt <= 0;
        else
          clk_cnt <= clk_cnt + 1;
        end if;
      end if;
    end if;
  end process;
  tick <= '1' when clk_cnt = DIV - 1 and stretch = '0' else '0';

  --------------------------------------------------------------------------
  -- Основний скінченний автомат (FSM) Master-пристрою
  --------------------------------------------------------------------------
  p_fsm : process (clk)
  begin
    if rising_edge(clk) then
      done_r <= '0';

      if rst = '1' then
        state    <= S_IDLE;
        phase    <= "00";
        bit_cnt  <= 7;
        scl_oe_r <= '0';
        sda_oe_r <= '0';
        err_r    <= '0';
        rd_r     <= (others => '0');

      elsif state = S_IDLE then
        scl_oe_r <= '0';                      -- шина відпущена (SCL=SDA=1)
        sda_oe_r <= '0';
        phase    <= "00";
        if start = '1' then
          shreg <= addr & rw;                 -- перший байт: адреса + R/W
          dreg  <= data_wr;
          rw_r  <= rw;
          err_r <= '0';
          state <= S_START;
        end if;

      elsif tick = '1' then
        phase <= phase + 1;                   -- перехід до наступної чверті

        case state is

          -- START: SDA 1->0 при SCL = 1, потім SCL -> 0
          when S_START =>
            case phase is
              when "01"   => sda_oe_r <= '1';
              when "11"   => scl_oe_r <= '1';
                             bit_cnt  <= 7;
                             state    <= S_ADDR;
              when others => null;
            end case;

          -- Передача байта (адреса або дані), старшим бітом вперед
          when S_ADDR | S_WRITE =>
            case phase is
              when "00"   => sda_oe_r <= not shreg(7);  -- 0 -> тягнемо, 1 -> відпускаємо
              when "01"   => scl_oe_r <= '0';
              when "11"   =>
                scl_oe_r <= '1';
                if bit_cnt = 0 then
                  if state = S_ADDR then state <= S_ACK_ADDR;
                  else                    state <= S_ACK_DATA;
                  end if;
                else
                  bit_cnt <= bit_cnt - 1;
                  shreg   <= shreg(6 downto 0) & '0';
                end if;
              when others => null;
            end case;

          -- Прийом ACK від Slave (SDA = 0 -> ACK, SDA = 1 -> NACK)
          when S_ACK_ADDR | S_ACK_DATA =>
            case phase is
              when "00"   => sda_oe_r <= '0';           -- відпускаємо SDA
              when "01"   => scl_oe_r <= '0';
              when "10"   => if sda_in = '1' then err_r <= '1'; end if;
              when "11"   =>
                scl_oe_r <= '1';
                bit_cnt  <= 7;
                if state = S_ACK_DATA or err_r = '1' then
                  state <= S_STOP;
                elsif rw_r = '0' then
                  shreg <= dreg;
                  state <= S_WRITE;
                else
                  state <= S_READ;
                end if;
              when others => null;
            end case;

          -- Прийом байта від Slave (вибірка SDA при SCL = 1)
          when S_READ =>
            case phase is
              when "00"   => sda_oe_r <= '0';
              when "01"   => scl_oe_r <= '0';
              when "10"   => shreg    <= shreg(6 downto 0) & sda_in;
              when "11"   =>
                scl_oe_r <= '1';
                if bit_cnt = 0 then
                  state <= S_MACK;
                else
                  bit_cnt <= bit_cnt - 1;
                end if;
              when others => null;
            end case;

          -- Master відповідає NACK (SDA = 1) - читання завершене
          when S_MACK =>
            case phase is
              when "00"   => sda_oe_r <= '0';
              when "01"   => scl_oe_r <= '0';
              when "11"   => scl_oe_r <= '1';
                             rd_r     <= shreg;
                             state    <= S_STOP;
              when others => null;
            end case;

          -- STOP: SDA = 0, SCL -> 1, потім SDA 0->1 при SCL = 1
          when S_STOP =>
            case phase is
              when "00"   => sda_oe_r <= '1';
              when "01"   => scl_oe_r <= '0';
              when "10"   => sda_oe_r <= '0';
              when "11"   => done_r   <= '1';
                             state    <= S_IDLE;
              when others => null;
            end case;

          when S_IDLE => null;
        end case;
      end if;
    end if;
  end process;

  -- вихідні сигнали
  scl_oe    <= scl_oe_r;
  sda_oe    <= sda_oe_r;
  busy      <= '0' when state = S_IDLE else '1';
  done      <= done_r;
  ack_error <= err_r;
  data_rd   <= rd_r;

end architecture rtl;
