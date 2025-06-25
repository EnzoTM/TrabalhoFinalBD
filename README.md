# TrabalhoFinalBD

Este repositório contém o trabalho final da disciplina de Banco de Dados.

- **Diagrama ER**: [Google Drive](https://drive.google.com/file/d/1vUCdp6B-5I2eiRN8RoiN-oFA1N8Vyzxp/view?usp=sharing)

## Pré-requisitos

1. **Docker** e **Docker Compose** instalados na sua máquina.
2. **Python 3.9+** instalado.
3. **VS Code** (ou outro editor que suporte Jupyter).
4. Extensões recomendadas no VS Code:
   - Python (Microsoft)
   - Jupyter (Microsoft)

## Como configurar

1. Clone este repositório:

   ```bash
   git clone https://github.com/EnzoTM/TrabalhoFinalBD
   cd TrabalhoFinalBD
   ```

2. Crie e ative um ambiente virtual Python:

   ```bash
   python -m venv env
   # Windows (PowerShell)
   .\env\Scripts\Activate.ps1
   # Linux/macOS
   source env/bin/activate
   ```

3. Instale as dependências do projeto:

   ```bash
   pip install --upgrade pip
   pip install -r requirements.txt
   ```

4. Suba o container do PostgreSQL via Docker Compose:

   ```bash
   docker compose up -d
   ```

   Isso vai criar o serviço `db` (Postgres) na porta **5432** e a pasta `db_data`.

## Rodando o Trabalho Final

1. No VS Code, abra `trabalho_final_bd.ipynb` na pasta `notebooks`.

2. Selecione o **kernel** Python apontando para o ambiente `env`.
   
3. Rode cédula a cédula :)

