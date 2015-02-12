require 'uri'
require 'net/http'

module Phoebo
  class Ping
    def self.send(request, configs)
      payload = {
        id: request.id,
        tasks: []
      }

      configs.each do |config|
        payload[:tasks] += config.tasks
      end

      uri = URI(request.ping_url)
      req = Net::HTTP::Post.new(uri, {'Content-Type' =>'application/json'})
      req.body = payload.to_json
      res = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(req)
      end
    end
  end
end