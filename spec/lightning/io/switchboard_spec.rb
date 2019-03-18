# frozen_string_literal: true

require 'spec_helper'

describe Lightning::IO::Switchboard do
  let(:switchboard) { Lightning::IO::Switchboard.spawn(:switchboard, authenticator, context) }
  let(:authenticator) { spawn_dummy_actor(name: :authenticator) }
  let(:transport) { spawn_dummy_actor(name: :transport) }
  let(:context) { build(:context) }

  describe 'on_message' do
    context 'with Disconnect' do
      subject do
        switchboard << Lightning::IO::PeerEvents::Disconnect['00' * 32]
        switchboard.ask(:await).wait
        switchboard.ask!(:peers)
      end

      before do
        switchboard << Lightning::IO::AuthenticateMessages::Authenticated[{}, transport, '00' * 32]
        switchboard.ask(:await).wait
      end

      it { expect(subject).to be_empty }
    end
  end
end
