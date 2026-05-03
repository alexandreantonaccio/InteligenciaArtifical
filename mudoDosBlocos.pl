:- use_module(library(lists)).

% ==========================================
% DEFINIÇÃO DOS BLOCOS E GRELHA
% ==========================================
bloco(a, 1).
bloco(b, 1).
bloco(c, 2).
bloco(d, 3).

% Grelha 6x4 (Largura x Altura)
posicao((X,Y)) :- between(1, 6, X), between(1, 4, Y).

% ==========================================
% FÍSICA DOS BLOCOS E CENTRO DE GRAVIDADE
% ==========================================
% Calcula as posições ocupadas por um bloco a partir da sua base esquerda (X,Y)
posicoes_bloco((X,Y), 1, [(X,Y)]).
posicoes_bloco((X,Y), 2, [(X,Y), (X1,Y)]) :- X1 is X + 1.
posicoes_bloco((X,Y), 3, [(X,Y), (X1,Y), (X2,Y)]) :- X1 is X + 1, X2 is X + 2.

% Verifica quais células estão imediatamente acima do bloco
acima_bloco((X,Y), Tam, Acima) :-
    Y1 is Y + 1,
    posicoes_bloco((X,Y1), Tam, Acima).

% LÓGICA DE ESTABILIDADE SIMPLIFICADA (Sem gravidade complexa)
% Define as exigências de suporte (occupied) abaixo da posição (X,Y) para manter a estabilidade.

% Tamanho 1: Exige apoio directo abaixo.
estavel_preconds((_,1), 1, []) :- !. % Chão não precisa de apoio
estavel_preconds((X,Y), 1, [occupied((X,Y0))]) :- Y0 is Y - 1, Y0 > 0.

% Tamanho 2: Exige apoio em ambas as bases.
estavel_preconds((_,1), 2, []) :- !. 
estavel_preconds((X,Y), 2, [occupied((X,Y0)), occupied((X1,Y0))]) :-
    Y0 is Y - 1, Y0 > 0, X1 is X + 1.

% Tamanho 3: Simplificado - Exige apenas um ponto de apoio (Centro) para evitar ramificação excessiva.
estavel_preconds((_,1), 3, []) :- !. 
estavel_preconds((X,Y), 3, [occupied((X1,Y0))]) :-
    Y0 is Y - 1, Y0 > 0, X1 is X + 1.

% ==========================================
% ACÇÕES (Mapeamento STRIPS)
% ==========================================
% acao(Nome, Precondicoes, ListaAdicao, ListaRemocao)

acao(mover(Bloco, Tam, (X1,Y1), (X2,Y2)), Preconds, Adds, Dels) :-
    bloco(Bloco, Tam),
    posicao((X1,Y1)), posicao((X2,Y2)), 
    (X1,Y1) \= (X2,Y2), % Não mover para o mesmo sítio
    
    posicoes_bloco((X1,Y1), Tam, PosAtuais),
    posicoes_bloco((X2,Y2), Tam, PosNovas),
    
    % --- PRÉ-CONDIÇÕES ---
    % 1. O bloco tem de estar na origem
    PrecondOn = [on(Bloco, (X1,Y1))],
    % 2. O espaço acima do bloco deve estar livre (clear)
    acima_bloco((X1,Y1), Tam, AcimaAtual),
    maplist(wrap_clear, AcimaAtual, PrecondsAcima),
    % 3. As posições de destino devem estar livres
    maplist(wrap_clear, PosNovas, PrecondsNovas),
    % 4. O bloco deve ficar estável no destino (verificação do centro de gravidade)
    estavel_preconds((X2,Y2), Tam, PrecondsEstavel),
    
    append([PrecondOn, PrecondsAcima, PrecondsNovas, PrecondsEstavel], PrecondsBrutas),
    list_to_set(PrecondsBrutas, Preconds), % Remove duplicados
    
    % --- LISTA DE ADIÇÃO (ADDS) ---
    maplist(wrap_occupied, PosNovas, AddsOccupied),
    maplist(wrap_clear, PosAtuais, AddsClear),
    append([[on(Bloco, (X2,Y2))], AddsOccupied, AddsClear], AddsBrutos),
    
    % --- LISTA DE REMOÇÃO (DELS) ---
    maplist(wrap_occupied, PosAtuais, DelsOccupied),
    maplist(wrap_clear, PosNovas, DelsClear),
    append([[on(Bloco, (X1,Y1))], DelsOccupied, DelsClear], DelsBrutos),
    
    % Limpar sobreposições lógicas (se movemos o bloco 1 casa para o lado, algumas coisas não mudam)
    subtract(AddsBrutos, DelsBrutos, Adds),
    subtract(DelsBrutos, AddsBrutos, Dels).

% Wrappers auxiliares
wrap_clear(Pos, clear(Pos)).
wrap_occupied(Pos, occupied(Pos)).


% ==========================================
% MOTOR STRIPS (ADAPTADO PARA FORWARD SEARCH)
% ==========================================

% Resolve o problema usando Aprofundamento Iterativo (Iterative Deepening) para encontrar o plano mais curto.
resolver(ListaOnInicial, Metas, Plano) :-
    gerar_estado_completo(ListaOnInicial, EstadoIni),
    format('A procurar plano...~n', []),
    % Limite maximo de profundidade (0 a 8 movimentos)
    between(0, 8, Limite),
    length(Plano, Limite), 
    busca_adiante(EstadoIni, Metas, Plano, [EstadoIni]),
    !. % Para no primeiro plano ótimo encontrado (evita continuar buscando atoa)

% Caso Base: Todas as metas foram atingidas no estado atual.
busca_adiante(Estado, Metas, [], _) :-
    satisfeito_todas(Metas, Estado).

% Passo de Busca Adiante
busca_adiante(Estado, Metas, [Acao|RestoPlano], Visitados) :-
    % OTIMIZAÇÃO CRUCIAL: Apenas tenta mover blocos a partir de onde eles *realmente* % estão no estado atual. Isso destrói a explosão combinatória.
    member(on(Bloco, (X1, Y1)), Estado),
    bloco(Bloco, Tam),
    posicao((X2, Y2)),
    Acao = mover(Bloco, Tam, (X1,Y1), (X2,Y2)),
    
    % Gera os requisitos STRIPS da ação selecionada
    acao(Acao, Preconds, Adds, Dels),
    
    % Verifica se a ação é legal no estado atual
    satisfeito_todas(Preconds, Estado),
    
    % Aplica a transição de estado
    aplicar_acao(Estado, Adds, Dels, NovoEstado),
    
    % Prevenção de loops infinitos (Sussman Anomaly)
    \+ member(NovoEstado, Visitados),
    
    % Continua a busca para os próximos passos
    busca_adiante(NovoEstado, Metas, RestoPlano, [NovoEstado|Visitados]).

% Verifica se todas as metas/condições estão satisfeitas
satisfeito_todas([], _).
satisfeito_todas([M|Ms], Estado) :-
    member(M, Estado),
    satisfeito_todas(Ms, Estado).

% Transição de Estado STRIPS: E = (E - Dels) U Adds
aplicar_acao(Estado, Adds, Dels, NovoEstado) :-
    subtract(Estado, Dels, E1),
    union(Adds, E1, NovoEstado).


% ==========================================
% HELPERS PARA GERAÇÃO DE ESTADOS
% ==========================================
% Cria a matriz completa de fluents (clear e occupied) automaticamente para não ter de escrevê-los a mao.
gerar_estado_completo(ListaOn, EstadoCompleto) :-
    findall(occupied((X,Y)), 
            (member(on(B, (Px, Py)), ListaOn), 
             bloco(B, Tam), 
             posicoes_bloco((Px,Py), Tam, Pos), 
             member((X,Y), Pos)), 
            OccupiedBruto),
    list_to_set(OccupiedBruto, Occupied),
    findall(clear((X,Y)), 
            (posicao((X,Y)), \+ member(occupied((X,Y)), Occupied)), 
            Clear),
    append([ListaOn, Occupied, Clear], EstadoCompleto).


% ==========================================
% CENÁRIOS E TESTES (Baseados no PDF)
% ==========================================

% SITUAÇÃO 1: Ir de S0 para Sf3
sit1_s0([on(c, (1,1)), on(a, (4,1)), on(b, (6,1)), on(d, (4,2))]).
sit1_sf3([on(c, (1,1)), on(a, (3,1)), on(d, (1,2)), on(b, (6,1))]). % d sobre c e a

teste_situacao1 :-
    sit1_s0(S0), sit1_sf3(Meta),
    resolver(S0, Meta, Plano),
    format('Plano Situacao 1: ~w~n', [Plano]).

% SITUAÇÃO 2: Ir de S0 para S5
sit2_s0([on(c, (1,1)), on(a, (1,2)), on(b, (2,2)), on(d, (4,1))]).
sit2_s5([on(c, (1,1)), on(a, (1,2)), on(b, (2,2)), on(d, (3,1))]).

teste_situacao2 :-
    sit2_s0(S0), sit2_s5(Meta),
    resolver(S0, Meta, Plano),
    format('Plano Situacao 2: ~w~n', [Plano]).

% SITUAÇÃO 3: Ir de S0 para S7
sit3_s0([on(c, (1,1)), on(a, (4,1)), on(b, (6,1)), on(d, (4,2))]).
sit3_s7([on(c, (1,1)), on(a, (1,2)), on(b, (2,2)), on(d, (4,1))]).

teste_situacao3 :-
    sit3_s0(S0), sit3_s7(Meta),
    resolver(S0, Meta, Plano),
    format('Plano Situacao 3: ~w~n', [Plano]).