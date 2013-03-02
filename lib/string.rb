# Extend the string class with some helper methods
class String
  # Replace all the letters with periods ('.')
  def phrase
    '.' * self.length
  end
  
  # Character at index
  def char_at(index)
    slice(index, 1)
  end

  # Count the number of matching characters
  def chars_matching(guess)
    # Make sure the characters match
    raise Exception, "Strings are differient lengths self='#{self}' vs guess='#{guess}'" if self.length != guess.length

    # How many matching characters are there?
    count = 0
    0.upto(length-1) do |index|
      lhs = self.char_at(index)
      rhs = guess.char_at(index)

      # Skip the invalid values
      next if lhs.nil? || lhs.empty? || lhs == '.'
      next if rhs.nil? || rhs.empty? || rhs == ' '

      # Increment the counter
      count = count + 1 if lhs == rhs
    end

    # Return the counter
    count
  end

  # Count the instances of char
  def char_count(char)
    self.scan(/#{char}/).count
  end
  
  # Count the characters by frequency
  def frequency(matches)
    0.upto(self.length-1) do |index|
      char = self.char_at(index)
      matches[char] ||= 0
      matches[char] = matches[char] + 1
    end
    matches
  end
end
