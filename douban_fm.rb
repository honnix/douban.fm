require 'net/http'
require 'json'

class DoubanFM
  def initialize(email, password)
    @email = email
    @password = password
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
    if not @current_playlist['err'].nil?
      login
      get_next_playlist
    end
  end

  def play_current_playlist
    
  end
end

if __FILE__ == $PROGRAM_NAME
  douban_fm = DoubanFM.new('xxx', 'xxx')
  douban_fm.login
  douban_fm.get_channels
  douban_fm.select_channel(0)
  douban_fm.get_next_playlist
end
