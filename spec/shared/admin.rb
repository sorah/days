shared_examples "an admin page" do
  before { env.delete 'rack.session' }

  it "redirects to /admin/login" do
    expect(subject).to be_redirect
    expect(URI.parse(subject.location).path).to eq('/admin/login')
  end
end
