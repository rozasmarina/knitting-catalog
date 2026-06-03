require_relative "../lib/yarn_weight_inferrer"

RSpec.describe YarnWeightInferrer do
  describe ".infer" do
    it "infers dk from gauge and needle" do
      result = described_class.infer(gauge_sts_10cm: 22, needle_mm: 4.0)
      expect(result).to eq("dk")
    end

    it "infers fingering from gauge and needle" do
      result = described_class.infer(gauge_sts_10cm: 29, needle_mm: 2.75)
      expect(result).to eq("fingering")
    end

    it "infers worsted from gauge and needle" do
      result = described_class.infer(gauge_sts_10cm: 18, needle_mm: 5.0)
      expect(["worsted", "aran"]).to include(result)
    end

    it "uses keyword as tiebreaker for ambiguous gauges" do
      result = described_class.infer(gauge_sts_10cm: 18, needle_mm: 5.25, text: "worsted weight yarn")
      expect(result).to eq("worsted")
    end

    it "infers from needle alone when gauge is nil" do
      result = described_class.infer(gauge_sts_10cm: nil, needle_mm: 3.5)
      expect(result).not_to be_nil
    end

    it "returns nil when both gauge and needle are nil and no keyword" do
      result = described_class.infer(gauge_sts_10cm: nil, needle_mm: nil)
      expect(result).to be_nil
    end
  end
end
