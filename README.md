# 1º Trabalho Prático da disciplina de Inteligência Artificia

**Professor: Edjard Mota**

**Integrantes**
  - Alexandre Antonaccio Senna
  - Fabricio Lessa Lorenzi Filho
  - Jurandy Alves Nogueira Junior
  - Tiago Rodrigues Bezerra

# Representação  do Conhecimento
**2.1. O Espaço e os Blocos**

A base de conhecimento modela o mundo como uma grade bidimensional de 6 colunas (X) por 4 linhas  (Y)
```bash
% Dimensões dos blocos
bloco(a, 1). bloco(b, 1). bloco(c, 2). bloco(d, 3).

% Validação do espaço (6x4)
posicao((X,Y)) :- between(1, 6, X), between(1, 4, Y).
```

**2.2. Estado do Mundo**

Ao invés de obrigar o utilizador a escrever cada espaço livre ou ocupado no estado inicial, o sistema deduz a topologia completa a partir da posição base do bloco:

* on(Bloco, (X, Y)): Indica que o bloco inicia na coordenada (X,Y) base esquerda.
* occupied((X, Y)): Predicado lógico que afirma que um espaço específico não pode ser transposto.
* clear((X, Y)): Predicado lógico que afirma que o espaço está vazio e disponível.

A função gerar_estado_completo/2 traduz uma simples lista de coordenadas (ex: [on(c, (1,1))]) em dezenas de factos occupied e clear.

**2.3. Leis da Física do Mundo dos Blocos**

Como os blocos têm larguras diferentes, eles ocupam múltiplas . Isso é gerido pelo predicado posicoes_bloco/3, que mapeia, que um bloco de tamanho 3 na posição (1,1) ocupará (1,1), (2,1) e (3,1), por exemplo.

**A Regra de Estabilidade (estavel_preconds/3)**

Para um bloco ser solto numa posição Y > 1, ele precisa de suporte (chão ou outro bloco). A estabilidade varia de acordo com o tamanho do bloco para simular o Centro de Gravidade:

* Tamanho 1: Exige 1 bloco exato diretamente abaixo.
* Tamanho 2: Exige apoio em ambas as bases (2 suportes), pois apoiar apenas uma extremidade causaria tombamento.
* Tamanho 3: Para evitar explosão combinatória na busca, simplificamos exigindo apenas apoio no centro geométrico do bloco.

# 3. Formalização STRIPS 

O núcleo da transição de estado é o predicado acao(Nome, Precondicoes, Adds, Dels). Ele define estritamente o que muda ao mover um bloco.

```bash
acao(mover(Bloco, Tam, (X1,Y1), (X2,Y2)), Preconds, Adds, Dels)
```

**1.Pré-condições (Preconds): O que deve ser verdade antes de executar a ação.**
* O bloco deve estar na posição (X1, Y1).
* Todos os espaços diretamente acima do bloco devem estar clear.
* Todas as posições de destino devem estar clear.
* O destino deve prover suporte válido (estavel_preconds).

**2.Lista de Adição (Adds): Fatos novos que passam a ser verdadeiros.**
* O bloco agora está on no destino.
* O destino torna-se occupied.
* A origem torna-se clear.

**3.Lista de Remoção (Dels): Fatos que deixam de ser verdadeiros.**
* O bloco não está mais on na origem.
* A origem não está mais occupied.
* O destino não está mais clear.

# 4. O Motor de Inferência (O Planejador)
Inicialmente, a abordagem de regressão de metas puras (planeamento de trás para frente) foi evitada. Coordenadas puramente numéricas e blocos de tamanho variável criam uma árvore de busca com ramos quase infinitos na regressão, causando travamentos.

Para resolver, aplicamos uma otimização massiva: Forward Search guiado por Iterative Deepening (Aprofundamento Iterativo).

**busca_adiante/4**

* **1.Iterative Deepening:** O predicado resolver/3 força o sistema a procurar primeiro por planos de 0 passos, depois 1 passo, até um máximo de 8. Isso garante que o plano encontrado seja sempre o caminho mais curto possível. 
* **Ancoragem de Origem:** Em vez de tentar "adivinhar" de onde um bloco veio, o sistema extrai as coordenadas reais do estado atual (member(on(Bloco, (X1, Y1)), Estado)). Isso elimina ramos inúteis da árvore de busca instantaneamente.
* **Transição Discreta:** Avalia se a ação é válida verificando o subconjunto de pré-condições. Se sim, calcula o novo estado subtraindo Dels e unindo Adds.
* **Prevenção de Loops:** Mantém uma lista de estados Visitados para garantir que o sistema não entre num ciclo infinito (ex: mover Bloco A para a direita, depois para a esquerda repetidamente).

# 5.Execução do Código

Para testar as situações requeridas pelo exercício, foram predefinidas as situações descritas na chamada do trabalho.

```bash
% Carregando o código
?- [mundo_blocos].

% Executando os testes conforme página 4 a 6 do PDF
?- teste_situacao1.
?- teste_situacao2.
?- teste_situacao3.
```
