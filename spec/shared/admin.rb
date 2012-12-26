shared_examples "an admin page" do
  before { env.delete 'rack.session' }

  it "returns 401" do
    subject.status.should == 401
  end
end
