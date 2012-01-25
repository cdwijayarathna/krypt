# -*- encoding: utf-8 -*-

require 'rspec'
require 'krypt-core'
require 'openssl'

describe Krypt::ASN1::UTF8String do 
  let(:klass) { Krypt::ASN1::UTF8String }
  let(:decoder) { Krypt::ASN1 }

  # For test against OpenSSL
  #
  #let(:klass) { OpenSSL::ASN1::UTF8String }
  #let(:decoder) { OpenSSL::ASN1 }
  #
  # OpenSSL stub for signature mismatch
  class OpenSSL::ASN1::UTF8String
    class << self
      alias old_new new
      def new(*args)
        if args.size > 1
          args = [args[0], args[1], :IMPLICIT, args[2]]
        end
        old_new(*args)
      end
    end
  end
  
  def _A(str)
    str.force_encoding("ASCII-8BIT")
  end

  describe '#new' do
    context 'gets value for construct' do
      subject { klass.new(value) }

      context '$B$3$s$K$A$O!"@$3&!*(B' do
        let(:value) { '$B$3$s$K$A$O!"@$3&!*(B' }

        its(:tag) { should == Krypt::ASN1::UTF8_STRING }
        its(:tag_class) { should == :UNIVERSAL }
        its(:value) { should == '$B$3$s$K$A$O!"@$3&!*(B' }
        its(:infinite_length) { should == false }
      end

      context '(empty)' do
        let(:value) { '' }

        its(:value) { should == '' }
      end
    end

    context 'gets explicit tag number as the 2nd argument' do
      subject { klass.new('$B$3$s$K$A$O!"@$3&!*(B', tag, :PRIVATE) }

      context 'default tag' do
        let(:tag) { Krypt::ASN1::UTF8_STRING }
        its(:tag) { should == tag }
      end

      context 'custom tag (allowed?)' do
        let(:tag) { 14 }
        its(:tag) { should == tag }
      end
    end

    context 'gets tag class symbol as the 3rd argument' do
      subject { klass.new('$B$3$s$K$A$O!"@$3&!*(B', Krypt::ASN1::UTF8_STRING, tag_class) }

      context 'UNIVERSAL' do
        let(:tag_class) { :UNIVERSAL }
        its(:tag_class) { should == tag_class }
      end

      context 'APPLICATION' do
        let(:tag_class) { :APPLICATION }
        its(:tag_class) { should == tag_class }
      end

      context 'CONTEXT_SPECIFIC' do
        let(:tag_class) { :CONTEXT_SPECIFIC }
        its(:tag_class) { should == tag_class }
      end

      context 'PRIVATE' do
        let(:tag_class) { :PRIVATE }
        its(:tag_class) { should == tag_class }
      end

      context 'unknown tag_class' do
        context nil do
          let(:tag_class) { nil }
          it { -> { subject }.should raise_error ArgumentError } # TODO: ossl does not check value
        end

        context :no_such_class do
          let(:tag_class) { :no_such_class }
          it { -> { subject }.should raise_error ArgumentError } # TODO: ossl does not check value
        end
      end
    end

    context 'when the 2nd argument is given but 3rd argument is omitted' do
      subject { klass.new('$B$3$s$K$A$O!"@$3&!*(B', Krypt::ASN1::UTF8_STRING) }
      its(:tag_class) { should == :CONTEXT_SPECIFIC }
    end
  end

  describe '#to_der' do
    context 'encodes a given value' do
      subject { klass.new(value).to_der }

      context '$B$3$s$K$A$O!"@$3&!*(B' do
        let(:value) { '$B$3$s$K$A$O!"@$3&!*(B' }
        it { should == _A("\x0C\x18" + value) }
      end

      context '(empty)' do
        let(:value) { '' }
        it { should == "\x0C\x00" }
      end

      context '1000 octets' do
        let(:value) { '$B$"(B' * 1000 }
        it { should == _A("\x0C\x82\x1F\x40" + value) }
      end
    end

    context 'encodes tag number' do
      let(:value) { '$B$3$s$K$A$O!"@$3&!*(B' }
      subject { klass.new(value, tag, :PRIVATE).to_der }

      context 'default tag' do
        let(:tag) { Krypt::ASN1::UTF8_STRING }
        it { should == _A("\xCC\x18" + value) }
      end

      context 'custom tag (TODO: allowed?)' do
        let(:tag) { 14 }
        it { should == _A("\xCE\x18" + value) }
      end
    end

    context 'encodes tag class' do
      let(:value) { '$B$3$s$K$A$O!"@$3&!*(B' }
      subject { klass.new(value, Krypt::ASN1::UTF8_STRING, tag_class).to_der }

      context 'UNIVERSAL' do
        let(:tag_class) { :UNIVERSAL }
        it { should == _A("\x0C\x18" + value) }
      end

      context 'APPLICATION' do
        let(:tag_class) { :APPLICATION }
        it { should == _A("\x4C\x18" + value) }
      end

      context 'CONTEXT_SPECIFIC' do
        let(:tag_class) { :CONTEXT_SPECIFIC }
        it { should == _A("\x8C\x18" + value) }
      end

      context 'PRIVATE' do
        let(:tag_class) { :PRIVATE }
        it { should == _A("\xCC\x18" + value) }
      end
    end
  end

  describe 'extracted from ASN1.decode' do
    subject { decoder.decode(der) }

    context 'extracted value' do
      context '$B$3$s$K$A$O!"@$3&!*(B' do
        let(:value) { '$B$3$s$K$A$O!"@$3&!*(B' }
        let(:der) { _A("\x0C\x18" + value) }
        its(:class) { should == klass }
        its(:tag) { should == Krypt::ASN1::UTF8_STRING }
        its(:value) { should == value }
      end

      context '(empty)' do
        let(:der) { "\x0C\x00" }
        its(:class) { should == klass }
        its(:tag) { should == Krypt::ASN1::UTF8_STRING }
        #its(:value) { should == '' }
        its(:value) { should == nil } #TODO: discuss
      end

      context '1000 octets' do
        let(:value) { '$B$"(B' * 1000 }
        let(:der) { _A("\x0C\x82\x1F\x40" + value) }
        its(:class) { should == klass }
        its(:tag) { should == Krypt::ASN1::UTF8_STRING }
        its(:value) { should == value }
      end
    end

    context 'extracted tag class' do
      let(:value) { '$B$3$s$K$A$O!"@$3&!*(B' }

      context 'UNIVERSAL' do
        let(:der) { _A("\x0C\x18" + value) }
        its(:tag_class) { should == :UNIVERSAL }
      end

      context 'APPLICATION' do
        let(:der) { _A("\x4C\x18" + value) }
        its(:tag_class) { should == :APPLICATION }
      end

      context 'CONTEXT_SPECIFIC' do
        let(:der) { _A("\x8C\x18" + value) }
        its(:tag_class) { should == :CONTEXT_SPECIFIC }
      end

      context 'PRIVATE' do
        let(:der) { _A("\xCC\x18" + value) }
        its(:tag_class) { should == :PRIVATE }
      end
    end
  end
end
