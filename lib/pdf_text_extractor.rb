require "pdf-reader"

class PdfTextExtractor
  EMPTY_THRESHOLD = 50

  def self.extract(path, header_pages: 5)
    new(path, header_pages: header_pages).extract
  end

  def initialize(path, header_pages: 5)
    @path = path
    @header_pages = header_pages
  end

  def extract
    reader = PDF::Reader.new(@path)
    pages  = reader.pages

    full_text   = pages.map(&:text).join("\n")
    header_text = pages.first(@header_pages).map(&:text).join("\n")

    if full_text.strip.length < EMPTY_THRESHOLD
      { status: :empty, full_text: full_text, header_text: header_text }
    else
      { status: :ok, full_text: full_text, header_text: header_text }
    end
  rescue PDF::Reader::MalformedPDFError, PDF::Reader::UnsupportedFeatureError => e
    { status: :error, error: e.message, full_text: "", header_text: "" }
  rescue => e
    { status: :error, error: e.message, full_text: "", header_text: "" }
  end
end
