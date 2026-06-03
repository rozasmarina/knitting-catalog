class FilenameParser
  # Matches "Pattern Name - Designer Name.pdf" (case-insensitive, flexible spacing)
  CONVENTION = /\A(.+?)\s+-\s+(.+?)\.pdf\z/i

  def self.parse(filename)
    new(filename).parse
  end

  def initialize(filename)
    @filename = filename
  end

  def parse
    basename = File.basename(@filename)
    match = CONVENTION.match(basename)
    return { pattern_name: nil, designer: nil } unless match

    { pattern_name: match[1].strip, designer: match[2].strip }
  end
end
