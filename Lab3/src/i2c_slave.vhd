--------------------------------------------------------------------------------
-- Модуль    : i2c_slave
-- Опис      : Slave-пристрій шини I2C (приймач / Rx-частина протоколу).
--             Працює з надлишковою вибіркою ліній SCL/SDA системним тактом,
--             розпізнає умови START/STOP, приймає адресу, порівнює її з
--             власною (generic SLAVE_ADDR) і відповідає ACK.
--               * запис (R/W = 0): приймає байти у rx_data, строб rx_valid;
--               * читання (R/W = 1): видає на шину байт tx_data.
-- Мова      : VHDL-2008
-- Варіант   : 5 (I2C, VHDL)
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2c_slave is
  generic (
    SLAVE_ADDR : std_logic_vector(6 downto 0) := "1010101"  -- 0x55
  );
  port (
    clk      : in  std_logic;                     -- системний такт
    rst      : in  std_logic;                     -- синхронне скидання
    -- фізичні лінії
    scl_i    : in  std_logic;                     -- рівень SCL
    sda_i    : in  std_logic;                     -- рівень SDA
    sda_oe   : out std_logic;                     -- 1 = притягнути SDA до 0
    -- інтерфейс користувача
    rx_data  : out std_logic_vector(7 downto 0);  -- прийнятий байт
    rx_valid : out std_logic;                     -- строб: новий байт прийнято
    tx_data  : in  std_logic_vector(7 downto 0);  -- байт для видачі Master'у
    addr_hit : out std_logic                      -- строб: адресу розпізнано
  );
end entity i2c_slave;

architecture rtl of i2c_slave is

  type state_t is (
    S_IDLE,      -- очікування START
    S_ADDR,      -- прийом адреси + R/W
    S_ACK_ADDR,  -- видача ACK на свою адресу
    S_RX,        -- прийом байта даних
    S_ACK_RX,    -- видача ACK на прийнятий байт
    S_TX,        -- передача байта Master'у
    S_ACK_TX     -- очікування ACK/NACK від Master
  );
  signal state     : state_t := S_IDLE;

  -- синхронізатори + попередні значення для виявлення фронтів
  signal scl_s     : std_logic_vector(2 downto 0) := "111";
  signal sda_s     : std_logic_vector(2 downto 0) := "111";
  signal scl_rise  : std_logic;
  signal scl_fall  : std_logic;
  signal start_det : std_logic;
  signal stop_det  : std_logic;

  signal shreg     : std_logic_vector(7 downto 0) := (others => '0');
  signal bit_cnt   : natural range 0 to 8 := 0;
  signal rw_r      : std_logic := '0';
  signal sda_oe_r  : std_logic := '0';
  signal rx_r      : std_logic_vector(7 downto 0) := (others => '0');
  signal rx_v      : std_logic := '0';
  signal hit_r     : std_logic := '0';

begin

  p_sync : process (clk)
  begin
    if rising_edge(clk) then
      scl_s <= scl_s(1 downto 0) & scl_i;
      sda_s <= sda_s(1 downto 0) & sda_i;
    end if;
  end process;

  -- детектори подій на шині
  scl_rise  <= '1' when scl_s(2 downto 1) = "01" else '0';
  scl_fall  <= '1' when scl_s(2 downto 1) = "10" else '0';
  start_det <= '1' when scl_s(1) = '1' and sda_s(2 downto 1) = "10" else '0'; -- SDA↓ при SCL=1
  stop_det  <= '1' when scl_s(1) = '1' and sda_s(2 downto 1) = "01" else '0'; -- SDA↑ при SCL=1

  p_fsm : process (clk)
  begin
    if rising_edge(clk) then
      rx_v  <= '0';
      hit_r <= '0';

      if rst = '1' then
        state    <= S_IDLE;
        sda_oe_r <= '0';
        bit_cnt  <= 0;
        rx_r     <= (others => '0');

      elsif start_det = '1' then            -- START або повторний START
        state    <= S_ADDR;
        bit_cnt  <= 0;
        sda_oe_r <= '0';

      elsif stop_det = '1' then             -- STOP: звільняємо шину
        state    <= S_IDLE;
        sda_oe_r <= '0';

      else
        case state is

          when S_IDLE => null;

          -- прийом 8 біт: 7 біт адреси + R/W
          when S_ADDR =>
            if scl_rise = '1' and bit_cnt < 8 then
              shreg   <= shreg(6 downto 0) & sda_s(1);
              bit_cnt <= bit_cnt + 1;
            elsif scl_fall = '1' and bit_cnt = 8 then
              if shreg(7 downto 1) = SLAVE_ADDR then
                rw_r     <= shreg(0);
                sda_oe_r <= '1';            -- ACK
                hit_r    <= '1';
                state    <= S_ACK_ADDR;
              else
                state    <= S_IDLE;         -- чужа адреса - мовчимо (NACK)
              end if;
            end if;

          -- кінець такту ACK -> переходимо до даних
          when S_ACK_ADDR =>
            if scl_fall = '1' then
              bit_cnt <= 0;
              if rw_r = '0' then
                sda_oe_r <= '0';
                state    <= S_RX;
              else
                shreg    <= tx_data;
                sda_oe_r <= not tx_data(7); -- одразу виставляємо старший біт
                state    <= S_TX;
              end if;
            end if;

          -- прийом байта даних від Master
          when S_RX =>
            if scl_rise = '1' and bit_cnt < 8 then
              shreg   <= shreg(6 downto 0) & sda_s(1);
              bit_cnt <= bit_cnt + 1;
            elsif scl_fall = '1' and bit_cnt = 8 then
              rx_r     <= shreg;
              rx_v     <= '1';
              sda_oe_r <= '1';              -- ACK
              state    <= S_ACK_RX;
            end if;

          when S_ACK_RX =>
            if scl_fall = '1' then
              sda_oe_r <= '0';
              bit_cnt  <= 0;
              state    <= S_RX;             -- можливий наступний байт
            end if;

          -- передача байта Master'у: новий біт - після кожного спаду SCL
          when S_TX =>
            if scl_fall = '1' then
              if bit_cnt = 7 then
                sda_oe_r <= '0';            -- відпускаємо SDA для ACK Master'а
                state    <= S_ACK_TX;
              else
                bit_cnt  <= bit_cnt + 1;
                shreg    <= shreg(6 downto 0) & '0';
                sda_oe_r <= not shreg(6);
              end if;
            end if;

          -- ACK від Master -> ще байт, NACK -> кінець
          when S_ACK_TX =>
            if scl_rise = '1' then
              if sda_s(1) = '1' then
                state <= S_IDLE;            -- NACK
              else
                rw_r  <= '1';
              end if;
            elsif scl_fall = '1' then
              bit_cnt  <= 0;
              shreg    <= tx_data;
              sda_oe_r <= not tx_data(7);
              state    <= S_TX;
            end if;

        end case;
      end if;
    end if;
  end process;

  sda_oe   <= sda_oe_r;
  rx_data  <= rx_r;
  rx_valid <= rx_v;
  addr_hit <= hit_r;

end architecture rtl;
