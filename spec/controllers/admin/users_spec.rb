require 'spec_helper'

describe Days::App, type: :controller do
  describe "admin: users" do
    let(:user) { Days::User.create!(login_name: 'blogger', name: 'blogger', password: 'x', password_confirmation: 'x') }

    before { login(user) }

    describe "GET /admin/users" do
      subject { get '/admin/users', {}, env }

      it_behaves_like 'an admin page'

      it { is_expected.to be_ok }

      it "lists up users" do
        expect(render[:data]).to eq(:'admin/users/index')

        users = render[:ivars][:@users]
        expect(users).to eq(Days::User.all)
      end
    end

    describe "GET /admin/users/new" do
      subject { get '/admin/users/new', {}, env }

      it_behaves_like 'an admin page'

      it { is_expected.to be_ok }

      it "renders form page" do
        expect(render[:data]).to eq(:'admin/users/form')
        user = render[:ivars][:@user]
        expect(user).to be_a(Days::User)
        expect(user).to be_new_record
      end
    end

    describe "POST /admin/users" do
      subject { post '/admin/users', params, env }
      let(:user_params) do
        {
          name: "Writer", login_name: "writer",
          password: "pass", password_confirmation: "pass"
        }
      end
      let(:params) { {user: user_params} }

      it_behaves_like 'an admin page'

      it "creates user" do
        expect(subject).to be_redirect

        user = Days::User.last
        expect(user.name).to eq("Writer")
        expect(user.login_name).to eq("writer")
      end

      context "when user is invalid" do
        before do
          allow_any_instance_of(Days::User).to receive_messages(:valid? => false, :save => false)
        end

        specify { expect(subject.status).to eq(406) } # not acceptable

        it "renders form" do
          expect(render[:data]).to eq(:'admin/users/form')
          iuser = render[:ivars][:@user]
          expect(iuser).to be_a_new_record
          expect(iuser.name).to eq('Writer')
          expect(iuser.login_name).to eq('writer')
        end
      end
    end

    describe "GET /admin/users/:id" do
      subject { get "/admin/users/#{user.id}", {}, env }

      it_behaves_like 'an admin page'

      it "renders form page" do
        expect(render[:data]).to eq(:'admin/users/form')
        expect(render[:ivars][:@user]).to eq(user)
      end

      context "with invalid user" do
        let(:user2) { Days::User.create!(login_name: 'blogger2', name: 'blogger2', password: 'x', password_confirmation: 'x') }
        before { login(user2); user.destroy }

        it { is_expected.to be_not_found }
      end
    end

    describe "PUT /admin/users/:id" do
      subject { put path, params, env }
      let(:path) { "/admin/users/#{user.id}" }
      let(:valid_params) { {user: {name: 'Newbie', password: 'a', password_confirmation: 'a'}} }
      let(:params) { valid_params }

      it_behaves_like 'an admin page'

      it "updates user" do
        expect(subject).to be_redirect
        expect(URI.parse(subject['Location']).path).to eq(path)

        user.reload
        expect(user.name).to eq('Newbie')
      end

      context "when invalid" do
        before do
          allow_any_instance_of(Days::User).to receive_messages(:valid? => false, :save => false)
        end

        it "renders form" do
          expect(render[:data]).to eq(:'admin/users/form')
          iuser = render[:ivars][:@user]
          expect(iuser.id).to eq(user.id)
          expect(iuser.name).to eq('Newbie')
        end
      end

      context "with invalid user" do
        let(:user2) { Days::User.create!(login_name: 'blogger2', name: 'blogger2', password: 'x', password_confirmation: 'x') }
        before { login(user2); user.destroy }

        it { is_expected.to be_not_found }
      end
    end

    describe "DELETE /admin/users/:id" do
      let!(:another_user) { Days::User.create!(login_name: 'blogger2', name: 'blogger2', password: 'x', password_confirmation: 'x') }
      subject { delete "/admin/users/#{another_user.id}", {}, env }

      it_behaves_like 'an admin page'

      it "destroys user" do
        expect { subject }.to change { Days::User.count }.by(-1)
        expect(Days::User.where(id: another_user.id).count).to be_zero

        expect(subject).to be_redirect
        expect(URI.parse(subject.location).path).to eq("/admin/users")
      end

      context "when tried to delete myself" do
        subject { delete "/admin/users/#{user.id}", {}, env }

        it "doesn't destroy" do
          expect { subject }.to_not change { Days::User.count }

          expect(subject.status).to eq(400)
        end
      end

      context "with invalid user" do
        before { another_user.destroy }

        it { is_expected.to be_not_found }
      end
    end
  end
end
