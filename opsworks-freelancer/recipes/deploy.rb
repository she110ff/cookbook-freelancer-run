include_recipe 'build-essential'


app = search(:aws_opsworks_app).first
app_path = "/srv/#{app['shortname']}"


package 'git' do
  options '--force-yes' if node['platform'] == 'ubuntu' && node['platform_version'] == '14.04'
end

application app_path do
  git app_path do
    repository app['app_source']['url']
    action :sync
    ssh_wrapper "/srv/ssh_key/git_wrapper.sh" #the path to our private key file
  end
end
