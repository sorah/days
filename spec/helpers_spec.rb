require 'spec_helper'
require 'days/helpers'

describe Days::Helpers do
  include described_class

  let(:config) do
    double.tap do |_|
      _.stub(permalink: permalink)
    end
  end

  let!(:entry_a) do
    Days::Entry.create!(
      title: 'Sushi', body: 'Sushi!',
      published_at: Time.local(2012, 12, 31, 9, 24, 42),
      slug: "sushi"
    )
  end

  let!(:entry_b) do
    Days::Entry.create!(
      title: 'Neko', body: 'Meow!',
      published_at: Time.local(2012, 12, 31, 19, 14, 32),
      slug: "neko"
    )
  end

  let(:permalink) { "/{year}/{month}/{day}/{hour}/{minute}/{second}/{id}-{slug}" }

  describe ".#entry_path" do
    subject { entry_path(entry_a) }

    it { should == "/2012/12/31/09/24/42/#{entry_a.id}-sushi" }

    context "with invalid format (unbalanced parenthesis)" do
      let(:permalink) { "/{year}/{month}/{day/{hour}/{minute}/{second}/{id}-{slug" }

      it { should == "/2012/12/{day/09/24/42/#{entry_a.id}-{slug" }
    end

    context "with invalid format (invalid tag name)" do
      let(:permalink) { "/{foo}-{slug}" }

      it { should == "/-sushi" }
    end

    context "with not published entry" do
      before do
        entry_a.stub(published?: false)
      end

      it { should be_nil }
    end
  end

  describe ".#lookup_entry" do
    # Regexp.compile(Regexp.escape(a).gsub(/\\{(\w+?)\\}/) { "(?<#{$1}>.+?)" } + "$")
    subject { lookup_entry(path) }

    let(:path) { "/2012/12/31/09/24/42/#{entry_a.id}-sushi" }

    it { should == entry_a }

    context "with invalid link" do
      let(:path) { "/2012/12/31/09/24//#{entry_a.id}-sushi" }

      it { should be_nil }
    end

    context "with another format" do
      let(:permalink) { "/{year}/{month}/{day}/{slug}" }
      let(:path) { "/2012/12/31/sushi" }

      it { should == entry_a }
    end

    context "with invalid format (unbalanced parenthesis)" do
      let(:permalink) { "/{year}/{month}/{day/{slug}" }
      let(:path) { "/2012/12/31/sushi" }

      it { should be_nil }
    end

    context "with invalid format (invalid tag name)" do
      let(:permalink) { "/{year}/{month}/{sushi}/{slug}" }
      let(:path) { "/2012/12/31/sushi" }
    end

    context "when query has multiple result" do
      let(:permalink) { "/{year}/{month}/{day}" }
      let(:path) { "/2012/12/31" }

      it { should == [entry_a, entry_b] }
    end

    context "when entry has not published" do
      before do
        entry_a.draft = true
        entry_a.save
      end

      it { should be_nil }
    end
  end
end
