# Gemfile
require "rubygems"
require "bundler/setup"
require "sinatra"
require "sinatra/json"
require "json/pure"

require "app"
 
set :run, false
set :raise_errors, true
 
run YahooDictionary
