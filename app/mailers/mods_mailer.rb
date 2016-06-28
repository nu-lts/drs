class ModsMailer < ActionMailer::Base
  default from: "notifier@repository.library.northeastern.edu"

  def export_alert(pid, nuid, session_id)
    user = !nuid.blank? ? User.find_by_nuid(nuid) : nil
    @name = user.pretty_name || "No name set.  Uh oh!"
    @nuid = nuid || "No nuid set.  Uh oh!"
    @file_url = mods_download_url(id: pid, session_id: session_id)  || "No url set.  Uh oh!"
    mail(to: user.email,
         subject: "[DRS] MODS Export download link",
         content_type: "text/html")
  end
end