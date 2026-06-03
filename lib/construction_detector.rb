class ConstructionDetector
  CONSTRUCTIONS = {
    top_down:      /\btop[\s-]down\b/i,
    bottom_up:     /\bbottom[\s-]up\b/i,
    raglan:        /\braglan\b/i,
    circular_yoke: /\bcircular\s+yoke\b/i,
    set_in_sleeve: /\bset[\s-]in\s+sleeve[s]?\b/i,
    drop_shoulder: /\bdrop(?:ped)?\s+shoulder[s]?\b/i,
    saddle_shoulder: /\bsaddle\s+shoulder[s]?\b/i,
    seamless:      /\bseamless\b/i,
    seamed:        /\bseamed\b/i
  }.freeze

  def self.detect(text)
    new(text).detect
  end

  def initialize(text)
    @text = text.to_s
  end

  def detect
    CONSTRUCTIONS.transform_values { |pattern| !pattern.match(@text).nil? }
  end
end
