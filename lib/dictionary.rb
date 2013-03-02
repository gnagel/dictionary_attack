class Dictionary
  @@lines = []
  
  # Get a list of all words in the dictionary
  def self.words()
    # Return the lines if cached
    return @@lines if !@@lines.empty?

    # Read in the lines from the file
    @@lines = File.readlines(File.join(File.expand_path(File.dirname(__FILE__)), 'words.txt'))

    # Strip the newline characters
    # and lower-case the words
    @@lines.collect! { |word| word.strip.downcase }

    # Remove any duplicates introduced by downcase
    @@lines.uniq!

    # Return the lines
    @@lines
  end


  # Get a random word from the dictionary
  def self.random_word()
    # Get the words from the dictionary
    all_words = words()

    # How many lines are there in the dictionary?
    count = all_words.count

    # Choose one randomly
    index = rand(count)

    # Return the selected word
    all_words[index]
  end
end
