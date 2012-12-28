shared_examples "an admin page" do
  before { env.delete 'rack.session' }

  it "redirects to /admin/login" do
    subject.should be_redirect
    URI.parse(subject.location).path.should == '/admin/login'
  end
end
