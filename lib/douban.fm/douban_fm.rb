module DoubanFM
  require 'net/http'
  require 'json'
  require 'ruby-mpd'
  require 'date'

  class DoubanFM
    # DOUBAN_FM_MPD_PLAYLIST = 'douban.fm'
    MIN_SONGS_IN_DOUBAN_FM_MPD_PLAYLIST = 10

    RANDOM_CHANNEL_ID = -1

    attr_reader :waiting, :channels, :current_channel, :kbps, :liked_songs

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
      res = get_http_client().post_form(uri,
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
      today = Date.new
      if today != @last_fetching_channels_date
        uri = URI('http://www.douban.com/j/app/radio/channels')
        res = get_http_client().get(uri)
        @channels = JSON.parse(res)

        @last_fetching_channels_date = today
      else
        @logger.log('use channels in cache')
      end

      @logger.log("raw channel list #{channels}")
    end

    def fetch_liked_songs(count)
      uri = URI('http://www.douban.com/j/app/radio/liked_songs')
      params = {
          :app_name => 'radio_desktop_mac',
          :version => '100',
          :user_id => @user_info['user_id'],
          :expire => @user_info['expire'],
          :token => @user_info['token'],
          :count => count,
          :exclude => ''
      }
      uri.query = URI.encode_www_form(params)
      res = get_http_client().get_response(uri)
      @liked_songs = JSON.parse(res.body)
      @logger.log("liked songs #{@liked_songs}")

      unless @liked_songs['err'].nil?
        raise @liked_songs
      end
    end

    def select_channel(channel_num)
      @current_channel = channel_num
    end

    def set_kbps(kbps)
      @kbps = kbps
    end

    def fetch_next_playlist
      if @current_channel == RANDOM_CHANNEL_ID
        channel_id = select_random_channel
      else
        channel_id = @current_channel
      end

      @logger.log("now fetch next playlist from channel #{channel_id}")

      uri = URI('http://www.douban.com/j/app/radio/people')
      params = {
        :app_name => 'radio_desktop_mac',
        :version => "100",
        :user_id => @user_info['user_id'],
        :expire => @user_info['expire'],
        :token => @user_info['token'],
        :sid => '',
        :h => '',
        :channel => channel_id,
        :type => 'n',
        :kbps => @kbps
      }
      @logger.log(params)
      uri.query = URI.encode_www_form(params)
      res = get_http_client().get_response(uri)

      @current_playlist = JSON.parse(res.body)

      @logger.log("raw playlist #{@current_playlist}")

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
      if host.nil?
        host = 'localhost'
      end
      if port.nil?
        port = 6600
      end

      mpd = MPD.new(host, port)

      @logger.log("connecting to mpd at #{host}:#{port}")

      mpd.connect

      # remove after played
      mpd.consume = 1

      # unfortunately it is not the same as i thought.
      # i can not create a playlist specially for douban.fm since
      # mpd will not remove song from this playlist anyway which
      # means there is no chance for me to detect the total number
      # of songs in the playlist is below a threshhold.
      # so before i can find any better solution, just make use
      # of the default playlist which is dynamic.

      # begin
      #   songs = mpd.send_command(:listplaylistinfo, DOUBAN_FM_MPD_PLAYLIST)
      #   if songs.is_a? String
      #     total = 1
      #   else
      #     total = songs.length
      #   end
      # rescue
      #   total = 0
      # end

      total = mpd.status[:playlistlength]

      @logger.log("current total number of songs in mpd #{total}")

      added = false

      if total < MIN_SONGS_IN_DOUBAN_FM_MPD_PLAYLIST
        # douban_fm_playlist = MPD::Playlist.new(mpd, {:playlist => DOUBAN_FM_MPD_PLAYLIST})

        begin
          @logger.log('fetch next playlist')

          fetch_next_playlist
        rescue
          @logger.log('session expired, relogin')

          login

          @logger.log('fetch next playlist')

          fetch_next_playlist
        end

        add_current_playlist_to_mpd(mpd)

        added = true
      end

      mpd.disconnect

      added
    end

    def clear_mpd_playlist(host = 'localhost', port = 6600)
      if host.nil?
        host = 'localhost'
      end
      if port.nil?
        port = 6600
      end

      mpd = MPD.new(host, port)

      @logger.log("connecting to mpd at #{host}:#{port}")

      mpd.connect

      @logger.log('crop or clear current playlist')

      status = mpd.status
      mpd.clear # this will stop mpd if it is playing

      fetch_next_playlist
      add_current_playlist_to_mpd(mpd)

      if status[:state] == :play
        mpd.play
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

    private
    def get_http_client
      proxy = ENV['HTTP_PROXY'] || ENV['HTTPS_PROXY']
      unless proxy.nil?
        m = proxy.match(/http(s)?:\/\/(?<proxy_addr>.*):(?<proxy_port>[0-9]*)/)
        get_http_client()::Proxy(m['proxy_addr'], m['proxy_port'])
      else
        get_http_client()
      end
    end

    def add_current_playlist_to_mpd(mpd)
      @logger.log("add more songs to mpd")

      @current_playlist['song'].each do |song|
        @logger.log("send [#{song['url'].gsub('\\', '')}] to mpd")

        mpd.add(song['url'].gsub('\\', ''))
      end
    end

    # currently not used
    def crop(mpd, status)
      total = status[:playlistlength]
      current = status[:song]

      total.downto(current + 2) do |i|
        mpd.delete(i)
      end
      current.downto(1) do |i|
        mpd.delete(i)
      end
    end

    def select_random_channel
      fetch_channels

      channels = @channels['channels']
      which = Random.new.rand(0 ... channels.size)
      channels[which]['channel_id']
    end
  end  
end
