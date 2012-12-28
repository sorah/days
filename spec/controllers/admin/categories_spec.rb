require 'spec_helper'

describe Days::App, type: :controller do
  describe "admin: categories" do
    fixtures :users, :categories
    let(:user)  { users(:blogger) }
    let(:category) { categories(:daily) }

    before { login(user) }

    describe "GET /admin/categories" do
      subject { get '/admin/categories', {}, env }

      it_behaves_like 'an admin page'

      it { should be_ok }

      it "lists up categories" do
        render[:data].should == 'admin/categories'

        categories = render[:ivars][:@categories]
        categories.should == Days::Category.all
      end
    end

    describe "POST /admin/categories" do
      subject { post '/admin/categories', params, env }
      let(:params) { {category: {name: "Snowy"}} }

      it_behaves_like 'an admin page'

      it "creates category" do
        subject.should be_redirect

        Days::Category.last.name.should == params[:category][:name]
      end

      context "when category is invalid" do
        before do
          Days::Category.any_instance.stub(:valid? => false, :save => false)
        end

        specify { subject.status.should == 406 } # not acceptable

        it "renders form" do
          render[:data].should == 'admin/categories'
        end
      end
    end

    describe "PUT /admin/categories/:id" do
      subject { put "/admin/categories/#{category.id}", params, env }
      let(:params) { {category: {name: 'Storm'}} }

      it_behaves_like 'an admin page'

      it "updates category" do
        subject.should be_redirect
        URI.parse(subject['Location']).path.should == '/admin/categories'

        category.reload
        category.name.should == 'Storm'
      end

      context "when invalid" do
        before do
          Days::Category.any_instance.stub(:valid? => false, :save => false)
        end

        it "renders form" do
          render[:data].should == 'admin/categories'
        end
      end

      context "with invalid category" do
        let(:category) { double.tap { |_| _.stub(id: Days::Category.last.id.succ) } }

        it { should be_not_found }
      end
    end

    describe "DELETE /admin/categories/:id" do
      subject { delete "/admin/categories/#{category.id}", {}, env }

      it_behaves_like 'an admin page'

      it "destroys category" do
        expect { subject }.to change { Days::Category.where(id: category.id).count }.from(1).to(0)
        subject.should be_redirect
        URI.parse(subject.location).path.should == "/admin/categories"
      end

      context "with invalid category" do
        let(:category) { double.tap { |_| _.stub(id: Days::Category.last.id.succ) } }

        it { should be_not_found }
      end
    end
  end
end
