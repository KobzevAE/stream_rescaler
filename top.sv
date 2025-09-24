`timescale 1 ns / 1 ps

module stream_rescale #(
    parameter T_DATA_WIDTH = 1,
    S_KEEP_WIDTH = 8,
    M_KEEP_WIDTH = 3
)(
    input logic clk,
    input logic rst_n,
    input logic [T_DATA_WIDTH-1:0] s_data_in [S_KEEP_WIDTH-1:0],
    input logic [S_KEEP_WIDTH-1:0] s_keep_in,
    input logic s_last_in,
    input logic s_valid_in,
    output logic s_ready_out,
    output logic [T_DATA_WIDTH-1:0] m_data_out [M_KEEP_WIDTH-1:0],
    output logic [M_KEEP_WIDTH-1:0] m_keep_out,
    output logic m_last_out,
    output logic m_valid_out,
    input logic m_ready_in
);

always @(s_data_in) begin
 $display("in module       data == %p       time == %t", s_data_in, $time());
end


// buffer
localparam BUFFER_SIZE = S_KEEP_WIDTH * M_KEEP_WIDTH;   // we use this  ratio so that for any input parameters S_KEEP_WIDTH and M_KEEP_WIDTH we have enough buffer
localparam PTR_WIDTH = $clog2(BUFFER_SIZE);



logic [T_DATA_WIDTH-1:0] buffer [BUFFER_SIZE-1:0];
logic [BUFFER_SIZE-1:0] buffer_keep;
logic buffer_has_last;

// pointers
logic [PTR_WIDTH:0] wr;
logic [PTR_WIDTH:0] rd;
logic [PTR_WIDTH:0] buffer_cnt;    // if buffer_cnt >= M_KEEP_WIDTH  =>  m_data_out <= 0




logic [PTR_WIDTH:0] temp;

logic [$clog2(S_KEEP_WIDTH+1)-1:0] valid_data_cnt;

always_comb begin
    valid_data_cnt = 0;
    for (int i = 0; i < S_KEEP_WIDTH; i++) begin
        valid_data_cnt += s_keep_in[i];                  // we count how many valid data we have
    end
end

// logic for s_ready_out
assign s_ready_out = (buffer_cnt + valid_data_cnt) <= BUFFER_SIZE;     //s_ready_out = 1  if there's valid data left in the buffer, which is no more than the buffer depth



// logic for m_valid_out and m_last_out
assign m_valid_out = (buffer_cnt >= M_KEEP_WIDTH-1) || (buffer_has_last && buffer_cnt > 0);    // (if quantity of data in buffer is M_KEEP_WIDTH-1) OR (we have last pocket of data (check str 92) AND quantity of data in buffer more than 0)
assign m_last_out = buffer_has_last && (buffer_cnt <= M_KEEP_WIDTH);

// writing data in buffer
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin                                                                 //logic for reset
        wr <= 0;
        rd <= 0;
        buffer_cnt <= 0;
        buffer_has_last <= 0;
        buffer <= '{ default:0 };
	temp = 0;
        for (int i = 0; i < BUFFER_SIZE; i++) begin
            buffer[i] <= 0;
            buffer_keep[i] <= 0;
        end
    end else begin

  
        if (s_valid_in && s_ready_out) begin
            for (int i = 0; i < S_KEEP_WIDTH; i++) begin
                if (s_keep_in[i]) begin
                    buffer[wr] <= s_data_in[i];
                    buffer_keep[wr] <= s_keep_in[i];
                    $display("data == %p  ;;; data[i] == %b;;;; keep ==  %b  ;;; adr == %d ;;; time == %t", s_data_in,s_data_in[i], s_keep_in[i],wr, $time());
                    wr = wr + 1;
                    end

            end
	    temp = 0;
            for(int k = 0; k < S_KEEP_WIDTH; k++) begin
            temp = temp + s_keep_in[k];
            end
            buffer_cnt <= buffer_cnt + temp;
            if (s_last_in) buffer_has_last <= 1'b1;
        end
        

        if (m_valid_out && m_ready_in) begin
            rd <= rd + M_KEEP_WIDTH;
            if (buffer_cnt >= M_KEEP_WIDTH) begin
                buffer_cnt <= buffer_cnt - M_KEEP_WIDTH;
            end else begin
                buffer_cnt <= 0; 
            end
            
            
            if (buffer_has_last && buffer_cnt <= M_KEEP_WIDTH) begin
                buffer_has_last <= 1'b0;
            end
            
           
        end
        if (m_last_out) begin                                                   //after transac we clear our buffer and move the pointers to their original position
            buffer <= '{ default:0 };
            buffer_keep <= '{default:0};
            wr <= 0;
            rd <= 0;
        end 

        if (wr >= BUFFER_SIZE) wr <= 0;                                         // for the case when buffer is full, use and modify it with circullar buffer
        if (rd >= BUFFER_SIZE) rd <= 0;
    end
end

// reading from buffer
always_comb begin
    for (int i = 0; i < M_KEEP_WIDTH; i++) begin
        if (i < buffer_cnt) begin
        $display("OUT    data == %p ;;; keep == %b;;; time == %t",m_data_out,m_keep_out, $time());
            m_data_out[i] = buffer[rd + i];
            m_keep_out[i] = buffer_keep[rd + i];
        end else begin

            m_data_out[i] = 0;
            m_keep_out[i] = 1'b0;
        end
    end
end

endmodule