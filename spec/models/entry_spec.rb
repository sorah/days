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

    it "generates slug"do
      subject.slug.should == 'slug'
    end

    context "with empty slug" do
      before do
        String.any_instance.stub(to_url: "slug")
        subject.slug = ""
        subject.save
      end

      it { should be_valid }

      it "generates slug"do
        subject.slug.should == 'slug'
      end
    end
  end

  describe "#published?" do
    context "with nullified published_at" do
      before do
        subject.published_at = nil
      end

      specify do
        subject.should_not be_published
      end

      specify do
        subject.should_not be_scheduled
      end
    end

    context "when after published_at" do
      before do
        base = Time.now
        Time.stub(now: base)
        subject.published_at = base - 1
      end

      specify do
        subject.should be_published
      end

      specify do
        subject.should_not be_scheduled
      end
    end

    context "when just published_at" do
      before do
        base = Time.now
        Time.stub(now: base)
        subject.published_at = base
      end

      specify do
        subject.should be_published
      end

      specify do
        subject.should_not be_scheduled
      end
    end

    context "when before published_at" do
      before do
        base = Time.now
        Time.stub(now: base)
        subject.published_at = base + 1
      end

      specify do
        subject.should_not be_published
      end

      specify do
        subject.should be_scheduled
      end
    end
  end

  describe "published scope" do
    before do
      described_class.create(title: 'A', body: 'a', draft: true)
      described_class.create(title: 'B', body: 'b', published_at: Time.local(2012,12,30,11,0,0))
      described_class.create(title: 'C', body: 'c', published_at: Time.local(2012,12,30, 9,0,0))
      described_class.create(title: 'D', body: 'd', published_at: Time.local(2013, 1, 1, 9,0,0))
      Time.stub(now: Time.local(2012,12,30, 14,0,0))
    end

    subject do
      described_class.published
    end

    it "orders by published_at" do
      subject.map(&:title).should == ['B', 'C']
    end

    it "rejects not published entries" do
      subject.map(&:title).should_not include('A')
      subject.map(&:title).should_not include('D')
    end

    context "all published" do
      before do
        Time.stub(now: Time.local(2013,1,1,14,0,0))
      end

      it "orders by published_at" do
        subject.map(&:title).should == ['D', 'B', 'C']
      end

      it "rejects not published entries" do
        subject.map(&:title).should_not include('A')
        subject.map(&:title).should include('D')
      end
    end
  end

  describe "draft attribute" do
    context "with true" do
      before do
        subject.published_at = Time.now
        subject.draft = true
        subject.valid?
      end

      it "nullifies published_at" do
        subject.published_at.should be_nil
      end
    end

    context "with false" do
      let!(:base) { Time.now }

      before do
        subject.draft = false
      end

      context "when published_at is nil" do
        before do
          Time.stub(now: base)
          subject.published_at = nil
          subject.valid?
        end

        it "fills published_at" do
          subject.published_at.should == base
        end
      end

      context "when published_at is not nil" do
        before do
          Time.stub(now: base + 1)
          subject.published_at = base
          subject.valid?
        end

        it "keeps published_at" do
          subject.published_at.should == base
        end
      end
    end
  end
end
