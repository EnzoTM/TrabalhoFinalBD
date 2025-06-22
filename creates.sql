-- recria o schema limpo
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;

-- unidade escolar (campus)
CREATE TABLE UnidadeEscolar (
    codigo                varchar(50)  PRIMARY KEY,
    cidade                varchar(100) NOT NULL,
    estado                varchar(50)  NOT NULL,
    pais                  varchar(50)  NOT NULL,
    bloco                 varchar(50),      -- prédio / bloco
    Localidade_Especifica varchar(100)      -- ponto exato (opcional)
);

-- sala física
CREATE TABLE Sala (
    id_sala    serial  PRIMARY KEY,
    capacidade integer NOT NULL           -- assentos
);

-- regra acadêmica genérica (ex. frequência)
CREATE TABLE Regra (
    id_regra  serial PRIMARY KEY,
    descricao text   NOT NULL
);

-- recurso físico (lab, projetor, etc.)
CREATE TABLE Infraestrutura (
    id_infraestrutura serial PRIMARY KEY,
    nome              text   NOT NULL
);

-- turma de alunos (grupo lógico)
CREATE TABLE Turma (
    id_turma   serial  PRIMARY KEY,
    capacidade integer NOT NULL
);

-- bolsa de estudo
CREATE TABLE Bolsa (
    id_bolsa    serial        PRIMARY KEY,
    valor_bolsa numeric(10,2) NOT NULL,
    descricao   text,
    instituicao varchar(100)
);

-- desconto financeiro
CREATE TABLE Desconto (
    id_desconto serial        PRIMARY KEY,
    valor       numeric(10,2) NOT NULL,
    motivo      text
);

-- aluno (subtipo de usuário)
CREATE TABLE Aluno (
    nomeAluno        varchar(100),
    sobrenomeAluno   varchar(100),
    telefoneAluno    varchar(20),
    dataNasc         date,
    sexo             char(1),
    senha            varchar(100),
    email            varchar(100),
    codigoUnidadeEscolar varchar(50) NOT NULL,
    rua              varchar(100),
    cidade           varchar(100),
    estado           varchar(50),
    PRIMARY KEY (nomeAluno, sobrenomeAluno, telefoneAluno),
    FOREIGN KEY (codigoUnidadeEscolar) REFERENCES UnidadeEscolar(codigo)
);

-- professor (subtipo de usuário)
CREATE TABLE Professor (
    nomeProfessor        varchar(100),
    sobrenomeProfessor   varchar(100),
    telefoneProfessor    varchar(20),
    dataNasc             date,
    sexo                 char(1),
    senha                varchar(100),
    email                varchar(100),
    area_especializacao  varchar(100),
    titulacao            varchar(100),
    codigoUnidadeEscolar varchar(50) NOT NULL,
    rua                  varchar(100),
    cidade               varchar(100),
    estado               varchar(50),
    PRIMARY KEY (nomeProfessor, sobrenomeProfessor, telefoneProfessor),
    FOREIGN KEY (codigoUnidadeEscolar) REFERENCES UnidadeEscolar(codigo)
);

-- funcionário administrativo (subtipo de usuário)
CREATE TABLE FuncionarioAdministrativo (
    nomeFuncionario      varchar(100),
    sobrenomeFuncionario varchar(100),
    telefoneFuncionario  varchar(20),
    dataNasc             date,
    sexo                 char(1),
    senha                varchar(100),
    email                varchar(100),
    rua                  varchar(100),
    cidade               varchar(100),
    estado               varchar(50),
    PRIMARY KEY (nomeFuncionario, sobrenomeFuncionario, telefoneFuncionario)
);

-- departamento acadêmico
CREATE TABLE DepartamentoAcademico (
    codigo             varchar(50)  PRIMARY KEY,
    nome               varchar(100) NOT NULL,
    nomeProfessor      varchar(100) NOT NULL,   -- chefe
    sobrenomeProfessor varchar(100) NOT NULL,
    telefoneProfessor  varchar(20)  NOT NULL,
    FOREIGN KEY (nomeProfessor, sobrenomeProfessor, telefoneProfessor)
        REFERENCES Professor(nomeProfessor, sobrenomeProfessor, telefoneProfessor)
);

-- curso
CREATE TABLE Curso (
    codigo               varchar(50) PRIMARY KEY,
    nome                 varchar(100) NOT NULL,
    carga_horaria        integer,
    total_vagas          integer,
    nivel                varchar(50),           -- graduação, pós etc.
    id_sala              integer,               -- sala padrão
    codigoDepartamento   varchar(50),
    codigoUnidadeEscolar varchar(50),
    FOREIGN KEY (id_sala)            REFERENCES Sala(id_sala),
    FOREIGN KEY (codigoDepartamento) REFERENCES DepartamentoAcademico(codigo),
    FOREIGN KEY (codigoUnidadeEscolar) REFERENCES UnidadeEscolar(codigo)
);

-- disciplina
CREATE TABLE Disciplina (
    codigo               varchar(50) PRIMARY KEY,
    num_aulas_semanais   integer,
    material_recomendado text,
    codigoUnidadeEscolar varchar(50),
    nomeProfessor        varchar(100),
    sobrenomeProfessor   varchar(100),
    telefoneProfessor    varchar(20),
    FOREIGN KEY (codigoUnidadeEscolar) REFERENCES UnidadeEscolar(codigo),
    FOREIGN KEY (nomeProfessor, sobrenomeProfessor, telefoneProfessor)
        REFERENCES Professor(nomeProfessor, sobrenomeProfessor, telefoneProfessor)
);

-- mensagem interna
CREATE TABLE Mensagem (
    id_mensagem serial PRIMARY KEY,
    timestamp   timestamp NOT NULL,
    texto       text      NOT NULL,
    -- remetente (apenas um dos três grupos abaixo)
    nomeAluno        varchar(100),
    sobrenomeAluno   varchar(100),
    telefoneAluno    varchar(20),
    nomeProfessor      varchar(100),
    sobrenomeProfessor varchar(100),
    telefoneProfessor  varchar(20),
    nomeFuncionario      varchar(100),
    sobrenomeFuncionario varchar(100),
    telefoneFuncionario  varchar(20),
    FOREIGN KEY (nomeAluno, sobrenomeAluno, telefoneAluno)
        REFERENCES Aluno(nomeAluno, sobrenomeAluno, telefoneAluno),
    FOREIGN KEY (nomeProfessor, sobrenomeProfessor, telefoneProfessor)
        REFERENCES Professor(nomeProfessor, sobrenomeProfessor, telefoneProfessor),
    FOREIGN KEY (nomeFuncionario, sobrenomeFuncionario, telefoneFuncionario)
        REFERENCES FuncionarioAdministrativo(nomeFuncionario, sobrenomeFuncionario, telefoneFuncionario),
    CHECK ( ((nomeAluno IS NOT NULL)::int
           + (nomeProfessor IS NOT NULL)::int
           + (nomeFuncionario IS NOT NULL)::int) = 1 )
);

-- aviso geral (enviado por funcionário)
CREATE TABLE AvisoGeral (
    id_aviso       serial PRIMARY KEY,
    texto          text      NOT NULL,
    timestamp      timestamp NOT NULL,
    nomeFuncionario      varchar(100) NOT NULL,
    sobrenomeFuncionario varchar(100) NOT NULL,
    telefoneFuncionario  varchar(20)  NOT NULL,
    FOREIGN KEY (nomeFuncionario, sobrenomeFuncionario, telefoneFuncionario)
        REFERENCES FuncionarioAdministrativo(nomeFuncionario, sobrenomeFuncionario, telefoneFuncionario)
);

-- oferecimento (turma + disciplina + período)
CREATE TABLE Oferecimento (
    codigo_oferecimento serial PRIMARY KEY,
    codigo             varchar(50) NOT NULL,   -- disciplina
    id_turma           integer     NOT NULL,
    periodo            varchar(20),
    FOREIGN KEY (codigo)   REFERENCES Disciplina(codigo),
    FOREIGN KEY (id_turma) REFERENCES Turma(id_turma)
);

-- uso de sala por turma em horário específico
CREATE TABLE Ministra (
    id_sala     integer  NOT NULL,
    id_turma    integer  NOT NULL,
    dia         date     NOT NULL,
    hora_inicio time     NOT NULL,
    hora_fim    time     NOT NULL,
    PRIMARY KEY (id_sala, id_turma, dia, hora_inicio),
    FOREIGN KEY (id_sala)  REFERENCES Sala(id_sala),
    FOREIGN KEY (id_turma) REFERENCES Turma(id_turma)
);

-- matrícula do aluno em um oferecimento
CREATE TABLE Matricula (
    nomeAluno        varchar(100) NOT NULL,
    sobrenomeAluno   varchar(100) NOT NULL,
    telefoneAluno    varchar(20)  NOT NULL,
    codigo_oferecimento integer   NOT NULL,
    data             date         NOT NULL,
    status           varchar(20),
    data_limite      date,
    valor_matricula  numeric(10,2),
    PRIMARY KEY (nomeAluno, sobrenomeAluno, telefoneAluno,
                 codigo_oferecimento, data),
    FOREIGN KEY (nomeAluno, sobrenomeAluno, telefoneAluno)
        REFERENCES Aluno(nomeAluno, sobrenomeAluno, telefoneAluno),
    FOREIGN KEY (codigo_oferecimento) REFERENCES Oferecimento(codigo_oferecimento)
);

-- notas lançadas para matrícula
CREATE TABLE Notas (
    nomeAluno        varchar(100) NOT NULL,
    sobrenomeAluno   varchar(100) NOT NULL,
    telefoneAluno    varchar(20)  NOT NULL,
    codigo_oferecimento integer   NOT NULL,
    data             date         NOT NULL,
    nota             numeric(4,2) NOT NULL,
    PRIMARY KEY (nomeAluno, sobrenomeAluno, telefoneAluno,
                 codigo_oferecimento, data, nota),
    FOREIGN KEY (nomeAluno, sobrenomeAluno, telefoneAluno,
                 codigo_oferecimento, data)
        REFERENCES Matricula(nomeAluno, sobrenomeAluno, telefoneAluno,
                             codigo_oferecimento, data)
);

-- curso < - > regra (N:M)
CREATE TABLE ContemRegra (
    id_regra    integer     NOT NULL,
    codigoCurso varchar(50) NOT NULL,
    PRIMARY KEY (id_regra, codigoCurso),
    FOREIGN KEY (id_regra)    REFERENCES Regra(id_regra),
    FOREIGN KEY (codigoCurso) REFERENCES Curso(codigo)
);

-- curso < - > infraestrutura (N:M)
CREATE TABLE PrecisaInfraestrutura (
    id_infraestrutura integer     NOT NULL,
    codigoCurso       varchar(50) NOT NULL,
    PRIMARY KEY (id_infraestrutura, codigoCurso),
    FOREIGN KEY (id_infraestrutura) REFERENCES Infraestrutura(id_infraestrutura),
    FOREIGN KEY (codigoCurso)       REFERENCES Curso(codigo)
);

-- curso < - > disciplina (N:M)
CREATE TABLE CursoTemDisciplina (
    codigoCurso      varchar(50) NOT NULL,
    codigoDisciplina varchar(50) NOT NULL,
    PRIMARY KEY (codigoCurso, codigoDisciplina),
    FOREIGN KEY (codigoCurso)      REFERENCES Curso(codigo),
    FOREIGN KEY (codigoDisciplina) REFERENCES Disciplina(codigo)
);

-- pré-requisito entre cursos (auto N:M)
CREATE TABLE CursoPreRequisitoCurso (
    codigoCurso             varchar(50) NOT NULL,
    codigoCursoPreRequisito varchar(50) NOT NULL,
    PRIMARY KEY (codigoCurso, codigoCursoPreRequisito),
    FOREIGN KEY (codigoCurso)             REFERENCES Curso(codigo),
    FOREIGN KEY (codigoCursoPreRequisito) REFERENCES Curso(codigo)
);

-- disciplina pré-requisito de curso (N:M)
CREATE TABLE DisciplinaPreRequisitoCurso (
    codigoCurso      varchar(50) NOT NULL,
    codigoDisciplina varchar(50) NOT NULL,
    PRIMARY KEY (codigoCurso, codigoDisciplina),
    FOREIGN KEY (codigoCurso)      REFERENCES Curso(codigo),
    FOREIGN KEY (codigoDisciplina) REFERENCES Disciplina(codigo)
);

-- turma < - > aviso
CREATE TABLE TurmaRecebeAviso (
    id_turma integer NOT NULL,
    id_aviso integer NOT NULL,
    PRIMARY KEY (id_turma, id_aviso),
    FOREIGN KEY (id_turma) REFERENCES Turma(id_turma),
    FOREIGN KEY (id_aviso) REFERENCES AvisoGeral(id_aviso)
);

-- turma < - > mensagem
CREATE TABLE TurmaRecebeMensagem (
    id_turma    integer NOT NULL,
    id_mensagem integer NOT NULL,
    PRIMARY KEY (id_turma, id_mensagem),
    FOREIGN KEY (id_turma)    REFERENCES Turma(id_turma),
    FOREIGN KEY (id_mensagem) REFERENCES Mensagem(id_mensagem)
);

-- aluno < - > mensagem
CREATE TABLE AlunoRecebeMensagem (
    nomeAluno        varchar(100) NOT NULL,
    sobrenomeAluno   varchar(100) NOT NULL,
    telefoneAluno    varchar(20)  NOT NULL,
    id_mensagem      integer      NOT NULL,
    PRIMARY KEY (nomeAluno, sobrenomeAluno, telefoneAluno, id_mensagem),
    FOREIGN KEY (nomeAluno, sobrenomeAluno, telefoneAluno)
        REFERENCES Aluno(nomeAluno, sobrenomeAluno, telefoneAluno),
    FOREIGN KEY (id_mensagem) REFERENCES Mensagem(id_mensagem)
);

-- professor < - > mensagem
CREATE TABLE ProfessorRecebeMensagem (
    nomeProfessor      varchar(100) NOT NULL,
    sobrenomeProfessor varchar(100) NOT NULL,
    telefoneProfessor  varchar(20)  NOT NULL,
    id_mensagem        integer      NOT NULL,
    PRIMARY KEY (nomeProfessor, sobrenomeProfessor, telefoneProfessor, id_mensagem),
    FOREIGN KEY (nomeProfessor, sobrenomeProfessor, telefoneProfessor)
        REFERENCES Professor(nomeProfessor, sobrenomeProfessor, telefoneProfessor),
    FOREIGN KEY (id_mensagem) REFERENCES Mensagem(id_mensagem)
);

-- funcionário < - > mensagem
CREATE TABLE FuncionarioAdministrativoRecebeMensagem (
    nomeFuncionario      varchar(100) NOT NULL,
    sobrenomeFuncionario varchar(100) NOT NULL,
    telefoneFuncionario  varchar(20)  NOT NULL,
    id_mensagem          integer      NOT NULL,
    PRIMARY KEY (nomeFuncionario, sobrenomeFuncionario, telefoneFuncionario, id_mensagem),
    FOREIGN KEY (nomeFuncionario, sobrenomeFuncionario, telefoneFuncionario)
        REFERENCES FuncionarioAdministrativo(nomeFuncionario, sobrenomeFuncionario, telefoneFuncionario),
    FOREIGN KEY (id_mensagem) REFERENCES Mensagem(id_mensagem)
);

-- matrícula < - > bolsa
CREATE TABLE MatriculaTemBolsa (
    nomeAluno        varchar(100) NOT NULL,
    sobrenomeAluno   varchar(100) NOT NULL,
    telefoneAluno    varchar(20)  NOT NULL,
    codigo_oferecimento integer   NOT NULL,
    data             date         NOT NULL,
    id_bolsa         integer      NOT NULL,
    PRIMARY KEY (nomeAluno, sobrenomeAluno, telefoneAluno,
                 codigo_oferecimento, data, id_bolsa),
    FOREIGN KEY (nomeAluno, sobrenomeAluno, telefoneAluno,
                 codigo_oferecimento, data)
        REFERENCES Matricula(nomeAluno, sobrenomeAluno, telefoneAluno,
                             codigo_oferecimento, data),
    FOREIGN KEY (id_bolsa) REFERENCES Bolsa(id_bolsa)
);

-- matrícula < - > desconto
CREATE TABLE MatriculaTemDesconto (
    nomeAluno        varchar(100) NOT NULL,
    sobrenomeAluno   varchar(100) NOT NULL,
    telefoneAluno    varchar(20)  NOT NULL,
    codigo_oferecimento integer   NOT NULL,
    data             date         NOT NULL,
    id_desconto      integer      NOT NULL,
    PRIMARY KEY (nomeAluno, sobrenomeAluno, telefoneAluno,
                 codigo_oferecimento, data, id_desconto),
    FOREIGN KEY (nomeAluno, sobrenomeAluno, telefoneAluno,
                 codigo_oferecimento, data)
        REFERENCES Matricula(nomeAluno, sobrenomeAluno, telefoneAluno,
                             codigo_oferecimento, data),
    FOREIGN KEY (id_desconto) REFERENCES Desconto(id_desconto)
);

-- avaliação (aluno - professor ou oferta)
CREATE TABLE Avaliacao (
    id_avaliacao       serial PRIMARY KEY,
    texto              text NOT NULL,
    didatica           smallint,
    nomeAluno          varchar(100) NOT NULL,
    sobrenomeAluno     varchar(100) NOT NULL,
    telefoneAluno      varchar(20)  NOT NULL,
    nomeProfessor      varchar(100),
    sobrenomeProfessor varchar(100),
    telefoneProfessor  varchar(20),
    codigo_oferecimento integer,
    FOREIGN KEY (nomeAluno, sobrenomeAluno, telefoneAluno)
        REFERENCES Aluno(nomeAluno, sobrenomeAluno, telefoneAluno),
    FOREIGN KEY (nomeProfessor, sobrenomeProfessor, telefoneProfessor)
        REFERENCES Professor(nomeProfessor, sobrenomeProfessor, telefoneProfessor),
    FOREIGN KEY (codigo_oferecimento) REFERENCES Oferecimento(codigo_oferecimento),
    CHECK (
        ((nomeProfessor IS NOT NULL)::int
       + (codigo_oferecimento IS NOT NULL)::int) = 1
    )
);
