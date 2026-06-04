Pattern = Struct.new(
  # Identification
  :arquivo,
  :caminho_completo,
  :pasta,
  :hash_sha256,
  :possivel_duplicata,
  :possivel_duplicata_aproximada,
  :caminho_atualizado,
  :extraction_status,

  # Recipe
  :designer,
  :pattern_name,
  :garment_type,

  # Yarn
  :yarn_name,
  :yarn_weight,
  :gramas_por_novelo,
  :metros_por_novelo,
  :gramas_totais,
  :metragem_total_estimada,
  :gauge,
  :gauge_sts_10cm,
  :needle_size_mm,

  # Construction (booleans)
  :top_down,
  :bottom_up,
  :raglan,
  :circular_yoke,
  :set_in_sleeve,
  :drop_shoulder,
  :saddle_shoulder,
  :seamless,
  :seamed,

  # Techniques (booleans)
  :lace,
  :texture,
  :cables,
  :colorwork,
  :brioche,
  :short_rows,
  :held_double,

  # Other
  :sizes,
  :difficulty_estimate,
  :header_text,
  :search_text,

  keyword_init: true
) do
  def self.csv_headers
    members.map(&:to_s)
  end

  def to_csv_row
    members.map { |field| self[field] }
  end

  def fuzzy_key
    return nil if designer.nil? && pattern_name.nil?
    "#{normalize(designer)}|#{normalize(pattern_name)}"
  end

  private

  def normalize(str)
    return "" if str.nil?
    str.downcase
       .gsub(/\s*\(\d+\)\s*/, " ")  # strip "(1)", "(2)" suffixes
       .gsub(/[^a-z0-9]/, "")
  end
end
