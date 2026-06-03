#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift(File.join(__dir__, "lib"))
require_relative "lib/pattern_cataloger"

if ARGV.empty?
  puts "Uso: ruby cataloger.rb /caminho/para/receitas/"
  exit 1
end

input_dir = ARGV[0]

unless Dir.exist?(input_dir)
  puts "Erro: diretório não encontrado — #{input_dir}"
  exit 1
end

PatternCataloger.run(input_dir)
