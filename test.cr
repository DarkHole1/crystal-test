class A
  def initialize(@a : String)
  end
end

class B
  def initialize(@a : String)
  end
end

a : A | B = B.new("B")

case a
when A
  puts "A"
when B
  puts "B"
end
