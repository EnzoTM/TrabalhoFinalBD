-- vai percorrer todas tabelas no schema public e as trunca, reiniciando as sequences de identidade e aplicando CASCADE para remover dependências
-- isso é itil pra resetar todo o banco antes de inserir dados de teste

DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (
        SELECT tablename
        FROM pg_tables
        WHERE schemaname = 'public'
    ) LOOP
        EXECUTE 'TRUNCATE TABLE public.' || quote_ident(r.tablename) || ' RESTART IDENTITY CASCADE;';
    END LOOP;
END $$;

--  gera 10 registros de UnidadeEscolar com código padronizado (ex: '01U', '02U', ...), 
-- e campos cidade, estado, pais, bloco e Localidade_Especifica pra permitir links de alunos, professores, cursos e disciplinas a unidades físicas
INSERT INTO UnidadeEscolar(codigo, cidade, estado, pais, bloco, Localidade_Especifica)
SELECT
  lpad(gs::text, 2, '0') || 'U',                               -- gera código sequencial 01U a 10U
  format('Cidade_%s', gs),                                     
  format('Estado_%s', gs),                                     
  format('Pais_%s', gs),                                       
  format('Bloco_%s', (gs % 3) + 1),                            -- distribui blocos cíclicos pra simular diferentes edifícios
  format('Local_%s', gs)                                       
FROM generate_series(1,10) AS gs;

-- gera 100 salas físicas de aula ou laboratório
INSERT INTO Sala(capacidade)
SELECT (floor(random()*100) + 20)::int                        -- random entre 20 e 119 para variar tamanhos de sala
FROM generate_series(1,100) AS gs;

-- cria regras acadêmicas genéricas (ex: frequencia minima, criterio de aprovacao), pra associar depois com os cursos
INSERT INTO Regra(descricao)
SELECT 'Regra ' || gs                                        
FROM generate_series(1,50) AS gs;

-- gera recursos de infra (ex: laboratorio, projetor) pra associar a cursos conforme a necessidade
INSERT INTO Infraestrutura(nome)
SELECT 'Infraestrutura ' || gs                               
FROM generate_series(1,50) AS gs;

-- gera turmas lógicas, cada uma com capacidade de alunos entre 10 e 59 pra ofertar disciplinas
-- A capacidade vai ser usada ao validar número de matrículas
INSERT INTO Turma(capacidade)
SELECT (floor(random()*50) + 10)::int                       
FROM generate_series(1,100) AS gs;

-- cria bolsas de estudo variadas, com valor aleatório até 5000 e descrição/instituicao para associação a matrículas
INSERT INTO Bolsa(valor_bolsa, descricao, instituicao)
SELECT
  (random()*5000)::numeric(10,2),                             
  'Bolsa ' || gs,                                             
  'Instituicao ' || gs                                       
FROM generate_series(1,100) AS gs;

--  descontos financeiros para aplicar em matrículas, com valor até 1000
INSERT INTO Desconto(valor, motivo)
SELECT
  (random()*1000)::numeric(10,2),                            
  'Desconto ' || gs                                          -- motivo/descritivo sequencial
FROM generate_series(1,100) AS gs;

-- cria 2000 alunos de teste com nome, sobrenome e telefone únicos baseados no índice
-- Usa datas de nascimento aleatórias a partir de 1990, gênero aleatório, senha/email gerados, e vincula cada aluno a uma UnidadeEscolar que exite (códigos 01U a 10U)
INSERT INTO Aluno(
    nomeAluno, sobrenomeAluno, telefoneAluno,
    dataNasc, sexo, senha, email,
    codigoUnidadeEscolar, rua, cidade, estado
)
SELECT
  'Nome'  || gs,                                             
  'SobNome' || gs,                                           
  lpad((floor(random()*99999999))::text, 8, '0'),            
  date '1990-01-01' + (floor(random()*10000))::int * interval '1 day',  -- data de nascimento aleatória para faixa etária de adulto jovem
  (array['M','F'])[floor(random()*2)+1],                     -- gênero aleatório
  'senha' || gs,                                             
  'aluno' || gs || '@exemplo.com',                            
  lpad((floor(random()*10)+1)::text, 2, '0') || 'U',         -- vincula a unidades 01U a 10U
  'Rua ' || gs,                                              
  'Cidade ' || gs,
  'Estado ' || gs
FROM generate_series(1,2000) AS gs;

--  gera 500 professores com dados de identificação únicos
INSERT INTO Professor(
  nomeProfessor, sobrenomeProfessor, telefoneProfessor,
  dataNasc, sexo, senha, email,
  area_especializacao, titulacao, codigoUnidadeEscolar,
  rua, cidade, estado
)
SELECT
  'Prof' || gs,                                            
  'SobProf' || gs,                                         
  lpad((floor(random()*99999999))::text, 8, '0'),           
  date '1970-01-01' + (floor(random()*15000))::int * interval '1 day',  -- data de nascimento variada para faixa etária adulta
  (array['M','F'])[floor(random()*2)+1],                    
  'senhaP' || gs,                                           
  'prof' || gs || '@exemplo.com',                          
  'Area ' || (floor(random()*10)+1),                        -- área de especialização aleatória entre 1 e 10
  'Tit'  || (floor(random()*5)+1),                          
  lpad((floor(random()*10)+1)::text, 2, '0') || 'U',        -- vincula a unidades 01U a 10U
  'RuaP '    || gs,                                         
  'CidadeP ' || gs,
  'EstadoP ' || gs
FROM generate_series(1,500) AS gs;

-- gera funcionários administrativos fictícios, sem vinculação a UnidadeEscolar, com dados de identificação e endereço para uso em avisos e mensagens
INSERT INTO FuncionarioAdministrativo(
    nomeFuncionario, sobrenomeFuncionario, telefoneFuncionario,
    dataNasc, sexo, senha, email,
    rua, cidade, estado
)
SELECT
    'Func' || gs,                                          
    'SobFunc' || gs,                                        
    lpad((floor(random()*99999999))::text, 8, '0'),         
    date '1975-01-01' + (floor(random()*12000))::int * interval '1 day',  
    (array['M','F'])[floor(random()*2)+1],                 
    'senhaF' || gs,                                        
    'func' || gs || '@exemplo.com',                        
    'RuaF ' || gs,                                          
    'CidadeF ' || gs,
    'EstadoF ' || gs
FROM generate_series(1,200) AS gs;

-- insere 100 departamentos acadêmicos, 
-- atribui como chefe um professor, ciclando pela lista de professores para balancear cargas
-- permite que cada departamento tenha um professor existente como chefe
WITH profs AS (
  SELECT 
    nomeProfessor, 
    sobrenomeProfessor, 
    telefoneProfessor,
    ROW_NUMBER() OVER (ORDER BY nomeProfessor, sobrenomeProfessor, telefoneProfessor) AS rn
  FROM Professor
),
cnt AS (
  SELECT COUNT(*) AS total FROM profs
)
INSERT INTO DepartamentoAcademico(
  codigo, nome,
  nomeProfessor, sobrenomeProfessor, telefoneProfessor
)
SELECT
  'D' || LPAD(gs::text, 3, '0'),                         
  'Departamento ' || gs,                                 
  p.nomeProfessor,                                       
  p.sobrenomeProfessor,
  p.telefoneProfessor
FROM generate_series(1,100) AS gs
CROSS JOIN cnt
JOIN profs p
  ON p.rn = ((gs - 1) % cnt.total) + 1;                   -- ciclo para distribuir chefias

-- gera cursos fictícios com código 'C001' a 'C500'
-- carga horária e vagas aleatórias, nível aleatório entre Grad, Pos e Extensão
-- Atribui id_sala aleatório (supõe que salas existam com ids compatíveis), departamento randômico e UnidadeEscolar aleatória entre códigos 01U a 10U
INSERT INTO Curso(
  codigo, nome, carga_horaria, total_vagas, nivel,
  id_sala, codigoDepartamento, codigoUnidadeEscolar
)
SELECT
  'C' || LPAD(gs::text,3,'0'),                            
  'Curso ' || gs,                                        
  (floor(random()*200)+20)::int,                          -- carga horária entre 20 e 219 horas
  (floor(random()*100)+10)::int,                          -- vagas entre 10 e 109
  (array['Grad','Pos','Ext'])[floor(random()*3)+1],       -- nível de ensino aleatório
  (floor(random()*100)+1)::int,                           -
  (SELECT codigo FROM DepartamentoAcademico ORDER BY random() LIMIT 1),  
  lpad((floor(random()*10)+1)::text, 2, '0') || 'U'       -- vincula UnidadeEscolar 01U a 10U aleatória
FROM generate_series(1,500) AS gs;

-- insere 500 disciplinas vinculadas a professor e unidade escolar
-- Usa CTEs para gerar slots e embaralhar professores para distribuir responsabilidades
WITH slots AS (
  SELECT
    p.nomeProfessor,
    p.sobrenomeProfessor,
    p.telefoneProfessor,
    generate_series(1, floor(random()*4 + 1)::int) AS slot
  FROM Professor p
),
mix AS (
  SELECT
    ROW_NUMBER() OVER (ORDER BY random()) AS rn,
    nomeProfessor, sobrenomeProfessor, telefoneProfessor
  FROM slots  -- multiplica possibilidade de atribuir múltiplas disciplinas por professor
),
disc AS (
  SELECT
    gs                           AS idx,
    'D' || LPAD(gs::text,3,'0')  AS codigo
  FROM generate_series(1,500) AS gs
)
INSERT INTO Disciplina(
  codigo, num_aulas_semanais, material_recomendado,
  codigoUnidadeEscolar,
  nomeProfessor, sobrenomeProfessor, telefoneProfessor
)
SELECT
  d.codigo,                                               
  (floor(random()*5)+1)::int,                              
  'Material ' || d.idx,                                    
  lpad((floor(random()*10)+1)::text,2,'0') || 'U',         -- UnidadeEscolar vinculada
  m.nomeProfessor, m.sobrenomeProfessor, m.telefoneProfessor  -- professor responsável aleatório
FROM disc d
JOIN mix  m ON m.rn = d.idx;                               -- associa cada disciplina a um professor embaralhado

-- insere 200 mensagens com remetente aleatório (aluno/professor/funcionário)
-- e usando LATERAL JOIN para obter um remetente válido (Aluno, Professor ou Funcionário) conforme o tipo
-- Timestamp aleatório dos últimos 30 dias e texto identificador
WITH tipo AS (
  SELECT
    gs,
    (array['aluno','professor','funcionario'])[floor(random()*3)+1] AS tipo
  FROM generate_series(1,200) AS gs
)
INSERT INTO Mensagem(
  timestamp, texto,
  nomeAluno, sobrenomeAluno, telefoneAluno,
  nomeProfessor, sobrenomeProfessor, telefoneProfessor,
  nomeFuncionario, sobrenomeFuncionario, telefoneFuncionario
)
SELECT
  now() - (floor(random()*30)::int || ' days')::interval,   -- timestamp aleatório nos últimos 30 dias
  'mensagem exemplo ' || t.gs,                             
  CASE WHEN t.tipo='aluno' THEN a.nomeAluno END,           -- preenche remetente conforme tipo
  CASE WHEN t.tipo='aluno' THEN a.sobrenomeAluno END,
  CASE WHEN t.tipo='aluno' THEN a.telefoneAluno END,
  CASE WHEN t.tipo='professor' THEN p.nomeProfessor END,
  CASE WHEN t.tipo='professor' THEN p.sobrenomeProfessor END,
  CASE WHEN t.tipo='professor' THEN p.telefoneProfessor END,
  CASE WHEN t.tipo='funcionario' THEN f.nomeFuncionario END,
  CASE WHEN t.tipo='funcionario' THEN f.sobrenomeFuncionario END,
  CASE WHEN t.tipo='funcionario' THEN f.telefoneFuncionario END
FROM tipo t
LEFT JOIN LATERAL (
  SELECT nomeAluno, sobrenomeAluno, telefoneAluno
  FROM Aluno ORDER BY random() LIMIT 1
) a ON t.tipo='aluno'                                       -- escolhe um aluno aleatório se tipo for aluno
LEFT JOIN LATERAL (
  SELECT nomeProfessor, sobrenomeProfessor, telefoneProfessor
  FROM Professor ORDER BY random() LIMIT 1
) p ON t.tipo='professor'                                  -- escolhe professor aleatório se tipo for professor
LEFT JOIN LATERAL (
  SELECT nomeFuncionario, sobrenomeFuncionario, telefoneFuncionario
  FROM FuncionarioAdministrativo ORDER BY random() LIMIT 1
) f ON t.tipo='funcionario';                               -- escolhe funcionário aleatório se tipo for funcionário

-- insere 200 avisos gerais enviados por funcionários administrativos
-- para disponibilizar avisos a turmas via tabela intermediária depois.
WITH func AS (
  SELECT
    ROW_NUMBER() OVER (ORDER BY nomeFuncionario, sobrenomeFuncionario, telefoneFuncionario) AS rn,
    nomeFuncionario,
    sobrenomeFuncionario,
    telefoneFuncionario
  FROM FuncionarioAdministrativo
),
cnt AS (
  SELECT COUNT(*) AS n FROM func
)
INSERT INTO AvisoGeral(texto, timestamp, nomeFuncionario, sobrenomeFuncionario, telefoneFuncionario)
SELECT
  'aviso geral ' || gs,                                     
  now() - (floor(random()*30)::int || ' days')::interval,   -- timestamp aleatório
  f.nomeFuncionario,                                        -- funcionário remetente cíclico
  f.sobrenomeFuncionario,
  f.telefoneFuncionario
FROM generate_series(1,200) AS gs
CROSS JOIN cnt
JOIN func AS f
  ON f.rn = ((gs - 1) % cnt.n) + 1;                         -- distribui avisos entre funcionários

-- insere 2000 oferecimentos (Disciplina < - > Turma) em períodos variados
-- permite depois criar matrículas nessa oferta específica.
INSERT INTO Oferecimento(codigo, id_turma, periodo)
SELECT
  d.codigo,                                               
  (floor(random()*100)+1)::int,                          
  (array['2025-1','2025-2','2026-1'])[floor(random()*3)+1] -- período simulado
FROM (
  SELECT codigo FROM Disciplina ORDER BY random() LIMIT 2000
) d;

-- insere 500 ministra (Sala < - > Turma < - > horário)
-- ON CONFLICT evita violar PK caso já exista
-- simula horários de uso de sala por turma
WITH raw AS (
  SELECT
    (floor(random()*100)+1)::int      AS id_sala,         
    (floor(random()*100)+1)::int      AS id_turma,       
    date '2025-01-01' + floor(random()*365)::int        AS dia,            -- data aleatória em 2025
    (time '08:00' + (floor(random()*8) || ' hours')::interval)::time  AS hora_inicio  -- hora aleatória entre 08:00 e 15:00
  FROM generate_series(1,600)
),
dedup AS (
  SELECT DISTINCT
    id_sala, id_turma, dia, hora_inicio,
    (hora_inicio + interval '50 minutes')::time AS hora_fim     -- duração fixa de 50 minutos para cada uso de sala
  FROM raw
)
INSERT INTO Ministra(id_sala, id_turma, dia, hora_inicio, hora_fim)
SELECT id_sala, id_turma, dia, hora_inicio, hora_fim
FROM dedup
LIMIT 500                                                  -- limita a 500 inserções para não exagerar
ON CONFLICT DO NOTHING;                                    -- evita erro se duplicar PK na tabela Ministra

-- insere matrículas (Aluno < - > Oferecimento)
INSERT INTO Matricula(
  nomeAluno, sobrenomeAluno, telefoneAluno,
  codigo_oferecimento, data, status, data_limite, valor_matricula
)
SELECT
  a.nomeAluno,
  a.sobrenomeAluno,
  a.telefoneAluno,
  o.codigo_oferecimento,
  DATE '2025-01-01' + floor(random()*180)::int,           
  (array['confirmada','pendente','cancelada'])[floor(random()*3)+1],  -- status aleatório
  DATE '2025-07-01' + floor(random()*30)::int,           
  (random()*1000)::numeric(10,2)                        
FROM Aluno a
CROSS JOIN Oferecimento o
ORDER BY random()
LIMIT 10000;                                              -- limita para não criar combinatória completa demasiado grande

-- insere notas (Notas de Matrícula)
-- simulando avaliações de alunos nos oferecimentos. ORDER BY random para diversificar a amostra.
INSERT INTO Notas(
  nomeAluno, sobrenomeAluno, telefoneAluno,
  codigo_oferecimento, data, nota
)
SELECT
  m.nomeAluno,
  m.sobrenomeAluno,
  m.telefoneAluno,
  m.codigo_oferecimento,
  m.data,
  (random()*9.99)::numeric(4,2)                           
FROM Matricula m
ORDER BY random()
LIMIT 10000;                                              -- limita quantidade de notas geradas

-- associa cursos e regras de forma randômica, até 1000 pares, usando CROSS JOIN e randomização, ON CONFLICT evita duplicatas
-- Simula políticas aplicáveis a cursos
INSERT INTO ContemRegra(id_regra, codigoCurso)
SELECT
  r.id_regra,
  c.codigo
FROM Regra r
CROSS JOIN Curso c
ORDER BY random()
LIMIT 1000
ON CONFLICT DO NOTHING;                                   -- evita duplicar mesmo par

-- PrecisaInfraestrutura (Curso < - > Infraestrutura)
-- obs: associa cursos e infraestruturas necessárias, até 1000 pares randômicos, evitando duplicatas. Simula necessidades físicas de cada curso.
INSERT INTO PrecisaInfraestrutura(id_infraestrutura, codigoCurso)
SELECT
  i.id_infraestrutura,
  c.codigo
FROM Infraestrutura i
CROSS JOIN Curso c
ORDER BY random()
LIMIT 1000
ON CONFLICT DO NOTHING;

-- CursoTemDisciplina (Curso < - > Disciplina)
-- ON CONFLICT evita duplicar vínculo.
INSERT INTO CursoTemDisciplina(codigoCurso, codigoDisciplina)
SELECT
  c.codigo,
  d.codigo
FROM Curso c
CROSS JOIN Disciplina d
ORDER BY random()
LIMIT 1000
ON CONFLICT DO NOTHING;

-- CursoPreRequisitoCurso (Curso < - > Outro Curso)
-- já que gera pré-requisitos entre cursos diferentes,  evitando auto-relacionamento e duplicatas
INSERT INTO CursoPreRequisitoCurso(codigoCurso, codigoCursoPreRequisito)
SELECT
  c1.codigo,
  c2.codigo
FROM Curso c1
JOIN Curso c2 ON c2.codigo <> c1.codigo                   -- evita pré-requisito de si mesmo
ORDER BY random()
LIMIT 500
ON CONFLICT DO NOTHING;

-- DisciplinaPreRequisitoCurso (Curso < - > Disciplina)
-- obs: associa disciplinas como pré-requisito para cursos, até 500 pares randômicos (simula requisitos de conhecimentos prévios)
INSERT INTO DisciplinaPreRequisitoCurso(codigoCurso, codigoDisciplina)
SELECT
  c.codigo,
  d.codigo
FROM Curso c
CROSS JOIN Disciplina d
ORDER BY random()
LIMIT 500
ON CONFLICT DO NOTHING;

-- TurmaRecebeAviso (Turma < - > AvisoGeral)
-- para cada turma, escolhe até 5 avisos aleatórios, deduplica pares e insere até 500 vínculos, simulando recebimento de avisos por diferentes turmas
-- ON CONFLICT evita duplicatas
WITH pares AS (
  SELECT t.id_turma, a.id_aviso
  FROM Turma t
  CROSS JOIN LATERAL (
    SELECT id_aviso FROM AvisoGeral ORDER BY random() LIMIT 5
  ) a
)
INSERT INTO TurmaRecebeAviso(id_turma, id_aviso)
SELECT id_turma, id_aviso
FROM (
  SELECT DISTINCT id_turma, id_aviso FROM pares
) AS dedup
ORDER BY random()
LIMIT 500
ON CONFLICT DO NOTHING;

-- TurmaRecebeMensagem (Turma < - > Mensagem)
-- associa turmas e mensagens, deduplicadas e limitadas a 500 vínculos
-- simulando a comunicação em grupo
WITH pares AS (
  SELECT t.id_turma, m.id_mensagem
  FROM Turma t
  CROSS JOIN LATERAL (
    SELECT id_mensagem FROM Mensagem ORDER BY random() LIMIT 5
  ) m
)
INSERT INTO TurmaRecebeMensagem(id_turma, id_mensagem)
SELECT id_turma, id_mensagem
FROM (
  SELECT DISTINCT id_turma, id_mensagem FROM pares
) AS dedup
ORDER BY random()
LIMIT 500
ON CONFLICT DO NOTHING;

-- AlunoRecebeMensagem (Aluno < - > Mensagem)
-- vincula cada aluno a até 2 mensagens aleatórias... simulando mensagens direcionadas a alunos
WITH pares AS (
  SELECT a.nomeAluno, a.sobrenomeAluno, a.telefoneAluno, m.id_mensagem
  FROM Aluno a
  CROSS JOIN LATERAL (
    SELECT id_mensagem FROM Mensagem ORDER BY random() LIMIT 2
  ) m
)
INSERT INTO AlunoRecebeMensagem(nomeAluno, sobrenomeAluno, telefoneAluno, id_mensagem)
SELECT nomeAluno, sobrenomeAluno, telefoneAluno, id_mensagem
FROM (
  SELECT DISTINCT nomeAluno, sobrenomeAluno, telefoneAluno, id_mensagem FROM pares
) AS dedup
ORDER BY random()
LIMIT 500
ON CONFLICT DO NOTHING;

-- ProfessorRecebeMensagem (Professor < - > Mensagem)
-- relacioan cada professor a até 2 mensagens aleatórias... simulando comunicação direcionada a professores.
WITH pares AS (
  SELECT p.nomeProfessor, p.sobrenomeProfessor, p.telefoneProfessor, m.id_mensagem
  FROM Professor p
  CROSS JOIN LATERAL (
    SELECT id_mensagem FROM Mensagem ORDER BY random() LIMIT 2
  ) m
)
INSERT INTO ProfessorRecebeMensagem(nomeProfessor, sobrenomeProfessor, telefoneProfessor, id_mensagem)
SELECT nomeProfessor, sobrenomeProfessor, telefoneProfessor, id_mensagem
FROM (
  SELECT DISTINCT nomeProfessor, sobrenomeProfessor, telefoneProfessor, id_mensagem FROM pares
) AS dedup
ORDER BY random()
LIMIT 500
ON CONFLICT DO NOTHING;

-- FuncionarioAdministrativoRecebeMensagem (FuncAdmin < - > Mensagem)
-- associa cada funcionário a até 3 mensagens aleatórias - simulando comunicação direcionada a funcionários administrativos
WITH pares AS (
  SELECT f.nomeFuncionario, f.sobrenomeFuncionario, f.telefoneFuncionario, m.id_mensagem
  FROM FuncionarioAdministrativo f
  CROSS JOIN LATERAL (
    SELECT id_mensagem FROM Mensagem ORDER BY random() LIMIT 3
  ) m
)
INSERT INTO FuncionarioAdministrativoRecebeMensagem(
  nomeFuncionario, sobrenomeFuncionario, telefoneFuncionario, id_mensagem
)
SELECT nomeFuncionario, sobrenomeFuncionario, telefoneFuncionario, id_mensagem
FROM (
  SELECT DISTINCT nomeFuncionario, sobrenomeFuncionario, telefoneFuncionario, id_mensagem FROM pares
) AS dedup
ORDER BY random()
LIMIT 500
ON CONFLICT DO NOTHING;

-- MatriculaTemBolsa (Matrícula < - > Bolsa)
-- distribui bolsas entre matrículas de forma ciclíca: ordena matrículas e bolsas
-- relaciona cada matrícula a uma bolsa baseada em ((rn -1) mod total) e depois randomiza ordem e limita a 1000 inserções
WITH mats AS (
  SELECT ROW_NUMBER() OVER (ORDER BY nomeAluno, sobrenomeAluno, telefoneAluno, codigo_oferecimento, data) AS rn, m.*
  FROM Matricula m
),
bols AS (
  SELECT ROW_NUMBER() OVER (ORDER BY id_bolsa) AS rn, b.id_bolsa
  FROM Bolsa b
),
cnt_b AS (
  SELECT COUNT(*) AS n FROM bols
)
INSERT INTO MatriculaTemBolsa(
  nomeAluno, sobrenomeAluno, telefoneAluno,
  codigo_oferecimento, data, id_bolsa
)
SELECT
  m.nomeAluno, m.sobrenomeAluno, m.telefoneAluno,
  m.codigo_oferecimento, m.data,
  b.id_bolsa
FROM mats m
CROSS JOIN cnt_b
JOIN bols b ON b.rn = ((m.rn - 1) % cnt_b.n) + 1       -- ciclo para distribuir bolsas entre matrículas
ORDER BY random()
LIMIT 1000
ON CONFLICT DO NOTHING;

-- MatriculaTemDesconto (Matrícula < - > Desconto)
-- análogo à distribuição de bolsas, associa descontos ciclicamente às matrículas, randomiza e limita a 1000
WITH mats AS (
  SELECT ROW_NUMBER() OVER (ORDER BY nomeAluno, sobrenomeAluno, telefoneAluno, codigo_oferecimento, data) AS rn, m.*
  FROM Matricula m
),
descs AS (
  SELECT ROW_NUMBER() OVER (ORDER BY id_desconto) AS rn, d.id_desconto
  FROM Desconto d
),
cnt_d AS (
  SELECT COUNT(*) AS n FROM descs
)
INSERT INTO MatriculaTemDesconto(
  nomeAluno, sobrenomeAluno, telefoneAluno,
  codigo_oferecimento, data, id_desconto
)
SELECT
  m.nomeAluno, m.sobrenomeAluno, m.telefoneAluno,
  m.codigo_oferecimento, m.data,
  d.id_desconto
FROM mats m
CROSS JOIN cnt_d
JOIN descs d ON d.rn = ((m.rn - 1) % cnt_d.n) + 1      -- ciclo para distribuir descontos
ORDER BY random()
LIMIT 1000
ON CONFLICT DO NOTHING;

-- Avaliação de professor com distribuição variada
-- Para cada professor, define qtd aleatória de avaliações entre 1 e 20, e para cada gera avaliação com texto e nota didática aleatória.
-- Escolhe aluno aleatório para cada avaliação
-- simula feedback de alunos sobre professores
WITH profs AS (
  SELECT 
    nomeProfessor,
    sobrenomeProfessor,
    telefoneProfessor,
    (floor(random()*20) + 1)::int AS qtd_avals          -- de 1 a 20 avaliações por professor
  FROM Professor
)
INSERT INTO Avaliacao(
  texto, didatica,
  nomeAluno, sobrenomeAluno, telefoneAluno,
  nomeProfessor, sobrenomeProfessor, telefoneProfessor
)
SELECT
  'avaliação prof ' || p.nomeProfessor || '_' || gs    AS texto,  -- texto contendo referência ao professor
  floor(random()*11)::smallint                          AS didatica, -- nota de 0 a 10
  a.nomeAluno,
  a.sobrenomeAluno,
  a.telefoneAluno,
  p.nomeProfessor,
  p.sobrenomeProfessor,
  p.telefoneProfessor
FROM profs p
JOIN generate_series(1, p.qtd_avals) AS gs ON true      -- gera múltiplas linhas conforme qtd_avals
CROSS JOIN LATERAL (
  SELECT nomeAluno, sobrenomeAluno, telefoneAluno
  FROM Aluno
  ORDER BY random()
  LIMIT 1
) a;                                                     -- escolhe aluno aleatório para cada avaliação

-- Avaliação de oferta com distribuição variada
-- para cada oferecimento, define qtd aleatória de 1 a 20 avaliações e cria registros com texto e didática aleatória, referenciando aluno aleatório
-- Simula feedback sobre disciplina/oferecimento.
WITH offers AS (
  SELECT 
    codigo_oferecimento,
    (floor(random()*20) + 1)::int AS qtd_avals         -- de 1 a 20 avaliações por oferta
  FROM Oferecimento
)
INSERT INTO Avaliacao(
  texto, didatica,
  nomeAluno, sobrenomeAluno, telefoneAluno,
  codigo_oferecimento
)
SELECT
  'avaliação ofer ' || o.codigo_oferecimento || '_' || gs   AS texto,  -- texto contendo referência ao oferecimento
  floor(random()*11)::smallint                                AS didatica,  -- nota de 0 a 10
  a.nomeAluno,
  a.sobrenomeAluno,
  a.telefoneAluno,
  o.codigo_oferecimento
FROM offers o
JOIN generate_series(1, o.qtd_avals) AS gs ON true           -- gera múltiplas linhas conforme qtd_avals
CROSS JOIN LATERAL (
  SELECT nomeAluno, sobrenomeAluno, telefoneAluno
  FROM Aluno
  ORDER BY random()
  LIMIT 1
) a;                                                            -- aluno aleatório para cada avaliação