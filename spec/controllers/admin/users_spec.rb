require 'spec_helper'

describe Days::App, type: :controller do
  describe "admin: users" do
    let(:user) { Days::User.create!(login_name: 'blogger', name: 'blogger', password: 'x', password_confirmation: 'x') }

    before { login(user) }

    describe "GET /admin/users" do
      subject { get '/admin/users', {}, env }

      it_behaves_like 'an admin page'

      it { should be_ok }

      it "lists up users" do
        render[:data].should == :'admin/users/index'

        users = render[:ivars][:@users]
        users.should == Days::User.all
      end
    end

    describe "GET /admin/users/new" do
      subject { get '/admin/users/new', {}, env }

      it_behaves_like 'an admin page'

      it { should be_ok }

      it "renders form page" do
        render[:data].should == :'admin/users/form'
        user = render[:ivars][:@user]
        user.should be_a(Days::User)
        user.should be_new_record
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
        subject.should be_redirect

        user = Days::User.last
        user.name.should == "Writer"
        user.login_name.should == "writer"
      end

      context "when user is invalid" do
        before do
          Days::User.any_instance.stub(:valid? => false, :save => false)
        end

        specify { subject.status.should == 406 } # not acceptable

        it "renders form" do
          render[:data].should == :'admin/users/form'
          iuser = render[:ivars][:@user]
          iuser.should be_a_new_record
          iuser.name.should == 'Writer'
          iuser.login_name.should == 'writer'
        end
      end
    end

    describe "GET /admin/users/:id" do
      subject { get "/admin/users/#{user.id}", {}, env }

      it_behaves_like 'an admin page'

      it "renders form page" do
        render[:data].should == :'admin/users/form'
        render[:ivars][:@user].should == user
      end

      context "with invalid user" do
        let(:user2) { Days::User.create!(login_name: 'blogger2', name: 'blogger2', password: 'x', password_confirmation: 'x') }
        before { login(user2); user.destroy }

        it { should be_not_found }
      end
    end

    describe "PUT /admin/users/:id" do
      subject { put path, params, env }
      let(:path) { "/admin/users/#{user.id}" }
      let(:valid_params) { {user: {name: 'Newbie', password: 'a', password_confirmation: 'a'}} }
      let(:params) { valid_params }

      it_behaves_like 'an admin page'

      it "updates user" do
        subject.should be_redirect
        URI.parse(subject['Location']).path.should == path

        user.reload
        user.name.should == 'Newbie'
      end

      context "when invalid" do
        before do
          Days::User.any_instance.stub(:valid? => false, :save => false)
        end

        it "renders form" do
          render[:data].should == :'admin/users/form'
          iuser = render[:ivars][:@user]
          iuser.id.should == user.id
          iuser.name.should == 'Newbie'
        end
      end

      context "with invalid user" do
        let(:user2) { Days::User.create!(login_name: 'blogger2', name: 'blogger2', password: 'x', password_confirmation: 'x') }
        before { login(user2); user.destroy }

        it { should be_not_found }
      end
    end

    describe "DELETE /admin/users/:id" do
      let!(:another_user) { Days::User.create!(login_name: 'blogger2', name: 'blogger2', password: 'x', password_confirmation: 'x') }
      subject { delete "/admin/users/#{another_user.id}", {}, env }

      it_behaves_like 'an admin page'

      it "destroys user" do
        expect { subject }.to change { Days::User.count }.by(-1)
        Days::User.where(id: another_user.id).count.should be_zero

        subject.should be_redirect
        URI.parse(subject.location).path.should == "/admin/users"
      end

      context "when tried to delete myself" do
        subject { delete "/admin/users/#{user.id}", {}, env }

        it "doesn't destroy" do
          expect { subject }.to_not change { Days::User.count }

          subject.status.should == 400
        end
      end

      context "with invalid user" do
        before { another_user.destroy }

        it { should be_not_found }
      end
    end
  end
end
