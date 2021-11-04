require "toka"
require "./requester"
require "random"
require "csv"

class Cli
  Toka.mapping({
    command_help: {
      type:        Bool,
      default:     false,
      description: "Show help for command",
    },
    csv: {
      type:        String?,
      description: "Path to csv file for output",
    },
    extended: {
      type: Bool,
      default: false,
      description: "Extended mode generation for mutate mode"
    }
  }, {
    banner: "Usage: anytme {check | random | mutate} [options] params...\n\nOptions:\n",
    footer: "\nWrite command name with --command-help for additional help",
  })
end

opts = Cli.new
csv = nil
unless opts.csv.nil?
  csv_file = File.open(opts.csv.not_nil!, "w")
  csv = CSV::Builder.new(csv_file)
  at_exit {
    csv_file.close()
  }
end

if opts.positional_options.size < 1
  puts Toka::HelpPageRenderer.new(Cli, true)
  exit 1
end
case opts.positional_options[0]
when "check"
  if opts.command_help
    puts "Usage: anytme check {@username | filename}..."
    puts <<-STRING

        This command check entity existence and type. If option starts with @,
        it is treated as username. In other case, it's treated as file where each
        line is a username. You can specify multiply options per time.
    STRING
    exit
  end
  opts.positional_options[1..].each { |option|
    if option.starts_with? '@'
      process_entity Tme::Requester.get(option[1..]), true, csv
    else
      Tme::Requester.new(File.read_lines(option).each).each { |e| process_entity e, true, csv }
    end
  }
when "random"
  if opts.command_help
    puts "Usage: anytme random"
    puts <<-STRING

        This command generates random username and then checks it. It generates
        more uniform distribution than tmesca. You can use --verbose option for
        showing unsuccesful attempts. You can use --csv option too.
    STRING
    exit
  end
  i = 0
  loop {
    entity = Tme::Requester.get generate_random_username
    process_entity entity, false
    i += 1
    puts "Tried #{i}" if i % 100 == 0
    # break if i == 299
  }
when "mutate"
  if opts.command_help || opts.positional_options.size < 2
    puts "Usage: anytme mutate @username"
    puts <<-STRING

        This command generates usernames from username with mutations known as
        leetspeak and then checks it.You can use --csv option to save results in
        csv.
    STRING
    exit
  end

  if opts.extended
    mutations = generate_mutations_extended(opts.positional_options[1][1..])
  else
    mutations = generate_mutations(opts.positional_options[1][1..])
  end
  Tme::Requester.new(mutations.each).each { |e| process_entity e, true, csv }
when "recursive"
  puts "Not implemented yet 🥲"
else
  puts "Unknown command"
  exit 1
end

def process_entity(entity, unknown = true, csv = nil)
  case entity
  when Tme::Channel
    puts "✓ @#{entity.id} channel".colorize.green
    csv.row("@#{entity.id}", "channel") unless csv.nil?
  when Tme::Group
    puts "✓ @#{entity.id} group".colorize.green
    csv.row("@#{entity.id}", "group") unless csv.nil?
  when Tme::User
    puts "✓ @#{entity.id} user".colorize.green
    csv.row("@#{entity.id}", "user") unless csv.nil?
  when Tme::Unknown
    if unknown
      puts "✗ @#{entity.id} not found".colorize.red
      csv.row("@#{entity.id}", "not found") unless csv.nil?
    end
  else
    puts "✗ [some error occured]".colorize.red
  end
end

ALPHABET_FIRST = ('a'..'z').to_a
ALPHABET_LAST  = ALPHABET_FIRST + ('0'..'9').to_a
ALPHABET       = ALPHABET_LAST + ['_']
PROB_TABLE     = [3.341185004830632e-41,
                  1.236238451787334e-39,
                  4.453799611439233e-38,
                  1.603401271968172e-36,
                  5.772247920270425e-35,
                  2.0780092847092026e-33,
                  7.480833428294315e-32,
                  2.6931000342193655e-30,
                  9.695160123193057e-29,
                  3.490257644349534e-27,
                  1.2564927519658324e-25,
                  4.523373907076997e-24,
                  1.628414606547719e-22,
                  5.862292583571788e-21,
                  2.1104253300858436e-19,
                  7.597531188309038e-18,
                  2.7351112277912534e-16,
                  9.846400420048513e-15,
                  3.544704151217464e-13,
                  1.2760934944382872e-11,
                  4.5939365799778334e-10,
                  1.65381716879202e-08,
                  5.953741807651273e-07,
                  2.1433470507544583e-05,
                  0.0007716049382716049,
                  0.027777777777777776,
                  1.0]

def generate_random_username
  r = Random.rand
  i = 0
  while PROB_TABLE[i] < r
    i += 1
  end
  l = 5 + i
  username : Array(Char) = [ALPHABET_FIRST.sample]
  (l - 2).times {
    username <<= ALPHABET.sample
  }
  username <<= ALPHABET_LAST.sample
  res = username.join
  if res.includes? "__"
    generate_random_username
  else
    res
  end
end

MUTS = {
  'a' => '4',
	'b' => '6',
	'e' => '3',
	'f' => '8',
	'g' => '9',
	'i' => '1',
	'l' => '1',
	'o' => '0',
	's' => '5',
	't' => '7',
	'z' => '2'
}

def generate_mutations(s : String) : Array(String)
  return [""] if s.size == 0
  return generate_mutations(s[1..]).map { |ss| s[0] + ss } unless MUTS.has_key? s[0]
  res = [] of String
  generate_mutations(s[1..]).each { |ss|
    res <<= s[0] + ss
    res <<= MUTS[s[0]] + ss
  }
  res
end

def generate_mutations_extended(s : String) : Array(String)
  arr = generate_mutations(s)
  res = [] of String
  subres = [] of String
  arr.each { |s|
    subres <<= s
    subres <<= "xxx" + s
    subres <<= "xxx_" + s
  }
  subres.each { |s|
    res <<= s
    res <<= s + "xxx"
    res <<= s + "_xxx"
  }
  res
end
