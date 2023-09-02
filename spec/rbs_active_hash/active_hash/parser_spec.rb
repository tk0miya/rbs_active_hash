# frozen_string_literal: true

require "active_hash"
require "rbs_active_hash"

RSpec.describe RbsActiveHash::ActiveHash::Parser::Parser do
  describe ".parse" do
    subject { parser.parse(string, target) }

    let(:parser) { described_class.new }
    let(:target) { %i[Mod SubMod Klass] }
    let(:string) do
      <<~RUBY
        module Mod
          module SubMod
            class Klass
              has_one :foo
            end
          end
        end

        module Mod::SubMod
          class Klass
            has_many :bars, class_name: "Bar"

            class SubKlass
              has_one :baz
            end
          end
        end

        class Mod::SubMod::Klass
          belongs_to :qux
        end

        module Other
          class Mod::SubMod::Klass
            has_one :quux
          end
        end
      RUBY
    end

    it "parses associations" do
      subject
      expect(parser.has_one).to eq([[:foo, {}]])
      expect(parser.has_many).to eq([[:bars, { class_name: "Bar" }]])
      expect(parser.belongs_to).to eq([[:qux, {}]])
    end
  end
end
