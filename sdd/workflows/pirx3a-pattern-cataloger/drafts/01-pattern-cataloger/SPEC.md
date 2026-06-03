---
title: Pattern Cataloger
change_id: pattern-cataloger-1
type: feature
status: ready_for_review
created_at: "2026-06-03"
workflow_id: pirx3a
---

# Pattern Cataloger

## Overview

### Background

Uma biblioteca pessoal com 550+ receitas de tricô em PDF não tem forma de busca ou filtro. Encontrar um padrão específico exige abrir manualmente dezenas de arquivos. O objetivo é extrair metadados automaticamente de todos os PDFs e gerar um catálogo pesquisável que permita no futuro recomendações do tipo "suéter DK com textura" ou "tenho 1200m de fio fingering".

### Current State

Nenhum catálogo existe. Os PDFs estão organizados em pastas, com convenção de nome `Nome - designer.pdf` em muitos (mas não todos) os casos. Alguns PDFs têm camada de texto nativa; outros são compostos de imagens JPG escaneadas sem texto extraível.

---

## User Stories

1. Como usuária, quero rodar um script apontando para a pasta de receitas e obter um CSV com metadados de todos os PDFs, para que eu possa buscar e filtrar receitas sem abrir arquivo por arquivo.
2. Como usuária, quero que o script pule arquivos já processados em runs subsequentes, para que re-execuções sejam rápidas.
3. Como usuária, quero um relatório de PDFs que falharam na extração, para que eu possa preencher os dados manualmente.

---

## Functional Requirements

### FR-01: Varredura recursiva de PDFs
Percorrer recursivamente o diretório de entrada e processar todos os arquivos `.pdf` encontrados, independentemente de quantos níveis de subpastas existam.

### FR-02: Extração de texto com fallback OCR
Para cada PDF:
1. Tentar extração de texto via `pdf-reader`
2. Se o texto extraído tiver menos de 50 caracteres (após strip), o PDF é considerado image-only
3. Rasterizar páginas necessárias com `pdftoppm` a ~150 DPI
4. Aplicar OCR com `tesseract`
5. Registrar `extraction_status`: `text` | `ocr` | `failed`

Se `tesseract` ou `pdftoppm` não estiverem instalados, degradar com elegância: `extraction_status = failed`, preencher só colunas de identificação, continuar o batch.

### FR-03: Orçamentos de página separados
- **Cabeçalho:** primeiras `HEADER_PAGES` páginas (constante, default 5) → metadados (designer, nome, fio, gauge, agulha, tamanhos)
- **Varredura de técnica:** texto completo (`TECHNIQUE_SCAN_PAGES`, default = todas) → técnicas detectadas no corpo das instruções

### FR-04: Parsing de filename
Tentar extrair designer e nome do padrão `Nome - designer.pdf`. Se o arquivo não seguir a convenção, usar texto do PDF como fallback. Registrar a fonte (`filename` ou `text`) no campo correspondente.

### FR-05: Inferência de yarn_weight
Método primário: mapear `gauge_sts_10cm` + `needle_size_mm` para a tabela CYC (ver Tabela 1). Keyword como desempate/reforço. Campo vazio se gauge/agulha não extraídos.

### FR-06: Normalização de agulha
Preferir valor em mm presente no texto (`3 mm [US2.5]`, `5 mm (US Size 8)`). Converter US→mm via tabela de referência somente quando mm não estiver disponível.

### FR-07: Normalização de gauge
Cobrir variações: `28 sts x 40 rows = 10 x 10 cm`, `16 sts and 24 rows = 4 x 4"`. Normalizar para pontos por 10 cm (4" = 10,16 cm ≈ 10 cm).

### FR-08: Detecção de técnicas e construção
Booleanos detectados por palavras-chave no texto completo (FR-03).

### FR-09: Metragem estimada
Calcular `metragem_total_estimada = (gramas_totais / gramas_por_novelo) * metros_por_novelo` quando os três campos existirem. Converter yardas para metros (1 yd = 0,9144 m) antes do cálculo.

### FR-10: Detecção de duplicatas
- `possivel_duplicata`: SHA256 idêntico entre dois ou mais arquivos
- `possivel_duplicata_aproximada`: chave fuzzy normalizada (`designer` + `pattern_name`, lowercase, sem pontuação) coincide entre arquivos diferentes

### FR-11: Runs incrementais
Ao encontrar um CSV existente, ler e indexar entradas por SHA256. Arquivos com SHA256 inalterado são reutilizados sem reprocessamento. Se o SHA256 bater mas o caminho for diferente, atualizar `caminho_completo` e sinalizar `caminho_atualizado = true`.

### FR-12: Relatório de falhas
Ao final do batch, gerar `pdfs_com_falha.csv` com colunas: `arquivo`, `caminho_completo`, `erro`. Inclui PDFs com `extraction_status = failed` e PDFs que lançaram exceção durante o processamento.

### FR-13: Encoding UTF-8 com BOM
Gravar `catalogo_receitas.csv` com BOM UTF-8 para compatibilidade com Excel. Frações (¾, ½), graus (°) e aspas tipográficas devem ser preservados.

### FR-14: Processamento paralelo
Processar PDFs em paralelo usando a gem `parallel`. Workers = `[Parallel.processor_count, 8].min`. Resultados escritos no CSV de forma thread-safe (coleta de resultados após processamento paralelo).

---

## Non-Functional Requirements

| Categoria | Requisito |
|-----------|-----------|
| Performance | Sem SLA; roda em background |
| Memória | Compatível com MacBook Air (8 GB RAM); processar um PDF por vez por worker, liberar memória após cada arquivo |
| Confiabilidade | Um arquivo corrompido não aborta o batch; todos os erros são capturados e registrados |
| Portabilidade | macOS (primário); Linux compatível desde que tesseract/poppler instalados |
| Manutenibilidade | Classes pequenas e coesas; sem arquivo único maior que ~200 linhas |

---

## Technical Design

### Arquitetura de Classes

```
PatternCataloger          Orquestra o batch (recursão, paralelismo, escrita CSV)
PatternAnalyzer           Coordena análise de um único PDF, monta Pattern
Pattern                   Value object com todos os campos (Struct ou classe)
PdfTextExtractor          Extrai texto; detecta texto vazio (< 50 chars)
OcrFallback               Rasteriza com pdftoppm + OCR com tesseract
GaugeParser               Extrai e normaliza gauge → sts/10cm
NeedleSizeNormalizer      mm preferencial; conversão US→mm como fallback
YarnWeightInferrer        gauge + agulha → peso (tabela CYC)
YarnParser                Nome do fio, gramas/metros por novelo, metragem total
TechniqueDetector         Booleanos de técnica (texto completo)
ConstructionDetector      Booleanos de construção
GarmentClassifier         Tipo de peça (texto + filename)
FilenameParser            Designer/nome a partir de "Nome - designer.pdf"
DuplicateDetector         SHA256 + chave fuzzy
SearchTextBuilder         Monta search_text normalizado
SpreadsheetExporter       Escreve CSV UTF-8 + BOM; gera pdfs_com_falha.csv
```

### Fluxo de Dados

```
PatternCataloger
  ├── Glob recursivo → lista de arquivos .pdf
  ├── Carrega CSV existente → índice SHA256 → campanhas incrementais
  ├── Parallel.map(arquivos) → PatternAnalyzer.analyze(path)
  │     ├── FilenameParser.parse(filename)
  │     ├── PdfTextExtractor.extract(path)
  │     │     └── se vazio → OcrFallback.extract(path)
  │     ├── GaugeParser.parse(text)
  │     ├── NeedleSizeNormalizer.normalize(text)
  │     ├── YarnWeightInferrer.infer(gauge_sts, needle_mm, keywords)
  │     ├── YarnParser.parse(text)
  │     ├── TechniqueDetector.detect(full_text)
  │     ├── ConstructionDetector.detect(full_text)
  │     ├── GarmentClassifier.classify(text, filename)
  │     ├── SearchTextBuilder.build(pattern)
  │     └── → Pattern
  ├── DuplicateDetector.mark!(patterns)
  └── SpreadsheetExporter.write(patterns, failures)
```

### Tabela 1 — Inferência de yarn_weight (CYC)

| Peso | sts/10cm | agulha (mm) |
|------|----------|-------------|
| lace | 32–34+ | 1,5–2,25 |
| fingering | 27–32 | 2,25–3,25 |
| sport | 23–26 | 3,25–3,75 |
| dk | 21–24 | 3,75–4,5 |
| worsted | 16–20 | 4,5–5,5 |
| aran | 16–18 | 5,0–6,0 |
| bulky | 12–15 | 5,5–8,0 |
| super bulky | 7–11 | 8,0+ |

Quando gauge e agulha se contradizem (faixas sobrepostas), usar keyword como desempate; sem keyword, preferir o valor da agulha.

### Colunas do CSV

#### Identificação
| Coluna | Descrição |
|--------|-----------|
| `arquivo` | Nome do arquivo |
| `caminho_completo` | Caminho absoluto |
| `pasta` | Subpasta relativa ao diretório de entrada |
| `hash_sha256` | SHA256 do arquivo |
| `possivel_duplicata` | Idêntico por SHA256 |
| `possivel_duplicata_aproximada` | Mesmo padrão por chave fuzzy |
| `caminho_atualizado` | true se SHA256 bateu mas caminho mudou |
| `extraction_status` | `text` \| `ocr` \| `failed` |

#### Receita
| Coluna | Descrição |
|--------|-----------|
| `designer` | Fonte: filename ou text |
| `pattern_name` | Fonte: filename ou text |
| `garment_type` | sweater, cardigan, vest, shawl, hat, socks, dress, tee |

#### Fio
| Coluna | Descrição |
|--------|-----------|
| `yarn_name` | Nome do fio |
| `yarn_weight` | Inferido por gauge+agulha |
| `gramas_por_novelo` | |
| `metros_por_novelo` | Convertido de yd se necessário |
| `gramas_totais` | Menor tamanho disponível |
| `metragem_total_estimada` | Calculado quando os três campos existem |
| `gauge` | Texto bruto |
| `gauge_sts_10cm` | Normalizado |
| `needle_size_mm` | Preferindo mm; convertido de US como fallback |

#### Construção (booleanos)
`top_down`, `bottom_up`, `raglan`, `circular_yoke`, `set_in_sleeve`, `drop_shoulder`, `saddle_shoulder`, `seamless`, `seamed`

#### Técnicas (booleanos)
`lace`, `texture`, `cables`, `colorwork`, `brioche`, `short_rows`

#### Outros
| Coluna | Descrição |
|--------|-----------|
| `sizes` | Linha bruta de tamanhos |
| `difficulty_estimate` | beginner / intermediate / advanced |
| `header_text` | Texto das primeiras HEADER_PAGES páginas |
| `search_text` | Concatenação normalizada para busca futura |

---

## Error Handling

| Cenário | Comportamento |
|---------|---------------|
| PDF corrompido / exceção | Rescue por arquivo; adicionar a `pdfs_com_falha.csv`; continuar |
| PDF image-only sem tesseract | `extraction_status = failed`; preencher só identificação |
| Gauge ilegível | Colunas de gauge/peso vazias; resto preenchido normalmente |
| Yardas sem metros_por_novelo | `metragem_total_estimada` vazio; conversão não acontece |
| Arquivo sem convenção de nome | Fallback para texto; campo `designer`/`pattern_name` vazio se texto também falhar |

---

## Acceptance Criteria

**AC-01 — Varredura completa**
- Dado um diretório com PDFs em subpastas
- Quando o script é executado
- Então o CSV contém uma linha para cada arquivo `.pdf` encontrado recursivamente

**AC-02 — Incremental**
- Dado um CSV existente e uma pasta onde 10 de 100 PDFs foram adicionados
- Quando o script é re-executado
- Então apenas os 10 novos arquivos são processados; os 90 existentes são copiados do CSV anterior

**AC-03 — Arquivo movido**
- Dado um CSV existente onde um PDF tinha `caminho_completo = /a/x.pdf`
- Quando o mesmo arquivo (SHA256 idêntico) está agora em `/b/x.pdf`
- Então a entrada é atualizada com o novo caminho e `caminho_atualizado = true`

**AC-04 — OCR fallback**
- Dado um PDF image-only (< 50 chars de texto)
- Quando tesseract está instalado
- Então `extraction_status = ocr` e os campos de metadados são preenchidos com o resultado do OCR

**AC-05 — Falha sem abort**
- Dado um PDF corrompido na pasta
- Quando o script é executado
- Então o PDF aparece em `pdfs_com_falha.csv` com a mensagem de erro; o resto do batch completa normalmente

**AC-06 — Encoding**
- Dado o CSV gerado
- Quando aberto no Excel em macOS
- Então frações (¾), graus (°) e acentos aparecem corretamente

**AC-07 — yarn_weight por gauge**
- Dado um padrão com `gauge_sts_10cm = 22` e `needle_size_mm = 4.0`
- Quando inferido pela tabela CYC
- Então `yarn_weight = dk`

**AC-08 — Relatório de falhas**
- Dado um batch com 3 PDFs corrompidos
- Quando o script completa
- Então `pdfs_com_falha.csv` contém exatamente 3 linhas com `arquivo`, `caminho_completo`, `erro`

---

## Domain Model

### Entidades

| Entidade | Definição |
|----------|-----------|
| Pattern | Representação de uma receita de tricô com todos os metadados extraídos |
| PDF | Arquivo fonte; pode ter texto nativo ou ser image-only |
| ExtractionResult | Resultado da extração de texto (status + conteúdo) |
| GaugeReading | Gauge bruto + valor normalizado em sts/10cm |

### Glossário

| Termo | Definição |
|-------|-----------|
| gauge | Tensão do tricô: pontos e carreiras por 10cm em meia/stockinette |
| yarn weight | Categoria de espessura do fio (lace → super bulky) |
| header pages | Primeiras N páginas do PDF; contêm metadados da receita |
| extraction_status | Indicador de como o texto foi obtido: `text`, `ocr`, `failed` |
| possivel_duplicata | Arquivo byte-idêntico a outro (SHA256 igual) |
| possivel_duplicata_aproximada | Mesmo padrão com nome/designer normalizados iguais |
| CYC | Craft Yarn Council — tabela padrão de pesos de fio |
| BOM | Byte Order Mark UTF-8 — necessário para Excel não corromper acentos |

---

## Specs Directory Changes

### Antes
```
specs/
└── INDEX.md
```

### Depois
```
specs/
├── INDEX.md
└── changes/
    └── (gerado pelo workflow)
```

### Changes Summary

| Path | Ação | Descrição |
|------|------|-----------|
| `specs/INDEX.md` | Atualizar | Adicionar entrada para pattern-cataloger-1 |

---

## Components

Nenhum componente SDD (tech pack TypeScript não aplicável). A implementação usa estrutura Ruby direta conforme a arquitetura acima.

> New components will be scaffolded during implementation.

---

## System Analysis

### Requisitos Inferidos

- O campo `search_text` deve ser construído somente após todos os outros campos estarem populados
- `DuplicateDetector` precisa ver todos os patterns ao mesmo tempo (não pode rodar por arquivo individualmente)
- A escrita do CSV precisa ser feita após o processamento paralelo completar (não durante)
- O CSV de falhas deve ser gerado mesmo quando não há falhas (arquivo vazio com header)

### Gaps & Assumptions

| # | Assunção |
|---|----------|
| A1 | Limiar OCR = 50 chars após strip |
| A2 | Workers = `[Parallel.processor_count, 8].min` |
| A3 | Arquivos sem extensão `.pdf` são ignorados silenciosamente |
| A4 | `FilenameParser`: fallback para texto do PDF; vazio se ambos falham |
| A5 | `metros_por_novelo` em jardas é convertido antes de armazenar |
| A6 | `gramas_totais` captura o menor tamanho disponível na receita |
| A7 | `pdfs_com_falha.csv` é sempre gerado (com ou sem falhas) |

---

## Requirements Discovery

### Solicitation Phase

| # | Pergunta | Resposta | Fonte |
|---|----------|----------|-------|
| S1 | O problema/contexto está correto? | Correto; detalhe: alguns PDFs são JPGs com texto, sem camada de texto nativa | Usuário |
| S2 | Os requisitos funcionais extraídos estão completos? | Sim, com adição de suporte a runs incrementais | Usuário |
| S3 | O CSV sobrescreve ou suporta runs incrementais? | Suportar runs incrementais: reutilizar entradas com SHA256 inalterado | Usuário |
| S4 | Outros argumentos CLI além do diretório? | Não; apenas `ruby cataloger.rb /path/` | Usuário |
| S5 | Expectativa de performance? | Sem SLA; roda em background | Usuário |
| S6 | Limiar OCR para texto "quase vazio"? | < 50 chars após strip (confirmado) | Usuário |
| S7 | Número de workers paralelos? | `Parallel.processor_count` com cap configurável (aceita sugestão) | Usuário |
| S8 | Restrição de memória? | Compatível com MacBook Air; sem restrição específica | Usuário |
| S9 | Edge cases adicionais além dos listados? | Nenhum adicional | Usuário |
| S10 | `caxlsx` incluído? Saída xlsx? | Não; saída exclusivamente CSV | Usuário |
| S11 | SHA256 igual mas caminho diferente (arquivo movido)? | Atualizar caminho e sinalizar (`caminho_atualizado = true`) | Usuário |
| S12 | Arquivo sem convenção de nome? | Fallback para texto; vazio se ambos falham | Inferido do briefing |
| S13 | Tipo de testes? | Unitários para classes de parsing | Usuário |
| S14 | Registrar PDFs com falha? | Sim; gerar `pdfs_com_falha.csv` para input manual posterior | Usuário |

### Open Questions

Nenhuma questão em aberto.

---

## Testing Strategy

### Unitários

| Classe | Cenários |
|--------|---------|
| `GaugeParser` | `28 sts x 40 rows = 10 x 10 cm`; `16 sts and 24 rows = 4 x 4"`; gauge ausente; gauge em polegadas |
| `NeedleSizeNormalizer` | `3 mm [US2.5]` → 3.0; `US 6` → 4.0; `5 mm (US Size 8)` → 5.0; formato desconhecido |
| `YarnWeightInferrer` | sts=22 + mm=4.0 → dk; sts=29 + mm=2.75 → fingering; ambiguidade → desempate por keyword |
| `FilenameParser` | `Socks - Designer.pdf` → correto; `pattern_001.pdf` → nil; `Nome - Designer Duplo.pdf` → correto |
| `TechniqueDetector` | texto com "cable" → cables=true; "brioche" → brioche=true; texto sem técnicas → todos false |
| `ConstructionDetector` | "top down" → top_down=true; "raglan" → raglan=true; "dropped shoulders" → drop_shoulder=true |
| `GarmentClassifier` | "pullover" → sweater; "Anker Tee" → tee; "beanie" → hat; desconhecido → nil |
| `DuplicateDetector` | 2 arquivos SHA256 igual → ambos marcados; mesmo designer+nome paths diferentes → fuzzy match |
| `SearchTextBuilder` | campos populados → concatenação lowercase sem espaços extras |

### Dados de Teste

- Mínimo 3 PDFs de amostra: (1) com texto nativo, (2) image-only, (3) corrompido
- Fixtures de texto para cada parser (strings hardcoded nos testes)

---

## Dependencies

### Externas
| Dependência | Tipo | Obrigatório |
|-------------|------|-------------|
| `pdf-reader` | Gem | Sim |
| `parallel` | Gem | Sim |
| `csv` | Gem (stdlib) | Sim |
| `digest` | Gem (stdlib) | Sim |
| `tesseract` | Binário do sistema | Não (fallback gracioso) |
| `pdftoppm` (poppler-utils) | Binário do sistema | Não (fallback gracioso) |

---

## Out of Scope

- Interface web ou desktop
- Embeddings / busca semântica (Fase 2)
- Cruzamento com stash de fios (Fase 2)
- Recomendações automáticas (Fase 2)
- Saída XLSX
- Suporte nativo a Windows (sem WSL)
- Download automático de PDFs

---

## Open Questions

Nenhuma.

---

## References

- Briefing original do projeto (fornecido pelo usuário em 2026-06-03)
- [Craft Yarn Council — Standard Yarn Weight System](https://www.craftyarncouncil.com/standards/yarn-weight-system)
- [pdf-reader gem](https://github.com/yob/pdf-reader)
- [parallel gem](https://github.com/grosser/parallel)
