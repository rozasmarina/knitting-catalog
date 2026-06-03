require "csv"

class SpreadsheetExporter
  UTF8_BOM = "\xEF\xBB\xBF"

  def self.write(patterns, failures, output_path: "catalogo_receitas.csv", failures_path: "pdfs_com_falha.csv")
    new(patterns, failures, output_path: output_path, failures_path: failures_path).write
  end

  def initialize(patterns, failures, output_path:, failures_path:)
    @patterns      = patterns
    @failures      = failures
    @output_path   = output_path
    @failures_path = failures_path
  end

  def write
    write_catalog
    write_failures
  end

  private

  def write_catalog
    File.open(@output_path, "w:UTF-8") do |f|
      f.write(UTF8_BOM)
      csv = CSV.new(f)
      csv << Pattern.csv_headers
      @patterns.each { |p| csv << p.to_csv_row }
    end
    puts "Catálogo gravado: #{File.expand_path(@output_path)} (#{@patterns.size} receitas)"
  end

  def write_failures
    File.open(@failures_path, "w:UTF-8") do |f|
      f.write(UTF8_BOM)
      csv = CSV.new(f)
      csv << %w[arquivo caminho_completo erro]
      @failures.each { |entry| csv << [entry[:arquivo], entry[:caminho_completo], entry[:erro]] }
    end
    puts "Falhas gravadas: #{File.expand_path(@failures_path)} (#{@failures.size} entradas)"
  end
end
