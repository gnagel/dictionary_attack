require 'json/pure'
require File.join(File.expand_path(File.dirname(__FILE__)), 'lib/string.rb')
require File.join(File.expand_path(File.dirname(__FILE__)), 'lib/dictionary.rb')
require File.join(File.expand_path(File.dirname(__FILE__)), 'lib/user_state.rb')


class DictionaryApp < Sinatra::Base
  before do
    content_type 'application/json'
  end

  # Get the dictionary of all words
  get "/dict" do
    # Read in the lines from the file
    words = Dictionary.words()

    # Return the words as json
    { :words => words }.to_json
  end


  # Encode the username
  get '/start' do
    # User state for the API
    # 1) Token
    # 2) Count = 0
    # 3) Randomly selected word
    user_state = UserState.create(params[:name])

    # Return the token
    { :token => user_state.token, :count => user_state.count }.to_json
  end


  # Get the pass phrase
  get '/phrase' do
    # User state for the API
    user_state = UserState.load(params['token'])

    # Return the phass phrase
    { :phrase => user_state.phrase, :count => user_state.count }.to_json
  end


  # Get the pass phrase
  get '/guess' do
    # User state for the API
    user_state = UserState.load(params['token'])

    # Increment the guess counter
    user_state.count = user_state.count + 1

    # Save the UserState
    user_state.save
    
    gusses = params['guess'].split(' ')
    words  = user_state.words
    raise Exception, "gusses=#{params['guess']} doesn't match words phrase=#{user_state.phrase}" unless gusses.size == words.size
    
    # How many characters match?
    matches = 0
    0.upto(words.size-1) do |index|
      # How many characters match?
      matches = matches + words[index].chars_matching(gusses[index])
    end

    # Return the phass phrase
    { :matches => matches, :count => user_state.count }.to_json
  end
end
