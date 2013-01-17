module DoubanFM
  require 'net/http'
  require 'json'
  require 'ruby-mpd'

  class DoubanFM
    DOUBAN_FM_MPD_PLAYLIST = 'douban.fm'
    MIN_SONGS_IN_DOUBAN_FM_MPD_PLAYLIST = 10

    attr_reader :waiting, :channels, :current_playlist

    def initialize(logger = DummyLogger.new, email = '', password = '')
      @logger = logger
      @email = email
      @password = password
      @semaphore = Mutex.new
      @waiting = false # read this to determin whether to fetch one more playlist
      @user_info = {'user_id' => '', 'expire' => '', 'token' => ''}
    end

    def login
      uri = URI('http://www.douban.com/j/app/login')
      res = Net::HTTP.post_form(uri,
                                'email' => @email,
                                'password' => @password,
                                'app_name' => 'radio_desktop_mac',
                                'version' => '100')
      @user_info = JSON.parse(res.body)
      if @user_info['err'] != 'ok'
        raise @user_info["err"]
      end
    end

    def fetch_channels
      uri = URI('http://www.douban.com/j/app/radio/channels')
      res = Net::HTTP.get(uri)
      @channels = JSON.parse(res)

      @logger.log("raw channel list #{channels}")
    end

    def select_channel(channel_num)
      @current_channel = channel_num
    end

    def fetch_next_playlist
      uri = URI('http://www.douban.com/j/app/radio/people')
      params = {
        :app_name => 'radio_desktop_mac',
        :version => "100",
        :user_id => @user_info['user_id'],
        :expire => @user_info['expire'],
        :token => @user_info['token'],
        :sid => '',
        :h => '',
        :channel => @current_channel,
        :type => 'n'
      }
      uri.query = URI.encode_www_form(params)
      res = Net::HTTP.get_response(uri)

      @current_playlist = JSON.parse(res.body)

      @logger.log("raw playlist #{current_playlist}")

      unless @current_playlist['err'].nil?
        raise @current_playlist
      end
    end

    def play
      @continue = true

      Thread.new do
        @waiting = false

        @current_playlist['song'].each do |song|
          @semaphore.lock

          unless @continue
            @semaphore.unlock
            break
          end

          @player_pid = spawn("mpg123 #{song['url']} > /dev/null 2>&1")

          @semaphore.unlock

          @logger.log("playing song \"#{song['title']}\"")

          Process.wait
        end

        @waiting = @continue
        yield @waiting if block_given?
      end
    end

    def add_to_mpd(host = 'localhost', port = 6600)
      mpd = MPD.new(host, port)
      mpd.connect

      begin
        songs = mpd.send_command(:listplaylistinfo, DOUBAN_FM_MPD_PLAYLIST)
        if songs.is_a? String
          total = 1
        else
          total = songs.length
        end
      rescue
        total = 0
      end

      @logger.log("current total number of songs in mpd #{total}")

      if total < MIN_SONGS_IN_DOUBAN_FM_MPD_PLAYLIST
        douban_fm_playlist = MPD::Playlist.new(mpd, {:playlist => DOUBAN_FM_MPD_PLAYLIST})

        begin
          @logger.log('fetch next playlist')

          fetch_next_playlist
        rescue
          @logger.log('session expired, relogin')

          login

          @logger.log('fetch next playlist')

          fetch_next_playlist
        end

        @logger.log("add more songs to mpd")

        @current_playlist['song'].each do |song|
          @logger.log("send [#{song['url'].gsub('\\', '')}] to mpd")

          douban_fm_playlist.add(song['url'].gsub('\\', ''))
        end
      end

      mpd.disconnect
    end

    def stop
      @semaphore.synchronize do
        @continue = false

        begin
          Process.kill(9, @player_pid) unless @player_pid.nil?
        rescue Errno::ESRCH
        end
      end
    end
  end  
end
