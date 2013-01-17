# Douban.fm

Play music from douban.fm.

__Note that this project is still on-going, so I will only try my best to stablize the interface.__

## Installation

Add this line to your application's Gemfile:

    gem 'douban.fm'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install douban.fm

## Usage

<pre>
$ douban.fm -h

Usage: douban.fm [OPTIONS]
    -u, --user email                 douban.fm account name, normally an email address
                                     if not provided, will play anonymous playlist
    -p, --password [password]        douban.fm account password
                                     if not provided, will be asked
    -m, --mpd                        do not play by it own, send playlist to Music Player Daemon
    -c, --channel channel            which channel to play
                                     if not provided, channel 0 will be selected but who knows what it is
    -l, --list                       list all available channels
    -v, --verbose                    verbose mode
    -h, --help                       show this message
</pre>

Basically there are two ways to play music

1. to play direclty by `mpg123`

    Under this mode, music will be played by forking `mpg123` directly. Sorry currently there is no way to configure which music player to use.

    * `douban.fm` will play anonymous playlist of channel 0
    * `douban.fm -c 1` will play channel 1
    * `douban.fm -u xxx@xxx.com -p xxx` will play private playlist
    * `douban.fm -u xxx@xxx.com -p xxx -c 1` will play channel 1 but with your account signed in
    * `douban.fm -u xxx@xx.com -p` will play private playlist but will ask for your password to sign in

2. to play by [Music Player Daemon](http://mpd.wikia.com/wiki/Music_Player_Daemon_Wiki)

    Under this mode, URL of music will be sent to MPD which will actually play. Whenever there are less than _10_ songs in MPD playlist, more will be retrieved from douban.fm.

    It is fantastic to use MPD since there are quite many [clients](http://mpd.wikia.com/wiki/Clients) to use. I am now just use my iPhone with [MPoD2](http://mpd.wikia.com/wiki/Client:MPoD2).

    * `douban.fm -m` will play anonymous playlist of channel 0
    * `douban.fm -m -c 1` will play channel 1
    * `douban.fm -m -u xxx@xxx.com -p xxx` will play private playlist
    * `douban.fm -m -u xxx@xxx.com -p xxx -c 1` will play channel 1 but with your account signed in
    * `douban.fm -m -u xxx@xx.com -p` will play private playlist but will ask for your password to sign in

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
