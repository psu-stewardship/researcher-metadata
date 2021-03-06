shared_examples_for "a profile management page" do
  it "shows a link to return to the public profile" do
    expect(page).to have_link "Public Profile", href: profile_path(webaccess_id: user.webaccess_id)
  end

  it "shows a link to return to the home page" do
    expect(page).to have_link "Home", href: root_path
  end

  it "shows an email support link" do
    expect(page).to have_link "Support", href: 'mailto:L-FAMS@lists.psu.edu?subject=Researcher Metadata Database Profile Support'
  end

  it "shows a link to the edit profile publications page" do
    expect(page).to have_link "Publications", href: edit_profile_publications_path
  end

  it "shows a link to the edit profile presentations page" do
    expect(page).to have_link "Presentations", href: edit_profile_presentations_path
  end

  it "shows a link to the edit profile performances page" do
    expect(page).to have_link "Performances", href: edit_profile_performances_path
  end

  it "shows a sign out link" do
    expect(page).to have_link "Sign out", href: destroy_user_session_path
  end
end
