#!/usr/bin/env ruby

module Hotdog
  module Commands
    class Hosts < BaseCommand
      def run(args=[], options={})
        if args.empty?
          result = execute("SELECT id FROM hosts").to_a.reduce(:+)
          show_hosts(result)
        else
          if args.any? { |host_name| glob?(host_name) }
            result = args.flat_map { |host_name|
              execute("SELECT id FROM hosts WHERE LOWER(name) GLOB LOWER(?);", [host_name]).to_a.reduce(:+) || []
            }
          else
            sqlite_limit_compound_select = options[:sqlite_limit_compound_select] || SQLITE_LIMIT_COMPOUND_SELECT
            result = args.each_slice(sqlite_limit_compound_select).flat_map { |args|
              execute("SELECT id FROM hosts WHERE name IN (%s);" % args.map { "?" }.join(", "), args).to_a.reduce(:+) || []
            }
          end
          if result.empty?
            STDERR.puts("no match found: #{args.join(" ")}")
            exit(1)
          else
            show_hosts(result)
            logger.info("found %d host(s)." % result.length)
            if result.length < args.length
              STDERR.puts("insufficient result: #{args.join(" ")}")
              exit(1)
            end
          end
        end
      end

      def show_hosts(hosts)
        result, fields = get_hosts(hosts || [])
        STDOUT.print(format(result, fields: fields))
      end
    end
  end
end

# vim:set ft=ruby :
