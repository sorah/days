require 'spec_helper'

describe Days::App, type: :controller do
  shared_examples "an setup page" do
    context "when user exists" do
      before do
        Days::User.create!(
          name: 'Blogger', login_name: 'blogger',
          password: 'password', password_confirmation: 'password'
        )
      end

      it "denies access" do
        expect(subject.status).to eq(403)
      end
    end
  end

  describe "admin: setup" do
    describe "GET /admin/setup" do
      subject { get '/admin/setup', {}, env }

      it_behaves_like 'an setup page'

      context "when user not exists" do
        it { is_expected.to be_ok }

        it "renders form page" do
          expect(render[:data]).to eq(:'admin/setup')
          user = render[:ivars][:@user]
          expect(user).to be_a(Days::User)
          expect(user).to be_new_record
        end
      end
    end

    describe "POST /admin/setup" do
      subject { post '/admin/setup', {user: user_params}, env }
      let(:user_params) do
        {login_name: 'newbie', name: 'Newbie',
          password: 'a', password_confirmation: 'a'}
      end

      it_behaves_like 'an setup page'

      context "when user not exists" do
        it "creates user" do
          expect { subject }.to change { Days::User.count }.from(0).to(1)
          user = Days::User.last
          expect(user.name).to eq("Newbie")
        end

        it "logs in" do
          expect(session[:user_id]).to be_nil
          subject
          expect(session[:user_id]).to eq(Days::User.last.id)
        end

        it "redirects to /admin" do
          expect(subject).to be_redirect
          expect(URI.parse(subject.location).path).to eq('/admin')
        end

        context "when user is invalid" do
          before do
            allow_any_instance_of(Days::User).to receive_messages(:valid? => false, :save => false)
          end

          specify { expect(subject.status).to eq(406) } # not acceptable

          it "renders form" do
            expect(render[:data]).to eq(:'admin/setup')
            iuser = render[:ivars][:@user]
            expect(iuser).to be_a_new_record
            expect(iuser.name).to eq('Newbie')
            expect(iuser.login_name).to eq('newbie')
          end
        end
      end
    end
  end
end
