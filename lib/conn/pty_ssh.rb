if RUBY_VERSION < '2.1'
  require 'refinements'
end
require 'net/ssh/connection/session'

module Conn
  module PtySSH
    refine Net::SSH::Connection::Session do
      alias open_channel_orig open_channel
      def open_channel(type="session", *extra, &on_confirm)
        on_confirm_with_tty = Proc.new do |ch|
          ch.request_pty
          on_confirm.call(ch)
        end
        open_channel_orig(type, *extra, &on_confirm_with_tty)
      end

      def exec(command, &block)
        open_channel do |channel|
          channel.exec(command) do |ch, success|
            raise "could not execute command: #{command.inspect}" unless success

            channel.on_data do |ch2, data|
              if block
                block.call(ch2, :stdout, data)
              else
                $stdout.print(data)
              end
            end

            channel.on_extended_data do |ch2, type, data|
              if block
                block.call(ch2, :stderr, data)
              else
                $stderr.print(data)
              end
            end
          end
        end
      end

      def exec!(command, &block)
        block_or_concat = block || Proc.new do |ch, type, data|
          ch[:result] ||= ""
          ch[:result] << data
        end

        channel = exec(command, &block_or_concat)
        channel.wait

        channel[:result] ||= "" unless block

        return channel[:result]
      end
    end
  end
end
