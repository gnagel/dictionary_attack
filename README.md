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
phrases     = ............. ................. .....
phrases_[0] = .............
phrases_[1] = .................
phrases_[2] = .....
Found match = 'instructively unsusceptibleness acara', in attempts=27

...

words.count = 234371
phrases     = ........ ............. .............
phrases_[0] = ........
phrases_[1] = .............
phrases_[2] = .............
Found match = 'meekling pentaspermous wordsworthian', in attempts=37

=========================
Avg Attempts/Word = 14.2758620689655

Total Dict Words  = 234371
Total Attempts    = 414
Total Phrases     = 29
=========================

```
