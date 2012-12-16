File.open('_all_words.txt', 'w') { |out_file| Dir.glob("app_bundle_words/*.txt") { |in_file| out_file.puts File.read(in_file) } }
