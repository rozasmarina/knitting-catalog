require "tempfile"
require "fileutils"

class OcrFallback
  PDFTOPPM = "pdftoppm"
  TESSERACT = "tesseract"

  def self.available?
    system("which #{PDFTOPPM} > /dev/null 2>&1") &&
      system("which #{TESSERACT} > /dev/null 2>&1")
  end

  def self.extract(path, header_pages: 5)
    new(path, header_pages: header_pages).extract
  end

  def initialize(path, header_pages: 5)
    @path = path
    @header_pages = header_pages
  end

  def extract
    return { status: :unavailable, full_text: "", header_text: "" } unless self.class.available?

    Dir.mktmpdir("ocr_") do |tmpdir|
      full_text   = ocr_pages(@path, tmpdir, last_page: nil)
      header_text = ocr_pages(@path, tmpdir, last_page: @header_pages)

      if full_text.strip.empty?
        { status: :failed, full_text: "", header_text: "" }
      else
        { status: :ok, full_text: full_text, header_text: header_text }
      end
    end
  rescue => e
    { status: :failed, full_text: "", header_text: "", error: e.message }
  end

  private

  def ocr_pages(pdf_path, tmpdir, last_page:)
    prefix = File.join(tmpdir, "page")
    args = [PDFTOPPM, "-r", "150", "-jpeg"]
    args += ["-l", last_page.to_s] if last_page
    args += [pdf_path, prefix]

    system(*args, out: File::NULL, err: File::NULL)

    ppm_files = Dir["#{prefix}*.jpg", "#{prefix}*.ppm"].sort
    ppm_files.map { |f| tesseract_page(f) }.join("\n")
  end

  def tesseract_page(image_path)
    out = `#{TESSERACT} "#{image_path}" stdout -l eng 2>/dev/null`.strip
    out
  end
end
