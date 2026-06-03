require_relative "../lib/needle_size_normalizer"

RSpec.describe NeedleSizeNormalizer do
  describe ".normalize" do
    it "extracts mm directly" do
      expect(described_class.normalize("3 mm [US2.5]")).to eq(3.0)
    end

    it "extracts mm with parenthesis notation" do
      expect(described_class.normalize("5 mm (US Size 8)")).to eq(5.0)
    end

    it "extracts mm without US notation" do
      expect(described_class.normalize("4.5mm needle")).to eq(4.5)
    end

    it "converts US size to mm when no mm present" do
      expect(described_class.normalize("US 6")).to eq(4.0)
    end

    it "converts US 10.5 to mm" do
      expect(described_class.normalize("US 10.5")).to eq(6.5)
    end

    it "returns nil for unrecognized format" do
      expect(described_class.normalize("use a medium needle")).to be_nil
    end

    it "prefers mm over US size in same string" do
      expect(described_class.normalize("3.25 mm / US 3")).to eq(3.25)
    end
  end
end
