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
    -r, --remote remote              mpd remote host, in format of <IP>:<Port>
    -c, --channel channel            which channel to play
                                     if not provided, channel 0 will be selected but who knows what it is
    -l, --list                       list all available channels
    -i, --interaction [port]         start an http server for interaction
                                     if omit port, 3000 will be used by default
                                     GET /channels to get all available channels
                                     GET /now to get current playing channel
                                     GET /channel/<id> to switch to channel of the specified id
    -V, --verbose                    verbose mode
    -v, --version                    show current version
    -h, --help                       show this message
</pre>

Basically there are two ways to play music

* to play direclty by `mpg123`

    Under this mode, music will be played by forking `mpg123` directly. Sorry currently there is no way to configure which music player to use.

    * `douban.fm` will play anonymous playlist of channel 0
    * `douban.fm -c 1` will play channel 1
    * `douban.fm -u xxx@xxx.com -p xxx` will play private playlist
    * `douban.fm -u xxx@xxx.com -p xxx -c 1` will play channel 1 but with your account signed in
    * `douban.fm -u xxx@xx.com -p` will play private playlist but will ask for your password to sign in

* to play by [Music Player Daemon](http://mpd.wikia.com/wiki/Music_Player_Daemon_Wiki)

    Under this mode, URL of music will be sent to MPD which will actually play. Whenever there are less than _10_ songs in MPD playlist, more will be retrieved from douban.fm.

    It is fantastic to use MPD since there are quite many [clients](http://mpd.wikia.com/wiki/Clients) to use. I am now just use my iPhone with [MPoD2](http://mpd.wikia.com/wiki/Client:MPoD2).

    Thanks for @tdsparrow pointing out MPD, otherwise I might have been doing some really stupid things.

    * `douban.fm -m` will play anonymous playlist of channel 0
    * `douban.fm -m -c 1` will play channel 1
    * `douban.fm -m -u xxx@xxx.com -p xxx` will play private playlist
    * `douban.fm -m -u xxx@xxx.com -p xxx -c 1` will play channel 1 but with your account signed in
    * `douban.fm -m -u xxx@xx.com -p` will play private playlist but will ask for your password to sign in
    * if "-m -i" is provided, a web server will start listening on 3000 by default, and you may
        * GET /channels to get all available channels
        * GET /now to get current playing channel
        * GET /channel/<id> to switch to channel of the specified id

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
