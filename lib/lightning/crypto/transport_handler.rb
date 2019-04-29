# frozen_string_literal: true

module Lightning
  module Crypto
    class TransportHandler < Concurrent::Actor::Context
      include Lightning::Wire::HandshakeMessages

      PREFIX = '00'.htb.freeze
      PROLOGUE = '6c696768746e696e67'.htb.freeze

      attr_reader :static_key, :remote_key

      def initialize(static_key, session, remote_key: nil)
        @static_key = static_key
        @remote_key = remote_key

        session << self

        @connection =
          if initiator?
            make_writer.tap(&:start_handshake).tap do |connection|
              payload = connection.write_message('')
              reference.parent << Act[PREFIX + payload, session]
            end
          else
            make_reader.tap(&:start_handshake)
          end
        @status = TransportHandlerStateHandshake.new(self, session, @static_key, @connection)
      end

      def on_message(message)
        @status = @status.next(message)
      end

      def initiator?
        !@remote_key.nil?
      end

      def create_ephemeral_private_key
        Bitcoin::Key.generate.priv_key
      end

      def make_writer
        keypairs = { s: @static_key.htb, e: create_ephemeral_private_key.htb, rs: @remote_key.htb }
        initiator = Noise::Connection::Initiator.new('Noise_XK_secp256k1_ChaChaPoly_SHA256', keypairs: keypairs)
        initiator.prologue = PROLOGUE
        initiator
      end

      def make_reader
        keypairs = { s: @static_key.htb, e: create_ephemeral_private_key.htb }
        responder = Noise::Connection::Responder.new('Noise_XK_secp256k1_ChaChaPoly_SHA256', keypairs: keypairs)
        responder.prologue = PROLOGUE
        responder
      end

      def to_s
        "TransportHandler @static_key = #{static_key} @remote_key = #{remote_key}"
      end

      def inspect
        "TransportHandler @static_key = #{static_key} @remote_key = #{remote_key}"
      end

      class TransportHandlerState
        include Concurrent::Concern::Logging
        include Algebrick::Matching
        include Lightning::Exceptions
        include Lightning::Wire::HandshakeMessages
        include Lightning::Wire::LightningMessages

        def initialize(actor, session, static_key, connection, buffer: +'')
          @actor = actor
          @session = session
          @static_key = static_key
          @connection = connection
          @buffer = buffer
        end

        def encrypt_internal(data)
          n = @connection.cipher_state_encrypt.n
          ciphertext = @connection.encrypt(data)
          @connection.rekey(@connection.cipher_state_encrypt) if n == 999
          ciphertext
        end

        def encrypt(data)
          ciphertext = encrypt_internal([data.bytesize].pack('n*'))
          ciphertext + encrypt_internal(data)
        end

        def decrypt_internal(data)
          n = @connection.cipher_state_decrypt.n
          plaintext = @connection.decrypt(data)
          @connection.rekey(@connection.cipher_state_decrypt) if n == 999
          plaintext
        end

        def decrypt(buffer)
          if buffer.bytesize < 18
            [nil, buffer]
          else
            cipher_length = buffer[0...18]
            remainder = buffer[18..-1]
            plain_length = decrypt_internal(cipher_length)
            length = plain_length.unpack('n*').first
            if remainder.bytesize < length + 16
              [nil, buffer]
            else
              ciphertext = remainder[0...length + 16]
              remainder = remainder[length + 16..-1]
              payload = decrypt_internal(ciphertext)
              log(Logger::DEBUG, '/transport', "RECEIVE_DATA #{payload.bth}")
              message = Lightning::Wire::LightningMessages::LightningMessage.load(payload)
              [message, remainder]
            end
          end
        end

        def send_to(listener, message)
          log(Logger::INFO, '/transport', "RECEIVE #{message.inspect}")
          listener << message
        end

        def decrypt_and_send(buffer, listener)
          return +'' if buffer.nil? || buffer.empty?
          begin
            lightning_message, remainder = decrypt(buffer)
            send_to(listener, lightning_message) if lightning_message
            buffer = remainder || +''
          end while lightning_message && !buffer.empty?
          buffer
        end
      end

      class TransportHandlerStateHandshake < TransportHandlerState
        def expected_length(connection)
          case connection.handshake_state.message_patterns.length
          when 1 then 66
          when 2, 3 then 50
          end
        end

        def next(message)
          match message, (on Received.(~any) do |data|
            @buffer += data
            if @buffer.bytesize < expected_length(@connection)
              self
            else
              raise InvalidTransportVersion.new(@buffer[0], PREFIX) unless @buffer[0] == PREFIX
              payload = @buffer[1...expected_length(@connection)]
              remainder = @buffer[expected_length(@connection)..-1]
              _ = @connection.read_message(payload)

              unless @connection.handshake_finished
                payload = @connection.write_message('')
                @actor.reference.parent << Act[PREFIX + payload, @session]
              end

              @buffer = remainder

              if @connection.handshake_finished
                rs = @connection.rs
                @actor.reference.parent << HandshakeCompleted[@session, @actor.reference, @static_key, rs.bth]
                TransportHandlerStateWaitingForListener.new(@actor, @session, @static_key, @connection, buffer: @buffer)
              else
                self
              end
            end
          end)
        end
      end

      class TransportHandlerStateWaitingForListener < TransportHandlerState
        def next(message)
          case message
          when Received
            @buffer += message[:data]
            self
          when Listener
            @buffer = decrypt_and_send(@buffer, message[:listener])
            TransportHandlerStateWaitingForCiphertext.new(
              @actor, @session, @static_key, @connection, buffer: @buffer, listener: message[:listener]
            )
          end
        end
      end

      class TransportHandlerStateWaitingForCiphertext < TransportHandlerState
        def initialize(actor, session, static_key, connection, buffer: +'', listener: nil)
          super(actor, session, static_key, connection, buffer: buffer)
          @listener = listener
        end

        def next(message)
          case message
          when Received
            @buffer += message[:data]
            @buffer = decrypt_and_send(@buffer, @listener)
          when Lightning::Wire::LightningMessages
            ciphertext = encrypt(message.to_payload)
            log(Logger::DEBUG, '/transport', "SEND_DATA #{message.to_payload.bth}")
            log(Logger::INFO, '/transport', "SEND #{message.inspect}")
            @session << Send[ciphertext]
          end
          self
        end
      end
    end
  end
end

module Noise
  module Connection
    class Base
      def rekey(cipher)
        k = cipher.k
        ck = handshake_state.symmetric_state.ck
        ck, k = protocol.hkdf_fn.call(ck, k, 2)
        handshake_state.symmetric_state.initialize_chaining_key(ck)
        cipher.initialize_key(k)
      end
    end
  end

  module State
    class SymmetricState
      def initialize_chaining_key(ck)
        @ck = ck
      end
    end
  end
end
