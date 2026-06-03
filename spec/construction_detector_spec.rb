require_relative "../lib/construction_detector"

RSpec.describe ConstructionDetector do
  describe ".detect" do
    it "detects top-down construction" do
      result = described_class.detect("Knit top-down from the collar")
      expect(result[:top_down]).to be true
    end

    it "detects raglan" do
      result = described_class.detect("Classic raglan shaping at the shoulders")
      expect(result[:raglan]).to be true
    end

    it "detects dropped shoulders" do
      result = described_class.detect("Easy dropped shoulders construction")
      expect(result[:drop_shoulder]).to be true
    end

    it "detects seamless" do
      result = described_class.detect("This sweater is worked seamless in the round")
      expect(result[:seamless]).to be true
    end

    it "detects circular yoke" do
      result = described_class.detect("Beautiful circular yoke worked from the top")
      expect(result[:circular_yoke]).to be true
    end

    it "returns all false for non-specific text" do
      result = described_class.detect("Cast on and work in stockinette stitch")
      expect(result.values).to all(be false)
    end
  end
end
