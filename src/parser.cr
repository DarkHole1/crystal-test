require "colorize"
require "html5"

module Tme
  module Entity
    getter id : String

    def link
      "https://t.me/#{@id}"
    end
  end

  class Unknown
    include Entity

    def initialize(@id : String)
    end
  end

  class User
    include Entity
    getter title : String
    getter description : String

    def initialize(@id : String, @title : String, @description : String)
    end
  end

  class Channel
  include Entity
    getter title : String
    getter description : String
    getter members : String

    def initialize(@id : String, @title : String, @description : String, @members : String | Nil)
    end
  end

  class Group
  include Entity
    getter title : String
    getter description : String
    getter members : String

    def initialize(@id : String, @title : String, @description : String, @members : String)
    end
  end

  class Parser
    def self.parse(data : String, id : String) : Entity | Nil
      html = HTML5.parse data

      type_link = html.xpath("//a[contains(@class,'tgme_action_button_new')]")
      button_link = html.xpath("//a[contains(@class,'tgme_action_button_new')][2]")
      members_str = html.xpath("//div[contains(@class,'tgme_page_extra')]")
      title = html.xpath("//div[contains(@class,'tgme_page_title')]")
      description = html.xpath("//div[contains(@class,'tgme_page_description')]")

      return Unknown.new(id) if type_link.nil? || title.nil?

      entity_type = begin
        unless button_link.nil?
          :channel
        else
          case
          when !members_str.nil? && members_str.inner_text.includes? "members"
            :group
          when type_link.inner_text.includes? "Send Message"
            :user
          else
            :unknown
          end
        end
      end

      if description.nil?
        desc = ""
      else
        desc = description.inner_text
      end

      case entity_type
      when :user
        User.new(id, title.inner_text, desc)
      when :group
        Group.new(id, title.inner_text, desc, parse_members members_str)
      when :channel
        Channel.new(id, title.inner_text, desc, parse_members members_str)
      else
        Unknown.new(id)
      end
    end

    private def self.parse_members(members : HTML5::Node | Nil) : String
      unless members.nil?
        m = /\d+/.match(members.inner_text)
        return m[0] unless m.nil?
      end
      ""
    end
  end
end
