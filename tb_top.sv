module stream_rescale_tb_simple;                  // второй вариант

// Параметры
parameter T_DATA_WIDTH = 1;
parameter S_KEEP_WIDTH = 3;
parameter M_KEEP_WIDTH = 6;

// Сигналы
logic clk;
logic rst_n;
logic [T_DATA_WIDTH-1:0] s_data_in [S_KEEP_WIDTH-1:0];
logic [S_KEEP_WIDTH-1:0] s_keep_in;
logic s_last_in;
logic s_valid_in;
logic s_ready_out;
logic [T_DATA_WIDTH-1:0] m_data_out [M_KEEP_WIDTH-1:0];
logic [M_KEEP_WIDTH-1:0] m_keep_out;
logic m_last_out;
logic m_valid_out;
logic m_ready_in;

// Тактовый сигнал
always #5 clk = ~clk;

// DUT
stream_rescale #(
    .T_DATA_WIDTH(T_DATA_WIDTH),
    .S_KEEP_WIDTH(S_KEEP_WIDTH),
    .M_KEEP_WIDTH(M_KEEP_WIDTH)
) dut (.*);

// Тест
initial begin
    // Инициализация
    clk = 0;
    rst_n = 1;
    s_valid_in = 0;
    s_last_in = 0;
    m_ready_in = 1;
    s_data_in[0] = 0;
    s_data_in[1] = 0;
    s_data_in[2] = 0;
    s_keep_in = 0;
    
    // Сброс
    rst_n = 0;
    #20;
    rst_n = 1;
    #10;
    

    @(posedge clk);
    s_valid_in = 1;
    s_data_in[0] = 1'b1;
    s_data_in[1] = 1'b0;
    s_data_in[2] = 4'b1;
    s_keep_in = 3'b111;
    s_last_in = 0;
    
    @(posedge clk);
    s_valid_in = 0;
    
    // Ждем выходные данные
    #100;
    

    @(posedge clk);
    s_valid_in = 1;
    s_data_in[0] = 1'b1;
    s_data_in[1] = 1'b0;
    s_data_in[2] = 1'b1;
    s_keep_in = 3'b111;
    s_last_in = 1;
    
    @(posedge clk);
    s_valid_in = 0;
    
    // Ждем выходные данные
    #100;
     @(posedge clk);
    s_valid_in = 1;
    s_data_in[0] = 1'b1;
    s_data_in[1] = 1'b1;
    s_data_in[2] = 1'b1;
    s_keep_in = 3'b111;
    s_last_in = 0;
    
    @(posedge clk);
    s_valid_in = 0;
    
    // Ждем выходные данные
    #100;  
    @(posedge clk);
    s_valid_in = 1;
    s_data_in[0] = 1'b1;
    s_data_in[1] = 1'b1;
    s_data_in[2] = 1'b1;
    s_keep_in = 3'b111;
    s_last_in = 1;
    
    @(posedge clk);
    s_valid_in = 0;
    
    // Завершение
    #100;
    $finish;
end

endmodule