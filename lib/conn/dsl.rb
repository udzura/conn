require 'thread'
require 'etc'
require 'net/ssh'
require 'colored'

require 'conn/pty_ssh'

module Conn
  module DSL
    def ssh(hostname, &blk)
      queue = Queue.new
      cmd_loop = Thread.new do
        blk.call(queue)
        queue.respond_to?(:close) ? queue.close : (queue << false)
      end
      Net::SSH.start(*to_ssh_config(hostname)) do |ssh|
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

    def ssh_try!(hostname)
      Net::SSH.start(*to_ssh_config(hostname, timeout: 3)) do |ssh|
        ssh.exec! 'uptime'
      end
    end

    def ssh_try(hostname)
      ssh_try!(hostname)
    rescue => e
      false
    end

    private
    def to_ssh_config(hostname, **opts)
      config = Net::SSH::Config.for(hostname).merge(opts)
      user = config[:user] || Etc.getlogin
      [hostname, user, config]
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

    public
    using Conn::PtySSH
    def ssh_pty(hostname, &blk)
      queue = Queue.new
      cmd_loop = Thread.new do
        blk.call(queue)
        queue.respond_to?(:close) ? queue.close : (queue << false)
      end
      Net::SSH.start(*to_ssh_config(hostname)) do |ssh|
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
  end

  extend DSL
end
