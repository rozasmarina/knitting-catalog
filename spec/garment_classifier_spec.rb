require_relative "../lib/garment_classifier"

RSpec.describe GarmentClassifier do
  describe ".classify" do
    it "classifies sweater from pullover keyword" do
      expect(described_class.classify("A classic pullover for all seasons")).to eq("sweater")
    end

    it "classifies tee" do
      expect(described_class.classify("Anker Tee - summer top")).to eq("tee")
    end

    it "classifies hat" do
      expect(described_class.classify("Simple beanie for winter")).to eq("hat")
    end

    it "classifies socks" do
      expect(described_class.classify("Toe-up socks with short row heel")).to eq("socks")
    end

    it "uses filename for classification" do
      expect(described_class.classify("", "Cozy Cardigan - Designer.pdf")).to eq("cardigan")
    end

    it "returns nil for unrecognized type" do
      expect(described_class.classify("Cast on 100 stitches")).to be_nil
    end
  end
end
