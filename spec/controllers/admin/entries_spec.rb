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

      it { should be_success }

      it "lists up entries" do
        render[:data].should == 'admin/entries/index'

        entries = render[:ivars][:@entries]
        entries.should == Entry.all
      end
    end

    describe "GET /admin/entries/new" do
      subject { get '/admin/entries/new', {}, env }

      it_behaves_like 'an admin page'

      it { should be_success }

      it "renders form page" do
        render[:data].should == 'admin/entries/form'
        entry = render[:ivars][:@entry]
        entry.should be_a(Days::Entry)
        entry.should be_new
      end
    end

    describe "POST /admin/entries/create" do
      subject { post '/admin/entries/create', params, env }
      subject(:entry) { Entry.last }
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
          Entry.any_instance.stub(:valid? => false, :save => false)
        end

        specify { subject.status.should == 406 } # not acceptable

        it "renders form" do
          render[:data].should == 'admin/entries/form'
          ientry = render[:ivars][:@entry]
          ientry.should be_a_new_record
          ientry.title.should == 'Hello'
          ientry.body.should == 'World'
        end
      end

      context "with category" do
        let(:categories) do
          Hash[Category.pluck(:id).map{ |_| [_, '1'] }]
        end

        let(:params) do
          {entry: entry_params.merge(categories: categories)}
        end

        it "creates entry with categories" do
          subject.should be_success
          entry.categories.reload.pluck(:id).should == Category.pluck(:id)
        end
      end
    end

    describe "GET /admin/entries/:id" do
      subject { post "/admin/entries/#{entry.id}", {}, env }

      it_behaves_like 'an admin page'

      it "renders form page" do
        render[:data].should == 'admin/entries/form'
        render[:ivars][:@entry].should == entry.id
      end

      context "with invalid entry" do
        let(:entry) { double.tap { |_| _.stub(id: Entry.last.id.succ) } }

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
        subject['Location'].should == path

        entry.reload
        entry.title.should == 'New'
        entry.body.should == 'a rainy day'
      end

      context "when invalid" do
        before do
          Entry.any_instance.stub(:valid? => false, :save => false)
        end

        it "renders form" do
          render[:data].should == 'admin/entries/form'
          ientry = render[:ivars][:@entry]
          ientry.id.should == entry.id
          ientry.title.should == 'New'
          entry.title.should == 'Today was'
        end
      end

      context "with category" do
        let(:params) do
          {entry: entry_params.merge(categories: {categories(:rainy).id.to_s => '1'})}
        end

        it "creates entry with categories" do
          subject.should be_success
          entry.categories.reload.pluck(:id).should == [categories(:rainy).id]
        end
      end

      context "with invalid entry" do
        let(:entry) { double.tap { |_| _.stub(id: Entry.last.id.succ) } }

        it { should be_not_found }
      end
    end

    describe "DELETE /admin/entries/:id" do
      subject { delete "/admin/entries/#{entry.id}", {}, env }

      it_behaves_like 'an admin page'

      it "destroys entry" do
        expect { subject }.to change { Entry.where(id: entry.id).count }.from(1).to(0)
        subject.should be_redirect
        subject['Location'].should == "/admin/entries"
      end

      context "with invalid entry" do
        let(:entry) { double.tap { |_| _.stub(id: Entry.last.id.succ) } }

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
