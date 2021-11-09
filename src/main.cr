# require "toka"
require "./cli"
require "./requester"
require "./entity"
require "./generators"
require "colorize"
require "csv"

cli = Cli.new

csv = nil
cli.options.csv.try do |filename|
  csv = File.open(filename, "w")
end

case _command = cli.command
when Sub::Check
  Tme::Entity.from_strings(cli.args).each { |entity|
    process_entity entity.resolve, csv
  }
when Sub::Random
  i = 0
  loop {
    entity = Tme.random_entity.resolve
    process_entity entity, csv
    i += 1
    puts "Tried #{i}" if i % 100 == 0
  }
when Sub::Mutate
  mutations = Tme.generate_mutations(cli.args[0][1..], _command.extended)
  Tme::Requester.new(mutations.each).each do |entity|
    process_entity entity, csv
  end
else
  puts "Unknown command"
  exit 1
end

def process_entity(entity : Tme::Entity, csv : IO | Nil = nil)
  case entity
  when Tme::Unknown
    puts entity.format("✗ @%{id} %{type}").colorize.red
  else
    puts entity.format("✓ @%{id} %{type}").colorize.green
  end
  entity.to_csv csv
end
