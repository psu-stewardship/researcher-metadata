class FacultyNotificationsMailerPreview < ActionMailer::Preview
  # Accessible from http://localhost:3000/rails/mailers/faculty_notifications_mailer/open_access_reminder
  def open_access_reminder
    fake_user = OpenStruct.new({email: 'test@example.com',
                                name: 'Example User'})
    pub1 = OpenStruct.new({title: "Example Publication One"})
    pub2 = OpenStruct.new({title: "Example Publication Two"})
    pub3 = OpenStruct.new({title: "Example Publication Three"})
    old_fake_pubs = [pub1, pub2]
    new_fake_pubs = [pub3]

    FacultyNotificationsMailer.open_access_reminder(fake_user, old_fake_pubs, new_fake_pubs)
  end
end
