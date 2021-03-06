# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: lightning/payment/events.proto

require 'google/protobuf'

require 'lightning/wire/types_pb'
Google::Protobuf::DescriptorPool.generated_pool.build do
  add_message "lightning.payment.events.PaymentSent" do
    optional :channel_id, :string, 1
    optional :amount_msat, :uint64, 2
    optional :fees_paid, :uint64, 3
    optional :payment_hash, :string, 4
  end
  add_message "lightning.payment.events.PaymentRelayed" do
    optional :original_channel_id, :string, 1
    optional :amount_msat_in, :uint64, 2
    optional :amount_msat_out, :uint64, 3
    optional :payment_hash, :string, 4
  end
  add_message "lightning.payment.events.PaymentReceived" do
    optional :channel_id, :string, 1
    optional :amount_msat, :uint64, 2
    optional :payment_hash, :string, 3
  end
  add_message "lightning.payment.events.PaymentSucceeded" do
    optional :amount_msat, :uint64, 1
    optional :payment_hash, :string, 2
    optional :payment_preimage, :string, 3
  end
  add_message "lightning.payment.events.PaymentFailed" do
    optional :payment_hash, :string, 1
  end
end

module Lightning
  module Payment
    module Events
      PaymentSent = Google::Protobuf::DescriptorPool.generated_pool.lookup("lightning.payment.events.PaymentSent").msgclass
      PaymentRelayed = Google::Protobuf::DescriptorPool.generated_pool.lookup("lightning.payment.events.PaymentRelayed").msgclass
      PaymentReceived = Google::Protobuf::DescriptorPool.generated_pool.lookup("lightning.payment.events.PaymentReceived").msgclass
      PaymentSucceeded = Google::Protobuf::DescriptorPool.generated_pool.lookup("lightning.payment.events.PaymentSucceeded").msgclass
      PaymentFailed = Google::Protobuf::DescriptorPool.generated_pool.lookup("lightning.payment.events.PaymentFailed").msgclass
    end
  end
end
