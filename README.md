# knitting-catalog

Personal knitting pattern library. Analyzes 550+ PDF patterns and generates a searchable CSV catalog with extracted metadata: yarn weight, gauge, needle size, construction method, techniques, and more.

## Requirements

- Ruby 3.x
- `tesseract` (OCR fallback for image-only PDFs)
- `poppler-utils` / `pdftoppm` (PDF rasterization for OCR)

Install system dependencies:

```bash
# macOS
brew install tesseract poppler

# Ubuntu/Debian
sudo apt-get install tesseract-ocr poppler-utils
```

Install Ruby gems:

```bash
# Use the rbenv Ruby 3.x (system Ruby on macOS is too old)
~/.rbenv/versions/3.3.8/bin/bundle install
```

> **Dica:** Para não precisar digitar o caminho completo toda vez, configure o rbenv no seu terminal:
> ```bash
> echo 'eval "$(~/.rbenv/bin/rbenv init - zsh)"' >> ~/.zshrc
> source ~/.zshrc
> ```
> After that, `bundle install` and `ruby` will use the correct version automatically.

## Usage

```bash
~/.rbenv/versions/3.3.8/bin/bundle exec ~/.rbenv/versions/3.3.8/bin/ruby cataloger.rb /path/to/patterns/
```

Or, after configuring rbenv in your shell (see above):

```bash
bundle exec ruby cataloger.rb /path/to/patterns/
```

Output: `catalogo_receitas.csv` (UTF-8 with BOM for Excel compatibility)

## Output Columns

See `specs/` for full field definitions. Key fields:

- **Identification**: file path, SHA256 hash, duplicate detection
- **Recipe**: designer, pattern name, garment type
- **Yarn**: weight (inferred from gauge + needle), yardage, grams
- **Construction**: top-down, raglan, seamless, etc.
- **Techniques**: lace, cables, colorwork, brioche, short rows
- **extraction_status**: `text` | `ocr` | `failed`

A second file `pdfs_com_falha.csv` is always generated listing any PDFs that could not be processed, for manual review.

## Project Structure

```
knitting-catalog/
├── cataloger.rb                  # Entry point
├── Gemfile
├── lib/
│   ├── pattern.rb                # Value object — all CSV fields
│   ├── filename_parser.rb        # Parses "Name - Designer.pdf" convention
│   ├── pdf_text_extractor.rb     # Text extraction via pdf-reader
│   ├── ocr_fallback.rb           # pdftoppm + tesseract for image-only PDFs
│   ├── gauge_parser.rb           # Extracts and normalizes gauge → sts/10cm
│   ├── needle_size_normalizer.rb # Prefers mm; converts US→mm as fallback
│   ├── yarn_weight_inferrer.rb   # CYC table: gauge + needle → yarn weight
│   ├── yarn_parser.rb            # Yarn name, g/skein, m/skein, total meterage
│   ├── technique_detector.rb     # Boolean flags: lace, cables, colorwork, etc.
│   ├── construction_detector.rb  # Boolean flags: top-down, raglan, seamless, etc.
│   ├── garment_classifier.rb     # Garment type from text + filename
│   ├── pattern_analyzer.rb       # Coordinates analysis of a single PDF
│   ├── duplicate_detector.rb     # SHA256 + fuzzy key duplicate detection
│   ├── search_text_builder.rb    # Builds normalized search_text field
│   ├── spreadsheet_exporter.rb   # Writes CSV (UTF-8 + BOM) + failure report
│   └── pattern_cataloger.rb      # Batch orchestration, parallelism, incremental runs
└── spec/                         # RSpec unit tests for all parsing classes
```

## Running Tests

```bash
bundle exec rspec
```

---

## Setup no Windows (para quem não é programadora)

Este guia é passo a passo. Você não precisa entender o que cada coisa faz — só seguir a ordem.

### Passo 1 — Instalar o WSL (Linux dentro do Windows)

O programa foi feito para rodar em Linux/macOS. No Windows, a forma mais fácil é usar o **WSL** (Windows Subsystem for Linux), que instala um Linux invisível dentro do seu Windows.

1. Clique na lupa de busca do Windows e procure por **"PowerShell"**
2. Clique com o botão direito em **Windows PowerShell** e escolha **"Executar como administrador"**
3. Cole o comando abaixo e pressione Enter:
   ```
   wsl --install
   ```
4. Quando terminar, **reinicie o computador**
5. Após reiniciar, uma janela preta vai abrir pedindo para criar um usuário Linux. Escolha um nome simples (sem espaços) e uma senha — anote em algum lugar!

> Se aparecer algum erro durante o `wsl --install`, visite: https://aka.ms/wsl2-install

---

### Passo 2 — Abrir o terminal Linux

1. Clique na lupa e procure por **"Ubuntu"**
2. Abra o aplicativo Ubuntu — será uma janela preta com texto verde/branco
3. É nessa janela que você vai digitar todos os comandos a seguir

---

### Passo 3 — Instalar Ruby, Tesseract e Poppler

Na janela do Ubuntu, cole cada bloco de comandos abaixo e pressione Enter. Espere terminar antes de passar para o próximo.

**Atualizar o sistema:**
```bash
sudo apt-get update && sudo apt-get upgrade -y
```
(vai pedir a senha que você criou no Passo 1)

**Instalar Ruby e dependências:**
```bash
sudo apt-get install -y ruby ruby-bundler build-essential
```

**Instalar as ferramentas de OCR** (necessárias para PDFs que são imagens):
```bash
sudo apt-get install -y tesseract-ocr poppler-utils
```

---

### Passo 4 — Baixar o programa

Ainda na janela do Ubuntu:

```bash
cd ~
git clone https://github.com/rozasmarina/knitting-catalog.git
cd knitting-catalog
bundle install
```

O `bundle install` vai instalar as bibliotecas Ruby do programa. Pode demorar alguns minutos.

---

### Passo 5 — Colocar seus PDFs em uma pasta acessível

No Windows, seus arquivos ficam em um caminho como `C:\Users\SeuNome\`. No WSL, essa pasta aparece como `/mnt/c/Users/SeuNome/`.

Por exemplo, se você tiver uma pasta `C:\Users\Marina\Receitas`, no terminal Ubuntu ela será:
```
/mnt/c/Users/Marina/Receitas
```

---

### Passo 6 — Rodar o programa

```bash
cd ~/knitting-catalog
bundle exec ruby cataloger.rb /mnt/c/Users/SeuNome/Receitas
```

Substitua `/mnt/c/Users/SeuNome/Receitas` pelo caminho real da sua pasta de PDFs.

O programa vai criar dois arquivos na pasta `knitting-catalog`:
- **`catalogo_receitas.csv`** — abre direto no Excel com todos os dados
- **`pdfs_com_falha.csv`** — lista de PDFs que precisam de revisão manual

---

### Abrir o CSV no Excel

1. Abra o **Explorador de Arquivos** do Windows
2. Na barra de endereço, cole: `\\wsl$\Ubuntu\home\SeuUsuario\knitting-catalog`
3. Você verá o arquivo `catalogo_receitas.csv` — clique duas vezes para abrir no Excel

> **Dica:** O arquivo já está no formato correto (UTF-8 com BOM) para o Excel não estragar os acentos.
