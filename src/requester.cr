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

    def self.by_chunks(arr : Array(NotChecked), size = 300, &block : Entity ->)
      arr.each_slice(size).map do |chunk|
        start = Time.monotonic
        fmap(chunk) do |entity|
          response = HTTP::Client.get "https://t.me/#{entity.id}"
          Parser.parse response.body, entity.id
        end.each &block
        diff = Time.monotonic - start
        sleep(1.minute - diff) if diff < 1.minute
      end
    end

    private def self.fmap(arr : Array(T), &block : T -> U) forall T, U
      res = Array(U).new arr.size
      chan = ::Channel(U).new
      arr.each do |e|
        spawn do
          chan.send(block.call(e))
        end
      end

      count = 0
      while count < arr.size
        res <<= chan.receive
        count += 1
      end
      res
    end
  end

end

class Array(T)
  def resolve(size = 300, &block : Tme::Entity ->)
    Tme::Requester.by_chunks(self, size, &block)
  end
end
