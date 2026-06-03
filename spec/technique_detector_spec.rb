require_relative "../lib/technique_detector"

RSpec.describe TechniqueDetector do
  describe ".detect" do
    it "detects cables" do
      result = described_class.detect("This pattern features beautiful cable work")
      expect(result[:cables]).to be true
    end

    it "detects brioche" do
      result = described_class.detect("Work in brioche stitch throughout")
      expect(result[:brioche]).to be true
    end

    it "detects lace" do
      result = described_class.detect("Delicate lace edging and eyelet pattern")
      expect(result[:lace]).to be true
    end

    it "detects colorwork" do
      result = described_class.detect("Classic Fair Isle colorwork yoke")
      expect(result[:colorwork]).to be true
    end

    it "detects short rows" do
      result = described_class.detect("Use short rows to shape the bust")
      expect(result[:short_rows]).to be true
    end

    it "detects texture" do
      result = described_class.detect("Simple textured seed stitch pattern")
      expect(result[:texture]).to be true
    end

    it "returns all false for plain text" do
      result = described_class.detect("Cast on 100 stitches. Knit every row.")
      expect(result.values).to all(be false)
    end
  end
end
