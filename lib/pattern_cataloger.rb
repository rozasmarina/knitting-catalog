require "parallel"
require "csv"
require "digest"
require_relative "pattern"
require_relative "pattern_analyzer"
require_relative "duplicate_detector"
require_relative "spreadsheet_exporter"

class PatternCataloger
  MAX_WORKERS = [Parallel.processor_count, 8].min

  def self.run(input_dir, output_path: "catalogo_receitas.csv", failures_path: "pdfs_com_falha.csv")
    new(input_dir, output_path: output_path, failures_path: failures_path).run
  end

  def initialize(input_dir, output_path:, failures_path:)
    @input_dir     = File.expand_path(input_dir)
    @output_path   = output_path
    @failures_path = failures_path
  end

  def run
    pdf_files = find_pdfs
    puts "Encontrados #{pdf_files.size} PDFs em #{@input_dir}"

    existing  = load_existing_catalog
    to_process, reused = partition_files(pdf_files, existing)

    puts "Reaproveitando #{reused.size} entradas existentes, processando #{to_process.size} arquivos..."

    new_patterns, failures = process_files(to_process)

    all_patterns = reused + new_patterns
    DuplicateDetector.mark!(all_patterns)

    SpreadsheetExporter.write(
      all_patterns, failures,
      output_path:   @output_path,
      failures_path: @failures_path
    )
  end

  private

  def find_pdfs
    Dir.glob(File.join(@input_dir, "**", "*.pdf")).sort
  end

  # Returns { sha256 => Pattern } from an existing CSV
  def load_existing_catalog
    return {} unless File.exist?(@output_path)

    index = {}
    CSV.foreach(@output_path, headers: true, encoding: "bom|utf-8") do |row|
      sha = row["hash_sha256"]
      next if sha.nil? || sha.empty?

      attrs = Pattern.members.each_with_object({}) do |field, h|
        h[field] = row[field.to_s]
      end
      index[sha] = Pattern.new(**attrs)
    end
    index
  rescue => e
    warn "Aviso: não foi possível ler o catálogo existente — #{e.message}"
    {}
  end

  def partition_files(pdf_files, existing)
    reused     = []
    to_process = []

    pdf_files.each do |path|
      sha = Digest::SHA256.file(path).hexdigest
      if existing.key?(sha)
        entry = existing[sha]
        if entry.caminho_completo != path
          entry.caminho_completo  = path
          entry.caminho_atualizado = true
        end
        reused << entry
      else
        to_process << path
      end
    end

    [to_process, reused]
  end

  def process_files(paths)
    patterns = []
    failures = []
    mutex    = Mutex.new

    Parallel.each(paths, in_threads: MAX_WORKERS) do |path|
      pattern = PatternAnalyzer.analyze(path, base_dir: @input_dir)
      mutex.synchronize { patterns << pattern }
    rescue => e
      entry = { arquivo: File.basename(path), caminho_completo: path, erro: e.message }
      mutex.synchronize { failures << entry }
    end

    [patterns, failures]
  end
end
