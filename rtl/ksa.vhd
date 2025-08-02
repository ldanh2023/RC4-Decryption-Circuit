library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ksa is
  port(
    CLOCK_50            : in  std_logic;  -- Clock pin
    KEY                 : in  std_logic_vector(3 downto 0);  -- push button switches
    SW                 : in  std_logic_vector(9 downto 0);  -- slider switches
    LEDR : out std_logic_vector(9 downto 0);  -- red lights
    HEX0 : out std_logic_vector(6 downto 0);
    HEX1 : out std_logic_vector(6 downto 0);
    HEX2 : out std_logic_vector(6 downto 0);
    HEX3 : out std_logic_vector(6 downto 0);
    HEX4 : out std_logic_vector(6 downto 0);
    HEX5 : out std_logic_vector(6 downto 0));
end ksa;

architecture rtl of ksa is
   COMPONENT SevenSegmentDisplayDecoder IS
    PORT
    (
        ssOut : OUT STD_LOGIC_VECTOR (6 DOWNTO 0);
        nIn : IN STD_LOGIC_VECTOR (3 DOWNTO 0)
    );
    END COMPONENT;


    -- Working memory (S)
    COMPONENT s_memory IS
        PORT
        (
            address		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
            clock		: IN STD_LOGIC  := '1';
            data		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
            wren		: IN STD_LOGIC ;
            q		    : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
        );
    END COMPONENT;

    -- Encrypted message memory (E)
    COMPONENT encrypted_msg_memory IS
        PORT
        (
            address		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
            clock		: IN STD_LOGIC  := '1';
            q		    : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
        );
    END COMPONENT;


    -- Decrypted message memory (D)
    COMPONENT decrypted_msg_memory IS
        PORT
        (
            address		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
            clock		: IN STD_LOGIC  := '1';
            data		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
            wren		: IN STD_LOGIC ;
            q		    : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
        );
    END COMPONENT;


    -- Top module rc4_solution (FSM control top module)
    COMPONENT rc4_solution IS
        PORT
        (
            clock : IN STD_LOGIC;
            buttons : IN STD_LOGIC_VECTOR(3 downto 0);

            lower_key_index : IN STD_LOGIC_VECTOR(23 downto 0);
            upper_key_index : IN STD_LOGIC_VECTOR(23 downto 0);
            current_key : OUT STD_LOGIC_VECTOR(23 downto 0);
            successful_key : OUT STD_LOGIC; --output key is found, output to top module (0 if not found, 1 if found)
            stop_search : IN STD_LOGIC;

            -- S memory interface controls
            S_address : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            DataIn_toS : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            S_DataOut_toFSM : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            S_write_en : OUT STD_LOGIC;


            -- Encrypted memory controls
            Encrypted_mem_address : OUT STD_LOGIC_VECTOR(7 downto 0);
            Encrypted_mem_DataOut_toFSM : IN STD_LOGIC_VECTOR(7 downto 0);


            -- Decrypted memory controls
            Decrypted_mem_address : OUT STD_LOGIC_VECTOR(7 downto 0);
            DataIn_to_decrypted_mem : OUT STD_LOGIC_VECTOR(7 downto 0);
            Decrypted_mem_DataOut_toFSM : IN STD_LOGIC_VECTOR(7 downto 0);
            Decrypted_mem_write_en : OUT STD_LOGIC
        );
    END COMPONENT;


    -- Bonus
    COMPONENT Display_SecretKey IS
        PORT
        (
            clk : IN STD_LOGIC;
            reset : IN STD_LOGIC;

            --Secret Key from Cores
            secretKey_inst1 : IN STD_LOGIC_VECTOR(23 downto 0);
            secretKey_inst2 : IN STD_LOGIC_VECTOR(23 downto 0);
            secretKey_inst3 : IN STD_LOGIC_VECTOR(23 downto 0);
            secretKey_inst4 : IN STD_LOGIC_VECTOR(23 downto 0);

            --If key was successfully found
            key_found_finish_inst1 : IN STD_LOGIC; --if key was found in check
            key_found_finish_inst2 : IN STD_LOGIC;
            key_found_finish_inst3 : IN STD_LOGIC;
            key_found_finish_inst4 : IN STD_LOGIC;

            --Secret Key out to Display
            secretKey_out : OUT STD_LOGIC_VECTOR(23 downto 0);
            stop_search : OUT STD_LOGIC
        );
    END COMPONENT;

    -- Bonus: Clock divider is used to generate clock for display on HEX displays otherwise keys will flash too quickly at the default clock frequency
    COMPONENT Arbitrary_Clock_Divider_My_Version IS
        GENERIC (
            duty_cycle : integer := 2;
            N          : integer := 32
        );
        PORT (
            in_clk       : IN  STD_LOGIC;
            out_clk      : OUT STD_LOGIC;
            freq_counter : IN  STD_LOGIC_VECTOR(31 downto 0);
            on_off       : IN STD_LOGIC
        );
    END COMPONENT;


    -- clock and reset signals  
	 signal clk, reset_n : std_logic;

    -- Found key signals
     signal key_success : std_logic;
     signal secretKey_Display : std_logic_vector(23 downto 0);
     signal stop_search : std_logic;

    -- Clock divider signals
    signal out_clk : std_logic;

    -- ============================================= Decryption Core #1 ========================================
     -- s_memory signals
     signal s_address1, s_DataIn1, s_DataOut1  : std_logic_vector (7 downto 0);
     signal	s_write_en1                      : std_logic;


     -- Encrypted memory signals
     signal encrypted_mem_address1, encrypted_mem_DataOut1 : std_logic_vector (7 downto 0);
     

     -- Decrypted memory signals
     signal decrypted_mem_address1, decrypted_mem_DataIn1, decrypted_mem_DataOut1  : std_logic_vector (7 downto 0);
     signal decrypted_mem_write_en1                                              : std_logic;


    -- Secret key signals
    signal secret_key_inst1 : std_logic_vector(23 downto 0);
    signal successful_key_inst1: std_logic;



    -- ============================================= Decryption Core #2 ========================================
     -- s_memory signals
     signal s_address2, s_DataIn2, s_DataOut2  : std_logic_vector (7 downto 0);
     signal	s_write_en2                      : std_logic;


     -- Encrypted memory signals
     signal encrypted_mem_address2, encrypted_mem_DataOut2 : std_logic_vector (7 downto 0);
     

     -- Decrypted memory signals
     signal decrypted_mem_address2, decrypted_mem_DataIn2, decrypted_mem_DataOut2  : std_logic_vector (7 downto 0);
     signal decrypted_mem_write_en2                                              : std_logic;


    -- Secret key signals
    signal secret_key_inst2 : std_logic_vector(23 downto 0);
    signal successful_key_inst2: std_logic;



    -- ============================================= Decryption Core #3 ========================================
     -- s_memory signals
     signal s_address3, s_DataIn3, s_DataOut3  : std_logic_vector (7 downto 0);
     signal	s_write_en3                      : std_logic;


     -- Encrypted memory signals
     signal encrypted_mem_address3, encrypted_mem_DataOut3 : std_logic_vector (7 downto 0);
     

     -- Decrypted memory signals
     signal decrypted_mem_address3, decrypted_mem_DataIn3, decrypted_mem_DataOut3  : std_logic_vector (7 downto 0);
     signal decrypted_mem_write_en3                                              : std_logic;


    -- Secret key signals
    signal secret_key_inst3 : std_logic_vector(23 downto 0);
    signal successful_key_inst3: std_logic;



    -- ============================================= Decryption Core #4 ========================================
     -- s_memory signals
     signal s_address4, s_DataIn4, s_DataOut4  : std_logic_vector (7 downto 0);
     signal	s_write_en4                      : std_logic;


     -- Encrypted memory signals
     signal encrypted_mem_address4, encrypted_mem_DataOut4 : std_logic_vector (7 downto 0);
     

     -- Decrypted memory signals
     signal decrypted_mem_address4, decrypted_mem_DataIn4, decrypted_mem_DataOut4  : std_logic_vector (7 downto 0);
     signal decrypted_mem_write_en4                                              : std_logic;


    -- Secret key signals
    signal secret_key_inst4 : std_logic_vector(23 downto 0);
    signal successful_key_inst4: std_logic;



begin

    clk <= CLOCK_50;
    -- reset_n <= KEY(3); given in original template, not needed

    key_success <= successful_key_inst1 or successful_key_inst2 or successful_key_inst3 or successful_key_inst4;
    LEDR(0) <= key_success;
    LEDR(1) <= not key_success;
    

    SevenSegment1: SevenSegmentDisplayDecoder
        port map (
            ssOut => HEX0,
            nIn => secretKey_Display(3 downto 0)
        );

    SevenSegment2: SevenSegmentDisplayDecoder
        port map (
            ssOut => HEX1,
            nIn => secretKey_Display(7 downto 4)
        );

    SevenSegment3: SevenSegmentDisplayDecoder
        port map (
            ssOut => HEX2,
            nIn => secretKey_Display(11 downto 8)
        );

    SevenSegment4: SevenSegmentDisplayDecoder
        port map (
            ssOut => HEX3,
            nIn => secretKey_Display(15 downto 12)
        );

    SevenSegment5: SevenSegmentDisplayDecoder
        port map (
            ssOut => HEX4,
            nIn => secretKey_Display(19 downto 16)
        );
    
    SevenSegment6: SevenSegmentDisplayDecoder
        port map (
            ssOut => HEX5,
            nIn => secretKey_Display(23 downto 20)
        );


    -- Bonus
    Display_SecretKey_inst : Display_SecretKey
        port map (
            clk => out_clk,
            reset => '0',

            --Secret Key from Cores
            secretKey_inst1 => secret_key_inst1,
            secretKey_inst2 => secret_key_inst2,
            secretKey_inst3 => secret_key_inst3,
            secretKey_inst4 => secret_key_inst4,

            --If key was successfully found
            key_found_finish_inst1 => successful_key_inst1, --if key was found in check
            key_found_finish_inst2 => successful_key_inst2,
            key_found_finish_inst3 => successful_key_inst3,
            key_found_finish_inst4 => successful_key_inst4,

            --Secret Key out to Display
            secretKey_out => secretKey_Display,
            stop_search => stop_search
        );

    
    Arbitrary_Clock_Divider_My_Version_inst : Arbitrary_Clock_Divider_My_Version
        generic map (
            duty_cycle => 2,
            N          => 32
        )
        port map (
            in_clk       => clk,
            out_clk      => out_clk,
            freq_counter => std_logic_vector(to_unsigned(2500000, 32)),
            on_off       => '1' -- inverse logic, 1 is on, 0 is off
        );


    -- Calculations: Valid key range: 0 to B"0011_1111_1111_1111_1111_1111" (decimal: 4,194,303)
    -- Bonus: divide into 4 equal ranges
        -- Instance 1: 0 - 1,048,575
        -- Instance 2: 1,048,576 - 2,097,151
        -- Instance 3: 2,097,152 - 3,145,727
        -- Instance 4: 3,145,728 - 4,194,303


    -- ============================================= Decryption Core #1 ========================================

    -- Instantiate the RAM (working memory)
    S_memory_inst1 : s_memory
        port map (
            address => s_address1,
            clock   => clk,
            data    => s_DataIn1,
            wren    => s_write_en1,
            q       => s_DataOut1
        );
    

    -- Instantiate encrypted message memory (E)
    encrypted_msg_memory_inst1 : encrypted_msg_memory
        port map (
            address => encrypted_mem_address1,
            clock   => clk,
            q       => encrypted_mem_DataOut1
        );


    -- Decrypted message memory (D)
    decrypted_msg_memory_inst1 : decrypted_msg_memory
        port map (
            address => decrypted_mem_address1,
            clock   => clk,
            data    => decrypted_mem_DataIn1,
            wren    => decrypted_mem_write_en1,
            q       => decrypted_mem_DataOut1
        );
    

    -- Instantiate the top module rc4_solution (FSM control top module)
    rc4_solution_inst1 : rc4_solution
        port map (
            clock => clk,
            buttons => KEY,

            lower_key_index => std_logic_vector(to_unsigned(0, 24)),
            upper_key_index => std_logic_vector(to_unsigned(1048575, 24)),
            current_key => secret_key_inst1,
            successful_key => successful_key_inst1,
            stop_search => stop_search,


            -- S memory interface controls
            S_address => s_address1,
            DataIn_toS => s_DataIn1,
            S_DataOut_toFSM => s_DataOut1,
            S_write_en => s_write_en1,


            -- Encrypted memory controls
            Encrypted_mem_address => encrypted_mem_address1,
            Encrypted_mem_DataOut_toFSM => encrypted_mem_DataOut1,


            -- Decrypted memory controls
            Decrypted_mem_address => decrypted_mem_address1,
            DataIn_to_decrypted_mem => decrypted_mem_DataIn1,
            Decrypted_mem_DataOut_toFSM => decrypted_mem_DataOut1,
            Decrypted_mem_write_en => decrypted_mem_write_en1
        );





    -- ============================================= Decryption Core #2 ========================================

    -- Instantiate the RAM (working memory)
    S_memory_inst2 : s_memory
        port map (
            address => s_address2,
            clock   => clk,
            data    => s_DataIn2,
            wren    => s_write_en2,
            q       => s_DataOut2
        );
    

    -- Instantiate encrypted message memory (E)
    encrypted_msg_memory_inst2 : encrypted_msg_memory
        port map (
            address => encrypted_mem_address2,
            clock   => clk,
            q       => encrypted_mem_DataOut2
        );


    -- Decrypted message memory (D)
    decrypted_msg_memory_inst2 : decrypted_msg_memory
        port map (
            address => decrypted_mem_address2,
            clock   => clk,
            data    => decrypted_mem_DataIn2,
            wren    => decrypted_mem_write_en2,
            q       => decrypted_mem_DataOut2
        );
    

    -- Instantiate the top module rc4_solution (FSM control top module)
    rc4_solution_inst2 : rc4_solution
        port map (
            clock => clk,
            buttons => KEY,

            lower_key_index => std_logic_vector(to_unsigned(1048576, 24)),
            upper_key_index => std_logic_vector(to_unsigned(2097151, 24)),
            current_key => secret_key_inst2,
            successful_key => successful_key_inst2,
            stop_search => stop_search,
            

            -- S memory interface controls
            S_address => s_address2,
            DataIn_toS => s_DataIn2,
            S_DataOut_toFSM => s_DataOut2,
            S_write_en => s_write_en2,


            -- Encrypted memory controls
            Encrypted_mem_address => encrypted_mem_address2,
            Encrypted_mem_DataOut_toFSM => encrypted_mem_DataOut2,


            -- Decrypted memory controls
            Decrypted_mem_address => decrypted_mem_address2,
            DataIn_to_decrypted_mem => decrypted_mem_DataIn2,
            Decrypted_mem_DataOut_toFSM => decrypted_mem_DataOut2,
            Decrypted_mem_write_en => decrypted_mem_write_en2
        );



    -- ============================================= Decryption Core #3 ========================================

    -- Instantiate the RAM (working memory)
    S_memory_inst3 : s_memory
        port map (
            address => s_address3,
            clock   => clk,
            data    => s_DataIn3,
            wren    => s_write_en3,
            q       => s_DataOut3
        );
    

    -- Instantiate encrypted message memory (E)
    encrypted_msg_memory_inst3 : encrypted_msg_memory
        port map (
            address => encrypted_mem_address3,
            clock   => clk,
            q       => encrypted_mem_DataOut3
        );


    -- Decrypted message memory (D)
    decrypted_msg_memory_inst3 : decrypted_msg_memory
        port map (
            address => decrypted_mem_address3,
            clock   => clk,
            data    => decrypted_mem_DataIn3,
            wren    => decrypted_mem_write_en3,
            q       => decrypted_mem_DataOut3
        );
    

    -- Instantiate the top module rc4_solution (FSM control top module)
    rc4_solution_inst3 : rc4_solution
        port map (
            clock => clk,
            buttons => KEY,

            lower_key_index => std_logic_vector(to_unsigned(2097152, 24)),
            upper_key_index => std_logic_vector(to_unsigned(3145727, 24)),
            current_key => secret_key_inst3,
            successful_key => successful_key_inst3,
            stop_search => stop_search,
            

            -- S memory interface controls
            S_address => s_address3,
            DataIn_toS => s_DataIn3,
            S_DataOut_toFSM => s_DataOut3,
            S_write_en => s_write_en3,


            -- Encrypted memory controls
            Encrypted_mem_address => encrypted_mem_address3,
            Encrypted_mem_DataOut_toFSM => encrypted_mem_DataOut3,


            -- Decrypted memory controls
            Decrypted_mem_address => decrypted_mem_address3,
            DataIn_to_decrypted_mem => decrypted_mem_DataIn3,
            Decrypted_mem_DataOut_toFSM => decrypted_mem_DataOut3,
            Decrypted_mem_write_en => decrypted_mem_write_en3
        );



    -- ============================================= Decryption Core #4 ========================================

    -- Instantiate the RAM (working memory)
    S_memory_inst4 : s_memory
        port map (
            address => s_address4,
            clock   => clk,
            data    => s_DataIn4,
            wren    => s_write_en4,
            q       => s_DataOut4
        );
    

    -- Instantiate encrypted message memory (E)
    encrypted_msg_memory_inst4 : encrypted_msg_memory
        port map (
            address => encrypted_mem_address4,
            clock   => clk,
            q       => encrypted_mem_DataOut4
        );


    -- Decrypted message memory (D)
    decrypted_msg_memory_inst4 : decrypted_msg_memory
        port map (
            address => decrypted_mem_address4,
            clock   => clk,
            data    => decrypted_mem_DataIn4,
            wren    => decrypted_mem_write_en4,
            q       => decrypted_mem_DataOut4
        );
    

    -- Instantiate the top module rc4_solution (FSM control top module)
    rc4_solution_inst4 : rc4_solution
        port map (
            clock => clk,
            buttons => KEY,

            lower_key_index => std_logic_vector(to_unsigned(3145728, 24)),
            upper_key_index => std_logic_vector(to_unsigned(4194303, 24)),
            current_key => secret_key_inst4,
            successful_key => successful_key_inst4,
            stop_search => stop_search,
            

            -- S memory interface controls
            S_address => s_address4,
            DataIn_toS => s_DataIn4,
            S_DataOut_toFSM => s_DataOut4,
            S_write_en => s_write_en4,


            -- Encrypted memory controls
            Encrypted_mem_address => encrypted_mem_address4,
            Encrypted_mem_DataOut_toFSM => encrypted_mem_DataOut4,


            -- Decrypted memory controls
            Decrypted_mem_address => decrypted_mem_address4,
            DataIn_to_decrypted_mem => decrypted_mem_DataIn4,
            Decrypted_mem_DataOut_toFSM => decrypted_mem_DataOut4,
            Decrypted_mem_write_en => decrypted_mem_write_en4
        );
end RTL;
