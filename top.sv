module stream_rescale #(
    parameter T_DATA_WIDTH = 1,
    S_KEEP_WIDTH = 3,
    M_KEEP_WIDTH = 6
)(
    input logic clk,
    input logic rst_n,
    input logic [T_DATA_WIDTH-1:0] s_data_in [S_KEEP_WIDTH],
    input logic [S_KEEP_WIDTH-1:0] s_keep_in,
    input logic s_last_in,
    input logic s_valid_in,
    output logic s_ready_out,
    output logic [T_DATA_WIDTH-1:0] m_data_out [M_KEEP_WIDTH],
    output logic [M_KEEP_WIDTH-1:0] m_keep_out,
    output logic m_last_out,
    output logic m_valid_out,
    input logic m_ready_in
);

// размер буфера
localparam BUFFER_SIZE = S_KEEP_WIDTH * 4;
localparam PTR_WIDTH = $clog2(BUFFER_SIZE);


logic [T_DATA_WIDTH-1:0] buffer [BUFFER_SIZE-1:0];
logic [BUFFER_SIZE-1:0] buffer_keep;
logic buffer_has_last;

// Указатели и счетчик
logic [PTR_WIDTH:0] wr;
logic [PTR_WIDTH:0] rd;
logic [PTR_WIDTH:0] buffer_cnt;
logic [PTR_WIDTH-1:0] last_ptr;

// Подсчет валидных входных данных
logic [$clog2(S_KEEP_WIDTH+1)-1:0] valid_data_cnt;

always_comb begin
    valid_data_cnt = 0;
    for (int i = 0; i < S_KEEP_WIDTH; i++) begin
        valid_data_cnt += s_keep_in[i];
    end
end

// Логика готовности приема
assign s_ready_out = (buffer_cnt + valid_data_cnt) <= BUFFER_SIZE;

// Логика валидности передачи
assign m_valid_out = (buffer_cnt >= M_KEEP_WIDTH) || (buffer_has_last && buffer_cnt > 0);
assign m_last_out = buffer_has_last && (buffer_cnt <= M_KEEP_WIDTH);

// Запись в буфер
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        wr <= 0;
        rd <= 0;
        buffer_cnt <= 0;
        buffer_has_last <= 0;
        buffer <= '{ default:0 };
        for (int i = 0; i < BUFFER_SIZE; i++) begin
            buffer[i] <= 0;
            buffer_keep[i] <= 0;
        end
    end else begin
        // Запись входных данных
        if (s_valid_in && s_ready_out) begin
            for (int i = 0; i < S_KEEP_WIDTH; i++) begin
                buffer_keep <= s_keep_in[i];
                if (s_keep_in[i])
                buffer[wr + i] <= s_data_in[i];

            end
            wr <= wr + S_KEEP_WIDTH;
            buffer_cnt <= buffer_cnt + S_KEEP_WIDTH;
            if (s_last_in) buffer_has_last <= 1'b1;
        end
        
        // Чтение выходных данных
        if (m_valid_out && m_ready_in) begin
            rd <= rd + M_KEEP_WIDTH;
            if (buffer_cnt >= M_KEEP_WIDTH) begin
                buffer_cnt <= buffer_cnt - M_KEEP_WIDTH;
            end else begin
                buffer_cnt <= 0; // Последний неполный пакет
            end
            
            // Сброс last флага после отправки последнего пакета
            if (buffer_has_last && buffer_cnt <= M_KEEP_WIDTH) begin
                buffer_has_last <= 1'b0;
            end
        end
        
        // Обработка переполнения указателей (кольцевой буфер)
        if (wr >= BUFFER_SIZE) wr <= wr - BUFFER_SIZE;
        if (rd >= BUFFER_SIZE) rd <= rd - BUFFER_SIZE;
    end
end

// Чтение из буфера (комбинационная логика)
always_comb begin
    for (int i = 0; i < M_KEEP_WIDTH; i++) begin
        if (i < buffer_cnt) begin
            // Данные есть в буфере
            m_data_out[i] = buffer[rd + i];
            m_keep_out[i] = buffer_keep[rd + i];
        end else begin
            // Данных нет - заполняем нулями
            m_data_out[i] = 0;
            m_keep_out[i] = 1'b0;
        end
    end
end

endmodule