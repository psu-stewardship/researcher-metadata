require 'component/component_spec_helper'

describe LDAPImporter do
  let(:importer) { LDAPImporter.new }

  let!(:user_1) { create :user, webaccess_id: 'abc1' }
  let!(:user_2) { create :user, webaccess_id: 'def2' }
  let!(:user_3) { create :user, webaccess_id: 'ghi3' }
  let!(:user_4) { create :user, webaccess_id: 'jkl4', orcid_identifier: 'existing-orcid' }

  let(:user_1_filter) { double 'user 1 filter' }
  let(:user_2_filter) { double 'user 2 filter' }
  let(:user_3_filter) { double 'user 3 filter' }
  let(:user_4_filter) { double 'user 4 filter' }

  let(:psu_ldap) { double 'PSU LDAP' }

  before do
    allow(Net::LDAP).to receive(:new).with(host: 'dirapps.aset.psu.edu', port: 389).and_return psu_ldap

    allow(Net::LDAP::Filter).to receive(:eq).with('uid', 'abc1').and_return user_1_filter
    allow(Net::LDAP::Filter).to receive(:eq).with('uid', 'def2').and_return user_2_filter
    allow(Net::LDAP::Filter).to receive(:eq).with('uid', 'ghi3').and_return user_3_filter
    allow(Net::LDAP::Filter).to receive(:eq).with('uid', 'jkl4').and_return user_4_filter

    allow(psu_ldap).to receive(:search).with(base: 'dc=psu,dc=edu',
                                             filter: user_1_filter).and_return([{edupersonorcid: ['user-1-orcid']}])
    allow(psu_ldap).to receive(:search).with(base: 'dc=psu,dc=edu',
                                             filter: user_2_filter).and_return([{edupersonorcid: ['user-2-orcid']}])
    allow(psu_ldap).to receive(:search).with(base: 'dc=psu,dc=edu',
                                             filter: user_3_filter).and_return([])
    allow(psu_ldap).to receive(:search).with(base: 'dc=psu,dc=edu',
                                             filter: user_4_filter).and_return([{edupersonorcid: []}])
  end
  describe "#call" do
    it "updates each user's ORCID ID with the value returned from LDAP" do
      importer.call

      expect(user_1.reload.orcid_identifier).to eq 'user-1-orcid'
      expect(user_2.reload.orcid_identifier).to eq 'user-2-orcid'
      expect(user_3.reload.orcid_identifier).to be_nil
      expect(user_4.reload.orcid_identifier).to be_nil
    end
  end
end
