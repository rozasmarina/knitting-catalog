# knitting-catalog — Claude Instructions

## Project Overview

Ruby tool that extracts metadata from 550+ knitting pattern PDFs and generates a searchable CSV catalog.

## Key Decisions (do not simplify)

1. **OCR fallback** — many PDFs are image-only; `tesseract` + `pdftoppm` are required for them.
2. **yarn_weight is inferred from gauge + needle size** (CYC table), not from keyword matching alone.
3. **Technique detection scans the full PDF**, not just the header pages.
4. **Needle size: prefer mm** from text; convert US→mm only as fallback.
5. **Filename parsing** (`Name - designer.pdf`) is the most reliable source for designer and pattern name.

## Architecture

Small, focused classes — no god objects:

- `PatternCataloger` — batch orchestration, parallelism, CSV writing
- `PatternAnalyzer` — coordinates analysis of a single PDF
- `Pattern` — value object with all fields
- `PdfTextExtractor` / `OcrFallback` — text extraction
- `GaugeParser`, `NeedleSizeNormalizer`, `YarnWeightInferrer`
- `YarnParser`, `TechniqueDetector`, `ConstructionDetector`
- `GarmentClassifier`, `FilenameParser`, `DuplicateDetector`
- `SearchTextBuilder`, `SpreadsheetExporter`

## Output

`catalogo_receitas.csv` — UTF-8 with BOM (Excel-compatible). Never abort the batch on a single file error; mark as `failed` and continue.

## SDD Workflow

This project uses Spec-Driven Development. See `sdd/` and `specs/` for workflow state and specifications.
