require 'spec_helper'

describe Days::Entry do
  subject do
    described_class.new(title: 'title', body: 'a')
  end

  describe "#render!" do
    def generate_pipeline(rendered_text)
      double("pipeline(#{rendered_text.inspect})").tap do |d|
        allow(d).to receive(:call) do |text|
          expect(text).to eq 'text'
          {output: rendered_text}
        end
      end
    end

    let(:pipeline) do

    end

    subject do
      described_class.new(title: 'title', body: 'text')
    end

    before do
      allow(described_class).to receive(:default_pipeline).and_return(generate_pipeline('default'))
    end

    context "without pipeline, @pipeline" do
      it "uses default_pipeline" do
        expect {
          subject.render!
        }.to change {
          subject.rendered
        }.from(nil).to('default')
      end
    end

    context "with @pipeline" do
      before do
        subject.pipeline = generate_pipeline('instance')
      end

      it "uses @pipeline" do
        expect {
          subject.render!
        }.to change {
          subject.rendered
        }.from(nil).to('instance')
      end
    end

    context "with pipeline" do
      it "uses passed argument" do
        expect {
          subject.render!(pipeline: generate_pipeline('arg'))
        }.to change {
          subject.rendered
        }.from(nil).to('arg')
      end
    end
  end

  describe "auto-rendering" do
    subject do
      described_class.new(title: 'title', body: 'a')
    end

    before do
      allow(subject).to receive(:render!) do
        subject.rendered = 'rendered'
      end
    end

    context "normal" do
      before do
        subject.save
      end

      it { is_expected.to be_valid }

      specify do
        expect(subject.rendered).to eq('rendered')
      end
    end

    context "modified body" do
      before do
        subject.save!
        subject.rendered = ''
        subject.body = 'b'
        subject.save
      end

      it { is_expected.to be_valid }

      specify do
        expect(subject.rendered).to eq('rendered')
      end
    end
  end

  describe "slug" do
    before do
      allow_any_instance_of(String).to receive_messages(to_url: "slug")
      subject.save
    end

    it { is_expected.to be_valid }

    it "generates slug"do
      expect(subject.slug).to eq('slug')
    end

    context "with empty slug" do
      before do
        allow_any_instance_of(String).to receive_messages(to_url: "slug")
        subject.slug = ""
        subject.save
      end

      it { is_expected.to be_valid }

      it "generates slug"do
        expect(subject.slug).to eq('slug')
      end
    end
  end

  describe "#published?" do
    context "with nullified published_at" do
      before do
        subject.published_at = nil
      end

      specify do
        expect(subject).not_to be_published
      end

      specify do
        expect(subject).not_to be_scheduled
      end
    end

    context "when after published_at" do
      before do
        base = Time.now
        allow(Time).to receive_messages(now: base)
        subject.published_at = base - 1
      end

      specify do
        expect(subject).to be_published
      end

      specify do
        expect(subject).not_to be_scheduled
      end
    end

    context "when just published_at" do
      before do
        base = Time.now
        allow(Time).to receive_messages(now: base)
        subject.published_at = base
      end

      specify do
        expect(subject).to be_published
      end

      specify do
        expect(subject).not_to be_scheduled
      end
    end

    context "when before published_at" do
      before do
        base = Time.now
        allow(Time).to receive_messages(now: base)
        subject.published_at = base + 1
      end

      specify do
        expect(subject).not_to be_published
      end

      specify do
        expect(subject).to be_scheduled
      end
    end
  end

  describe "published scope" do
    before do
      described_class.create(title: 'A', body: 'a', draft: true)
      described_class.create(title: 'B', body: 'b', published_at: Time.local(2012,12,30,11,0,0))
      described_class.create(title: 'C', body: 'c', published_at: Time.local(2012,12,30, 9,0,0))
      described_class.create(title: 'D', body: 'd', published_at: Time.local(2013, 1, 1, 9,0,0))
      allow(Time).to receive_messages(now: Time.local(2012,12,30, 14,0,0))
    end

    subject do
      described_class.published
    end

    it "orders by published_at" do
      expect(subject.map(&:title)).to eq(['B', 'C'])
    end

    it "rejects not published entries" do
      expect(subject.map(&:title)).not_to include('A')
      expect(subject.map(&:title)).not_to include('D')
    end

    context "all published" do
      before do
        allow(Time).to receive_messages(now: Time.local(2013,1,1,14,0,0))
      end

      it "orders by published_at" do
        expect(subject.map(&:title)).to eq(['D', 'B', 'C'])
      end

      it "rejects not published entries" do
        expect(subject.map(&:title)).not_to include('A')
        expect(subject.map(&:title)).to include('D')
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
        expect(subject.published_at).to be_nil
      end
    end

    context "with false" do
      let!(:base) { Time.now }

      before do
        subject.draft = false
      end

      context "when published_at is nil" do
        before do
          allow(Time).to receive_messages(now: base)
          subject.published_at = nil
          subject.valid?
        end

        it "fills published_at" do
          expect(subject.published_at).to eq(base)
        end
      end

      context "when published_at is not nil" do
        before do
          allow(Time).to receive_messages(now: base + 1)
          subject.published_at = base
          subject.valid?
        end

        it "keeps published_at" do
          expect(subject.published_at).to eq(base)
        end
      end
    end
  end

  describe "#short_rendered" do
    subject do
      described_class.new(title: 'title', body: body)
    end

    before do
      subject.valid?
    end

    let(:body) { "a\n\n<!--more-->\n\nb" }

    it "deletes after <!--more-->" do
      expect(subject.short_rendered).to eq("<p>a</p>\n")
    end

    context "without <!--more--> in body" do
      let(:body) { "a\n\nb" }

      it "returns entire rendered body" do
        expect(subject.short_rendered).to eq(subject.rendered)
      end
    end

    context "with block" do
      it "replaces by block evaluation result" do
        expect(subject.short_rendered { "hi!" }).to eq("<p>a</p>\nhi!")
      end
    end
  end
end
