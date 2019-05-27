# frozen_string_literal: true

module Lightning
  module Channel
    class ChannelContext
      attr_accessor :node_params, :forwarder, :remote_node_id, :wallet, :blockchain, :router, :relayer, :broadcast, :spv, :watch_tower
      attr_accessor :channel_db
      def initialize(context, forwarder, remote_node_id)
        @node_params = context.node_params
        @forwarder = forwarder
        @remote_node_id = remote_node_id
        @wallet = context.wallet
        @blockchain = context.blockchain
        @router = context.router
        @relayer = context.relayer
        @broadcast = context.broadcast
        @watch_tower = context.watch_tower
        @spv = context.spv
        @channel_db = context.channel_db
      end
    end
  end
end
