require 'rubygems'
require 'curb'
require 'json/pure'
require 'uri'

HOST = 'localhost:9292'
NAME = 'gnagel'

class YahooDictionaryGuesser
  attr_accessor :hostname
  attr_accessor :words
  attr_accessor :token
  attr_accessor :phrases
  attr_accessor :username

  def initialize(hostname, username)
    @hostname = hostname
    @username = username
    @words    = get_dictionary
    @token    = get_token
    @phrases  = get_phrases
    @phrases_slices = @phrases.split(' ')
  end

  def run
    puts "words.count = #{@words.count}"

    # Count the vowels in all the words, and eliminate any vowels that are not present
    vowels = ['a', 'e', 'i', 'o', 'u', 'y'].select do |vowel|
      # Find the first word that contains this vowel
      @words.detect do |word|
        # Does the word include this vowel?
        word.include?(vowel)
      end
    end

    puts "vowels = #{vowels.to_yaml}"

    matched_phrases = []

    puts "phrases = #{phrases}"
    puts "phrases_slices = #{@phrases_slices.to_yaml}"

    0.upto(@phrases_slices.length-1) do |index|
      # How long is the word we are looking for?
      phrase_match_index        = @phrases_slices[index]
      phrase_match_index_length = phrase_match_index.length
      puts "phrases_slices[index] = #{@phrases_slices[index]}"
      puts "phrase_match_index_length = #{phrase_match_index_length}"

      # Find all the words of this length
      phrase_match_words = select_by_length(phrase_match_index_length, @words)
      puts "phrase_match_words.count = #{phrase_match_words.count}"

      # Make sure we have at least ONE word here
      assert_is_not_empty(phrase_match_words, index)

      # Filter the words by the most common character
      filter_by_character!(phrase_match_words, most_frequent_character(phrase_match_words), index)

      # We have more than ONE word to choose from
      # Iterate by vowels
      if (phrase_match_words.size > 1)
        # Sort the vowels by frequency
        vowels = most_frequent_characters(phrase_match_words) & vowels
        vowels.each do |vowel|
          # Filter the words
          filter_by_character!(phrase_match_words, vowel, index)

          # Make sure we have at least ONE word here
          assert_is_not_empty(phrase_match_words, index)

          # If we reached the finish
          break if phrase_match_words.size == 1
        end
      end

      # We have more than ONE word to choose from
      # Iterate by constants
      if (phrase_match_words.size > 1)
        0.upto(phrase_match_index_length-1) do |char_index|
          # Count the occurances of each character in the arrays
          chars_at = most_frequent_characters(phrase_match_words.collect { |w| w.slice(char_index,1) })

          # Iterate the characters from most frequent --> least frequent
          chars_at.each do |char|
            copy                    = @phrases_slices.dup
            copy[index]             = "#{'.' * (char_index)}#{char.to_s}#{'.' * ([phrase_match_index_length-char_index-1, 0].max)}"
            matches                 = get_guess(copy.join(' '))

            # No matches?
            if (matches == 0)
              # Delete all the words with CHAR at CHAR_INDEX
              phrase_match_words.reject! { |word| word.slice(char_index, 1) == char }
            else
              # Delete all the words without CHAR at CHAR_INDEX
              phrase_match_words.reject! { |word| word.slice(char_index, 1) != char }
              # Break the loop
              break;
            end
          end

          # Make sure we have at least ONE word here
          assert_is_not_empty(phrase_match_words, index)

          # If we reached the finish
          break if phrase_match_words.size == 1
        end
      end

      # Brute force the matching at this point ...
      if (phrase_match_words.size > 1)
        while(!phrase_match_words.empty?)
          word        = phrase_match_words.shift
          copy        = @phrases_slices.dup
          copy[index] = word
          matches     = get_guess(copy.join(' '))

          break if matches == word.length
        end
      end

      # Make sure we have at least ONE word here
      assert_is_not_empty(phrase_match_words, index)

      # Append the matched word to the array
      matched_phrases << phrase_match_words.first
    end
    
    puts "Found match = '#{matched_phrases.join(' ')}'"
  end

  private

  def get_dictionary
    response_body = Curl::Easy.http_get(URI.encode("http://#{@hostname}/dict")).body_str
    response_json = JSON.parse(response_body)
    response_json['words']
  end

  def get_token
    response_body = Curl::Easy.http_get(URI.encode("http://#{@hostname}/start?name=#{@username}")).body_str
    response_json = JSON.parse(response_body)
    response_json['token']
  end

  def get_phrases
    response_body = Curl::Easy.http_get(URI.encode("http://#{@hostname}/phrase?token=#{@token}")).body_str
    response_json = JSON.parse(response_body)
    response_json['phrase']
  end

  def get_guess(guess)
    response_body = Curl::Easy.http_get(URI.encode("http://#{@hostname}/guess?token=#{@token}&guess=#{guess}")).body_str
    response_json = JSON.parse(response_body)
    matches = response_json['matches'].to_i

    puts "#{__FILE__}:#{__LINE__} #{guess} ==> #{matches}"
    matches
  end

  def select_by_length(target_length, values)
    values.select { |value| value.length == target_length }
  end

  def most_frequent_character(values)
    matches = most_frequent_characters(values)
    puts "#{__FILE__}:#{__LINE__} match=#{matches.first.to_yaml}"
    matches.first
  end

  def most_frequent_characters(values)
    matches = {}

    values.each do |value|
      0.upto(value.length-1) do |index|
        char = value.slice(index, 1)
        matches[char] ||= 0
        matches[char] = matches[char] + 1
      end
    end
    
    puts "#{__FILE__}:#{__LINE__} matches=#{matches.to_yaml}"

    matches.collect { |char, count| [char, count] }.sort_by { |char, count| count }.collect { |char, count| char }.reverse
  end

  def filter_by_character!(values, char, index)
    copy        = @phrases_slices.dup
    copy[index] = char * @phrases_slices[index].length
    matches     = get_guess(copy.join(' '))

    # Remove any entries that don't have exactly MATCHES number of CHAR
    values.reject! { |word| word.scan(/#{char}/).count != matches }

    # Return the values
    values
  end

  def assert_is_not_empty(values, index)
    # Make sure we have at least ONE word here
    raise Exception, "No words match phrase index=#{index} in phrases=#{@phrases}" if values.empty?
  end
end


YahooDictionaryGuesser.new(HOST, NAME).run()
