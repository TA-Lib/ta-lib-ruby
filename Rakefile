# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

require "rubocop/rake_task"

RuboCop::RakeTask.new

task default: %i[spec rubocop]

namespace :doc do
  desc "Start a local server to view RDoc documentation"
  task :server do
    require "webrick"
    server = WEBrick::HTTPServer.new(
      Port: 8808,
      DocumentRoot: File.expand_path("./doc"),
      AccessLog: [],
      Logger: WEBrick::Log.new(File::NULL)
    )

    puts "Documentation server started at http://localhost:8808"
    puts "Press Ctrl+C to stop"

    trap("INT") { server.shutdown }
    server.start
  end
end
