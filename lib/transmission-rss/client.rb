require 'net/http'
require 'json'
require 'timeout'
require 'base64'

# TODO
#  * Why the hell do timeouts in get_session_id and add_torrent not work?!

# Class for communication with transmission utilizing the RPC web interface.
class TransmissionRSS::Client
  def initialize(host = 'localhost', port = 9091)
    @host, @port = host, port
    @log = Log.instance
  end

  # Get transmission session id by simple GET.
  def get_session_id
    get = Net::HTTP::Get.new '/transmission/rpc'

    response = request get

    id = response.header['x-transmission-session-id']

    @log.debug 'got session id ' + id

    id
  end

  # POST json packed torrent add command.
  def add_torrent(file, type, paused = false)
    hash = {
      'method' => 'torrent-add',
      'arguments' => {
        'paused' => paused
      }
    }

    case type
      when :url
        hash.arguments.filename = file
      when :file
        hash.arguments.metainfo = Base64.encode64 File.readlines(file).join
      else
        raise ArgumentError.new 'type has to be :url or :file.'
    end

    post = Net::HTTP::Post.new \
      '/transmission/rpc',
      initheader = {
        'Content-Type' => 'application/json',
        'X-Transmission-Session-Id' => get_session_id
      }

    post.body = hash.to_json

    response = request post

    result = JSON.parse(response.body).result

    @log.debug 'add_torrent result: ' + result
  end

  private

  def request(data)
#   retries = 3
#   begin
#     Timeout::timeout(5) do
        Net::HTTP.new(@host, @port).start do |http|
          http.request data
        end
#     end
#   rescue Timeout::Error
#     puts('timeout error exception') if($verbose)
#     if(retries > 0)
#       retries -= 1
#       puts('addTorrent timeout. retry..') if($verbose)
#       retry
#     else
#       $stderr << "timeout http://#{@host}:#{@port}/transmission/rpc"
#     end
#   end
  end
end
