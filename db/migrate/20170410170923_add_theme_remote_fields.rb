class AddThemeRemoteFields < ActiveRecord::Migration
  def change
    add_column :themes, :remote_url, :string
    add_column :themes, :remote_version, :string
    add_column :themes, :local_version, :string
    add_column :themes, :about_url, :string
    add_column :themes, :license_url, :string
  end
end
