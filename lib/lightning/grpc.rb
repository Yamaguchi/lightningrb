# frozen_string_literal: true

module Lightning
  module Grpc
    require 'lightning/grpc/service_pb'

    autoload :Api, 'lightning/grpc/api'
    autoload :Server, 'lightning/grpc/server'
    autoload :LightningService, 'lightning/grpc/lightning_service'
  end
end
