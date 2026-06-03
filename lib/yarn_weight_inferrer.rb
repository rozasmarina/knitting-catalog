class YarnWeightInferrer
  # CYC weight table: [weight_name, sts_range, needle_range_mm]
  WEIGHTS = [
    ["lace",        32..Float::INFINITY, 1.5..2.25],
    ["fingering",   27..32,              2.25..3.25],
    ["sport",       23..26,              3.25..3.75],
    ["dk",          21..24,              3.75..4.5],
    ["worsted",     16..20,              4.5..5.5],
    ["aran",        16..18,              5.0..6.0],
    ["bulky",       12..15,              5.5..8.0],
    ["super bulky",  7..11,              8.0..Float::INFINITY]
  ].freeze

  KEYWORDS = %w[lace fingering sport dk worsted aran bulky].freeze

  def self.infer(gauge_sts_10cm:, needle_mm:, text: "")
    new(gauge_sts_10cm: gauge_sts_10cm, needle_mm: needle_mm, text: text).infer
  end

  def initialize(gauge_sts_10cm:, needle_mm:, text: "")
    @sts    = gauge_sts_10cm
    @needle = needle_mm
    @text   = text.to_s.downcase
  end

  def infer
    # Without any signal, fall back to keyword only
    return keyword_match if @sts.nil? && @needle.nil?

    candidates = matching_weights
    return keyword_match if candidates.empty?
    return candidates.first if candidates.size == 1

    # Multiple candidates — use keyword as tiebreaker
    kw = keyword_match
    candidates.include?(kw) ? kw : candidates.first
  end

  private

  def matching_weights
    WEIGHTS.filter_map do |name, sts_range, needle_range|
      sts_match    = @sts.nil?    || sts_range.cover?(@sts)
      needle_match = @needle.nil? || needle_range.cover?(@needle)
      name if sts_match && needle_match
    end
  end

  def keyword_match
    KEYWORDS.find { |kw| @text.include?(kw) } ||
      ("super bulky" if @text.include?("super bulky"))
  end
end
