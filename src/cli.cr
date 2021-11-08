require "option_parser"

class Cli
  getter options : CommonOptions
  getter command : Subcommand

  def initialize
    @options = CommonOptions.new
    command : Subcommand | Nil = nil

    OptionParser.parse do |parser|
      parser.banner = "Usage: tmetoo {COMMAND} [ARGUMENTS]"
      parser.on("-c FILE", "--csv=FILE", "Specifies csv file name to write results into") { |fname|
        @options.csv = fname
      }
      parser.on("-v", "--verbose", "Enabled verbose output") {
        @options.verbose = true
      }
      parser.on("-h", "--help", "Print this help") {
        puts parser
        exit
      }

      parser.on("check", "Checks usernames") {
        command = _command = Sub::Check.new
        parser.banner = "Usage: tmetoo check [OPTIONS] {@username | filename}..."
      }

      parser.on("mutate", "Mutates username and checks them") {
        command = _command = Sub::Mutate.new
        parser.banner = "Usage: tmetoo mutate [OPTIONS] @username"
        parser.on("-e", "--extended", "Make more mutations") {
          _command.extended = true
        }
        parser.on("-n", "--numbers", "Try add numbers at the end") {
          _command.numbers = true
        }
      }

      parser.on("random", "Checks absolutely random usernames") {
        command = _command = Sub::Random.new
        parser.banner = "Usage: tmetoo random [OPTIONS]"
      }
    end

    if command.nil?
      puts "Unknown command. Run tmetoo --help to get help"
      exit 1
    else
      @command = command.not_nil!
    end
  end
end

struct CommonOptions
  property csv : String?
  property verbose : Bool = false
end

class Subcommand
end

module Sub
  class Check < Subcommand
  end

  class Mutate < Subcommand
    property extended : Bool = false
    property numbers : Bool = false
  end

  class Random < Subcommand
  end
end
