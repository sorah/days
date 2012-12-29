require 'spec_helper'

describe Days::Entry do
  before do
    described_class.destroy_all
  end

  after do
    described_class.destroy_all
  end

  subject do
    described_class.new(title: 'title', body: 'a')
  end


  describe "rendering" do
    subject do
      described_class.new(title: 'title', body: 'a')
    end

    before do
      Redcarpet::Markdown.any_instance.stub(render: "(sun)")
      subject.save
    end

    it { should be_valid }

    specify do
      subject.rendered.should == "(sun)"
    end
  end

  describe "slug" do
    before do
      String.any_instance.stub(to_url: "slug")
      subject.save
    end

    it { should be_valid }

    specify do
      subject.slug.should == 'slug'
    end
  end
end
