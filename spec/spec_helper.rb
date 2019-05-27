# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', File.dirname(__FILE__))
require 'lightning'
require 'factory_bot'
require 'support/factory_bot'

RSpec.configure do |config|
  config.before do
    mock = double('grpc')
    allow(Bitcoin::Grpc::Blockchain::Stub).to receive(:new).and_return(mock)
    allow(mock).to receive(:watch_tx_confirmed).and_return(nil)
    allow(mock).to receive(:events).and_return([])
  end
end

def test_wallet_path(wallet_id: 1)
  default_path = Dir.tmpdir + '/wallet'
  "#{default_path}wallet#{wallet_id}/"
end

def create_test_wallet(wallet_id: 1)
  path = test_wallet_path(wallet_id: wallet_id)
  FileUtils.rm_r(path) if Dir.exist?(path)

  default_path = Dir.tmpdir + '/wallet'
  Bitcoin::Wallet::Base.create(wallet_id, default_path)
end

def create_test_spv
  spv = double('spv')
  spv.stub(:generate_new_address).and_return('bc1qc7slrfxkknqcq2jevvvkdgvrt8080852dfjewde450xdlk4ugp7szw5tk9')
  spv.stub(:build_bitcoin_grpc_url).and_return('localhost:8080')
  spv
end

class DummyActor < Concurrent::Actor::Context
  def on_message(message)
  end
end

class DummyRelayer < Concurrent::Actor::Context
  def on_message(message)
    if message.is_a? Array
      message[0] << message[1]
    end
  end
end

def spawn_dummy_actor(name: :dummy)
  DummyActor.spawn(name)
end

def spawn_dummy_relayer(name: :dummy_relayer)
  DummyRelayer.spawn(name)
end
