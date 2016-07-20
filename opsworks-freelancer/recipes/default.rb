include_recipe 'build-essential'


app = search(:aws_opsworks_app).first
app_path = "/srv/#{app['shortname']}"


package 'git' do
  options '--force-yes' if node['platform'] == 'ubuntu' && node['platform_version'] == '14.04'
end

package 'libjpeg-dev' #for image
package 'libpq-dev' #for postgres
package 'memcached'

#Chef::Log.info("********** The app's SSH Key is '#{app['app_source']['ssh_key']}' **********")

# file ::File.join(app_path, 'ssh_key', 'id_rsa') do
#   content app['app_source']['ssh_key']
# end
directory '/srv/ssh_key' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

private_key = app['app_source']['ssh_key']
file "/srv/ssh_key/id_rsa" do
  content private_key
  owner 'root'
  group 'root'
  mode '0400'
end

file "/srv/ssh_key/git_wrapper.sh" do
  owner "root"
  mode "0755"
  #content "#!/bin/sh\nexec /usr/bin/ssh -i /srv/ssh_key/id_rsa \"$@\""
  content "#!/bin/bash\n exec ssh -o \"StrictHostKeyChecking=no\" -i \"/srv/ssh_key/id_rsa\" $1 $2"
end

application app_path do
  git app_path do
    repository app['app_source']['url']
    action :sync
    ssh_wrapper "/srv/ssh_key/git_wrapper.sh" #the path to our private key file
  end

  python '3'
  virtualenv
  pip_requirements

  file ::File.join(app_path, 'freelancer', 'sse.py') do
    content "\n
    \nfrom freelancer.setting_cache import *\n
    \nAWS_STORAGE_BUCKET_NAME = '#{node['s3_bucket_name']}'\n
    \nAWS_ACCESS_KEY_ID = '#{node['s3_ses_access_key']}' \n
    \nAWS_SECRET_ACCESS_KEY = '#{node['s3_ses_secret_key']}' \n
    \nAWS_QUERYSTRING_AUTH = AWS_S3_SECURE_URLS = False \n
    \nSTATIC_ROOT = AWS_S3_CUSTOM_DOMAIN = '%s.s3.amazonaws.com' % AWS_STORAGE_BUCKET_NAME \n
    \n STATIC_URL = 'http://%s/%s/' % (AWS_S3_CUSTOM_DOMAIN, STATICFILES_LOCATION) \n
    \n MEDIA_URL = 'http://%s/%s/' % (AWS_S3_CUSTOM_DOMAIN, MEDIAFILES_LOCATION) \n

    \nDEFAULT_IMP_KEY = '#{node['iamport_key']}'\n
    \nDEFAULT_IMP_SECRET = '#{node['iamport_secret_key']}'\n

    \nMAILGUN_ACCESS_KEY = '#{node['mailgun_access_key']}'\n
    \nMAILGUN_SERVER_NAME = '#{node['mailgun_server_name']}'\n
    \nDEFAULT_FROM_EMAIL = '#{node['default_from_email']}'\n
    \nSUPPORT_EMAIL = '#{node['support_email']}'\n
    \nPAYMENT_EMAIL = '#{node['payment_email']}'\n

    \nGOOGLE_ANALYTICS_ID = '#{node['google_analytics_id']}'\n

    \nSECRET_KEY = '#{node['app_secret_key']}'\n
    \nNEVERCACHE_KEY = '7_l!k&01ymk3zqrxuubn$(pawcwacl+-7vi@&0$#yo*#lu6(-$'\n"
  end

  file ::File.join(app_path, 'freelancer', 'deploy.py') do
     content "from freelancer.settings import *\nfrom freelancer.sse import *\n"
  end

  django do
    allowed_hosts ['localhost', node['cloud']['public_ipv4'], node['fqdn']]
    settings_module 'freelancer.deploy'

    database do
      engine node['db_engine']
      name node['db_name']
      host node['db_host']
      port node['db_port']
      user node['db_user']
      password node['db_passwd']
    end

    syncdb false
    collectstatic false
    migrate true
    debug true
  end

  gunicorn

end
