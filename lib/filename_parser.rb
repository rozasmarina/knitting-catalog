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

    name = match[1].strip.gsub(/\A[\d\-]+\s+/, "")  # strip leading "1213-01 "
    designer = match[2].strip.gsub(/\s*\(\d+\)\z/, "")  # strip trailing "(1)"

    { pattern_name: name, designer: designer }
  end
end
