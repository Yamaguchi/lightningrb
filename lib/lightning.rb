# frozen_string_literal: true

require 'lightning/version'

require 'ipaddr'
require 'pp'
require 'securerandom'

require 'algebrick'
require 'algebrick/serializer'
require 'bitcoin'
require 'bitcoin/grpc'
require 'byebug'
require 'concurrent'
require 'concurrent-edge'
require 'eventmachine'
require 'lightning/invoice'
require 'lightning/onion'
require 'noise'
require 'protobuf'

require 'extensions'

module Lightning
  autoload :Blockchain, 'lightning/blockchain'
  autoload :Channel, 'lightning/channel'
  autoload :Context, 'lightning/context'
  autoload :Crypto, 'lightning/crypto'
  autoload :Exceptions, 'lightning/exceptions'
  autoload :Feature, 'lightning/feature'
  autoload :Grpc, 'lightning/grpc'
  autoload :IO, 'lightning/io'
  autoload :NodeParams, 'lightning/node_params'
  autoload :Payment, 'lightning/payment'
  autoload :Router, 'lightning/router'
  autoload :Rpc, 'lightning/rpc'
  autoload :Store, 'lightning/store'
  autoload :Transactions, 'lightning/transactions'
  autoload :Utils, 'lightning/utils'
  autoload :Wire, 'lightning/wire'

  def self.start_server(context, port: 9735)
    host = '0.0.0.0'
    authenticator = IO::Authenticator.spawn(:authenticator)
    context.switchboard = IO::Switchboard.spawn(:switchboard, authenticator, context)
    Thread.start do
      EM.run do
        IO::Server.start(
          host,
          port,
          authenticator,
          context.node_params.private_key
        )
      end
    end
    Thread.start { Rpc::Server.run(context) }
  end

  def self.connect(context, public_key: '026a3648db07d42b9bc70845a54e7d6d728d084292c56ed163c678d1c296a55970')
    Thread.start do
      EM.run do
        context.switchboard << Lightning::IO::PeerEvents::Connect[public_key, '10.100.101.191', 9735]
      end
    end
  end

  def self.open(context, public_key: '026a3648db07d42b9bc70845a54e7d6d728d084292c56ed163c678d1c296a55970')
    Thread.start do
      EM.run do
        context.switchboard << Lightning::IO::PeerEvents::OpenChannel[public_key, 10_000_000, 0, 0x01, {}]
      end
    end
  end

  def self.start
    Bitcoin.chain_params = :regtest
    spv = Lightning::Blockchain::BitcoinService.new
    context = Lightning::Context.new(spv)
    start_server(context, port: 9735)
    context
  end
end

LN = Lightning
require 'em/pure_ruby'

# log level is one of FATAL, DEBUG, INFO, WARN, ERROR
Concurrent.use_simple_logger Logger::INFO
