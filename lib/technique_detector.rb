class TechniqueDetector
  TECHNIQUES = {
    lace:      /\b(?:lace|eyelet|openwork)\b/i,
    texture:   /\b(?:texture[d]?|seed\s+stitch|moss\s+stitch|garter|stockinette)\b/i,
    cables:    /\b(?:cables?|aran)\b/i,
    colorwork: /\b(?:colorwork|colour\s*work|fair\s*isle|stranded|intarsia)\b/i,
    brioche:   /\bbrioche\b/i,
    short_rows:  /\b(?:short\s+rows?|german\s+short\s+rows?|wrap\s+and\s+turn)\b/i,
    held_double: /\bheld\s+double\b|\bheld\s+together\b|\b2\s+strands?\b|\btwo\s+strands?\b/i
  }.freeze

  def self.detect(text)
    new(text).detect
  end

  def initialize(text)
    @text = text.to_s
  end

  def detect
    TECHNIQUES.transform_values { |pattern| !pattern.match(@text).nil? }
  end
end
