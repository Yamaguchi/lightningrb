# frozen_string_literal: true

module Lightning
  module Exceptions
    autoload :AmountBelowDustLimit, 'lightning/exceptions/amount_below_dust_limit'
    autoload :AmountTooLarge, 'lightning/exceptions/amount_too_large'
    autoload :CannotAffordFees, 'lightning/exceptions/cannot_afford_fees'
    autoload :CannotCloseWithUnsignedOutgoingHtlcs, 'lightning/exceptions/cannot_close_with_unsigned_outgoing_htlcs'
    autoload :CannotExtractSharedSecret, 'lightning/exceptions/cannot_extract_shared_secret'
    autoload :CannotSignBeforeRevocation, 'lightning/exceptions/cannot_sign_before_revocation'
    autoload :CannotSignWithoutChanges, 'lightning/exceptions/cannot_sign_without_changes'
    autoload :ClosingAlreadyInProgress, 'lightning/exceptions/closing_already_in_progress'
    autoload :ExpiryTooLarge, 'lightning/exceptions/expiry_too_large'
    autoload :ExpiryTooSmall, 'lightning/exceptions/expiry_too_small'
    autoload :FeerateTooLarge, 'lightning/exceptions/feerate_too_large'
    autoload :FeerateTooSmall, 'lightning/exceptions/feerate_too_small'
    autoload :FundeeCannotSendUpdateFee, 'lightning/exceptions/fundee_cannot_send_update_fee'
    autoload :HtlcSigCountMismatch, 'lightning/exceptions/htlc_sig_count_mismatch'
    autoload :HtlcValueTooHighInFlight, 'lightning/exceptions/htlc_value_too_high_in_flight'
    autoload :HtlcValueTooLarge, 'lightning/exceptions/htlc_value_too_large'
    autoload :HtlcValueTooSmall, 'lightning/exceptions/htlc_value_too_small'
    autoload :InsufficientChannelReserve, 'lightning/exceptions/insufficient_channel_reserve'
    autoload :InsufficientFunds, 'lightning/exceptions/insufficient_funds'
    autoload :InsufficientFundsInWallet, 'lightning/exceptions/insufficient_funds_in_wallet'
    autoload :InvalidCloseFee, 'lightning/exceptions/invalid_close_fee'
    autoload :InvalidCommitmentSignature, 'lightning/exceptions/invalid_commitment_signature'
    autoload :InvalidFailureCode, 'lightning/exceptions/invalid_failure_code'
    autoload :InvalidFinalScript, 'lightning/exceptions/invalid_final_script'
    autoload :InvalidHtlcPreimage, 'lightning/exceptions/invalid_htlc_preimage'
    autoload :InvalidHtlcSignature, 'lightning/exceptions/invalid_htlc_signature'
    autoload :InvalidKeyFormat, 'lightning/exceptions/invalid_key_format'
    autoload :InvalidPaymentHash, 'lightning/exceptions/invalid_payment_hash'
    autoload :InvalidRevocation, 'lightning/exceptions/invalid_revocation'
    autoload :InvalidTransportVersion, 'lightning/exceptions/invalid_transport_version'
    autoload :PushMsatTooLarge, 'lightning/exceptions/push_msat_too_large'
    autoload :TemporaryChannelIdNotMatch, 'lightning/exceptions/temporary_channe_id_not_match'
    autoload :TooManyAcceptedHtlcs, 'lightning/exceptions/too_many_accepted_htlcs'
    autoload :OutputNotFound, 'lightning/exceptions/output_not_found'
    autoload :RouteNotFound, 'lightning/exceptions/route_not_found'
    autoload :UnexpectedHtlcId, 'lightning/exceptions/unexpected_htlc_id'
    autoload :UnexpectedRevocation, 'lightning/exceptions/unexpected_revocation'
    autoload :UnknownHtlcId, 'lightning/exceptions/unknown_htlc_id'

    class ::StandardError
      def to_s
        if instance_variables.present?
          super() + " " + instance_variables.map do |v|
            "#{v}: #{instance_variable_get(v)}"
          end.join(", ")
        else
          super()
        end
      end
    end
  end
end
