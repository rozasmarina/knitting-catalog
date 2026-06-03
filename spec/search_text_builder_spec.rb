require_relative "../lib/pattern"
require_relative "../lib/search_text_builder"

RSpec.describe SearchTextBuilder do
  describe ".build" do
    it "builds lowercase concatenated search text" do
      pattern = Pattern.new(
        pattern_name: "Cozy Sweater",
        designer:     "Jane Doe",
        garment_type: "sweater",
        yarn_weight:  "dk",
        cables:       true,
        texture:      false,
        lace:         false,
        colorwork:    false,
        brioche:      false,
        short_rows:   false,
        top_down:     true,
        bottom_up:    false,
        raglan:       false,
        circular_yoke: false,
        set_in_sleeve: false,
        drop_shoulder: false,
        saddle_shoulder: false,
        seamless:     true,
        seamed:       false
      )

      result = described_class.build(pattern)
      expect(result).to include("cozy sweater")
      expect(result).to include("jane doe")
      expect(result).to include("cables")
      expect(result).to include("top down")
      expect(result).to include("seamless")
      expect(result).not_to match(/\s{2,}/)
    end

    it "handles nil fields gracefully" do
      pattern = Pattern.new(
        pattern_name: nil,
        designer:     nil,
        cables:       false,
        lace:         false,
        texture:      false,
        colorwork:    false,
        brioche:      false,
        short_rows:   false,
        top_down:     false,
        bottom_up:    false,
        raglan:       false,
        circular_yoke: false,
        set_in_sleeve: false,
        drop_shoulder: false,
        saddle_shoulder: false,
        seamless:     false,
        seamed:       false
      )
      expect { described_class.build(pattern) }.not_to raise_error
    end
  end
end
