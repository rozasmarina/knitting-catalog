class GarmentClassifier
  TYPES = {
    "sweater"  => /\b(?:sweater|pullover|jumper)\b/i,
    "tee"      => /\b(?:tee|t-shirt|top|tank)\b/i,
    "cardigan" => /\bcardigan\b/i,
    "vest"     => /\b(?:vest|slipover)\b/i,
    "shawl"    => /\b(?:shawl|wrap)\b/i,
    "hat"      => /\b(?:hat|beanie|bonnet)\b/i,
    "socks"    => /\bsocks?\b/i,
    "dress"    => /\bdress\b/i
  }.freeze

  def self.classify(text, filename = "")
    new(text, filename).classify
  end

  def initialize(text, filename = "")
    @text     = text.to_s
    @filename = filename.to_s
  end

  def classify
    combined = "#{@filename} #{@text}"
    TYPES.each do |type, pattern|
      return type if pattern.match?(combined)
    end
    nil
  end
end
