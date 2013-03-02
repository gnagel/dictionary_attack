require 'curb'
require 'json/pure'

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
  end

  def run
    # Count the vowels in all the words, and eliminate any vowels that are not present
    vowels = ['a', 'e', 'i', 'o', 'u', 'y'].select do |vowel|
      # Find the first word that contains this vowel
      @words.detect do |word|
        # Does the word include this vowel?
        word.include?(vowel)
      end
    end

    matched_phrases = []
    phrases_slices = @phrases.split(' ')
    0.upto(phrases_slices.length-1) do |index|
      # How long is the word we are looking for?
      phrase_match_length = phrases_slices[index]

      # Find all the words of this length
      phrase_match_words = @words.select { |word| word.length == phrase_match_length }

      # Make sure we have at least ONE word here
      raise Exception, "No words match phrase index=#{index} in phrases=#{@phrases}" if phrase_match_words.empty?

      # We have more than ONE word to choose from
      # Iterate by vowels
      if (phrase_match_words.size > 1)
        vowels.each do |vowel|
          copy        = phrases_slices.dup
          copy[index] = vowel * phrase_match_length
          matches     = get_guess(copy.join(' '))

          # Remove any entries that don't have exactly MATCHES number of vowels
          phrase_match_words.select! do |word|
            # Count the number of vowels in the word
            word.scan(/#{vowel}/).count == matches
          end

          # Make sure we have at least ONE word here
          raise Exception, "No words match phrase index=#{index} in phrases=#{@phrases}" if phrase_match_words.empty?

          # If we reached the finish
          break if phrase_match_words.size == 1
        end
      end

      # We have more than ONE word to choose from
      # Iterate by constants
      if (phrase_match_words.size > 1)
        0.upto(phrase_match_length-1) do |char_index|
          # Count the occurances of each character in the arrays
          chars_at = phrase_match_words.collect { |word| word[char_index] }
          chars_at = chars_at.group_by { |char| char }
          chars_at = chars_at.collect { |char, matches| [char,matches.count] }
          chars_at = chars_at.sort_by { |char,matches| matches }.reverse

          # Iterate the characters from most frequent --> least frequent
          chars_at.each do |char|
            copy                    = phrases_slices.dup
            copy[index]             = '.' * phrase_match_length
            copy[index][char_index] = char
            matches                 = get_guess(copy.join(' '))

            # No matches?
            if (matches == 0)
              # Delete all the words with CHAR at CHAR_INDEX
              phrase_match_words.reject! { |word| word[char_index] == char }
            else
              # Delete all the words without CHAR at CHAR_INDEX
              phrase_match_words.reject! { |word| word[char_index] != char }
              # Break the loop
              break;
            end
          end

          # Make sure we have at least ONE word here
          raise Exception, "No words match phrase index=#{index} in phrases=#{@phrases}" if phrase_match_words.empty?

          # If we reached the finish
          break if phrase_match_words.size == 1
        end
      end

      # Brute force the matching at this point ...
      if (phrase_match_words.size > 1)
        while(!phrase_match_words.empty?)
          word        = phrase_match_words.shift
          copy        = phrases_slices.dup
          copy[index] = word
          matches     = get_guess(copy.join(' '))

          break if matches == word.length
        end
      end
      
      # Make sure we have at least ONE word here
      raise Exception, "No words match phrase index=#{index} in phrases=#{@phrases}" if phrase_match_words.empty?

      # Append the matched word to the array
      matched_phrases << phrase_match_words.first
    end
  end

  private

  def get_dictionary
    response_body = Curl::Easy.http_get("http://#{@hostname}/dict").body_str
    response_json = JSON.parse(response_body)
    response_json['words']
  end

  def get_token
    response_body = Curl::Easy.http_get("http://#{@hostname}/start?name=#{@username}").body_str
    response_json = JSON.parse(response_body)
    response_json['token']
  end

  def get_phrases
    response_body = Curl::Easy.http_get("http://#{@hostname}/phrase?token=#{@token}").body_str
    response_json = JSON.parse(response_body)
    response_json['phrase']
  end

  def get_guess(guess)
    response_body = Curl::Easy.http_get("http://#{@hostname}/guess?token=#{@token}&guess=#{guess}").body_str
    response_json = JSON.parse(response_body)
    response_json['matches'].to_i
  end
end


YahooDictionaryGuesser.new(HOST, NAME).run()
