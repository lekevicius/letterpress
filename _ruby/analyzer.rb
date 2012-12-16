def check_word letters, word
	word.each_char do |letter| 
		if letters.include? letter 
			letters.delete_at( letters.index(letter) || letters.length ) 
		else return false
	true
end

available = []
letters = letters.gsub(" ", "").downcase.split('')
File.read('_all_words.txt').each_line { |word| available << word.strip if check_word letters.clone, word.strip }
puts available.sort_by(&:length).reverse[0..450]