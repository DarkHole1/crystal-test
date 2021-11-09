require "./requester"

module Tme
  module Entity
    getter id : String
    getter type : String

    def link
      "https://t.me/#{@id}"
    end

    def self.from_string(s : String) : Array(NotChecked)
      case
      when s.starts_with? '@'
        [NotChecked.new s[1..]]
      when File.exists? s
        File.read_lines(s).map { |s| NotChecked.new s }
      else
        [] of NotChecked
      end
    end

    def self.from_strings(ss : Array(String)) : Array(NotChecked)
      ss.map { |s| Entity.from_string s }.flatten
    end

    def format(s : String) : String
      s % {
        id: @id,
        link: link,
        type: @type
      }
    end
  end

  class NotChecked
    include Entity

    def initialize(@id : String)
      @type = "not checked"
    end

    def resolve() : Entity
      Requester.get(@id)
    end
  end

  class Unknown
    include Entity

    def initialize(@id : String)
      @type = "unknown"
    end
  end

  class User
    include Entity
    getter title : String
    getter description : String

    def initialize(@id : String, @title : String, @description : String)
      @type = "user"
    end
  end

  class Channel
    include Entity
    getter title : String
    getter description : String
    getter members : String

    def initialize(@id : String, @title : String, @description : String, @members : String | Nil)
      @type = "channel"
    end
  end

  class Group
    include Entity
    getter title : String
    getter description : String
    getter members : String

    def initialize(@id : String, @title : String, @description : String, @members : String)
      @type = "group"
    end
  end
end
