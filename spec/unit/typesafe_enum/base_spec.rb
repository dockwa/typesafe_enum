# frozen_string_literal: true

require 'spec_helper'

class Suit < TypesafeEnum::Base
  new :CLUBS
  new :DIAMONDS
  new :HEARTS
  new :SPADES
end

class Tarot < TypesafeEnum::Base
  new :CUPS, 'Cups'
  new :COINS, 'Coins'
  new :WANDS, 'Wands'
  new :SWORDS, 'Swords'
end

class RGBColor < TypesafeEnum::Base
  new :RED, :red
  new :GREEN, :green
  new :BLUE, :blue
end

class Scale < TypesafeEnum::Base
  new :DECA, 10
  new :HECTO, 100
  new :KILO, 1_000
  new :MEGA, 1_000_000
end

class Scheme < TypesafeEnum::Base
  new :HTTP, 'http'
  new :HTTPS, 'https'
  new :EXAMPLE, 'example'
  new :UNKNOWN, nil
end

module Super
  module Modular
    class Enum < TypesafeEnum::Base; end
  end
end

module TypesafeEnum
  describe Base do

    describe :new do
      it 'news a constant enum value' do
        enum = Suit::CLUBS
        expect(enum).to be_a(Suit)
      end

      it 'allows nil values' do
        expect do
          class ::NilValues < Base
            new :NONE, nil
          end
        end.not_to raise_error
        expect(::NilValues.to_a).not_to be_empty
      end

      it 'insists symbols be symbols' do
        expect do
          class ::StringKeys < Base
            new 'spades', 'spades'
          end
        end.to raise_error(TypeError)
        expect(::StringKeys.to_a).to be_empty
      end

      it 'insists symbols be uppercase' do
        expect do
          class ::LowerCaseKeys < Base
            new :spades, 'spades'
          end
        end.to raise_error(NameError)
        expect(::LowerCaseKeys.to_a).to be_empty
      end

      it 'disallows duplicate symbols with different values' do
        expect do
          class ::DuplicateSymbols < Base
            new :SPADES, 'spades'
            new :SPADES, 'more spades'
          end
        end.to raise_error(NameError)
        expect(::DuplicateSymbols.to_a).to eq([::DuplicateSymbols::SPADES])
        expect(::DuplicateSymbols::SPADES.value).to eq('spades')
        expect(::DuplicateSymbols.find_by_value('more spades')).to be_nil
      end

      it 'disallows duplicate values with different symbols' do
        expect do
          class ::DuplicateValues < Base
            new :SPADES, 'spades'
            new :ALSO_SPADES, 'spades'
          end
        end.to raise_error(NameError)
        expect(::DuplicateValues.to_a).to eq([::DuplicateValues::SPADES])
        expect(::DuplicateValues::SPADES.value).to eq('spades')
        expect(::DuplicateValues.find_by_key(:ALSO_SPADES)).to be_nil
      end

      it 'disallows duplicate nil values' do
        expect do
          class ::DuplicateNilValues < Base
            new :NONE, nil
            new :NULL, nil
          end.to raise_error(NameError)
          expect(::DuplicateNilValues.to_a).to eq([::DuplicateNilValues::NONE])
          expect(::DuplicateNilValues::NONE.value).to be_nil
          expect(::DuplicateNilValues.find_by_key(:NULL)).to be_nil
        end
      end

      it 'disallows nil keys' do
        expect do
          class ::NilKeys < Base
            new nil, 'nil'
          end
        end.to raise_error(TypeError)
        expect(::NilKeys.to_a).to be_empty
      end

      it 'allows, but ignores redeclaration of identical instances' do
        class ::IdenticalInstances < Base
          new :SPADES, 'spades'
        end
        expected_msg = /ignoring redeclaration of IdenticalInstances::SPADES with value "spades" \(source: .*base_spec.rb:[0-9]+:in `new'\)/
        expect(::IdenticalInstances).to receive(:warn).once.with(expected_msg)
        class ::IdenticalInstances < Base
          new :SPADES, 'spades'
        end
        expect(::IdenticalInstances.to_a).to eq([::IdenticalInstances::SPADES])
      end

      it 'defaults the value to a lower-cased version of the symbol' do
        expect(Suit::CLUBS.value).to eq('clubs')
        expect(Suit::DIAMONDS.value).to eq('diamonds')
        expect(Suit::HEARTS.value).to eq('hearts')
        expect(Suit::SPADES.value).to eq('spades')
      end

      it 'is private' do
        expect { Tarot.new(:PENTACLES) }.to raise_error(NoMethodError)
      end

      it 'can be overridden' do
        class ::Extras < Base
          attr_reader :x1
          attr_reader :x2

          def initialize(key, x1, x2)
            super(key)
            @x1 = x1
            @x2 = x2
          end

          new(:AB, 'a', 'b') do
            def x3
              'c'
            end
          end
        end

        expect(Extras::AB.key).to eq(:AB)
        expect(Extras::AB.value).to eq('ab')
        expect(Extras::AB.x1).to eq('a')
        expect(Extras::AB.x2).to eq('b')
        expect(Extras::AB.x3).to eq('c')
      end
    end

    describe :to_a do
      it 'returns the values as an array' do
        expect(Suit.to_a).to eq([Suit::CLUBS, Suit::DIAMONDS, Suit::HEARTS, Suit::SPADES])
      end
      it 'returns a copy' do
        array = Suit.to_a
        array.clear
        expect(array.empty?).to eq(true)
        expect(Suit.to_a).to eq([Suit::CLUBS, Suit::DIAMONDS, Suit::HEARTS, Suit::SPADES])
      end
    end

    describe :size do
      it 'returns the number of enum instances' do
        expect(Suit.size).to eq(4)
      end
    end

    describe :count do
      it 'returns the number of enum instances' do
        expect(Suit.count).to eq(4)
      end

      it 'counts items' do
        expect(Suit.count(Suit::SPADES)).to eq(1)
      end

      it 'counts items that match a predicate' do
        expect(Suit.count { |s| s.value.length == 6 }).to eq(2)
      end
    end

    describe :each do
      it 'iterates the enum instances' do
        expected = [Suit::CLUBS, Suit::DIAMONDS, Suit::HEARTS, Suit::SPADES]
        index = 0
        Suit.each do |s|
          expect(s).to be(expected[index])
          index += 1
        end
      end
    end

    describe :keys do
      it 'returns all keys of all instances' do
        expect(Suit.keys).to eq(%i[CLUBS DIAMONDS HEARTS SPADES])
      end
    end

    describe :values do
      it 'returns all values of all instances' do
        expect(Suit.values).to eq(%w[clubs diamonds hearts spades])
      end

    end

    describe :each_key do
      it 'iterates the enum keys' do
        expected = %i[CLUBS DIAMONDS HEARTS SPADES]
        index = 0
        Suit.each_key do |s|
          expect(s).to eq(expected[index])
          index += 1
        end
      end

    end

    describe :each_value do
      it 'iterates the enum values' do
        expected = %w[clubs diamonds hearts spades]
        index = 0
        Suit.each_value do |s|
          expect(s).to eq(expected[index])
          index += 1
        end
      end
    end

    describe :each_with_index do
      it 'iterates the enum values with indices' do
        expected = [Suit::CLUBS, Suit::DIAMONDS, Suit::HEARTS, Suit::SPADES]
        Suit.each_with_index do |s, index|
          expect(s).to be(expected[index])
        end
      end
    end

    describe :map do
      it 'maps enum values' do
        all_keys = Suit.map(&:key)
        expect(all_keys).to eq(%i[CLUBS DIAMONDS HEARTS SPADES])
      end
    end

    describe :flat_map do
      it 'flatmaps enum values' do
        result = Tarot.flat_map { |t| [t.key, t.value] }
        expect(result).to eq([:CUPS, 'Cups', :COINS, 'Coins', :WANDS, 'Wands', :SWORDS, 'Swords'])
      end
    end

    describe :<=> do
      it 'orders enum instances' do
        Suit.each_with_index do |s1, i1|
          Suit.each_with_index do |s2, i2|
            expect(s1 <=> s2).to eq(i1 <=> i2)
          end
        end
      end
    end

    describe :== do
      it 'returns true for identical instances, false otherwise' do
        Suit.each do |s1|
          Suit.each do |s2|
            identical = s1.equal?(s2)
            expect(s1 == s2).to eq(identical)
          end
        end
      end

      it 'reports instances as unequal to nil and other objects' do
        a_nil_value = nil
        Suit.each do |s|
          expect(s.nil?).to eq(false)
          expect(s == a_nil_value).to eq(false)
          Tarot.each do |t|
            expect(s == t).to eq(false)
            expect(t == s).to eq(false)
          end
        end
      end

      # rubocop:disable Security/MarshalLoad
      it 'survives marshalling' do
        Suit.each do |s1|
          dump = Marshal.dump(s1)
          s2 = Marshal.load(dump)
          expect(s1 == s2).to eq(true)
          expect(s2 == s1).to eq(true)
        end
      end
      # rubocop:enable Security/MarshalLoad
    end

    describe :!= do
      it 'returns false for identical instances, true otherwise' do
        Suit.each do |s1|
          Suit.each do |s2|
            different = !s1.equal?(s2)
            expect(s1 != s2).to eq(different)
          end
        end
      end

      it 'reports instances as unequal to nil and other objects' do
        a_nil_value = nil
        Suit.each do |s|
          expect(s != a_nil_value).to eq(true)
          Tarot.each do |t|
            expect(s != t).to eq(true)
            expect(t != s).to eq(true)
          end
        end
      end
    end

    describe :hash do
      it 'gives consistent values' do
        Suit.each do |s1|
          Suit.each do |s2|
            expect(s1.hash == s2.hash).to eq(s1 == s2)
          end
        end
      end

      it 'returns different values for different types' do
        class Suit2 < Base
          new :CLUBS, 'Clubs'
          new :DIAMONDS, 'Diamonds'
          new :HEARTS, 'Hearts'
          new :SPADES, 'Spades'
        end

        Suit.each do |s1|
          s2 = Suit2.find_by_key(s1.key)
          expect(s1.hash == s2.hash).to eq(false)
        end
      end

      # rubocop:disable Security/MarshalLoad
      it 'survives marshalling' do
        Suit.each do |s1|
          dump = Marshal.dump(s1)
          s2 = Marshal.load(dump)
          expect(s2.hash).to eq(s1.hash)
        end
      end
      # rubocop:enable Security/MarshalLoad

      it 'always returns a Fixnum' do
        Suit.each do |s1|
          expect(s1.hash).to be_a(Integer)
        end
      end
    end

    describe :eql? do
      it 'is consistent with #hash' do
        Suit.each do |s1|
          Suit.each do |s2|
            expect(s1.eql?(s2)).to eq(s1.hash == s2.hash)
          end
        end
      end
    end

    describe :value do
      it 'returns the string value of the enum instance' do
        expected = %w[clubs diamonds hearts spades]
        Suit.each_with_index do |s, index|
          expect(s.value).to eq(expected[index])
        end
      end

      it 'returns an explicit value' do
        expected = [10, 100, 1000, 1_000_000]
        Scale.each_with_index do |s, index|
          expect(s.value).to eq(expected[index])
        end
      end

      it 'supports nil values' do
        expected = ['http', 'https', 'example', nil]
        Scheme.each_with_index do |s, index|
          expect(s.value).to eq(expected[index])
        end
      end
    end

    describe :key do
      it 'returns the symbol key of the enum instance' do
        expected = %i[CLUBS DIAMONDS HEARTS SPADES]
        Suit.each_with_index do |s, index|
          expect(s.key).to eq(expected[index])
        end
      end
    end

    describe :ord do
      it 'returns the ord value of the enum instance' do
        Suit.each_with_index do |s, index|
          expect(s.ord).to eq(index)
        end
      end
    end

    describe :to_s do
      it 'provides an informative string' do
        aggregate_failures 'informative string' do
          [Suit, Tarot, RGBColor, Scale, Scheme].each do |ec|
            ec.each do |ev|
              result = ev.to_s
              [ec.to_s, ev.key, ev.ord, ev.value.inspect].each do |info|
                expect(result).to include(info.to_s)
              end
            end
          end
        end
      end
    end

    describe :find_by_key do
      it 'maps symbol keys to enum instances' do
        keys = %i[CLUBS DIAMONDS HEARTS SPADES]
        expected = Suit.to_a
        keys.each_with_index do |k, index|
          expect(Suit.find_by_key(k)).to be(expected[index])
        end
      end

      it 'returns nil for invalid keys' do
        expect(Suit.find_by_key(:WANDS)).to be_nil
      end
    end

    describe :find_by_value do
      it 'maps values to enum instances' do
        values = %w[clubs diamonds hearts spades]
        expected = Suit.to_a
        values.each_with_index do |n, index|
          expect(Suit.find_by_value(n)).to be(expected[index])
        end
      end

      it 'returns nil for invalid values' do
        expect(Suit.find_by_value('wands')).to be_nil
      end

      it 'supports enums with symbol values' do
        RGBColor.each do |c|
          expect(RGBColor.find_by_value(c.value)).to be(c)
        end
      end

      it 'supports enums with integer values' do
        Scale.each do |s|
          expect(Scale.find_by_value(s.value)).to be(s)
        end
      end

      it 'supports enums with explicit nil values' do
        Scheme.each do |s|
          expect(Scheme.find_by_value(s.value)).to be(s)
        end
      end
    end

    describe :find_by_value! do
      it 'maps values to enum instances' do
        values = %w[clubs diamonds hearts spades]
        expected = Suit.to_a
        values.each_with_index do |n, index|
          expect(Suit.find_by_value!(n)).to be(expected[index])
        end
      end

      it 'throws EnumValidationError for invalid values' do
        expect { Suit.find_by_value!('wands') }.to raise_error(Exceptions::EnumValidationError)
      end

      it 'supports enums with symbol values' do
        RGBColor.each do |c|
          expect(RGBColor.find_by_value!(c.value)).to be(c)
        end
      end

      it 'supports enums with integer values' do
        Scale.each do |s|
          expect(Scale.find_by_value!(s.value)).to be(s)
        end
      end

      it 'supports enums with explicit nil values' do
        Scheme.each do |s|
          expect(Scheme.find_by_value!(s.value)).to be(s)
        end
      end
    end

    describe :find_by_value_str do
      it 'maps string values to enum instances' do
        values = %w[clubs diamonds hearts spades]
        expected = Suit.to_a
        values.each_with_index do |n, index|
          expect(Suit.find_by_value_str(n)).to be(expected[index])
        end
      end

      it 'returns nil for invalid values' do
        expect(Suit.find_by_value_str('wands')).to be_nil
      end

      it 'supports enums with symbol values' do
        RGBColor.each do |c|
          expect(RGBColor.find_by_value_str(c.value.to_s)).to be(c)
        end
      end

      it 'supports enums with integer values' do
        Scale.each do |s|
          expect(Scale.find_by_value_str(s.value.to_s)).to be(s)
        end
      end

      it 'supports enums with explicit nil values' do
        Scheme.each do |s|
          expect(Scheme.find_by_value_str(s.value)).to be(s)
        end
      end
    end

    describe :find_by_value_str! do
      it 'maps string values to enum instances' do
        values = %w[clubs diamonds hearts spades]
        expected = Suit.to_a
        values.each_with_index do |n, index|
          expect(Suit.find_by_value_str!(n)).to be(expected[index])
        end
      end

      it 'throws EnumValidationError for invalid values' do
        expect { Suit.find_by_value_str!('wands') }.to raise_error(Exceptions::EnumValidationError)
      end

      it 'supports enums with symbol values' do
        RGBColor.each do |c|
          expect(RGBColor.find_by_value_str!(c.value.to_s)).to be(c)
        end
      end

      it 'supports enums with integer values' do
        Scale.each do |s|
          expect(Scale.find_by_value_str!(s.value.to_s)).to be(s)
        end
      end

      it 'supports enums with explicit nil values' do
        Scheme.each do |s|
          expect(Scheme.find_by_value_str!(s.value)).to be(s)
        end
      end
    end

    describe :find_by_ord do
      it 'maps ordinal indices to enum instances' do
        Suit.each do |s|
          expect(Suit.find_by_ord(s.ord)).to be(s)
        end
      end

      it 'returns nil for negative indices' do
        expect(Suit.find_by_ord(-1)).to be_nil
      end

      it 'returns nil for out-of-range indices' do
        expect(Suit.find_by_ord(Suit.size)).to be_nil
      end

      it 'returns nil for invalid indices' do
        expect(Suit.find_by_ord(100)).to be_nil
      end
    end

    describe :class_name do
      it 'returns the demodulized class name' do
        expect(Super::Modular::Enum.send(:class_name)).to eq "Enum"
        expect(Suit.send(:class_name)).to eq "Suit"
      end
    end

    it 'supports case statements' do
      def pip(suit)
        case suit
        when Suit::CLUBS
          '♣'
        when Suit::DIAMONDS
          '♦'
        when Suit::HEARTS
          '♥'
        when Suit::SPADES
          '♠'
        else
          raise "unknown suit: #{self}"
        end
      end

      expect(Suit.map { |s| pip(s) }).to eq(%w[♣ ♦ ♥ ♠])
    end

    it 'supports "inner class" methods' do
      class Operation < Base
        new(:PLUS, '+') do
          def eval(x, y)
            x + y
          end
        end
        new(:MINUS, '-') do
          def eval(x, y)
            x - y
          end
        end
      end

      expect(Operation.map { |op| op.eval(39, 23) }).to eq([39 + 23, 39 - 23])
    end

    it 'is an Enumerable' do
      expect(Suit).to be_an(Enumerable)
    end
  end
end
