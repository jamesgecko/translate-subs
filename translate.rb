class Sub
  attr_writer :line1_zh, :line2_zh

  def initialize(text)
    @place = text[0].strip
    @time = text[1].strip
    @line1_en = text[2].strip
    @line2_en = text[3]&.strip
    @line1_zh = nil
    @line2_zh = nil
  end

  def line_count
    @line2_en ? 2 : 1
  end

  def english_lines
    out = "#{@line1_en}\n"
    out << "#{@line2_en}\n" if @line2_en
    out
  end

  def zh_version
    out = "#{@place}\n#{@time}\n#{@line1_zh}\n"
    out << "#{@line2_zh || ' '}\n"
    out << "#{@line1_en}\n"
    out << "#{@line2_en || ' '}\n"
    out << "\n"
    out
  end
end

def sub_factory(file_name)
  subs = []
  buffer = []
  File.foreach(file_name) do |line|
    if line == "\n"
      subs << Sub.new(buffer)
      buffer = []
      next
    end
    buffer << line
  end
  subs
end

def chunk_subs(subs)
  chunks = []
  chunk = ''
  subs.each do |sub|
    english = sub.english_lines
    if chunk.length + english.length < 5000
      chunk << english
    else
      chunks << chunk
      chunk = english
    end
  end
  chunks << chunk
  chunks
end

def save_chunks(directory, chunks)
  chunks.each_with_index do |chunk, i|
    file_name = "#{directory}/en-#{i}.txt"
    puts "Writing #{file_name}"
    File.open(file_name, 'w') do |f|
      f.write chunk
    end
  end
end

def combine_translated_chunks(directory, chunk_count)
  full_script = ''
  chunk_count.times do |i|
    file_name = "#{directory}/zh-#{i}.txt"
    puts "Reading #{file_name}"
    File.foreach(file_name) do |line|
      full_script << line
    end
  end
  full_script
end

def merge_translation(subs, translated_script)
  translated_script = translated_script.split("\n")
  subs.each do |sub|
    abort 'Incomplete script' if translated_script.empty?
    sub.line1_zh = translated_script.shift
    sub.line2_zh = translated_script.shift if sub.line_count == 2
  end
end

def output_translation(directory, translated_subs)
  file_name = "#{directory}-zh.srt"
  File.open(file_name, 'w') do |f|
    translated_subs.each do |sub|
      f.write(sub.zh_version)
    end
  end
  puts "Wrote #{file_name}"
end

def build_translation(directory, subs, chunk_count)
  translated_script = combine_translated_chunks(directory, chunk_count)
  merge_translation(subs, translated_script)
  output_translation(directory, subs)
end

def working_dir(file_name)
  File.basename(file_name, File.extname(file_name))
end

CliArgs = Struct.new(:operation, :file_name)
def parse_args
  abort 'Usage: translate.rb [dump|build] [file name]' unless ARGV[0] && ARGV[1]
  abort 'Invalid operation' unless %w[dump build].include?(ARGV[0])

  CliArgs.new(ARGV[0], ARGV[1])
end

def main
  args = parse_args
  subs = sub_factory(args.file_name)
  chunks = chunk_subs(subs)
  directory = working_dir(args.file_name)
  Dir.mkdir(directory) unless File.exist?(directory)
  case args.operation
  when 'dump' then save_chunks(directory, chunks)
  when 'build' then build_translation(directory, subs, chunks.count)
  end
end

main
