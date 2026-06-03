require_relative "../lib/gauge_parser"

RSpec.describe GaugeParser do
  describe ".parse" do
    it "parses standard cm gauge" do
      result = described_class.parse("28 sts x 40 rows = 10 x 10 cm")
      expect(result[:gauge_sts_10cm]).to eq(28.0)
    end

    it "parses gauge in inches" do
      result = described_class.parse("16 sts and 24 rows = 4 x 4\"")
      expect(result[:gauge_sts_10cm]).to be_within(0.5).of(16.0)
    end

    it "returns nil for missing gauge" do
      result = described_class.parse("No gauge information here")
      expect(result[:gauge_sts_10cm]).to be_nil
    end

    it "normalizes stitches per 10cm from different measurements" do
      result = described_class.parse("14 sts = 4 inches")
      expect(result[:gauge_sts_10cm]).to be_within(1.0).of(13.8)
    end

    it "returns the raw gauge string" do
      result = described_class.parse("22 sts x 30 rows = 10 x 10 cm in stockinette")
      expect(result[:gauge_raw]).to include("22 sts")
    end
  end
end
