cask "tideline" do
  version "1.0.0"
  sha256 "REPLACE_WITH_SHA256_OF_RELEASE_ZIP"

  url "https://github.com/KaHooli/Tideline/releases/download/v#{version}/Tideline.zip"
  name "Tideline"
  desc "Manage, sort, and clean up your Safari bookmarks"
  homepage "https://github.com/KaHooli/Tideline"

  depends_on macos: ">= :sonoma"

  app "Tideline.app"

  zap trash: [
    "~/Library/Containers/au.id.cavanaghs.Tideline",
    "~/Library/Group Containers/group.au.id.cavanaghs.Tideline",
    "~/Library/Preferences/au.id.cavanaghs.Tideline.plist",
  ]
end
