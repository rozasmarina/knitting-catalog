class YarnParser
  YARDS_TO_METERS = 0.9144

  # Matches "100g", "100 grams", "100g/skein"
  GRAMS_PER_SKEIN = /(\d+)\s*g(?:rams?)?(?:\s*\/\s*(?:skein|ball|hank))?/i

  # Matches "200m", "200 meters", "200 metres" — (?!m) prevents matching "mm"
  METERS_PER_SKEIN = /(\d+)\s*m(?!m)\b(?:et(?:re|er)s?)?(?:\s*\/\s*(?:skein|ball|hank))?/i

  # Matches "218yd", "218 yards"
  YARDS_PER_SKEIN = /(\d+)\s*y(?:ar)?d?s?\b(?:\s*\/\s*(?:skein|ball|hank))?/i

  # Matches yarn name from common label patterns.
  # Note: "using" and bare "yarn" (without colon) are intentionally excluded — too many false positives.
  YARN_NAME = /
    (?:suggested\s+yarn|recommended\s+yarn|yarn)\s*[:\-]\s*([^\n\r,\.]{3,50})
    |
    (?:sample\s+(?:knitted|worked)\s+in|worked\s+in|knit(?:ted)?\s+in)\s*[:\-]?\s*([^\n\r,\.\[]{3,50})
    |
    \b(?:MC|CC)\s*[:\-]\s*([A-Z][^\n\r,\.\[]{2,50})
  /xi

  # Total grams: "approx. 450g total", "you'll need 450g", "400-500g"
  TOTAL_GRAMS = /(?:approx\.?\s*)?(\d+)\s*(?:-\s*\d+\s*)?g(?:rams?)?\s*(?:total|in total|of\s+yarn)?/i

  def self.parse(text)
    new(text).parse
  end

  def initialize(text)
    @text = text.to_s
  end

  def parse
    gramas_por_novelo  = extract_grams_per_skein
    metros_por_novelo  = extract_meters_per_skein
    gramas_totais      = extract_total_grams
    metragem_estimada  = estimate_yardage(gramas_totais, gramas_por_novelo, metros_por_novelo)

    {
      yarn_name:              extract_yarn_name,
      gramas_por_novelo:      gramas_por_novelo,
      metros_por_novelo:      metros_por_novelo,
      gramas_totais:          gramas_totais,
      metragem_total_estimada: metragem_estimada
    }
  end

  private

  def extract_yarn_name
    match = YARN_NAME.match(@text)
    return nil unless match
    (match[1] || match[2] || match[3])&.strip
  end

  def extract_grams_per_skein
    match = GRAMS_PER_SKEIN.match(@text)
    match ? match[1].to_i : nil
  end

  def extract_meters_per_skein
    # Prefer meters; fall back to yards converted
    m_match = METERS_PER_SKEIN.match(@text)
    return m_match[1].to_i if m_match

    yd_match = YARDS_PER_SKEIN.match(@text)
    yd_match ? (yd_match[1].to_f * YARDS_TO_METERS).round : nil
  end

  def extract_total_grams
    match = TOTAL_GRAMS.match(@text)
    match ? match[1].to_i : nil
  end

  def estimate_yardage(total_g, g_per_skein, m_per_skein)
    return nil if total_g.nil? || g_per_skein.nil? || m_per_skein.nil?
    return nil if g_per_skein.zero?

    ((total_g.to_f / g_per_skein) * m_per_skein).round
  end
end
