require 'spec_helper'

describe Days::App, type: :controller do
  describe "admin: entries" do
    fixtures :users, :categories, :entries
    let(:entry) { entries(:entry_one) }
    let(:user)  { users(:blogger) }

    before { login(user) }

    describe "GET /admin/entries" do
      subject { get '/admin/entries', {}, env }

      it_behaves_like 'an admin page'

      it { should be_ok }

      it "lists up entries" do
        render[:data].should == :'admin/entries/index'

        entries = render[:ivars][:@entries]
        entries.should == Days::Entry.all
      end
    end

    describe "GET /admin/entries/new" do
      subject { get '/admin/entries/new', {}, env }

      it_behaves_like 'an admin page'

      it { should be_ok }

      it "renders form page" do
        render[:data].should == :'admin/entries/form'
        entry = render[:ivars][:@entry]
        entry.should be_a(Days::Entry)
        entry.should be_new_record
      end
    end

    describe "POST /admin/entries" do
      subject { post '/admin/entries', params, env }
      let(:entry) { Days::Entry.last }
      let(:entry_params) { {title: "Hello", body: "World"} }
      let(:params) { {entry: entry_params} }

      it_behaves_like 'an admin page'

      it "creates entry" do
        subject.should be_redirect

        entry.title.should == "Hello"
        entry.body.should == "World"
        entry.user.should == user
      end

      context "when entry is invalid" do
        before do
          Days::Entry.any_instance.stub(:valid? => false, :save => false)
        end

        specify { subject.status.should == 406 } # not acceptable

        it "renders form" do
          render[:data].should == :'admin/entries/form'
          ientry = render[:ivars][:@entry]
          ientry.should be_a_new_record
          ientry.title.should == 'Hello'
          ientry.body.should == 'World'
        end
      end

      context "with category" do
        let(:categories) do
          Hash[Days::Category.pluck(:id).map{ |_| [_, '1'] }]
        end

        let(:params) do
          {entry: entry_params.merge(categories: categories)}
        end

        it { should be_redirect }

        it "creates entry with categories" do
          subject
          entry.categories.reload.map(&:id).should == Days::Category.pluck(:id)
        end
      end
    end

    describe "GET /admin/entries/:id" do
      subject { get "/admin/entries/#{entry.id}", {}, env }

      it_behaves_like 'an admin page'

      it "renders form page" do
        render[:data].should == :'admin/entries/form'
        render[:ivars][:@entry].should == entry
      end

      context "with invalid entry" do
        let(:entry) { double.tap { |_| _.stub(id: Days::Entry.last.id.succ) } }

        it { should be_not_found }
      end
    end

    describe "PUT /admin/entries/:id" do
      subject { put path, params, env }
      let(:path) { "/admin/entries/#{entry.id}" }
      let(:valid_params) { {entry: {title: 'New'}} }
      let(:params) { valid_params }

      it_behaves_like 'an admin page'

      it "updates entry" do
        subject.should be_redirect
        URI.parse(subject['Location']).path.should == path

        entry.reload
        entry.title.should == 'New'
        entry.body.should == 'a rainy day'
      end

      context "when invalid" do
        before do
          Days::Entry.any_instance.stub(:valid? => false, :save => false)
        end

        it "renders form" do
          render[:data].should == :'admin/entries/form'
          ientry = render[:ivars][:@entry]
          ientry.id.should == entry.id
          ientry.title.should == 'New'
          entry.title.should == 'Today was'
        end
      end

      context "with category" do
        let(:params) do
          {entry: {categories: {categories(:rainy).id.to_s => '1'}}}
        end

        it "creates entry with categories" do
          subject.should be_redirect
          entry.categories.reload.map(&:id).should == [categories(:rainy).id]
        end
      end

      context "with invalid entry" do
        let(:entry) { double.tap { |_| _.stub(id: Days::Entry.last.id.succ) } }

        it { should be_not_found }
      end
    end

    describe "DELETE /admin/entries/:id" do
      subject { delete "/admin/entries/#{entry.id}", {}, env }

      it_behaves_like 'an admin page'

      it "destroys entry" do
        expect { subject }.to change { Days::Entry.where(id: entry.id).count }.from(1).to(0)
        subject.should be_redirect
        URI.parse(subject.location).path.should == "/admin/entries"
      end

      context "with invalid entry" do
        let(:entry) { double.tap { |_| _.stub(id: Days::Entry.last.id.succ) } }

        it { should be_not_found }
      end
    end

    describe "POST /admin/entries/preview" do
      subject { post "/admin/entries/preview", params, env }
      let(:valid_params) { {} }
      let(:params) { valid_params }

      it_behaves_like 'an admin page'

      it "renders body for preview"
    end
  end
end
