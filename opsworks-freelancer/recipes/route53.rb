include_recipe "route53"


# z_id = node[:opsworks_route53][:zone_id]
# domain = node[:opsworks_route53][:domainname]
# subdomain = node[:opsworks][:stack][:name].downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '-')
#
# domain = node[:opsworks_route53][:prepend_stack_name] ? "#{subdomain}.#{domain}" : domain


search("aws_opsworks_instance").each do |instance|
  Chef::Log.info("********** ********** ********** ********** ********** **********")
  Chef::Log.info(" The instance's hostname is '#{instance['hostname']}' ")
  Chef::Log.info(" The instance's ID is '#{instance['instance_id']}' ")
  Chef::Log.info(" The instance's Public IP is '#{instance['public_ip']}' ")

  #ips = '#{instance['public_ip']}.#{ips}'
end

if node['set_route']
  #instance = search("aws_opsworks_instance").first

  route53_record "create a record" do
    name      'sol.freelancer.run'#"#{node[:opsworks][:instance][:hostname]}.#{domain}"
    value     node['cloud']['public_ipv4'] #instance['public_ip'] #node["opsworks"]["instance"]["ip"]
    type      "A"
    ttl       300 #node[:opsworks_route53][:ttl]
    zone_id               node['dns_zone_id']
    aws_access_key_id     node['route_access_key']
    aws_secret_access_key node['route_secret_key']
    overwrite true
    action    :create
  end
end
