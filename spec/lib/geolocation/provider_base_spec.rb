# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GeolocationProviders::ProviderBase do
  it 'raises NotImplementedError when lookup is called on the base class' do
    expect { described_class.new.lookup('1.1.1.1') }.to raise_error(NotImplementedError)
  end
end
