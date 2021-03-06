require 'spec_helper'

describe Days::App, type: :controller do
  describe "admin: entries" do
    let!(:entry) { Days::Entry.create!(title: 'foo', body: 'foo') }
    let!(:draft) { Days::Entry.create!(title: 'draft', body: 'foo', draft: true) }
    let!(:scheduled) { Days::Entry.create!(title: 'scheduled', body: 'foo', published_at: Time.now + (86400 * 365)) }
    let(:user)  { Days::User.create!(login_name: 'blogger', name: 'blogger', password: 'x', password_confirmation: 'x') }

    before { login(user) }

    describe "GET /admin/entries" do
      let(:now) { Time.now }

      before do
        # fix the time to fix time in SQL statement (might have difference in microsec)
        allow(Time).to receive(:now).and_return(now)
      end

      subject { get '/admin/entries', {}, env }

      it_behaves_like 'an admin page'

      it { is_expected.to be_ok }

      it "lists up entries" do
        expect(render[:data]).to eq(:'admin/entries/index')

        entries = render[:ivars][:@entries]
        expect(entries).to eq(Days::Entry.order(id: :desc).page(nil))
      end

      describe "with page" do
        subject { get '/admin/entries?page=2', {}, env }

        it "lists up entries for specified page" do
          expect(render[:data]).to eq(:'admin/entries/index')

          entries = render[:ivars][:@entries]
          expect(entries).to eq(Days::Entry.order(id: :desc).page(2))
        end
      end

      describe "with draft=1" do
        subject { get '/admin/entries?draft=1', {}, env }

        it "lists up drafts" do
          expect(render[:data]).to eq(:'admin/entries/index')

          entries = render[:ivars][:@entries]
          expect(entries).to eq(Days::Entry.order(id: :desc).draft.page(nil))
        end
      end

      describe "with scheduled=1" do
        subject { get '/admin/entries?scheduled=1', {}, env }

        it "lists up scheduled entries" do
          expect(render[:data]).to eq(:'admin/entries/index')

          entries = render[:ivars][:@entries]
          expect(entries).to eq(Days::Entry.order(id: :desc).scheduled.page(1))
        end
      end

      describe "with published=1" do
        subject { get '/admin/entries?published=1', {}, env }

        it "lists up published entries" do
          expect(render[:data]).to eq(:'admin/entries/index')

          entries = render[:ivars][:@entries]
          expect(entries).to eq(Days::Entry.order(id: :desc).published.page(nil))
        end
      end
    end

    describe "GET /admin/entries/new" do
      subject { get '/admin/entries/new', {}, env }

      it_behaves_like 'an admin page'

      it { is_expected.to be_ok }

      it "renders form page" do
        expect(render[:data]).to eq(:'admin/entries/form')
        entry = render[:ivars][:@entry]
        expect(entry).to be_a(Days::Entry)
        expect(entry).to be_new_record
      end
    end

    describe "POST /admin/entries" do
      subject { post '/admin/entries', params, env }
      let(:entry) { Days::Entry.last }
      let(:entry_params) { {title: "Hello", body: "World"} }
      let(:params) { {entry: entry_params} }

      it_behaves_like 'an admin page'

      it "creates entry" do
        expect(subject).to be_redirect

        entry = Days::Entry.last
        expect(entry.title).to eq("Hello")
        expect(entry.body).to eq("World")
        expect(entry.user).to eq(user)
      end

      context "when entry is invalid" do
        before do
          allow_any_instance_of(Days::Entry).to receive_messages(:valid? => false, :save => false)
        end

        specify { expect(subject.status).to eq(406) } # not acceptable

        it "renders form" do
          expect(render[:data]).to eq(:'admin/entries/form')
          ientry = render[:ivars][:@entry]
          expect(ientry).to be_a_new_record
          expect(ientry.title).to eq('Hello')
          expect(ientry.body).to eq('World')
        end
      end

      context "with config.html_pipeline" do
        let(:pipeline) do
          double('pipeline')
        end

        let(:entry) do
          Days::Entry.new(entry_params)
        end

        before do
          Days::App.config.html_pipeline = pipeline
          allow(Days::Entry).to receive(:new).and_return(entry)
        end

        it "sets pipeline to entry" do
          allow(entry).to receive(:save).and_wrap_original do |m, *args|
            expect(entry.pipeline).to eq(pipeline)
            entry.pipeline = nil
            m.call
          end

          expect(subject).to be_redirect
        end

        after do
          Days::App.config.html_pipeline = nil
        end
      end

      context "with category" do
        let(:categories) do
          Hash[Days::Category.pluck(:id).map{ |_| [_, '1'] }]
        end

        let(:params) do
          {entry: entry_params.merge(categories: categories)}
        end

        it { is_expected.to be_redirect }

        it "creates entry with categories" do
          subject
          entry = Days::Entry.last
          expect(entry.categories.reload.map(&:id)).to eq(Days::Category.pluck(:id))
        end
      end
    end

    describe "GET /admin/entries/:id" do
      subject { get "/admin/entries/#{entry.id}", {}, env }

      it_behaves_like 'an admin page'

      it "renders form page" do
        expect(render[:data]).to eq(:'admin/entries/form')
        expect(render[:ivars][:@entry]).to eq(entry)
      end

      context "with invalid entry" do
        before { entry.destroy }

        it { is_expected.to be_not_found }
      end
    end

    describe "PUT /admin/entries/:id" do
      subject { put path, params, env }
      let(:path) { "/admin/entries/#{entry.id}" }
      let(:valid_params) { {entry: {title: 'New'}} }
      let(:params) { valid_params }

      it_behaves_like 'an admin page'

      it "updates entry" do
        expect(subject).to be_redirect
        expect(URI.parse(subject['Location']).path).to eq(path)

        entry.reload
        expect(entry.title).to eq('New')
        expect(entry.body).to eq('foo')
      end

      context "when invalid" do
        before do
          allow_any_instance_of(Days::Entry).to receive_messages(:valid? => false, :save => false)
        end

        it "renders form" do
          expect(render[:data]).to eq(:'admin/entries/form')
          ientry = render[:ivars][:@entry]
          expect(ientry.id).to eq(entry.id)
          expect(ientry.title).to eq('New')

          entry.reload
          expect(entry.title).to eq('foo')
        end
      end

      context "with category" do
        let(:category) { Days::Category.create!(name: 'daily') }
        let(:params) do
          {entry: {categories: {category.id.to_s => '1'}}}
        end

        it "creates entry with categories" do
          expect(subject).to be_redirect
          expect(entry.reload.categories.reload.map(&:id)).to eq([category.id])
        end
      end

      context "with invalid entry" do
        before { entry.destroy }

        it { is_expected.to be_not_found }
      end

      context "with config.html_pipeline" do
        let(:pipeline) do
          double('pipeline')
        end

        before do
          Days::App.config.html_pipeline = pipeline
          expect(Days::Entry).to receive(:find_by).with(id: entry.id.to_s).and_return(entry)
        end

        it "sets pipeline to entry" do
          allow(entry).to receive(:save).and_wrap_original do |m, *args|
            expect(entry.pipeline).to eq(pipeline)
            entry.pipeline = nil
            m.call
          end

          expect(subject).to be_redirect
        end

        after do
          Days::App.config.html_pipeline = nil
        end
      end
    end

    describe "DELETE /admin/entries/:id" do
      subject { delete "/admin/entries/#{entry.id}", {}, env }

      it_behaves_like 'an admin page'

      it "destroys entry" do
        expect { subject }.to change { Days::Entry.where(id: entry.id).count }.from(1).to(0)
        expect(subject).to be_redirect
        expect(URI.parse(subject.location).path).to eq("/admin/entries")
      end

      context "with invalid entry" do
        before { entry.destroy }

        it { is_expected.to be_not_found }
      end
    end

    describe "POST /admin/entries/preview" do
      subject { post "/admin/entries/preview", params, env }
      let(:valid_params) { {} }
      let(:params) { valid_params }

      it_behaves_like 'an admin page'

      it "renders body for preview"
    end
  end
end
