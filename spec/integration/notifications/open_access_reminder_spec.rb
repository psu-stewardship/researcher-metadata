require 'integration/integration_spec_helper'

describe 'sending open access reminder emails' do
  let!(:user1) { create :user, webaccess_id: 'abc123', first_name: "Tester", last_name: "Testerson" }
  let!(:membership1) { create :user_organization_membership, user: user1, started_on: Date.new(2019, 1, 1) }
  let!(:pub1) { create :publication, published_on: Date.new(2020, 2, 1), title: "Test Pub" }
  let!(:auth1) { create :authorship, user: user1, publication: pub1, confirmed: true }

  let!(:user2) { create :user, webaccess_id: 'def456', first_name: "Other", last_name: "User" }
  let!(:membership2) { create :user_organization_membership, user: user2, started_on: Date.new(2019, 1, 1) }
  let!(:pub2) { create :publication, published_on: Date.new(2020, 2, 1), title: "Other Pub", open_access_url: 'a_url' }
  let!(:auth2) { create :authorship, user: user2, publication: pub2, confirmed: true }

  before { OpenAccessNotifier.new.send_notifications }

  it "successfully sends a message only to applicable users" do
    open_email('abc123@psu.edu')
    expect(current_email).not_to be_nil

    open_email('def456@psu.edu')
    expect(current_email).to be_nil
  end

  it "includes the user's name in the message" do
    open_email('abc123@psu.edu')
    expect(current_email.body).to match(/Tester Testerson/)
  end

  context "when done twice in immediate succession" do
    before { clear_emails }

    it "does not send the same email twice" do
      OpenAccessNotifier.new.send_notifications

      open_email('abc123@psu.edu')
      expect(current_email).to be_nil
    end
  end
end
