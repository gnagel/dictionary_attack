# Setup your environment
```
$ git clone git://github.com/gnagel/dictionary_attack.git
$ cd dictionary_attack
$ bundle install 
- or - 
$ sudo bundle install (if you don't have RVM or the correct permissions)
```


# Start the App in a new tab
```
$ cd dictionary_attack
$ rackup
```


# Run the script in a new tab
```
$ cd dictionary_attack
$ ruby run.rb
```


# Example output
```
words.count = 234371
phrases     = ......... ..........
phrases_[0] = .........
phrases_[1] = ..........
Found match = 'gustation episodical', in attempts=24

...

words.count = 234371
phrases     = ........... ........
phrases_[0] = ...........
phrases_[1] = ........
Found match = 'prochondral yotacize', in attempts=22

=========================
Avg Attempts/Word = 13.4285714285714
Total Phrases     = 28
Total Attempts    = 376
=========================

```
