`timescale 1ns/1ns

module Robo_TB;

parameter N = 2'b00, S = 2'b01, L = 2'b10, O = 2'b11;

reg clock, reset, head, left, under, barrier;
wire forward, turn, remove, standby;

reg [0:59] Mapa [0:10]; // linha 0 reservada para posicao do robo e quantidade de movimentos
reg [0:59] Linha_Mapa;
reg [0:59] Linha_Atual;
reg [0:14] Linha_Robo;
reg [0:14] Coluna_Robo;
reg [0:5] Orientacao_Robo; 
reg [0:23] Qtd_Movimentos;
reg [0:47] String_Orientacao_Robo;
reg [0:0] primeiro_bit;
reg [0:0] segundo_bit;
reg [0:0] terceiro_bit;

integer i;
integer contador_remocao;
integer tamanho_lixo;

Robo DUV (.clock(clock), .reset(reset), .head(head), .left(left), .under(under), .barrier(barrier), .forward(forward), .turn(turn), .remove(remove));

always
	#50 clock = !clock;

initial
begin
	clock = 0;
	reset = 0;
	head = 0;
	left = 1;
	under = 1;
	barrier = 0;
	tamanho_lixo = 0;

	$readmemb("Mapa.txt", Mapa);
	Linha_Mapa = Mapa[0];
	Linha_Robo = Linha_Mapa[0:14];
	Coluna_Robo = Linha_Mapa[15:29];
	Orientacao_Robo = Linha_Mapa[30:35];
	Qtd_Movimentos = 8'b11001000;
	$display ("Linha = %d Coluna = %d Orientacao = %s Movimentos = %d", Linha_Robo, Coluna_Robo, String_Orientacao_Robo, Qtd_Movimentos);

    // Mapa fica salvo no reg mapa, depois que remover alterar valor dele pode fazer uma funcao

	if (Situacoes_Anomalas(1)) $stop;
	
	for (i = 0; i < Qtd_Movimentos; i = i + 1)
	begin
		@ (negedge clock);
		Define_Sensores;
		$display ("H = %b L = %b U = %b B = %b Forward = %b", head, left, under, barrier, forward);
		#1;
		Atualiza_Posicao_Robo;
		case (Orientacao_Robo)
			N: String_Orientacao_Robo = "Norte";
			S: String_Orientacao_Robo = "Sul  ";
			L: String_Orientacao_Robo = "Leste";
			O: String_Orientacao_Robo = "Oeste";
		endcase
		$display ("Linha = %d Coluna = %d Orientacao = %s", Linha_Robo, Coluna_Robo, String_Orientacao_Robo);
		if (Situacoes_Anomalas(1)) $stop;
	end

	//#50 $stop;
end

function Situacoes_Anomalas (input X);
begin
	Situacoes_Anomalas = 0;
	if ( (Linha_Robo < 1) || (Linha_Robo > 10) || (Coluna_Robo < 1) || (Coluna_Robo > 58) ) // O tb percorre o mapa de 3 em 3
		Situacoes_Anomalas = 1;
end
endfunction

task Define_Sensores;
begin
	case (Orientacao_Robo)
		N:	begin
				// definicao de head
				if (Linha_Robo == 1) // Se igual a um quer dizer que ele tá no mais em cima possível, por isso é 1 no head
					head = 1;
				else
				begin
					Linha_Mapa = Mapa[Linha_Robo - 1]; // Pega a linha que tá acima da cabeça do robo					
					
					primeiro_bit = Linha_Mapa[Coluna_Robo - 1];
					segundo_bit = Linha_Mapa[Coluna_Robo];
					terceiro_bit = Linha_Mapa[Coluna_Robo + 1];

					$display ("Linha = %b", Linha_Mapa);
					$display ("primeiro_bit = %b", Linha_Mapa[0]);
					$display ("primeiro = %b segundo = %b terceiro = %b", primeiro_bit, segundo_bit, terceiro_bit);

                    if ((primeiro_bit == 0) && ( segundo_bit == 0) && (terceiro_bit == 1))
                    begin
                        head = 1;
                    end
                    else
                    begin
                        head = 0;
                    end

                    if ((primeiro_bit == 0) && ( segundo_bit == 1) && (terceiro_bit == 0))
                    begin
						tamanho_lixo = 1;
                        barrier = 1;
                    end
					else if ((primeiro_bit == 0) && ( segundo_bit == 1) && (terceiro_bit == 1))
                    begin
						tamanho_lixo = 2;
                        barrier = 1;
                    end
                    else if ((primeiro_bit == 1) && ( segundo_bit == 0) && (terceiro_bit == 0))
                    begin
						tamanho_lixo = 3;
                        barrier = 1;
                    end
                    else
                    begin
                        barrier = 0;
                    end
				end				

				// definicao de left
				if (Coluna_Robo == 1)
					left = 1;
				else
				begin
					Linha_Mapa = Mapa[Linha_Robo];
					
					primeiro_bit = Linha_Mapa[Coluna_Robo - 4];
					segundo_bit = Linha_Mapa[Coluna_Robo - 3];
					terceiro_bit = Linha_Mapa[Coluna_Robo - 2];
					
					$display ("Linha = %b", Linha_Mapa);

					
                    if ((primeiro_bit == 0) && ( segundo_bit == 0) && (terceiro_bit == 1))
                    begin
                        left = 1;
                    end
                    else
                    begin
                        left = 0;
                    end
				end

				// definicao do under
				Linha_Mapa = Mapa[Linha_Robo-1]; // -1 N deveria ta ai, mas funcionou assim

				primeiro_bit = Linha_Mapa[Coluna_Robo - 1];
				segundo_bit = Linha_Mapa[Coluna_Robo];
				terceiro_bit = Linha_Mapa[Coluna_Robo + 1];

				if ((primeiro_bit == 1) && ( segundo_bit == 1) && (terceiro_bit == 1))
					under = 1;
				else
				begin
					under = 0;
				end

			end
		S:	begin
				// definicao de head
				if (Linha_Robo == 10)// Se igual a 10 quer dizer que ele tá no mais em baixo possível, por isso é 1 no head
					head = 1;
				else
				begin
					Linha_Mapa = Mapa[Linha_Robo + 1];
										
					primeiro_bit = Linha_Mapa[Coluna_Robo - 1];
					segundo_bit = Linha_Mapa[Coluna_Robo];
					terceiro_bit = Linha_Mapa[Coluna_Robo + 1];

					$display ("Linha = %b", Linha_Mapa);
					
                    if ((primeiro_bit == 0) && ( segundo_bit == 0) && (terceiro_bit == 1))
                    begin
                        head = 1;
                    end
                    else
                    begin
                        head = 0;
                    end

                    if ((primeiro_bit == 0) && ( segundo_bit == 1) && (terceiro_bit == 0))
                    begin
						tamanho_lixo = 1;
                        barrier = 1;
                    end
					else if ((primeiro_bit == 0) && ( segundo_bit == 1) && (terceiro_bit == 1))
                    begin
						tamanho_lixo = 2;
                        barrier = 1;
                    end
                    else if ((primeiro_bit == 1) && ( segundo_bit == 0) && (terceiro_bit == 0))
                    begin
						tamanho_lixo = 3;
                        barrier = 1;
                    end
                    else
                    begin
                        barrier = 0;
                    end                    
				end

				// definicao de left
				if (Coluna_Robo == 58)
					left = 1;
				else
				begin
					Linha_Mapa = Mapa[Linha_Robo];
					
					primeiro_bit = Linha_Mapa[Coluna_Robo + 2];
					segundo_bit = Linha_Mapa[Coluna_Robo + 3];
					terceiro_bit = Linha_Mapa[Coluna_Robo + 4];
					
                    if ((primeiro_bit == 0) && ( segundo_bit == 0) && (terceiro_bit == 1))
                    begin
                        left = 1;
                    end
                    else
                    begin
                        left = 0;
                    end
				end

				// definicao do under
				Linha_Mapa = Mapa[Linha_Robo-1];

				primeiro_bit = Linha_Mapa[Coluna_Robo - 1];
				segundo_bit = Linha_Mapa[Coluna_Robo];
				terceiro_bit = Linha_Mapa[Coluna_Robo + 1];

				if ((primeiro_bit == 1) && ( segundo_bit == 1) && (terceiro_bit == 1))
                begin
					under = 1;
                end
				else
				begin
					under = 0;
				end
			end
		L:	begin
				// definicao de head
				if (Coluna_Robo == 58)
					head = 1;
				else
				begin
					Linha_Mapa = Mapa[Linha_Robo];
					
					primeiro_bit = Linha_Mapa[Coluna_Robo + 2];
					segundo_bit = Linha_Mapa[Coluna_Robo + 3];
					terceiro_bit = Linha_Mapa[Coluna_Robo + 4];

					$display ("Linha = %b", Linha_Mapa);
					
                    if ((primeiro_bit == 0) && ( segundo_bit == 0) && (terceiro_bit == 1))
                    begin
                        head = 1;
                    end
                    else
                    begin
                        head = 0;
                    end					
                    if ((primeiro_bit == 0) && ( segundo_bit == 1) && (terceiro_bit == 0))
                    begin
                        barrier = 1;
                    end
					else if ((primeiro_bit == 0) && ( segundo_bit == 1) && (terceiro_bit == 1))
                    begin
                        barrier = 1;
                    end
                    else if ((primeiro_bit == 1) && ( segundo_bit == 0) && (terceiro_bit == 0))
                    begin
                        barrier = 1;
                    end
                    else
                    begin
                        barrier = 0;
                    end            
				end

				// definicao de left
				if (Linha_Robo == 1)
					left = 1;
				else
				begin
					Linha_Mapa = Mapa[Linha_Robo - 1];
					
					primeiro_bit = Linha_Mapa[Coluna_Robo - 1];
					segundo_bit = Linha_Mapa[Coluna_Robo];
					terceiro_bit = Linha_Mapa[Coluna_Robo + 1];
					
                    if ((primeiro_bit == 0) && ( segundo_bit == 0) && (terceiro_bit == 1))
                    begin
                        left = 1;
                    end
                    else
                    begin
                        left = 0;
                    end
				end

				// definicao do under
				Linha_Mapa = Mapa[Linha_Robo-1];

				primeiro_bit = Linha_Mapa[Coluna_Robo - 1];
				segundo_bit = Linha_Mapa[Coluna_Robo];
				terceiro_bit = Linha_Mapa[Coluna_Robo + 1];

				if ((primeiro_bit == 1) && ( segundo_bit == 1) && (terceiro_bit == 1))
                begin
					under = 1;
                end
				else
				begin
					under = 0;
				end
			end
		O:	begin
				// definicao de head
				if (Coluna_Robo == 1)
					begin
					head = 1;
					Linha_Mapa = Mapa[Linha_Robo];
					$display ("Linha = %b", Linha_Mapa);
					end
				else
				begin
					Linha_Mapa = Mapa[Linha_Robo];
					
					primeiro_bit = Linha_Mapa[Coluna_Robo - 4];
					segundo_bit = Linha_Mapa[Coluna_Robo - 3];
					terceiro_bit = Linha_Mapa[Coluna_Robo - 2];

					$display ("Linha = %b", Linha_Mapa);
					
                    if ((primeiro_bit == 0) && ( segundo_bit == 0) && (terceiro_bit == 1))
                    begin
                        head = 1;
                    end
                    else
                    begin
                        head = 0;
                    end

                    if ((primeiro_bit == 0) && ( segundo_bit == 1) && (terceiro_bit == 0))
                    begin
                        barrier = 1;
                    end
					else if ((primeiro_bit == 0) && ( segundo_bit == 1) && (terceiro_bit == 1))
                    begin
                        barrier = 1;
                    end
                    else if ((primeiro_bit == 1) && ( segundo_bit == 0) && (terceiro_bit == 0))
                    begin
                        barrier = 1;
                    end
                    else
                    begin
                        barrier = 0;
                    end             
				end

				// definicao de left
				if (Linha_Robo == 10)
					left = 1;
				else
				begin
					Linha_Mapa = Mapa[Linha_Robo + 1]; // Pega a linha que tá acima da cabeça do robo
					
					primeiro_bit = Linha_Mapa[Coluna_Robo - 1];
					segundo_bit = Linha_Mapa[Coluna_Robo];
					terceiro_bit = Linha_Mapa[Coluna_Robo + 1];
					
                    if ((primeiro_bit == 0) && ( segundo_bit == 0) && (terceiro_bit == 1))
                    begin
                        left = 1;
                    end
                    else
                    begin
                        left = 0;
                    end
				end

				// definicao do under
				Linha_Mapa = Mapa[Linha_Robo-1];

				primeiro_bit = Linha_Mapa[Coluna_Robo - 1];
				segundo_bit = Linha_Mapa[Coluna_Robo];
				terceiro_bit = Linha_Mapa[Coluna_Robo + 1];

				if ((primeiro_bit == 1) && ( segundo_bit == 1) && (terceiro_bit == 1))
                begin
					under = 1;
                end
				else
				begin
					under = 0;
				end
			end
	endcase
end
endtask

task Atualiza_Posicao_Robo;
begin
	case (Orientacao_Robo)
		N:	begin
				// definicao de orientacao / linha / coluna
				// Solucao alternativa: Ao inves de analisar a saida do robo, considerar a entrada pra dizer a posicao
				if (forward)
				begin
					Linha_Robo = Linha_Robo - 1;
				end
				else if (turn)
				begin
					Orientacao_Robo = O;
				end
				else if (remove)
				begin
					Muda_Codigo_Entulho(tamanho_lixo);
				end
			end
		S:	begin
				// definicao de orientacao / linha / coluna
				if (forward)
				begin
					Linha_Robo = Linha_Robo + 1;
				end
				else if (turn)
				begin
					Orientacao_Robo = L;
				end
				else if (remove)
				begin
					Muda_Codigo_Entulho(tamanho_lixo);
				end
			end
		L:	begin
				// definicao de orientacao / linha / coluna
				if (forward)
				begin
					Coluna_Robo = Coluna_Robo + 3;
				end
				else if (turn)
				begin
					Orientacao_Robo = N;
				end
				else if (remove)
				begin
					Orientacao_Robo = L;
				end
			end
		O:	begin
				// definicao de orientacao / linha / coluna
				if (forward)
				begin
					Coluna_Robo = Coluna_Robo - 3;
				end
				else if (turn)
				begin
					Orientacao_Robo = S;
				end
				else if (remove)
				begin
					Orientacao_Robo = O;
				end
			end
	endcase
end
endtask

task Muda_Codigo_Entulho (input integer tamanho_lixo);
begin
	
  case (Orientacao_Robo)
    N: begin
			// se entulho tamanho 2 -> 1
			if (tamanho_lixo == 2) begin 
				Linha_Mapa = Mapa[Linha_Robo - 1]; 					
						
				//primeiro_bit
				Linha_Mapa[Coluna_Robo - 1] = 0;
				//segundo_bit
				Linha_Mapa[Coluna_Robo] = 1;
				//terceiro_bit
				Linha_Mapa[Coluna_Robo + 1] = 0;

				Mapa[Linha_Robo - 1] = Linha_Mapa;

				barrier = 0;
			end
		
			// se entulho tamanho 1 -> 0
			if (tamanho_lixo == 1) begin
				Linha_Mapa = Mapa[Linha_Robo - 1];				
						
				//primeiro_bit
				Linha_Mapa[Coluna_Robo - 1] = 0;
				//segundo_bit
				Linha_Mapa[Coluna_Robo] = 0;
				//terceiro_bit
				Linha_Mapa[Coluna_Robo + 1] = 0;

				Mapa[Linha_Robo - 1] = Linha_Mapa;
			
				barrier = 0;
			end
		end
	S: begin

			// se entulho tamanho 3 -> 2
			if (tamanho_lixo == 3) begin 
				Linha_Mapa = Mapa[Linha_Robo + 1];
										
				//primeiro_bit 
				Linha_Mapa[Coluna_Robo - 1] = 0;
				//segundo bit
				Linha_Mapa[Coluna_Robo] = 1;
				//terceiro_bit
				Linha_Mapa[Coluna_Robo + 1 ] = 1;

				Mapa[Linha_Robo + 1] = Linha_Mapa;
				barrier = 0;
			end

			// se entulho tamanho 2 -> 1
			if (tamanho_lixo == 2) begin 
				Linha_Mapa = Mapa[Linha_Robo + 1];
										
				//primeiro_bit 
				Linha_Mapa[Coluna_Robo - 1] = 0;
				//segundo bit
				Linha_Mapa[Coluna_Robo] = 1;
				//terceiro_bit
				Linha_Mapa[Coluna_Robo + 1 ] = 0;

				Mapa[Linha_Robo + 1] = Linha_Mapa;

				barrier = 0;
			end
		
			// se entulho tamanho 1 -> 0
			if (tamanho_lixo == 1) begin
				Linha_Mapa = Mapa[Linha_Robo + 1];				
						
				//primeiro_bit
				Linha_Mapa[Coluna_Robo - 1] = 0;
				//segundo_bit
				Linha_Mapa[Coluna_Robo] = 0;
				//terceiro_bit
				Linha_Mapa[Coluna_Robo + 1] = 0;

				Mapa[Linha_Robo + 1] = Linha_Mapa;
			
				barrier = 0;
			end

		end
  endcase
end
endtask

endmodule


