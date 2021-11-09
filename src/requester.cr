require "http/client"
require "./parser"

module Tme
  class Requester
    include Iterator(Entity)
    @@count = 0
    @@start_time = Time.monotonic

    def initialize(@ids : Iterator(String))
    end

    def next
      id = @ids.next
      return id if id.is_a? Iterator::Stop
      
      Requester.get id
    end

    def self.get(id : String)
      if @@count >= 300
        diff = Time.monotonic - @@start_time
        # puts "Limit reached #{diff}"
        sleep(1.minute - diff) if diff < 1.minute
        @@count = 0
        @@start_time = Time.monotonic
      end

      @@count += 1
      response = HTTP::Client.get "https://t.me/#{id}"
      Parser.parse response.body, id
    end
  end
end
