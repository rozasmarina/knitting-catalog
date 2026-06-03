require_relative "../lib/pattern"
require_relative "../lib/duplicate_detector"

RSpec.describe DuplicateDetector do
  def make_pattern(sha256:, designer: nil, pattern_name: nil)
    Pattern.new(
      hash_sha256:                   sha256,
      designer:                      designer,
      pattern_name:                  pattern_name,
      possivel_duplicata:            false,
      possivel_duplicata_aproximada: false
    )
  end

  describe ".mark!" do
    it "flags SHA256 duplicates" do
      p1 = make_pattern(sha256: "abc123")
      p2 = make_pattern(sha256: "abc123")
      p3 = make_pattern(sha256: "def456")

      described_class.mark!([p1, p2, p3])

      expect(p1.possivel_duplicata).to be true
      expect(p2.possivel_duplicata).to be true
      expect(p3.possivel_duplicata).to be false
    end

    it "flags fuzzy duplicates with different SHA256" do
      p1 = make_pattern(sha256: "aaa", designer: "Jane Doe", pattern_name: "Cozy Socks")
      p2 = make_pattern(sha256: "bbb", designer: "Jane Doe", pattern_name: "Cozy Socks")

      described_class.mark!([p1, p2])

      expect(p1.possivel_duplicata_aproximada).to be true
      expect(p2.possivel_duplicata_aproximada).to be true
    end

    it "does not flag fuzzy duplicates when already marked as exact duplicate" do
      p1 = make_pattern(sha256: "abc", designer: "Jane", pattern_name: "Socks")
      p2 = make_pattern(sha256: "abc", designer: "Jane", pattern_name: "Socks")

      described_class.mark!([p1, p2])

      expect(p1.possivel_duplicata).to be true
      expect(p1.possivel_duplicata_aproximada).to be false
    end

    it "ignores patterns with nil fuzzy keys" do
      p1 = make_pattern(sha256: "aaa")
      p2 = make_pattern(sha256: "bbb")

      expect { described_class.mark!([p1, p2]) }.not_to raise_error
    end
  end
end
