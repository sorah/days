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

  describe "GET /:year/:month" do
    fixtures :categories, :entries
    subject { get '/2012/12' }

    it { should be_ok }

    it "renders entries" do
      render[:data].should == :entries

      base = Time.local(2012, 12, 1, 0, 0, 0)
      range = (base.beginning_of_month .. base.end_of_month)
      render[:ivars][:@entries].to_a.should == Days::Entry.where(published_at: range).published.to_a
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
