require 'spec_helper'

describe Days::App, type: :controller do
  shared_examples "an setup page" do
    context "when user exists" do
      fixtures :users

      it "denies access" do
        subject.status.should == 403
      end
    end
  end

  describe "admin: setup" do
    describe "GET /admin/setup" do
      subject { get '/admin/setup', {}, env }

      it_behaves_like 'an setup page'

      context "when user not exists" do
        before do
          Days::User.destroy_all
        end

        it { should be_ok }

        it "renders form page" do
          render[:data].should == :'admin/setup'
          user = render[:ivars][:@user]
          user.should be_a(Days::User)
          user.should be_new_record
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
        before do
          Days::User.destroy_all
        end

        it "creates user" do
          expect { subject }.to change { Days::User.count }.from(0).to(1)
          user = Days::User.last
          user.name.should == "Newbie"
        end

        it "logs in" do
          session[:user_id].should be_nil
          subject
          session[:user_id].should == Days::User.last.id
        end

        it "redirects to /admin" do
          subject.should be_redirect
          URI.parse(subject.location).path.should == '/admin'
        end

        context "when user is invalid" do
          before do
            Days::User.any_instance.stub(:valid? => false, :save => false)
          end

          specify { subject.status.should == 406 } # not acceptable

          it "renders form" do
            render[:data].should == :'admin/setup'
            iuser = render[:ivars][:@user]
            iuser.should be_a_new_record
            iuser.name.should == 'Newbie'
            iuser.login_name.should == 'newbie'
          end
        end
      end
    end
  end
end
