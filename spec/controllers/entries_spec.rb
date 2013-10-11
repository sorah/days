require 'spec_helper'

describe Days::App, type: :controller do
  describe "entry page" do
    fixtures :categories, :entries
    let(:path) { '/2012/12/slug' }
    subject { get path, {}, {} }

    before do
      Days::App.any_instance.should_receive(:lookup_entry).at_least(:once).with(path).and_return(result)
    end

    let(:result) { entries(:entry_one) }

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
      let(:result) { [entries(:entry_one), entries(:entry_two)] }

      it { should be_ok }

      it "renders entry.haml" do
        render[:data].should == :entries
        render[:ivars][:@entries].should == result
      end
    end
  end

  describe "redirection from old path" do
    fixtures :categories, :entries
    let(:path) { nil }
    subject { get path, {}, {} }

    before do
      Days::App.any_instance.stub(lookup_entry: nil)
    end

    context "when entry not found" do
      let(:path) { '/post/like-old-but-not-exists' }

      it { should be_not_found }
    end

    context "when entry found by old path" do
      let(:path) { '/post/old-path' }

      it "redirects to present path" do
        expect(subject.status).to eq 301
        expect(subject['Location']).to eq '/2012/11/today-is-a-rainy-day'
      end
    end
  end

  describe "GET /:year/:month" do
    fixtures :categories, :entries
    subject { get '/2012/12', params }
    let(:params) { {} }

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
    fixtures :categories, :entries
    subject { get '/category/daily', params }
    let(:params) { {} }

    it { should be_ok }

    it "renders entries" do
      render[:data].should == :entries

      render[:ivars][:@entries].to_a.should == categories(:daily).entries.published.to_a
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
    fixtures :categories, :entries
    subject { get '/', params }
    let(:params) { {} }

    it "renders entries" do
      render[:data].should == :entries
      render[:ivars][:@entries].current_page.should == 1
      render[:ivars][:@entries].should_not include(entries(:entry_draft))
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
    fixtures :categories, :entries
    subject { get '/feed' }

    it { should be_ok }

    specify do
      subject.content_type.should == 'application/atom+xml'
    end
  end
end
