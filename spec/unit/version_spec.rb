# Source: https://github.com/jlindsey/semantic. Released under the MIT license.
require 'spec_helper'

describe Semantic::Version do
  before(:each) do
    @test_versions = [
      '1.0.0',
      '12.45.182',
      '0.0.1-pre.1',
      '1.0.1-pre.5+build.123.5',
      '1.1.1+123',
      '0.0.0+hello',
      '1.2.3-1'
    ]

    @bad_versions = [
      'a.b.c',
      '1.a.3',
      'a.3.4',
      '5.2.a',
      'pre3-1.5.3',
      "I am not a valid semver\n0.0.0\nbut I still pass"
    ]
  end

  context "parsing" do
    it "parses valid SemVer versions" do
      @test_versions.each do |v|
        expect { Semantic::Version.new v }.to_not raise_error()
      end
    end

    it "raises an error on invalid versions" do
      @bad_versions.each do |v|
        expect { Semantic::Version.new v }.to raise_error()
      end
    end

    it "stores parsed versions in member variables" do
      v1 = Semantic::Version.new '1.5.9'
      expect(v1.major).to eq 1
      expect(v1.minor).to eq 5
      expect(v1.patch).to eq 9
      expect(v1.pre).to be_nil
      expect(v1.build).to be_nil

      v2 = Semantic::Version.new '0.0.1-pre.1'
      expect(v2.major).to eq 0
      expect(v2.minor).to eq 0
      expect(v2.patch).to eq 1
      expect(v2.pre).to eq 'pre.1'
      expect(v2.build).to be_nil

      v3 = Semantic::Version.new '1.0.1-pre.5+build.123.5'
      expect(v3.major).to eq 1
      expect(v3.minor).to eq 0
      expect(v3.patch).to eq 1
      expect(v3.pre).to eq 'pre.5'
      expect(v3.build).to eq 'build.123.5'

      v4 = Semantic::Version.new '0.0.0+hello'
      expect(v4.major).to eq 0
      expect(v4.minor).to eq 0
      expect(v4.patch).to eq 0
      expect(v4.pre).to be_nil
      expect(v4.build).to eq 'hello'
    end

    it "provides round-trip fidelity for an empty build parameter" do
      v = Semantic::Version.new("1.2.3")
      v.build = ""
      expect(Semantic::Version.new(v.to_s).build).to eq(v.build)
    end

    it "provides round-trip fidelity for a nil build parameter" do
      v = Semantic::Version.new("1.2.3+build")
      v.build = nil
      expect(Semantic::Version.new(v.to_s).build).to eq(v.build)
    end
  end

  context "comparisons" do
    before(:each) do
      # These three are all semantically equivalent, according to the spec.
      @v1_5_9_pre_1 = Semantic::Version.new '1.5.9-pre.1'
      @v1_5_9_pre_1_build_5127 = Semantic::Version.new '1.5.9-pre.1+build.5127'
      @v1_5_9_pre_1_build_4352 = Semantic::Version.new '1.5.9-pre.1+build.4352'

      @v1_5_9 = Semantic::Version.new '1.5.9'
      @v1_6_0 = Semantic::Version.new '1.6.0'
    end

    it "determines sort order" do
      # The second parameter here can be a string, so we want to ensure that this kind of comparison works also.
      expect(@v1_5_9_pre_1 <=> @v1_5_9_pre_1.to_s).to eq 0

      expect(@v1_5_9_pre_1 <=> @v1_5_9_pre_1_build_5127).to eq 0
      expect(@v1_5_9_pre_1 <=> @v1_5_9).to eq -1
      expect(@v1_5_9_pre_1_build_5127 <=> @v1_5_9).to eq -1

      expect(@v1_5_9_pre_1_build_5127.build).to eq 'build.5127'

      expect(@v1_5_9 <=> @v1_5_9).to eq 0

      expect(@v1_5_9 <=> @v1_6_0).to eq -1
      expect(@v1_6_0 <=> @v1_5_9).to eq 1
      expect(@v1_6_0 <=> @v1_5_9_pre_1).to eq 1
      expect(@v1_5_9_pre_1 <=> @v1_6_0).to eq -1

      expect([@v1_5_9_pre_1, @v1_5_9_pre_1_build_5127, @v1_5_9, @v1_6_0]
        .reverse
        .sort
        ).to eq [@v1_5_9_pre_1, @v1_5_9_pre_1_build_5127, @v1_5_9, @v1_6_0]
    end

    it "determines whether it is greater than another instance" do
      # These should be equal, since "Build metadata SHOULD be ignored when determining version precedence".
      # (SemVer 2.0.0-rc.2, paragraph 10 - http://www.semver.org)
      expect(@v1_5_9_pre_1).to_not be > @v1_5_9_pre_1_build_5127
      expect(@v1_5_9_pre_1).to_not be < @v1_5_9_pre_1_build_5127

      expect(@v1_6_0).to be > @v1_5_9
      expect(@v1_5_9).to_not be > @v1_6_0
      expect(@v1_5_9).to be > @v1_5_9_pre_1_build_5127
      expect(@v1_5_9).to be > @v1_5_9_pre_1
    end

    it "determines whether it is less than another instance" do
      expect(@v1_5_9_pre_1).to_not be < @v1_5_9_pre_1_build_5127
      expect(@v1_5_9_pre_1_build_5127).to_not be < @v1_5_9_pre_1
      expect(@v1_5_9_pre_1).to be < @v1_5_9
      expect(@v1_5_9_pre_1).to be < @v1_6_0
      expect(@v1_5_9_pre_1_build_5127).to be < @v1_6_0
      expect(@v1_5_9).to be < @v1_6_0
    end

    it "determines whether it is greater than or equal to another instance" do
      expect(@v1_5_9_pre_1).to be >= @v1_5_9_pre_1
      expect(@v1_5_9_pre_1).to be >= @v1_5_9_pre_1_build_5127
      expect(@v1_5_9_pre_1_build_5127).to be >= @v1_5_9_pre_1
      expect(@v1_5_9).to be >= @v1_5_9_pre_1
      expect(@v1_6_0).to be >= @v1_5_9
      expect(@v1_5_9_pre_1_build_5127).to_not be >= @v1_6_0
    end

    it "determines whether it is less than or equal to another instance" do
      expect(@v1_5_9_pre_1).to be <= @v1_5_9_pre_1_build_5127
      expect(@v1_6_0).to_not be <= @v1_5_9
      expect(@v1_5_9_pre_1_build_5127).to be <= @v1_5_9_pre_1_build_5127
      expect(@v1_5_9).to_not be <= @v1_5_9_pre_1
    end

    it "determines whether it is semantically equal to another instance" do
      expect(@v1_5_9_pre_1).to be == @v1_5_9_pre_1.dup
      expect(@v1_5_9_pre_1_build_5127).to be == @v1_5_9_pre_1_build_5127.dup

      # "Semantically equal" is the keyword here; these are by definition not "equal" (different build), but should be treated as
      # equal according to the spec.
      expect(@v1_5_9_pre_1_build_4352).to be == @v1_5_9_pre_1_build_5127
      expect(@v1_5_9_pre_1_build_4352).to be == @v1_5_9_pre_1
    end

    it "determines whether it satisfies >= style specifications" do
      expect(@v1_6_0.satisfies('>=1.6.0')).to be true
      expect(@v1_6_0.satisfies('<=1.6.0')).to be true
      expect(@v1_6_0.satisfies('>=1.5.0')).to be true
      expect(@v1_6_0.satisfies('<=1.5.0')).to_not be true

      # partial / non-semver numbers after comparator are extremely common in
      # version specifications in the wild

      expect(@v1_6_0.satisfies('>1.5')).to be true
      expect(@v1_6_0.satisfies('<1')).to_not be true
    end

    it "determines whether it satisfies * style specifications" do
      expect(@v1_6_0.satisfies('1.*')).to be true
      expect(@v1_6_0.satisfies('1.6.*')).to be true
      expect(@v1_6_0.satisfies('2.*')).to_not be true
      expect(@v1_6_0.satisfies('1.5.*')).to_not be true
    end

    it "determines whether it satisfies ~ style specifications" do
      expect(@v1_6_0.satisfies('~1.6')).to be true
      expect(@v1_5_9_pre_1.satisfies('~1.5')).to be true
      expect(@v1_6_0.satisfies('~1.5')).to_not be true
    end
  end

  context "type coercions" do
    it "converts to a string" do
      @test_versions.each do |v|
        expect(Semantic::Version.new(v).to_s).to eq v
      end
    end

    it "converts to an array" do
      expect(Semantic::Version.new('1.0.0').to_a).to eq [1, 0, 0, nil, nil]
      expect(Semantic::Version.new('6.1.4-pre.5').to_a).to eq [6, 1, 4, 'pre.5', nil]
      expect(Semantic::Version.new('91.6.0+build.17').to_a).to eq [91, 6, 0, nil, 'build.17']
      expect(Semantic::Version.new('0.1.5-pre.7+build191').to_a).to eq [0, 1, 5, 'pre.7', 'build191']
    end

    it "converts to a hash" do
      expect(Semantic::Version.new('1.0.0').to_h).to eq({ major: 1, minor: 0, patch: 0, pre: nil, build: nil })
      expect(Semantic::Version.new('6.1.4-pre.5').to_h).to eq({ major: 6, minor: 1, patch: 4, pre: 'pre.5', build: nil })
      expect(Semantic::Version.new('91.6.0+build.17').to_h).to eq({ major: 91, minor: 6, patch: 0, pre: nil, build: 'build.17' })
      expect(Semantic::Version.new('0.1.5-pre.7+build191').to_h).to eq({ major: 0, minor: 1, patch: 5, pre: 'pre.7', build: 'build191' })
    end

    it "aliases conversion methods" do
      v = Semantic::Version.new('0.0.0')
      [:to_hash, :to_array, :to_string].each { |sym| expect(v).to respond_to(sym) }
    end
  end

  describe '#major!' do
    subject { described_class.new('1.2.3-pre1+build2') }

    context 'changing the major term' do
      it 'changes the major version and resets the others' do
        expect(subject.major!).to eq '2.0.0'
      end
    end
  end

  describe '#minor' do
    subject { described_class.new('1.2.3-pre1+build2') }

    context 'changing the minor term' do
      it 'changes minor term and resets patch, pre and build' do
        expect(subject.minor!).to eq '1.3.0'
      end
    end
  end

  describe '#patch' do
    subject { described_class.new('1.2.3-pre1+build2') }

    context 'changing the patch term' do
      it 'changes the patch term and resets the pre and build' do
        expect(subject.patch!).to eq '1.2.4'
      end
    end
  end
end
