class GaugeParser
  # Matches patterns like:
  #   28 sts x 40 rows = 10 x 10 cm
  #   16 sts and 24 rows = 4 x 4"
  #   22 sts x 30 rows over 10cm
  #   20 stitches = 4 inches
  GAUGE_PATTERN = /
    (\d+(?:\.\d+)?)\s*(?:sts?|stitches?)   # stitch count
    (?:\s*(?:x|and)\s*\d+\s*(?:rows?|rnd?s?))?  # optional row count
    (?:\s*[=over]+\s*)?                     # separator
    (?:\s*(\d+(?:\.\d+)?)\s*(?:x\s*\d+(?:\.\d+)?)?\s*(cm|"|in(?:ch(?:es?)?)?))?  # measurement
  /xi

  INCHES_PER_CM = 1.0 / 2.54

  def self.parse(text)
    new(text).parse
  end

  def initialize(text)
    @text = text.to_s
  end

  def parse
    match = GAUGE_PATTERN.match(@text)
    return { gauge_raw: nil, gauge_sts_10cm: nil } unless match

    sts      = match[1].to_f
    over     = match[2]&.to_f
    unit     = match[3]&.downcase

    gauge_sts_10cm = normalize_to_10cm(sts, over, unit)

    { gauge_raw: match[0].strip, gauge_sts_10cm: gauge_sts_10cm }
  end

  private

  def normalize_to_10cm(sts, over, unit)
    return nil if sts.zero?

    # Default: assume over = 10 cm if not specified
    return sts.round(1) if over.nil? || over.zero?

    if unit&.start_with?('"') || unit&.start_with?("in")
      # Convert inches to cm: over inches → 10 cm
      over_cm = over * 2.54
    else
      over_cm = over
    end

    (sts * 10.0 / over_cm).round(1)
  end
end
