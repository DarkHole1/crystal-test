require "./entity"
require "html5"

module Tme
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
        User.new(id, title.inner_text.strip, desc)
      when :group
        Group.new(id, title.inner_text.strip, desc, parse_members members_str)
      when :channel
        Channel.new(id, title.inner_text.strip, desc, parse_members members_str)
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
