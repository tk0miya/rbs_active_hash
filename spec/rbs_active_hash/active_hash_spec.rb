# frozen_string_literal: true

require "active_hash"
require "active_record"
require "rbs_active_hash"

class Colour < ActiveHash::Base
  include ActiveHash::Enum

  enum_accessor :name

  self.data = [
    {
      id: 1,
      name: "red",
      code: "#ff0000",
      palette: [255, 0, 0],
      palette_h: { red: 255, green: 0, blue: 0 },
      order: 1,
      other: "misc"
    },
    {
      id: 2,
      name: "green",
      code: "#00ff00",
      palette: [0, 255, 0],
      palette_h: { red: 0, green: 255, blue: 0 },
      order: 2,
      other: nil
    },
    {
      id: 3,
      name: "blue",
      code: "#0000ff",
      palette: [0, 0, 255],
      palette_h: { red: 0, green: 0, blue: 255 },
      order: 3,
      other: true
    }
  ]
end

class Item < ActiveRecord::Base
end

class Skill # rubocop:disable Lint/EmptyClass
end

class Job < ActiveRecord::Base
end

class Group < ActiveRecord::Base
end

class GamePlayer < ActiveHash::Base
  include ActiveHash::Associations

  has_many :items
  has_many :skills
  has_one :job
  belongs_to :team, class_name: "Group"

  self.data = [
    { id: 1, name: "Alice", team_id: 1 }
  ]
end

class Team < ActiveHash::Base
  scope :red, -> { where(colour: "red") }
  scope :blue, ->(_obj) { where(colour: "blue") }
end

RSpec.describe RbsActiveHash::ActiveHash do
  describe ".user_defined_model?" do
    subject { described_class.user_defined_model?(klass) }

    context "When user-defined model given" do
      let(:klass) { Colour }

      it { is_expected.to be_truthy }
    end

    context "When subclasses in active_hash gem given" do
      let(:klass) { ActiveYaml::Base }

      it { is_expected.to be_falsy }
    end
  end

  describe ".class_to_rbs" do
    subject { described_class.class_to_rbs(klass) }

    context "When enum model given" do
      let(:klass) { Colour }
      let(:expected) do
        <<~RBS
          class Colour < ::ActiveHash::Base
            include ActiveHash::Enum
            extend ActiveHash::Enum::Methods

            RED: Colour
            GREEN: Colour
            BLUE: Colour

            def self.find: (Integer id) -> instance
                         | ...

            def name: () -> String
            def name=: (String value) -> String
            def name?: () -> bool
            def self.find_by_name: (String value) -> instance?
            def self.find_all_by_name: (String value) -> Array[instance]

            def code: () -> String
            def code=: (String value) -> String
            def code?: () -> bool
            def self.find_by_code: (String value) -> instance?
            def self.find_all_by_code: (String value) -> Array[instance]

            def palette: () -> Array[Integer]
            def palette=: (Array[Integer] value) -> Array[Integer]
            def palette?: () -> bool
            def self.find_by_palette: (Array[Integer] value) -> instance?
            def self.find_all_by_palette: (Array[Integer] value) -> Array[instance]

            def palette_h: () -> Hash[Symbol, Integer]
            def palette_h=: (Hash[Symbol, Integer] value) -> Hash[Symbol, Integer]
            def palette_h?: () -> bool
            def self.find_by_palette_h: (Hash[Symbol, Integer] value) -> instance?
            def self.find_all_by_palette_h: (Hash[Symbol, Integer] value) -> Array[instance]

            def order: () -> Integer
            def order=: (Integer value) -> Integer
            def order?: () -> bool
            def self.find_by_order: (Integer value) -> instance?
            def self.find_all_by_order: (Integer value) -> Array[instance]

            def other: () -> (String | bool)?
            def other=: ((String | bool)? value) -> (String | bool)?
            def other?: () -> bool
            def self.find_by_other: ((String | bool)? value) -> instance?
            def self.find_all_by_other: ((String | bool)? value) -> Array[instance]
          end
        RBS
      end

      it "Generate type definition correctly" do
        expect(subject).to eq expected
      end
    end

    context "When association model given" do
      let(:klass) { GamePlayer }
      let(:expected) do
        <<~RBS
          class GamePlayer < ::ActiveHash::Base
            include ActiveHash::Associations
            extend ActiveHash::Associations::Methods

            def items: () -> Item::ActiveRecord_Relation
            def item_ids: () -> Array[Integer]

            def skills: () -> Array[Skill]
            def skill_ids: () -> Array[Integer]

            def job: () -> Job
            def team: () -> Group
            def team=: (Integer) -> Integer

            def self.find: (Integer id) -> instance
                         | ...

            def name: () -> String
            def name=: (String value) -> String
            def name?: () -> bool
            def self.find_by_name: (String value) -> instance?
            def self.find_all_by_name: (String value) -> Array[instance]

            def team_id: () -> Integer
            def team_id=: (Integer value) -> Integer
            def team_id?: () -> bool
            def self.find_by_team_id: (Integer value) -> instance?
            def self.find_all_by_team_id: (Integer value) -> Array[instance]
          end
        RBS
      end

      it "Generate type definition correctly" do
        expect(subject).to eq expected
      end
    end

    context "When scope model given" do
      let(:klass) { Team }
      let(:expected) do
        <<~RBS
          class Team < ::ActiveHash::Base
            def self.red: () -> ActiveHash::Relation[instance]
            def self.blue: (untyped _obj) -> ActiveHash::Relation[instance]
          end
        RBS
      end

      it "Generate type definition correctly" do
        expect(subject).to eq expected
      end
    end
  end
end
