# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  it { is_expected.to validate_presence_of(:email) }
  it { is_expected.to validate_uniqueness_of(:email).case_insensitive }

  it 'is valid with the factory defaults' do
    expect(build(:user)).to be_valid
  end

  it 'assigns a JTI before creation' do
    user = create(:user)

    expect(user.jti).to be_present
  end
end
