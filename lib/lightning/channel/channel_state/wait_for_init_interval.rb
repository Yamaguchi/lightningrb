# frozen_string_literal: true

module Lightning
  module Channel
    class ChannelState
      class WaitForInitInterval < ChannelState
        def next(message, data)
          match message, (on ~InputInitFunder do |init|
            context.broadcast << ChannelCreated[channel, channel.parent, context.remote_node_id, 1, init[:temporary_channel_id]]
            context.forwarder << init[:remote]
            local_param = init[:local_param]
            first_per_commitment_point = Lightning::Crypto::Key.per_commitment_point(local_param[:sha_seed], 0)
            open = OpenChannel.new(
              chain_hash: context.node_params.chain_hash,
              temporary_channel_id: init[:temporary_channel_id],
              funding_satoshis: init[:funding_satoshis],
              push_msat: init[:push_msat],
              dust_limit_satoshis: local_param[:dust_limit_satoshis],
              max_htlc_value_in_flight_msat: local_param[:max_htlc_value_in_flight_msat],
              channel_reserve_satoshis: local_param[:channel_reserve_satoshis],
              htlc_minimum_msat: local_param[:htlc_minimum_msat],
              initial_feerate_per_kw: init[:initial_feerate_per_kw],
              to_self_delay: local_param[:to_self_delay],
              max_accepted_htlcs: local_param[:max_accepted_htlcs],
              funding_pubkey: local_param[:funding_priv_key].pubkey,
              revocation_basepoint: local_param.revocation_basepoint,
              payment_basepoint: local_param.payment_basepoint,
              delayed_payment_basepoint: local_param.delayed_payment_basepoint,
              htlc_basepoint: local_param.htlc_basepoint,
              first_per_commitment_point: first_per_commitment_point,
              channel_flags: init[:channel_flags]
            )
            open.validate!
            goto(
              WaitForAcceptChannel.new(channel, context),
              data: DataWaitForAcceptChannel[init, open],
              sending: open
            )
          end), (on ~InputInitFundee do |init|
            return [self, data] if init[:local_param].funder == 1
            context.forwarder << init[:remote]
            goto(
              WaitForOpenChannel.new(channel, context),
              data: DataWaitForOpenChannel[init]
            )
          end), (on OpenChannel do
            # TODO: pending open_channel message.
            [self, data]
          end), (on ~InputRestored do |msg|
            data = msg[:data]
            log(Logger::INFO, :channel, "channel restoring ... #{data[:commitments][:channel_id]}")

            case data
            when DataNormal
              context.broadcast << ChannelRestored[channel, channel.parent, context.remote_node_id, data[:commitments][:local_param][:funder], data[:commitments][:channel_id], data]
              context.broadcast << ShortChannelIdAssigned[channel, data[:commitments][:channel_id], data[:short_channel_id]]
              goto(Offline.new(channel, context), data: data)
            else
              log(Logger::ERROR, :channel, 'channel data is not supported.')
              [self, data]
            end
          end)

        rescue => e
          log(Logger::ERROR, :channel, e.message)
          [self, data]
        end
      end
    end
  end
end
