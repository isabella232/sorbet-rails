require 'rails_helper'
require 'sorbet-rails/model_rbi_formatter'

RSpec.describe SorbetRails::PluckToTStruct do
  let!(:harry) do
    Wizard.create!(
      name: 'Harry Potter',
      house: :Gryffindor,
    )
  end

  let!(:harrys_wand) do
    Wand.create!(
      wizard: harry,
      core_type: :phoenix_feather,
      wood_type: "Holly",
      chosen_at_date: Date.parse('2019-09-01'),
      chosen_at_time: Time.parse('2019-09-01T09:00:00Z'),
      broken: true,
      broken_at: Time.parse('2019-09-05T15:30:00Z'),
    )
  end

  let!(:hermione) do
    Wizard.create!(
      name: 'Hermione Granger',
      house: :Gryffindor,
    )
  end

  let!(:hermiones_wand) do
    Wand.create!(
      wizard: hermione,
      core_type: :phoenix_feather,
      wood_type: "Vine",
      chosen_at_date: Date.parse('2019-09-01'),
      chosen_at_time: Time.parse('2019-09-01T09:00:00Z'),
      broken: true,
      broken_at: Time.parse('2019-09-05T15:30:00Z'),
    )
  end

  class WizardName < T::Struct
    const :name, String

    def ==(other)
      return false unless other.is_a?(self.class)
      name == other.name
    end

    def eql?(other)
      self == other
    end
  end

  class WizardT < T::Struct
    const :name, String
    const :house, String

    def ==(other)
      return false unless other.is_a?(self.class)
      name == other.name && house == other.house
    end

    def eql?(other)
      self == other
    end
  end

  class WizardWithWandT < T::Struct
    const :name, String
    const :house, String
    const :wand_wood_type, String

    def ==(other)
      return false unless other.is_a?(self.class)
      name == other.name && house == other.house
    end

    def eql?(other)
      self == other
    end
  end

  shared_examples 'pluck_to_tstruct' do |struct_type, expected_values|
    it 'plucks correctly from ActiveRecord model' do
      plucked = Wizard.pluck_to_tstruct(TA[struct_type].new)
      expect(plucked).to match_array(expected_values)
    end

    it 'plucks correctly from ActiveRecord relation' do
      plucked = Wizard.all.pluck_to_tstruct(TA[struct_type].new)
      expect(plucked).to match_array(expected_values)
    end
  end

  shared_examples 'pluck_to_tstruct with associations' do |struct_type, associations, expected_values|
    it 'plucks correctly from ActiveRecord model with associations' do
      plucked = Wizard.joins(:wand).pluck_to_tstruct(TA[struct_type].new, associations: associations)
      expect(plucked).to match_array(expected_values)
    end

    it 'plucks correctly from ActiveRecord relation with associations' do
      plucked = Wizard.all.joins(:wand).pluck_to_tstruct(TA[struct_type].new, associations: associations)
      expect(plucked).to match_array(expected_values)
    end
  end

  context 'pluck 1 attribute' do
    it_should_behave_like 'pluck_to_tstruct', WizardName, [
      WizardName.new(name: "Harry Potter"),
      WizardName.new(name: "Hermione Granger"),
    ]
  end

  context 'pluck multiple attributes' do
    it_should_behave_like 'pluck_to_tstruct', WizardT, [
      WizardT.new(name: "Harry Potter", house: "Gryffindor"),
      WizardT.new(name: "Hermione Granger", house: "Gryffindor"),
    ]
  end

  context 'given a wrong type' do
    it 'should raise error' do
      expect {
        Wizard.pluck_to_tstruct(TA[String].new)
      }.to raise_error(SorbetRails::PluckToTStruct::UnexpectedType)
    end
  end

  context "given associations mappings that don't exist in T::Struct" do
    it 'should raise error' do
      expect {
        Wizard.pluck_to_tstruct(
          TA[WizardWithWandT].new,
          associations: { wood_type: "wands.wood_type" }
        )
      }.to raise_error(SorbetRails::PluckToTStruct::UnexpectedAssociations)
    end
  end

  context 'pluck with associations' do
    associations = { wand_wood_type: "wands.wood_type" }

    expected = [
      WizardWithWandT.new(name: "Harry Potter", house: "Gryffindor", wand_wood_type: "Holly"),
      WizardWithWandT.new(name: "Hermione Granger", house: "Gryffindor", wand_wood_type: "Vine"),
    ]

    it_should_behave_like 'pluck_to_tstruct with associations', WizardWithWandT, associations, expected
  end
end
