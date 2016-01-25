require 'thread'
require 'etc'
require 'net/ssh'
require 'colored'

module Conn
  module DSL
    def ssh(hostname, &blk)
      config = Net::SSH::Config.for(hostname)
      user = config[:user] || Etc.getlogin
      queue = Queue.new
      cmd_loop = Thread.new do
        blk.call(queue)
        queue.respond_to?(:close) ? queue.close : (queue << false)
      end
      Net::SSH.start(hostname, user, config) do |ssh|
        ssh.loop do
          msg = queue.pop
          if msg
            input(msg)
            ssh.exec!(msg) do |chan, stream, data|
              if stream == :stdout
                stdout(data)
              else
                stderr(data)
              end
            end
            true
          else
            false
          end
        end
      end
      cmd_loop.join if cmd_loop.alive?
    end

    def input(str)
      puts "%s %s" % ["SSH<<".green.bold, str.yellow]
    end

    def stdout(str)
      puts "%s %s" % ["SSH>>".magenta.bold, str.cyan]
    end

    def stderr(str)
      puts "%s %s" % ["SSH!>".red.bold, str.red]
    end
  end

  extend DSL
end
