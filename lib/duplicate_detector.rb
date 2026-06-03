class DuplicateDetector
  def self.mark!(patterns)
    new(patterns).mark!
  end

  def initialize(patterns)
    @patterns = patterns
  end

  def mark!
    mark_sha256_duplicates!
    mark_fuzzy_duplicates!
    @patterns
  end

  private

  def mark_sha256_duplicates!
    groups = @patterns.group_by(&:hash_sha256).select { |_, v| v.size > 1 }
    groups.each_value do |dupes|
      dupes.each { |p| p.possivel_duplicata = true }
    end
  end

  def mark_fuzzy_duplicates!
    groups = @patterns
      .reject { |p| p.fuzzy_key.nil? }
      .group_by(&:fuzzy_key)
      .select { |_, v| v.size > 1 }

    groups.each_value do |dupes|
      # Only flag as approximate duplicate when SHA256 differs (not already exact dup)
      dupes.each do |p|
        p.possivel_duplicata_aproximada = true unless p.possivel_duplicata
      end
    end
  end
end
