# frozen_string_literal: true

require "active_hash"
require "rbs_active_hash/active_hash"

class Colour < ActiveHash::Base
  include ActiveHash::Enum

  enum_accessor :name

  self.data = [
    { id: 1, name: "red", code: "#ff0000" },
    { id: 2, name: "green", code: "#00ff00" },
    { id: 3, name: "blue", code: "#0000ff" }
  ]
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

    let(:klass) { Colour }
    let(:expected) do
      <<~RBS
        class Colour < ::ActiveHash::Base
          include ActiveHash::Enum
          extend ActiveHash::Enum::Methods

          RED: instance
          GREEN: instance
          BLUE: instance

          def name: () -> untyped
          def name=: (untyped value) -> void
          def name?: () -> bool
          def self.find_by_name: (untyped value) -> self?
          def self.find_all_by_name: (untyped value) -> Array[self]

          def code: () -> untyped
          def code=: (untyped value) -> void
          def code?: () -> bool
          def self.find_by_code: (untyped value) -> self?
          def self.find_all_by_code: (untyped value) -> Array[self]
        end
      RBS
    end

    it "Generate type definition correctly" do
      expect(subject).to eq expected
    end
  end
end
