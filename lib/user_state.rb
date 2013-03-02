require 'yaml'
require 'md5'
require File.join(File.expand_path(File.dirname(__FILE__)), 'dictionary.rb')


class UserState
  attr_accessor :token
  attr_accessor :username
  attr_accessor :count
  attr_accessor :words
  
  def initialize(opts = {})
    @token    = opts[:token]
    @username = opts[:username]
    @count    = opts[:count] || 0
    @words    = opts[:words] || []
  end


  # Create a new UserState and save it to disk
  def self.create(username)
    # Create the new user state
    user_state = UserState.new(:token => MD5.md5(username).to_s, :username => username, :count => 0, :words => [])

    # 1 to 3 random words
    0.upto(1 + rand(2)) { |i| user_state.words << Dictionary.random_word() }

    # Save the state, overwriting any saved state
    user_state.save()

    # Return the UserState
    user_state
  end


  # Load the user state for the given token
  def self.load(token)
    # New instance of the UserState
    user_state = UserState.new(YAML.load_file("/tmp/#{token}.yml"))
    
    # Return the UserState
    user_state
  end


  # Save the user state to a file
  def save
    File.open("/tmp/#{self.token}.yml", 'w') { |file| file.write(to_hash.to_yaml) }
    self
  end



  # Get the phrase the user has to match
  def phrase
    # Gather all the patterns together
    patterns = words.collect do |word|
      # Replace all the letters with periods ('.')
      '.' * word.length
      # word.length.downto(1).collect { |i| '.' }
    end

    # Join the patterns with spaces
    # Return the result
    patterns.join(' ')
  end


  # Count the number of matching characers
  def guess_matches(guess)
    # downcase the input
    guess.downcase!

    # Join the words by spaces
    match_words = words.join(' ')

    # Count of matching characters
    count = 0
    
    guess_chars = guess.chars.collect { |char| char }
    match_chars = match_words.chars.collect { |char| char }

    # Iterate the strings in parallel and match the characers
    0.upto([guess_chars.size, match_chars.size].min) do |index|
      # Input (LHS) vs Expected (RHS)
      lhs = guess_chars[index]
      next if lhs.nil? || lhs.empty? || lhs == '.'
      
      rhs = match_chars[index]
      next if rhs.nil? || rhs.empty? || rhs == ' '
      
      matches = lhs == rhs
      # puts "\n#{__FILE__}:#{__LINE__} lhs=#{lhs}, rhs=#{rhs}, matches=#{matches}\n"

      count = count + 1 if (matches)
    end
    
    # puts "\n#{__FILE__}:#{__LINE__} words=#{words.join(' ')}, guess=#{guess}, count=#{count}\n\n"

    # Return the counter
    count
  end


  # Convert the UserState to a hash
  def to_hash
    {
      :token    => token,
      :username => username,
      :count    => count,
      :words    => words
    }
  end
end
