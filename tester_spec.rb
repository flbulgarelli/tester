require 'active_support/all'

module Tester
  module Base
    def multi_sample?
      true
    end

    def test_for(spec)
      test_lines_for(spec).flatten.join("\n")
    end

    def sample_title_for(subject, sample)
      "#{application_for(subject, sample[:arguments])} should return #{sample[:return]}"
    end

    def application_for(subject, arguments)
      if arguments.blank?
        "#{subject}()"
      else
        "#{subject}(#{arguments.join(', ')})"
      end
    end
  end

  module Haskell
    extend Tester::Base

    def self.test_lines_for(spec)
      ["describe \"#{spec[:subject]}: \" $ do",
        spec[:examples].map { |sample| sample_lines_for(spec[:subject], sample) }
      ]
    end

    def self.sample_lines_for(subject, sample)
      [
        "  it \"#{sample_title_for(subject, sample)}\" $ do",
        "    #{application_for subject, sample[:arguments]} `shouldBe` #{sample[:return]}"
      ]
    end

    def self.application_for(subject, arguments)
      if arguments.blank?
        subject
      else
        "#{subject} #{arguments.join(' ')}"
      end
    end
  end

  module Gobstones
    extend Tester::Base

    def self.multi_sample?
      false
    end

    def self.test_lines_for(spec)
      [
        "subject: #{spec[:subject]}",
        "examples:",
        spec[:examples].map { |it| sample_lines_for spec[:subject], it }
      ]
    end

    def self.sample_lines_for(subject, sample)
      [
        "- title: #{sample_title_for(subject, sample)}",
        "  return: #{sample[:return]}"
      ]
    end
  end

  module Javascript
    extend Tester::Base

    def self.test_lines_for(spec)
      ["describe(\"#{spec[:subject]}: \", function() {",
        spec[:examples].map { |sample| sample_lines_for(spec[:subject], sample) },
        "});"
      ]
    end

    def self.sample_lines_for(subject, sample)
      [
        "  it(\"#{sample_title_for(subject, sample)}\", function() {",
        "    assertEqual(#{sample[:return]}, #{application_for subject, sample[:arguments]});",
        "  });"
      ]
    end
  end
end


def test_for(language, spec)
  return '' if spec[:examples].empty?
  "Tester::#{language.to_s.camelize}".constantize.test_for(spec)
end

def valid?(spec)
  !spec[:examples].nil? && spec[:examples].all? { |it| !it[:return].nil? }
end

describe "tester" do

  it { expect(Tester::Haskell.multi_sample?).to be true }
  it { expect(Tester::Javascript.multi_sample?).to be true }
  it { expect(Tester::Gobstones.multi_sample?).to be false }

  it { expect(test_for(:gobstones, examples: [])).to eq  ''  }
  it { expect(test_for(:gobstones, subject: 'pared', examples: [{return: :Negro}])).to eq(
'subject: pared
examples:
- title: pared() should return Negro
  return: Negro')  }



  it { expect(test_for(:haskell, examples: [])).to eq  ''  }

  it { expect(test_for(:haskell,
                    subject: :sumar,
                    examples: [
                      {arguments: [1, 1], return: 2}])).to eq(
'describe "sumar: " $ do
  it "sumar 1 1 should return 2" $ do
    sumar 1 1 `shouldBe` 2') }

  it { expect(test_for(:haskell,
                    subject: :sumar,
                    examples: [
                      {arguments: [1, 1], return: 2},
                      {arguments: [2, 3], return: 5}])).to eq(
'describe "sumar: " $ do
  it "sumar 1 1 should return 2" $ do
    sumar 1 1 `shouldBe` 2
  it "sumar 2 3 should return 5" $ do
    sumar 2 3 `shouldBe` 5') }

  it { expect(test_for(:haskell,
                    subject: :pi,
                    examples: [{return: 3.14}])).to eq(
'describe "pi: " $ do
  it "pi should return 3.14" $ do
    pi `shouldBe` 3.14') }

  it { expect(test_for(:haskell, examples: [])).to eq  ''  }

  it { expect(test_for(:javascript,
                    subject: :sumar,
                    examples: [
                      {arguments: [1, 1], return: 2}])).to eq(
'describe("sumar: ", function() {
  it("sumar(1, 1) should return 2", function() {
    assertEqual(2, sumar(1, 1));
  });
});') }


  it { expect(valid?(examples: [])).to be true }
  it { expect(valid?(subject: :sumar, examples: [{arguments: [1, 1], return: 2}])).to be true }
  it { expect(valid?(subject: :sumar, examples: [])).to be true }
  it { expect(valid?(subject: :sumar, example: [])).to be false }
  it { expect(valid?(subject: :sumar, examples: [{arguments: [1, 2]}])).to be false }
  it { expect(valid?(subject: :pi, examples: [{return: 3.14}])).to be true }
end

# data type handling
# name generation
# test code generation
# subject: ping
# examples:
# - input: ping
#   output: pong
# - input: foo
#  output: ':('
