require 'cgi'

class YoutubeUrl
  def self.parse_map(encoded_stream_map)
    encoded_stream_map.split(',').map { |part| self.new(part) }
  end

  def initialize(encoded_stream)
    @encoded_stream = encoded_stream
  end

  def download_url
    url = param('url')
    if sig = param('sig')
      url + "&signature=" + sig
    elsif s = param('s')
      sig = s[6, 1] + s[1, 2] + s[62, 1] + s[7,36] +
        s[0,1] + s[56,1] + s[45,11] + s[43,1] + s[57,5] +
        s[3,1] + s[63,21];
      url + "&signature=" + sig
    else
      raise "No signature in #{@encoded_stream}"
    end
  end

  def itag
    itag = param('itag')
    if itag
      itag.to_i
    else
      raise "No itag in #{@encoded_stream}"
    end
  end

  # http://en.wikipedia.org/wiki/YouTube
  def video_resolution
    res = {
      5   => 240,
      6   => 270,
      13  => 0,
      17  => 144,
      18  => 360,
      22  => 720,
      34  => 360,
      35  => 480,
      36  => 240,
      37  => 1080,
      38  => 3072,
      43  => 360,
      44  => 480,
      45  => 720,
      46  => 1080,
      82  => 360,
      83  => 240,
      84  => 720,
      85  => 520,
      100 => 360,
      101 => 360,
      102 => 720,
      120 => 720,
    }[itag]
    if res
      res
    else
      raise "Unknown itag #{itag} in #{@encoded_stream}"
    end
  end

  def ext
    case itag
    when 5, 6, 34, 36, 120
      'flv'
    when 13, 17, 36
      '3gp'
    when 18, 22, 37, 38, 82, 83, 84, 85
      'mp4'
    when 43, 44, 45, 46, 100, 101, 102
      'webm'
    else
      raise "Unknown itag #{itag} in #{@encoded_stream}"
    end
  end

  def param(name)
    params[name].first
  end

  def params
    CGI.parse(@encoded_stream)
  end
end
