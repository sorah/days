require 'spec_helper'

describe Days::App, type: :controller do
  describe "entry page" do
    let(:path) { '/2012/12/slug' }
    subject { get path, {}, {} }

    before do
      Days::App.any_instance.should_receive(:lookup_entry).at_least(:once).with(path).and_return(result)
    end

    let(:result) { Days::Entry.create!(title: 'foo', body: 'foo') }

    it { should be_ok }

    it "renders entry.haml" do
      render[:data].should == :entry
      render[:options][:locals][:entry].should == result
    end

    context "when lookup_entry returned nil" do
      let(:result) { nil }

      it { should be_not_found }
    end

    context "when lookup_entry returned Array" do
      let(:result) {
        [
          Days::Entry.create!(title: 'foo', body: 'foo'),
          Days::Entry.create!(title: 'foo2', body: 'foo')
        ]
      }

      it { should be_ok }

      it "renders entry.haml" do
        render[:data].should == :entries
        render[:ivars][:@entries].should == result
      end
    end
  end

  describe "redirection from old path" do
    let(:path) { nil }
    subject { get path, {}, {} }

    before do
      Days::App.any_instance.stub(lookup_entry: nil)
      Days::Entry.create!(title: 'new', body: 'foo', old_path:  '/post/old-path', published_at: Time.local(2012,11,30,0,0,0))
    end

    context "when entry not found" do
      let(:path) { '/post/like-old-but-not-exists' }

      it { should be_not_found }
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

    it { should be_ok }

    it "renders entries" do
      render[:data].should == :entries

      base = Time.local(2012, 12, 1, 0, 0, 0)
      range = (base.beginning_of_month .. base.end_of_month)
      render[:ivars][:@entries].to_a.should == Days::Entry.where(published_at: range).published.to_a
      render[:ivars][:@entries].current_page.should == 1
    end

    context "with page param" do
      let(:params) { {page: 2} }

      it "renders entries" do
        render[:data].should == :entries
        render[:ivars][:@entries].current_page.should == 2
      end
    end

    context "with character" do
      it "returns not found" do
        get('/aaa/01').should   be_not_found
        get('/2012/bbb').should be_not_found
        get('/aaa/bbb').should  be_not_found
      end
    end
  end

  describe "GET /category/:name" do
    subject { get '/category/cat', params }
    let(:params) { {} }

    it { should be_ok }

    let!(:category) { Days::Category.create!(name: 'cat') }
    let!(:entry) { Days::Entry.create!(title: 'a', body: 'a', categories: [category]) }

    it "renders entries" do
      render[:data].should == :entries

      render[:ivars][:@entries].to_a.should == category.entries.reload.published.to_a
      render[:ivars][:@entries].current_page.should == 1
    end

    context "with page param" do
      let(:params) { {page: 2} }

      it "renders entries" do
        render[:data].should == :entries
        render[:ivars][:@entries].current_page.should == 2
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
      render[:data].should == :entries
      render[:ivars][:@entries].current_page.should == 1
      render[:ivars][:@entries].should_not include(draft)
    end

    context "with page param" do
      let(:params) { {page: 2} }

      it "renders entries" do
        render[:data].should == :entries
        render[:ivars][:@entries].current_page.should == 2
      end
    end
  end

  describe "GET /feed" do
    subject { get '/feed' }

    it { should be_ok }

    specify do
      subject.content_type.should == 'application/atom+xml'
    end
  end
end
