# frozen_string_literal: true

module Lightning
  module Exceptions
    class TooManyAcceptedHtlcs < StandardError
      attr_accessor :commitments, :htlc
      def initialize(commitments, htlc)
        @commitments = commitments
        @htlc = htlc
      end
    end
  end
end
