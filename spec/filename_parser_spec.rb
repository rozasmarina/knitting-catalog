require_relative "../lib/filename_parser"

RSpec.describe FilenameParser do
  describe ".parse" do
    it "parses standard convention" do
      result = described_class.parse("Socks - Designer.pdf")
      expect(result[:pattern_name]).to eq("Socks")
      expect(result[:designer]).to eq("Designer")
    end

    it "handles double-barrelled designer names" do
      result = described_class.parse("Cable Sweater - Jane Van Der Berg.pdf")
      expect(result[:pattern_name]).to eq("Cable Sweater")
      expect(result[:designer]).to eq("Jane Van Der Berg")
    end

    it "returns nil for non-convention filenames" do
      result = described_class.parse("pattern_001.pdf")
      expect(result[:pattern_name]).to be_nil
      expect(result[:designer]).to be_nil
    end

    it "returns nil for unnamed files" do
      result = described_class.parse("Unnamed.pdf")
      expect(result[:pattern_name]).to be_nil
    end

    it "handles extra whitespace around dash" do
      result = described_class.parse("My Pattern  -  Designer Name.pdf")
      expect(result[:pattern_name]).to eq("My Pattern")
      expect(result[:designer]).to eq("Designer Name")
    end

    it "strips 'Cópia de' prefix from pattern name" do
      result = described_class.parse("Cópia de My Favourite Things - Designer.pdf")
      expect(result[:pattern_name]).to eq("My Favourite Things")
    end

    it "strips 'Copia de' prefix (without accent)" do
      result = described_class.parse("Copia de Some Pattern - Designer.pdf")
      expect(result[:pattern_name]).to eq("Some Pattern")
    end

    it "strips 'Copy of' prefix from pattern name" do
      result = described_class.parse("Copy of Some Pattern - Designer.pdf")
      expect(result[:pattern_name]).to eq("Some Pattern")
    end
  end
end
