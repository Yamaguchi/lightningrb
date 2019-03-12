# frozen_string_literal: true

module Lightning
  module Router
    class RouterState
      include Concurrent::Concern::Logging
      include Algebrick
      include Algebrick::Matching
      include Lightning::Wire::LightningMessages
      include Lightning::Channel::Events
      include Lightning::Blockchain::Messages
      include Lightning::Router::Messages

      autoload :Normal, 'lightning/router/router_state/normal'
      autoload :WaitingForValidation, 'lightning/router/router_state/waiting_for_validation'

      attr_accessor :router, :context

      def initialize(router, context)
        @router = router
        @context = context
      end

      def goto(new_status, data: nil)
        @data = data
        [new_status, @data]
      end

      def next(message, data)
        log(Logger::DEBUG, 'router_state', "data:#{data}")
        case message
        when Lightning::Router::Messages::Timeout
          log(Logger::DEBUG, 'router_state', "router state update.")
          context.switchboard << data if context.switchboard && data
          [self, data]
        when LocalChannelUpdate
          channel = data[:channels][message[:short_channel_id]]
          unless channel
            router << message[:channel_announcement].value unless message[:channel_announcement].is_a? None
          end
          router << message[:channel_update]
          [self, data]
        when LocalChannelDown
          channel = data[:channels][message[:short_channel_id]]
          desc = Announcements.to_channel_desc(channel)
          [self, data]
        when ChannelAnnouncement
          if data[:channels].key?(message[:short_channel_id])
            # ignore
            [self, data]
          elsif !message.valid_signature?
            # TODO: router.parent << :error
            log(Logger::DEBUG, 'router_state', "signature invalid #{message.to_payload.bth}")
            [self, data]
          else
            [self, data.copy(channels: data[:channels].merge(message[:short_channel_id] => message))]
          end
        when NodeAnnouncement
          if data[:nodes].key?(message[:node_id]) && message.older_than?(data[:nodes][message[:node_id]])
            [self, data]
          elsif !message.valid_signature?
            # TODO: router.parent << :error
            log(Logger::DEBUG, 'router_state', "signature invalid #{message.to_payload.bth}")
            [self, data]
          elsif data[:nodes].key?(message[:node_id])
            # TODO: NodeUpdate event
            context.node_db.update(message)
            [self, data.copy(nodes: data[:nodes].merge(message[:node_id] => message))]
          elsif data[:channels].values.any? { |channel| related?(channel, message[:node_id]) }
            # TODO: NodeDiscovered event
            context.node_db.create(message)
            [self, data.copy(nodes: data[:nodes].merge(message[:node_id] => message))]
          else
            context.node_db.destroy_by(node_id: message[:node_id])
            [self, data]
          end
        when ChannelUpdate
          if data[:channels].key?(message[:short_channel_id])
            channel = data[:channels][message[:short_channel_id]]
            desc = Announcements.to_channel_desc(channel)
            node_id =
              if message[:channel_flags].to_i(16) & (2**0) == 0
                channel[:node_id_2]
              else
                channel[:node_id_1]
              end
            if data[:updates].key?(desc) && data[:updates][desc].timestamp >= message.timestamp
              log(Logger::DEBUG, 'router_state', "ignore old update #{message.to_payload.bth}")
              # ignore
              [self, data]
            elsif !message.valid_signature?(node_id)
              # TODO: router.parent << :error
              log(Logger::DEBUG, 'router_state', "signature invalid #{message.to_payload.bth}")
              [self, data]
            elsif data[:updates].key?(desc)
              # TODO: ChannelUpdateReceived
              # context.channel_db.update_channel_update(message)
              log(Logger::INFO, :router_state, '================================================================================')
              log(Logger::INFO, :router_state, '')
              log(Logger::INFO, :router_state, "Channel Updated #{message}")
              log(Logger::INFO, :router_state, '')
              log(Logger::INFO, :router_state, '================================================================================')
              [self, data.copy(updates: data[:updates].merge(desc => message))]
            else
              # TODO: ChannelUpdateReceived
              # context.channel_db.add_channel_update(message)
              log(Logger::INFO, :router_state, '================================================================================')
              log(Logger::INFO, :router_state, '')
              log(Logger::INFO, :router_state, "Channel Registered #{message}")
              log(Logger::INFO, :router_state, '')
              log(Logger::INFO, :router_state, '================================================================================')
              [self, data.copy(updates: data[:updates].merge(desc => message))]
            end
          else
            # TODO: wait for channel_announcement
            log(Logger::DEBUG, 'router_state', "wait for channel_announcement #{message.to_payload.bth}")
            [self, data]
          end
        when RouteRequest
          begin
            ignore_nodes = []
            ignore_channels = []
            hops = RouteFinder.find(message[:source], message[:target], data[:updates], message[:assisted_routes])
            if router.envelope.sender.is_a? Concurrent::Actor::Reference
              router.envelope.sender << RouteResponse[hops, ignore_nodes, ignore_channels]
            end
            [self, data]
          rescue Lightning::Exceptions::RouteNotFound => e
            log(Logger::DEBUG, 'router_state', 'Route to the final node is not found. Retry after a while')
            log(Logger::DEBUG, 'router_state', e.message)
            [self, data]
          end
        end
      end

      def related?(channel, node_id)
        node_id == channel.node_id_1 || node_id == channel.node_id_2
      end
    end
  end
end
