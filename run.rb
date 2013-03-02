require 'rubygems'
require 'curb'
require 'json/pure'
require 'uri'
require File.join(File.expand_path(File.dirname(__FILE__)), 'lib/string.rb')

HOST = 'localhost:9292'
NAME = 'gnagel'

class DictionaryGuesser
  attr_accessor :hostname
  attr_accessor :words
  attr_accessor :token
  attr_accessor :phrases
  attr_accessor :username
  attr_accessor :count

  def initialize(hostname, username)
    @count    = 0
    @hostname = hostname
    @username = username
    @words    = get_dictionary
    @token    = get_token
    @phrases  = get_phrases
    @phrases_slices = @phrases.split(' ')
  end

  def run
    puts "words.count = #{@words.count}"
    puts "phrases     = #{phrases}"

    # Find the matched words
    matched_phrases = []
    0.upto(@phrases_slices.length-1) do |index|
      matched_phrases << run_phrase(index)
    end

    puts "Found match = '#{matched_phrases.join(' ')}', in attempts=#{@count}"
  end

  private

  # Execute each phrase in the phrases
  def run_phrase(index)
    # How long is the word we are looking for?
    puts "phrases_[#{index}] = #{@phrases_slices[index]}"

    # Find all the words of this length
    values = select_by_length(@phrases_slices[index].length, @words)
    # puts "phrase_words[#{index}] = #{values.count}"

    # Make sure we have at least ONE word here
    assert_is_not_empty(values, index)

    # Filter the words by the most common CONSONANT characters
    ignore = ['a', 'e', 'i', 'o', 'u', 'y']
    0.upto(1+@phrases_slices[index].length/2) do |index_constant|
      # Get the most common consonant
      char = (most_frequent_characters(values) - ignore).first

      # If we ran out of consonants then break here
      break if char.nil?

      # Filter by the given character
      values = filter_words_by_char_guess(index, char, create_phrase_char(index, char), values)
      ignore << char

      # Exit here if we only have ONE word left
      return values.first if values.size == 1
    end

    # We know most english words have at least one vowel
    # So filter by vowels here
    vowels = most_frequent_characters(values) & ['a', 'e', 'i', 'o', 'u', 'y']
    vowels.each do |char|
      values = filter_words_by_char_guess(index, char, create_phrase_char(index, char), values)

      # Exit here if there is ONE word left
      return values.first if values.size == 1
    end

    # At this point we need to brute-force the search
    values.each do |word|
      matches = get_guess(create_phrase_word(index, word))
      if (matches == word.length)
        return word
      end
    end

    # No matches found, raise an error here
    raise Exception, "No words found to match index=#{index} in phrases=#{@phrases}"
  end


  # Filter the words that have exactly N instances of the character
  def filter_words_by_char_guess(index, char, guess, values)
    # How many matches?
    matches = get_guess(guess)

    # Filter the words that have EXACTLY "matches" instances of char
    # "Matches" may be 0 here
    values  = select_by_char_matches(values, char, matches)

    # Error here if there are no words left
    assert_is_not_empty(values, index)

    # Return the filtered words
    values
  end


  # Get the dictionary of words
  def get_dictionary
    response_body = Curl::Easy.http_get(URI.encode("http://#{@hostname}/dict")).body_str
    response_json = JSON.parse(response_body)
    response_json['words']
  end


  # Get the user token
  def get_token
    response_body = Curl::Easy.http_get(URI.encode("http://#{@hostname}/start?name=#{@username}")).body_str
    response_json = JSON.parse(response_body)
    @count = response_json['count']
    response_json['token']
  end


  # Get the phrase we are guessing
  def get_phrases
    response_body = Curl::Easy.http_get(URI.encode("http://#{@hostname}/phrase?token=#{@token}")).body_str
    response_json = JSON.parse(response_body)
    @count = response_json['count']
    response_json['phrase']
  end


  # Get the guess matches
  def get_guess(guess)
    response_body = Curl::Easy.http_get(URI.encode("http://#{@hostname}/guess?token=#{@token}&guess=#{guess}")).body_str
    response_json = JSON.parse(response_body)
    @count = response_json['count']
    response_json['matches'].to_i
  end


  # Create a phrase for the given word
  def create_phrase_word(index, word)
    copy        = @phrases_slices.dup
    copy[index] = word
    copy.join(' ')
  end


  # Create the phrase for a single character
  def create_phrase_char(index, char)
    create_phrase_word(index, char * @phrases_slices[index].length)
  end


  # Select only the words matching the given length
  def select_by_length(target_length, values)
    values.select { |value| value.length == target_length }
  end


  # Select only the words with char
  def select_by_char(values, char)
    values.select { |word| value.include?(char) }
  end


  # Select only the words with char
  def select_by_char_matches(values, char, matches)
    values.select { |value| value.char_count(char) == matches }
  end


  # Select the most frequent character in the list
  def most_frequent_character(values)
    most_frequent_characters(values).first
  end


  # Order the characters by Most Common ==> Least Common in the values
  def most_frequent_characters(values)
    matches = {}
    values.each { |value| value.frequency(matches) }

    # Gather the results into arrays and sort them by frequency descending
    chars = matches.collect { |char, count| [char, count] }.sort_by { |char, count| count }
    chars.collect! { |char, count| char }
    chars.reverse!

    chars
  end

  def assert_is_not_empty(values, index)
    # Make sure we have at least ONE word here
    raise Exception, "No words match phrase index=#{index} in phrases=#{@phrases}" if values.empty?
  end
end


# Loop a few times to get an average count
count = 0
words = 0
0.upto(10) do |i|
  guesser = DictionaryGuesser.new(HOST, NAME)
  guesser.run()
  count = count + guesser.count
  words = words + guesser.words.count
end

puts ""
puts "=====" * 5
puts "Avg Attempts/Word = #{count.to_f/words.to_f}"
puts "Total Words       = #{words}"
puts "Total Attempts    = #{count}"
puts "=====" * 5
puts ""
