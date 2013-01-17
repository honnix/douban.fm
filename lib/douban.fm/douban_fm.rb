module DoubanFM
  require 'net/http'
  require 'json'

  class DoubanFM
    attr_reader :waiting

    def initialize(email, password)
      @email = email
      @password = password
      @semaphore = Mutex.new
      @waiting = false # read this to determin whether to get one more playlist
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

    def get_channels
      uri = URI('http://www.douban.com/j/app/radio/channels')
      res = Net::HTTP.get(URI('http://www.douban.com/j/app/radio/channels'))
      @channels = JSON.parse(res)
    end

    def select_channel(channel_num)
      @current_channel = channel_num
    end

    def get_next_playlist
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

      unless @current_playlist['err'].nil?
        raise @current_playlist
      end
    end

    def play_current_playlist
      @continue = true

      Thread.new do
        @waiting = false

        @current_playlist['song'].each do |song|
          @semaphore.lock

          unless @continue
            @semaphore.unlock
            break
          end

          @player_pid = spawn("mpg123 #{song['url']}")

          @semaphore.unlock

          Process.wait
        end

        @waiting = @continue
        yield @waiting if block_given?
      end
    end

    def stop
      @semaphore.synchronize do
        @continue = false

        begin
          Process.kill(9, @player_pid)
        rescue Errno::ESRCH
        end
      end
    end
  end  
end
