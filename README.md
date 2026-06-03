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
bundle install
```

## Usage

```bash
ruby cataloger.rb /path/to/patterns/
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
