class SearchTextBuilder
  TECHNIQUE_FIELDS = %i[lace texture cables colorwork brioche short_rows].freeze
  CONSTRUCTION_FIELDS = %i[
    top_down bottom_up raglan circular_yoke set_in_sleeve
    drop_shoulder saddle_shoulder seamless seamed
  ].freeze

  def self.build(pattern)
    new(pattern).build
  end

  def initialize(pattern)
    @p = pattern
  end

  def build
    parts = [
      @p.pattern_name,
      @p.designer,
      @p.garment_type,
      @p.yarn_name,
      @p.yarn_weight,
      @p.gauge,
      active_techniques,
      active_constructions
    ]

    parts
      .flatten
      .compact
      .map { |s| s.to_s.downcase.gsub(/\s+/, " ").strip }
      .reject(&:empty?)
      .join(" ")
  end

  private

  def active_techniques
    TECHNIQUE_FIELDS.filter_map { |f| f.to_s.gsub("_", " ") if @p[f] }
  end

  def active_constructions
    CONSTRUCTION_FIELDS.filter_map { |f| f.to_s.gsub("_", " ") if @p[f] }
  end
end
