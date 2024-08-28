`timescale 1ns/1ns

module Robo_TB;

parameter N = 2'b00, S = 2'b01, L = 2'b10, O = 2'b11;

reg clock, reset, head, left, under, barrier;
wire forward, turn, remove;

reg [0:59] Mapa [0:20]; // linha 0 reservada para posicao do robo e quantidade de movimentos
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
reg [0:2] tamanho_lixo;
reg [1:0] contador_remocao;

integer i;

Robo DUV (.clock(clock), .reset(reset), .head(head), .left(left), .under(under), .barrier(barrier), .forward(forward), .turn(turn), .remove(remove));

always
	#50 clock = !clock;


initial
begin
	clock = 0;
	reset = 1;
	head = 0;
	left = 0;
	under = 1;
	barrier = 0;
	contador_remocao = 3'b00;

	Mapa[0]  = 60'b000000000001010000000000000001000000000000000000000000011001;
    Mapa[1]  = 60'b001001001001001001001001001000000100000000000001001001001001;
    Mapa[2]  = 60'b001001001001001001001001001000001001001001000001001001001001;
    Mapa[3]  = 60'b001001001001001001001001001000001001001000001001001001001001;
    Mapa[4]  = 60'b001001001001001000001001001000000000000000001001001001001001;
    Mapa[5]  = 60'b001001001001001000000000000000001001001001001001001001001001;
    Mapa[6]  = 60'b001001001001001000001001001000001001001001001001000000000000;
    Mapa[7]  = 60'b001001001001001011001001001000001001001000000000000001001001;
    Mapa[8]  = 60'b000000000000000000001001001000000000000000001001001001001001;
    Mapa[9]  = 60'b000001001001001000000000001001001001001000001010000000011000;
    Mapa[10] = 60'b000001001001001001001100001001001001001000001001001000001001;
    Mapa[11] = 60'b111001001001001000000000000000000000001000000000000000001001;
	
	Linha_Mapa = Mapa[0];
	Linha_Robo = Linha_Mapa[0:14];
	Coluna_Robo = Linha_Mapa[15:29];
	Orientacao_Robo = Linha_Mapa[30:35];
	Qtd_Movimentos = 8'b11001000;
	$display ("Linha = %d Coluna = %d Orientacao = %s Movimentos = %d", Linha_Robo, Coluna_Robo, String_Orientacao_Robo, Qtd_Movimentos);

    // Mapa fica salvo no reg mapa, depois que remover alterar valor dele pode fazer uma funcao

	if (Situacoes_Anomalas(1)) $stop;
	
	
	#100 @ (negedge clock) reset = 0; //sincroniza com borda de descida
	#25 @ (posedge clock) under = 0; 
	

	for (i = 0; i < Qtd_Movimentos; i = i + 1)
	begin
		@ (negedge clock);
		Define_Sensores;
		$display ("H = %b L = %b U = %b B = %b", head, left, under, barrier);
		@ (negedge clock);
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

/*
function Muda_Codigo_Entulho (input linha, input bit_um, input bit_dois, input bit_tres);
begin
	if ((bit_um == 1) && ( bit_dois == 0) && (bit_tres == 0))
	begin
		// Mudar mapa Mapa[x][y] para prox codigo -> 011
	end
	else if ((bit_um == 0) && ( bit_dois == 1) && (bit_tres == 1))
	begin
		// Mudar mapa Mapa[x][y] para prox codigo -> 010
	end
	else if ((bit_um == 0) && ( bit_dois == 1) && (bit_tres == 0))
	begin
		// Mudar mapa Mapa[x][y] para prox codigo -> 000
	end
end
endfunction
*/

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
				if (Linha_Robo == 1) // Se igual a um quer dizer que ele t� no mais em cima poss�vel, por isso � 1 no head
					head = 1;
				else
				begin
					Linha_Mapa = Mapa[Linha_Robo - 1]; // Pega a linha que t� acima da cabe�a do robo					
					
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
						tamanho_lixo = 3'b010;
                        barrier = 1;
                    end
					else if ((primeiro_bit == 0) && ( segundo_bit == 1) && (terceiro_bit == 1))
                    begin
						tamanho_lixo = 3'b011;
                        barrier = 1;
                    end
                    else if ((primeiro_bit == 1) && ( segundo_bit == 0) && (terceiro_bit == 0))
                    begin
						tamanho_lixo = 3'b100;
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
					
					primeiro_bit = Linha_Mapa[Coluna_Robo - 3];
					segundo_bit = Linha_Mapa[Coluna_Robo - 2];
					terceiro_bit = Linha_Mapa[Coluna_Robo - 1];
					
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
				Linha_Atual = Mapa[Linha_Robo];

				primeiro_bit = Linha_Atual[Coluna_Robo - 1];
				segundo_bit = Linha_Atual[Coluna_Robo];
				terceiro_bit = Linha_Atual[Coluna_Robo + 1];

				if ((primeiro_bit == 1) && ( segundo_bit == 1) && (terceiro_bit == 1))
					under = 1;
				else
				begin
					under = 0;
				end

			end
		S:	begin
				// definicao de head
				if (Linha_Robo == 10)// Se igual a 10 quer dizer que ele t� no mais em baixo poss�vel, por isso � 1 no head
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
				Linha_Atual = Mapa[Linha_Robo];

				primeiro_bit = Linha_Atual[Coluna_Robo - 1];
				segundo_bit = Linha_Atual[Coluna_Robo];
				terceiro_bit = Linha_Atual[Coluna_Robo + 1];

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
				Linha_Atual = Mapa[Linha_Robo];

				primeiro_bit = Linha_Atual[Coluna_Robo - 1];
				segundo_bit = Linha_Atual[Coluna_Robo];
				terceiro_bit = Linha_Atual[Coluna_Robo + 1];

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
					Linha_Mapa = Mapa[Linha_Robo + 1]; // Pega a linha que t� acima da cabe�a do robo
					
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
				Linha_Atual = Mapa[Linha_Robo];

				primeiro_bit = Linha_Atual[Coluna_Robo - 1];
				segundo_bit = Linha_Atual[Coluna_Robo];
				terceiro_bit = Linha_Atual[Coluna_Robo + 1];

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
					Orientacao_Robo = S;
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



task Muda_Codigo_Entulho (input [0:2] tamanho_lixo);
begin
  case (contador_remocao)
    2'b00: begin
      // Primeiro ciclo de remoção
	  //NORTE
    	if (tamanho_lixo == 3'b011) // se entulho tamanho 2
    		//Mapa[Linha_Robo] = (primeiro_bit == 0) && ( segundo_bit == 1) && (terceiro_bit == 0); //Entulho 1
			Linha_Mapa = Mapa[Linha_Robo - 1]; // Pega a linha que t� acima da cabe�a do robo					
					
					//primeiro_bit
					Linha_Mapa[Coluna_Robo - 1] = 0;
					//segundo_bit
					Linha_Mapa[Coluna_Robo] = 1;
					//terceiro_bit
					Linha_Mapa[Coluna_Robo + 1] = 0;
			Mapa[Linha_Robo - 1] = Linha_Mapa;

        
      contador_remocao = 2'b01;
	  barrier = 0;
    end

    2'b01: begin
      // Segundo ciclo de remoção
     	if (tamanho_lixo == 3'b010)
      		//Mapa[Linha_Robo] = (primeiro_bit == 0) && ( segundo_bit == 0) && (terceiro_bit == 0); // Celula livre
			Linha_Mapa = Mapa[Linha_Robo - 1]; // Pega a linha que t� acima da cabe�a do robo					
					
					//primeiro_bit
					Linha_Mapa[Coluna_Robo - 1] = 0;
					//segundo_bit
					Linha_Mapa[Coluna_Robo] = 0;
					//terceiro_bit
					Linha_Mapa[Coluna_Robo + 1] = 0;
			Mapa[Linha_Robo - 1] = Linha_Mapa;
        
      contador_remocao = 2'b10;
	  barrier = 0;
    end
  endcase
end
endtask


endmodule




