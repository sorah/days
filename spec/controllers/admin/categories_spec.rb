require 'spec_helper'

describe Days::App, type: :controller do
  describe "admin: categories" do
    let(:user)  { Days::User.create!(login_name: 'blogger', name: 'blogger', password: 'x', password_confirmation: 'x') }
    let!(:category) { Days::Category.create!(name: 'daily') }

    before { login(user) }

    describe "GET /admin/categories" do
      subject { get '/admin/categories', {}, env }

      it_behaves_like 'an admin page'

      it { is_expected.to be_ok }

      it "lists up categories" do
        expect(render[:data]).to eq(:'admin/categories')

        categories = render[:ivars][:@categories]
        expect(categories.to_a).to eq([category])
      end
    end

    describe "POST /admin/categories" do
      subject { post '/admin/categories', params, env }
      let(:params) { {category: {name: "Snowy"}} }

      it_behaves_like 'an admin page'

      it "creates category" do
        expect(subject).to be_redirect

        expect(Days::Category.last.name).to eq(params[:category][:name])
      end

      context "when category is invalid" do
        before do
          allow_any_instance_of(Days::Category).to receive(:valid?).and_return(false)
          allow_any_instance_of(Days::Category).to receive(:save).and_return(false)
        end

        specify { expect(subject.status).to eq(406) } # not acceptable

        it "renders form" do
          expect(render[:data]).to eq(:'admin/categories')
        end
      end
    end

    describe "PUT /admin/categories/:id" do
      subject { put "/admin/categories/#{category.id}", params, env }
      let(:params) { {category: {name: 'Storm'}} }

      it_behaves_like 'an admin page'

      it "updates category" do
        expect(subject).to be_redirect
        expect(URI.parse(subject['Location']).path).to eq('/admin/categories')

        category.reload
        expect(category.name).to eq('Storm')
      end

      context "when invalid" do
        before do
          allow_any_instance_of(Days::Category).to receive_messages(:valid? => false, :save => false)
        end

        it "renders form" do
          expect(render[:data]).to eq(:'admin/categories')
        end
      end

      context "with invalid category" do
        before { category.destroy }

        it { is_expected.to be_not_found }
      end
    end

    describe "DELETE /admin/categories/:id" do
      subject { delete "/admin/categories/#{category.id}", {}, env }

      it_behaves_like 'an admin page'

      it "destroys category" do
        expect { subject }.to change { Days::Category.where(id: category.id).count }.from(1).to(0)
        expect(subject).to be_redirect
        expect(URI.parse(subject.location).path).to eq("/admin/categories")
      end

      context "with invalid category" do
        before { category.destroy }

        it { is_expected.to be_not_found }
      end
    end
  end
end
