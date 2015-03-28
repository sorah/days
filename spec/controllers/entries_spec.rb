require 'spec_helper'

describe Days::App, type: :controller do
  describe "entry page" do
    let(:path) { '/2012/12/slug' }
    subject { get path, {}, {} }

    before do
      expect_any_instance_of(Days::App).to receive(:lookup_entry).at_least(:once).with(path).and_return(result)
    end

    let(:result) { Days::Entry.create!(title: 'foo', body: 'foo') }

    it { is_expected.to be_ok }

    it "renders entry.haml" do
      expect(render[:data]).to eq(:entry)
      expect(render[:options][:locals][:entry]).to eq(result)
    end

    context "when lookup_entry returned nil" do
      let(:result) { nil }

      it { is_expected.to be_not_found }
    end

    context "when lookup_entry returned Array" do
      let(:result) {
        [
          Days::Entry.create!(title: 'foo', body: 'foo'),
          Days::Entry.create!(title: 'foo2', body: 'foo')
        ]
      }

      it { is_expected.to be_ok }

      it "renders entry.haml" do
        expect(render[:data]).to eq(:entries)
        expect(render[:ivars][:@entries]).to eq(result)
      end
    end
  end

  describe "redirection from old path" do
    let(:path) { nil }
    subject { get path, {}, {} }

    before do
      allow_any_instance_of(Days::App).to receive_messages(lookup_entry: nil)
      Days::Entry.create!(title: 'new', body: 'foo', old_path:  '/post/old-path', published_at: Time.local(2012,11,30,0,0,0))
    end

    context "when entry not found" do
      let(:path) { '/post/like-old-but-not-exists' }

      it { is_expected.to be_not_found }
    end

    context "when entry found by old path" do
      let(:path) { '/post/old-path' }

      it "redirects to present path" do
        expect(subject.status).to eq 301
        expect(subject['Location']).to eq '/2012/11/new'
      end
    end
  end

  describe "GET /:year/:month" do
    subject { get '/2012/12', params }
    let(:params) { {} }

    before do
      Days::Entry.create!(title: '1', body: 'a', published_at: Time.local(2012, 11, 15, 0, 0, 0))
      Days::Entry.create!(title: '2', body: 'a', published_at: Time.local(2012, 12, 25, 0, 0, 0))
      Days::Entry.create!(title: '3', body: 'a', published_at: Time.local(2012, 12, 5, 0, 0, 0))
    end

    it { is_expected.to be_ok }

    it "renders entries" do
      expect(render[:data]).to eq(:entries)

      base = Time.local(2012, 12, 1, 0, 0, 0)
      range = (base.beginning_of_month .. base.end_of_month)
      expect(render[:ivars][:@entries].to_a).to eq(Days::Entry.where(published_at: range).published.to_a)
      expect(render[:ivars][:@entries].current_page).to eq(1)
    end

    context "with page param" do
      let(:params) { {page: 2} }

      it "renders entries" do
        expect(render[:data]).to eq(:entries)
        expect(render[:ivars][:@entries].current_page).to eq(2)
      end
    end

    context "with character" do
      it "returns not found" do
        expect(get('/aaa/01')).to   be_not_found
        expect(get('/2012/bbb')).to be_not_found
        expect(get('/aaa/bbb')).to  be_not_found
      end
    end
  end

  describe "GET /category/:name" do
    subject { get '/category/cat', params }
    let(:params) { {} }

    it { is_expected.to be_ok }

    let!(:category) { Days::Category.create!(name: 'cat') }
    let!(:entry) { Days::Entry.create!(title: 'a', body: 'a', categories: [category]) }

    it "renders entries" do
      expect(render[:data]).to eq(:entries)

      expect(render[:ivars][:@entries].to_a).to eq(category.entries.reload.published.to_a)
      expect(render[:ivars][:@entries].current_page).to eq(1)
    end

    context "with page param" do
      let(:params) { {page: 2} }

      it "renders entries" do
        expect(render[:data]).to eq(:entries)
        expect(render[:ivars][:@entries].current_page).to eq(2)
      end
    end
  end

  describe "GET /" do
    subject { get '/', params }
    let(:params) { {} }

    before do
      Days::Entry.create!(title: '1', body: 'a', published_at: Time.local(2012, 11, 15, 0, 0, 0))
      Days::Entry.create!(title: '2', body: 'a', published_at: Time.local(2012, 12, 25, 0, 0, 0))
    end

    let!(:draft) do
      Days::Entry.create!(title: '3', body: 'a', draft: true)
    end

    it "renders entries" do
      expect(render[:data]).to eq(:entries)
      expect(render[:ivars][:@entries].current_page).to eq(1)
      expect(render[:ivars][:@entries]).not_to include(draft)
    end

    context "with page param" do
      let(:params) { {page: 2} }

      it "renders entries" do
        expect(render[:data]).to eq(:entries)
        expect(render[:ivars][:@entries].current_page).to eq(2)
      end
    end
  end

  describe "GET /feed" do
    subject { get '/feed' }

    it { is_expected.to be_ok }

    specify do
      expect(subject.content_type).to eq('application/atom+xml')
    end
  end

  describe "GET /feed/category/:name" do
    let!(:category) { Days::Category.create!(name: 'cat') }
    subject { get '/feed/category/cat' }

    it { is_expected.to be_ok }

    specify do
      expect(subject.content_type).to eq('application/atom+xml')
    end
  end
end
