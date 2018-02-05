require 'rails_helper'

RSpec.describe Tag, type: :model do
  let(:tag) { FactoryBot.build(:tag) }

  it 'has a valid factory' do
    expect(tag).to be_valid
  end

  it 'is not valid without a name' do
    tag.name = nil
    tag.valid?
    expect(tag.errors.details[:name]).to include(error: :blank)
  end

  it 'is not valid with a repeated name' do
    tag.save
    another_tag = FactoryBot.build(:tag, name: tag.name)
    another_tag.valid?
    expect(another_tag.errors.details[:name]).to include(error: :taken, value: tag.name)
  end

  it 'stores names in downcase' do
    name = 'MixOfUpper and DOWNS and spaces'
    tag.name = name
    tag.save
    tag.reload
    expect(tag.name).to eq(name.parameterize)
  end

  it 'find similar with a wrong tag' do
    wrong_tag =  FactoryBot.build(:tag, name: 'zemo')
    expect(wrong_tag.find_similar). to eq 'Maybe the tag zemo is wrong. Did you mean demo?'
  end

  it 'find similar with a correct tag' do
    correct_tag =  FactoryBot.build(:tag, name: 'demo')
    expect(correct_tag.find_similar).to be_nil
  end
end
