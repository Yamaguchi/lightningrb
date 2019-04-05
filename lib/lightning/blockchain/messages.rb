module Lightning
  module Blockchain
    module Messages
      WatchConfirmed = Algebrick.type do
        fields! listener: Object, # channel
                tx_hash: String,
                blocks: Numeric
      end

      WatchEventConfirmed = Algebrick.type do
        fields! event_type: String,
                block_height: Numeric,
                tx_index: Numeric
      end

      WatchUtxoSpent = Algebrick.type do
        fields! listener: Object, # channel
                tx_hash: String,
                output_index: Numeric
      end
    end
  end
end
