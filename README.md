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

> **Tip:** To avoid typing the full path every time, add rbenv to your shell:
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
