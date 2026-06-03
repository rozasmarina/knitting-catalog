class NeedleSizeNormalizer
  # US needle size → mm conversion table (Craft Yarn Council)
  US_TO_MM = {
    "0"    => 2.0,
    "1"    => 2.25,
    "1.5"  => 2.5,
    "2"    => 2.75,
    "2.5"  => 3.0,
    "3"    => 3.25,
    "4"    => 3.5,
    "5"    => 3.75,
    "6"    => 4.0,
    "7"    => 4.5,
    "8"    => 5.0,
    "9"    => 5.5,
    "10"   => 6.0,
    "10.5" => 6.5,
    "11"   => 8.0,
    "13"   => 9.0,
    "15"   => 10.0,
    "17"   => 12.75,
    "19"   => 15.0,
    "35"   => 19.0,
    "50"   => 25.0
  }.freeze

  # Matches "3 mm", "3.5mm", "3 mm [US2.5]", "5 mm (US Size 8)"
  MM_PATTERN = /(\d+(?:\.\d+)?)\s*mm/i

  # Matches "US 6", "US Size 8", "US2.5", "[US 10.5]"
  US_PATTERN = /\bUS\s*(?:Size\s*)?(\d+(?:\.\d+)?)/i

  def self.normalize(text)
    new(text).normalize
  end

  def initialize(text)
    @text = text.to_s
  end

  def normalize
    # Prefer mm value when present
    mm_match = MM_PATTERN.match(@text)
    return mm_match[1].to_f if mm_match

    # Fall back to US conversion
    us_match = US_PATTERN.match(@text)
    return nil unless us_match

    us_size = us_match[1]
    US_TO_MM[us_size] || US_TO_MM[us_size.to_f.to_s]
  end
end
