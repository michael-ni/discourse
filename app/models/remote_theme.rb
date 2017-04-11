require_dependency 'git_importer'

class RemoteTheme < ActiveRecord::Base
  has_one :theme

  def self.import_theme(url, user=Discourse.system_user)
    importer = GitImporter.new(url)
    importer.import!

    theme_info = JSON.parse(importer["about.json"])
    theme = Theme.new(user_id: user&.id || -1, name: theme_info["name"])

    remote_theme = new
    theme.remote_theme = remote_theme

    remote_theme.remote_url = importer.url
    remote_theme.remote_version = importer.version
    remote_theme.local_version = importer.version
    remote_theme.update_from_remote(importer)
    theme.save!
    theme
  ensure
    begin
      importer.cleanup!
    rescue => e
      Rails.logger.warn("Failed cleanup remote git #{e}")
    end
  end

  def update_from_remote(importer=nil)
    return unless remote_url
    cleanup = false
    unless importer
      cleanup = true
      importer = GitImporter.new(remote_url)
      importer.import!
    end

    Theme.targets.keys.each do |target|
      Theme::ALLOWED_FIELDS.each do |field|
        value = importer["#{target}/#{field=="scss"?"#{target}.scss":"#{field}.html"}"]
        theme.set_field(target.to_sym, field, value)
      end
    end

    self
  ensure
    begin
      importer.cleanup! if cleanup
    rescue => e
      Rails.logger.warn("Failed cleanup remote git #{e}")
    end
  end
end

# == Schema Information
#
# Table name: remote_themes
#
#  id                :integer          not null, primary key
#  remote_url        :string           not null
#  remote_version    :string
#  local_version     :string
#  about_url         :string
#  license_url       :string
#  commits_behind    :integer
#  remote_updated_at :datetime
#  created_at        :datetime
#  updated_at        :datetime
#
