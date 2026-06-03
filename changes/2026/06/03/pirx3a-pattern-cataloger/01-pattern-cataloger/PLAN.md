---
title: "Implementation Plan: Pattern Cataloger"
change: pattern-cataloger-1
type: feature
spec: ./SPEC.md
created: 2026-06-03
sdd_version: "7.3.0"
---

# Implementation Plan: Pattern Cataloger

## Overview

**Spec:** [SPEC.md](./SPEC.md)

Ruby CLI tool que extrai metadados de 550+ PDFs de receitas de tricô e gera um CSV pesquisável com suporte a runs incrementais e fallback OCR.

## Affected Components

- `lib/` — 15 classes Ruby (parsing, classificação, orquestração)
- `spec/` — testes unitários RSpec
- `cataloger.rb` — entry point CLI
- `Gemfile` — dependências

---

## Phases

### Phase 1: Project Setup + Core Models

**Outcome:** Estrutura de projeto configurada; `Pattern` value object e `FilenameParser` prontos e testáveis.

**Deliverables:**
- `Gemfile` com `pdf-reader`, `parallel`, `rspec`
- `lib/pattern.rb` — Struct/classe com todos os campos da spec
- `lib/filename_parser.rb` — parse de `Nome - designer.pdf`

**Files to Create:**
- `Gemfile`
- `Gemfile.lock`
- `lib/pattern.rb`
- `lib/filename_parser.rb`

**Estimated size:** ~5 files, ~150 lines

---

### Phase 2: Text Extraction

**Outcome:** `PdfTextExtractor` extrai texto de PDFs nativos; `OcrFallback` rasteriza e aplica OCR em PDFs image-only; `extraction_status` corretamente atribuído.

**Deliverables:**
- `lib/pdf_text_extractor.rb` — extração com `pdf-reader`; detecta texto vazio (< 50 chars)
- `lib/ocr_fallback.rb` — `pdftoppm` + `tesseract`; degrada com elegância se ausentes

**Files to Create:**
- `lib/pdf_text_extractor.rb`
- `lib/ocr_fallback.rb`

**Estimated size:** ~2 files, ~150 lines

---

### Phase 3: Metadata Parsers

**Outcome:** Gauge, agulha, yarn weight e fio extraídos e normalizados conforme SPEC.md.

**Deliverables:**
- `lib/gauge_parser.rb` — regex para variações de gauge; normaliza para sts/10cm
- `lib/needle_size_normalizer.rb` — prefere mm; converte US→mm via tabela
- `lib/yarn_weight_inferrer.rb` — tabela CYC; desempate por keyword
- `lib/yarn_parser.rb` — nome, gramas/novelo, metros/novelo, gramas totais, metragem estimada

**Files to Create:**
- `lib/gauge_parser.rb`
- `lib/needle_size_normalizer.rb`
- `lib/yarn_weight_inferrer.rb`
- `lib/yarn_parser.rb`

**Estimated size:** ~4 files, ~250 lines

---

### Phase 4: Classifiers

**Outcome:** Técnicas e construção detectadas no texto completo; tipo de peça classificado por texto + filename.

**Deliverables:**
- `lib/technique_detector.rb` — booleanos: lace, texture, cables, colorwork, brioche, short_rows
- `lib/construction_detector.rb` — booleanos: top_down, bottom_up, raglan, circular_yoke, set_in_sleeve, drop_shoulder, saddle_shoulder, seamless, seamed
- `lib/garment_classifier.rb` — sweater, cardigan, vest, shawl, hat, socks, dress, tee

**Files to Create:**
- `lib/technique_detector.rb`
- `lib/construction_detector.rb`
- `lib/garment_classifier.rb`

**Estimated size:** ~3 files, ~150 lines

---

### Phase 5: Orchestration + Output

**Outcome:** Pipeline completo funcionando end-to-end; CSV gerado com UTF-8 + BOM; runs incrementais operando; `pdfs_com_falha.csv` gerado.

**Deliverables:**
- `lib/pattern_analyzer.rb` — coordena análise de um PDF; monta `Pattern`
- `lib/duplicate_detector.rb` — SHA256 + chave fuzzy; marca duplicatas em batch
- `lib/search_text_builder.rb` — concatenação normalizada para `search_text`
- `lib/spreadsheet_exporter.rb` — CSV UTF-8 + BOM; `pdfs_com_falha.csv`
- `lib/pattern_cataloger.rb` — orquestração batch (glob recursivo, incremental, paralelo, escrita)
- `cataloger.rb` — entry point CLI (`ruby cataloger.rb /path/`)

**Files to Create:**
- `lib/pattern_analyzer.rb`
- `lib/duplicate_detector.rb`
- `lib/search_text_builder.rb`
- `lib/spreadsheet_exporter.rb`
- `lib/pattern_cataloger.rb`
- `cataloger.rb`

**Estimated size:** ~6 files, ~350 lines

---

### Phase 6: Unit Tests

**Outcome:** Cobertura unitária para todas as classes de parsing e classificação conforme SPEC.md § Testing Strategy.

**Deliverables:**
- `spec/gauge_parser_spec.rb`
- `spec/needle_size_normalizer_spec.rb`
- `spec/yarn_weight_inferrer_spec.rb`
- `spec/filename_parser_spec.rb`
- `spec/technique_detector_spec.rb`
- `spec/construction_detector_spec.rb`
- `spec/garment_classifier_spec.rb`
- `spec/duplicate_detector_spec.rb`
- `spec/search_text_builder_spec.rb`
- `.rspec`

**Files to Create:**
- `spec/` (9 arquivos de spec + `.rspec`)

**Estimated size:** ~10 files, ~400 lines

---

### Phase 7: Review

**Outcome:** Implementação verificada contra SPEC.md; todos os ACs validados; README atualizado se necessário.

**Checklist:**
- [ ] AC-01: Varredura completa de subpastas
- [ ] AC-02: Incremental — só novos/modificados processados
- [ ] AC-03: Arquivo movido — caminho atualizado + `caminho_atualizado = true`
- [ ] AC-04: OCR fallback para PDFs image-only
- [ ] AC-05: PDF corrompido não aborta batch; aparece em `pdfs_com_falha.csv`
- [ ] AC-06: Encoding correto no Excel (frações, acentos)
- [ ] AC-07: `yarn_weight` inferido corretamente pela tabela CYC
- [ ] AC-08: `pdfs_com_falha.csv` com 3 colunas corretas

---

## Dependencies

| Dependência | Versão | Obrigatório |
|-------------|--------|-------------|
| `pdf-reader` | ~> 2.0 | Sim |
| `parallel` | ~> 1.0 | Sim |
| `rspec` | ~> 3.0 | Dev |
| `tesseract` (sistema) | qualquer | Não (fallback gracioso) |
| `pdftoppm` / poppler (sistema) | qualquer | Não (fallback gracioso) |

---

## Tests

### Unit Tests
- [ ] `GaugeParser`: `28 sts x 40 rows = 10 x 10 cm` → `gauge_sts_10cm = 28`
- [ ] `GaugeParser`: `16 sts and 24 rows = 4 x 4"` → `gauge_sts_10cm = 16`
- [ ] `GaugeParser`: gauge ausente → `nil`
- [ ] `NeedleSizeNormalizer`: `3 mm [US2.5]` → `3.0`
- [ ] `NeedleSizeNormalizer`: `US 6` → `4.0`
- [ ] `NeedleSizeNormalizer`: `5 mm (US Size 8)` → `5.0`
- [ ] `YarnWeightInferrer`: sts=22 + mm=4.0 → `dk`
- [ ] `YarnWeightInferrer`: sts=29 + mm=2.75 → `fingering`
- [ ] `YarnWeightInferrer`: ambiguidade → desempate por keyword
- [ ] `FilenameParser`: `Socks - Designer.pdf` → `{ name: "Socks", designer: "Designer" }`
- [ ] `FilenameParser`: `pattern_001.pdf` → `{ name: nil, designer: nil }`
- [ ] `TechniqueDetector`: texto com "cable" → `cables: true`
- [ ] `TechniqueDetector`: texto sem técnicas → todos `false`
- [ ] `ConstructionDetector`: "top down" → `top_down: true`
- [ ] `ConstructionDetector`: "dropped shoulders" → `drop_shoulder: true`
- [ ] `GarmentClassifier`: "pullover" → `sweater`
- [ ] `GarmentClassifier`: "Anker Tee" → `tee`
- [ ] `DuplicateDetector`: 2 arquivos SHA256 igual → ambos `possivel_duplicata: true`
- [ ] `DuplicateDetector`: mesmo designer+nome paths diferentes → `possivel_duplicata_aproximada: true`
- [ ] `SearchTextBuilder`: campos populados → lowercase, espaços colapsados

---

## Risks

| Risco | Mitigação |
|-------|-----------|
| PDFs com gauge em formatos não cobertos pelos regex | Logar em `pdfs_com_falha.csv`; expandir regex na Phase 3 conforme testes com PDFs reais |
| Consumo alto de memória em OCR de PDFs grandes | Processar página por página; limpar arquivos temporários `.ppm` após cada página |
| `parallel` gem com PDFs que usam recursos compartilhados | Garantir que cada worker opera em estado isolado; sem escrita compartilhada durante processamento |

---

## Implementation State

**Current Phase:** pending

**Completed Phases:**
- [ ] Phase 1: Project Setup + Core Models
- [ ] Phase 2: Text Extraction
- [ ] Phase 3: Metadata Parsers
- [ ] Phase 4: Classifiers
- [ ] Phase 5: Orchestration + Output
- [ ] Phase 6: Unit Tests
- [ ] Phase 7: Review

**Actual Files Changed:** _(atualizado durante implementação)_

**Blockers:** nenhum
