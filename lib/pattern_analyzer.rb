require "digest"
require_relative "pattern"
require_relative "filename_parser"
require_relative "pdf_text_extractor"
require_relative "ocr_fallback"
require_relative "gauge_parser"
require_relative "needle_size_normalizer"
require_relative "yarn_weight_inferrer"
require_relative "yarn_parser"
require_relative "technique_detector"
require_relative "construction_detector"
require_relative "garment_classifier"
require_relative "search_text_builder"

class PatternAnalyzer
  HEADER_PAGES = (ENV["HEADER_PAGES"] || 5).to_i

  def self.analyze(path, base_dir: nil)
    new(path, base_dir: base_dir).analyze
  end

  def initialize(path, base_dir: nil)
    @path     = path
    @base_dir = base_dir || File.dirname(path)
  end

  def analyze
    sha256     = Digest::SHA256.file(@path).hexdigest
    filename   = File.basename(@path)
    pasta      = relative_folder

    extracted        = extract_text
    full_text        = extracted[:full_text]
    header_text      = extracted[:header_text]
    extraction_status = extracted[:status]

    filename_meta = FilenameParser.parse(filename)
    yarn_data     = YarnParser.parse(header_text)
    gauge_data    = GaugeParser.parse(header_text)
    needle_mm     = NeedleSizeNormalizer.normalize(header_text)
    yarn_weight   = YarnWeightInferrer.infer(
      gauge_sts_10cm: gauge_data[:gauge_sts_10cm],
      needle_mm:      needle_mm,
      text:           header_text
    )
    techniques    = TechniqueDetector.detect(full_text)
    construction  = ConstructionDetector.detect(full_text)
    garment       = GarmentClassifier.classify(header_text, filename)
    difficulty    = estimate_difficulty(techniques)

    pattern = Pattern.new(
      arquivo:             filename,
      caminho_completo:    @path,
      pasta:               pasta,
      hash_sha256:         sha256,
      possivel_duplicata:           false,
      possivel_duplicata_aproximada: false,
      caminho_atualizado:  false,
      extraction_status:   extraction_status.to_s,
      designer:            filename_meta[:designer],
      pattern_name:        filename_meta[:pattern_name],
      garment_type:        garment,
      yarn_name:           yarn_data[:yarn_name],
      yarn_weight:         yarn_weight,
      gramas_por_novelo:   yarn_data[:gramas_por_novelo],
      metros_por_novelo:   yarn_data[:metros_por_novelo],
      gramas_totais:       yarn_data[:gramas_totais],
      metragem_total_estimada: yarn_data[:metragem_total_estimada],
      gauge:               gauge_data[:gauge_raw],
      gauge_sts_10cm:      gauge_data[:gauge_sts_10cm],
      needle_size_mm:      needle_mm,
      **techniques,
      **construction,
      sizes:               extract_sizes(header_text),
      difficulty_estimate: difficulty,
      header_text:         header_text,
      search_text:         nil  # built after all fields populated
    )

    pattern.search_text = SearchTextBuilder.build(pattern)
    pattern
  end

  private

  def extract_text
    result = PdfTextExtractor.extract(@path, header_pages: HEADER_PAGES)

    if result[:status] == :empty
      ocr = OcrFallback.extract(@path, header_pages: HEADER_PAGES)
      case ocr[:status]
      when :ok         then ocr.merge(status: :ocr)
      when :unavailable then { status: :failed, full_text: "", header_text: "" }
      else              { status: :failed, full_text: "", header_text: "" }
      end
    elsif result[:status] == :error
      { status: :failed, full_text: "", header_text: "" }
    else
      result.merge(status: :text)
    end
  end

  def extract_sizes(text)
    match = text.match(/(?:sizes?\s*[:\-]?\s*)([XSML\d\s()\/,–\-]+)/i)
    match ? match[1].strip : nil
  end

  def estimate_difficulty(techniques)
    if techniques[:brioche] || techniques[:lace] || techniques[:colorwork]
      "advanced"
    elsif techniques[:texture] || techniques[:short_rows] || techniques[:cables]
      "intermediate"
    else
      "beginner"
    end
  end

  def relative_folder
    dir = File.dirname(@path)
    begin
      require "pathname"
      Pathname.new(dir).relative_path_from(Pathname.new(@base_dir)).to_s
    rescue
      dir
    end
  end
end
