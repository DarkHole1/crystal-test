require "http/client"
require "benchmark"

def fmap(arr : Array(T), &block : T -> T) forall T
  res = Array(T).new arr.size, ""
  chan = Channel(T).new
  arr.each { |e|
    spawn {
      chan.send(block.call(e))
    }
  }
  count = 0
  while count < arr.size
    res[count] = chan.receive
    count += 1
  end
  res
end

arr = %w[darkhole1] * 150
# p! arr
Benchmark.bm { |x|
  x.report("fiber map") {
    r = fmap(arr) { |s|
      HTTP::Client.get("https://t.me/#{s}").body
    }
  }

  x.report("simple map") {
    r = arr.each { |s|
      HTTP::Client.get("https://t.me/#{s}").body
    }
  }
}
# p! r
