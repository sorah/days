require 'spec_helper'

describe Days::App, type: :controller do
  describe "admin: sessions" do
    let(:user) do
      Days::User.create(
        name: 'Blogger', login_name: 'blogger',
        password: 'password', password_confirmation: 'password'
      )
    end

    describe "GET /admin/login" do
      subject { get '/admin/login' }

      it "renders login page" do
        render[:data].should == 'admin/login'
      end
    end

    describe "POST /admin/login" do
      subject { post '/admin/login', params, env }
      let(:params) { {login_name: 'blogger', password: 'password'} }

      it "logs in" do
        expect { subject }.to \
          change { session[:user_id] }.from(nil).to(user.id)
      end

      it "redirects to /admin" do
        subject.should be_redirect
        URI.parse(subject.location).path.should == '/admin'
      end

      context "without login name" do
        let(:params) { {password: 'password'} }

        specify do
          subject.status.should == 400
        end
      end

      context "without password" do
        let(:params) { {login_name: 'blogger'} }

        specify do
          subject.status.should == 400
        end
      end

      context "with wrong login name" do
        let(:params) { {login_name: 'not exists', password: 'password'} }

        it "doesn't log in" do
          subject
          session[:user_id].should be_nil
        end

        it "returns login page" do
          subject.status.should == 401
          render[:data].should == 'admin/login'
        end
      end

      context "with wrong password" do
        let(:params) { {login_name: 'blogger', password: 'passw0rd'} }

        it "doesn't log in" do
          subject
          session[:user_id].should be_nil
        end

        it "returns login page" do
          subject.status.should == 401
          render[:data].should == 'admin/login'
        end
      end
    end

    describe "POST /admin/logout" do
      subject { post '/admin/logout', {}, env }
      context "when logged in" do
        before { login(user) }

        it "redirects to /admin/login" do
          subject.should be_redirect
          URI.parse(subject.location).path.should == '/admin/login'
        end

        specify do
          expect { subject }.to change { session[:user_id] }.to(nil)
        end
      end

      context "when not logged in" do
        it "redirects to /admin/login" do
          subject.should be_redirect
          URI.parse(subject.location).path.should == '/admin/login'
        end
      end
    end
  end
end

