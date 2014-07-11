# Encoding: utf-8
#
# Cookbook Name:: pythonstack
# Recipe:: apache
#
# Copyright 2014, Rackspace UK, Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Include the necessary recipes.
%w(pythonstack::default apache2::default apache2::mod_wsgi apache2::mod_proxy apache2::mod_proxy_http apache2::mod_python).each do |recipe|
  include_recipe recipe
end

# Create the sites.
node['apache']['sites'].each do | site_name |
  site_name = site_name[0]
  site = node['apache']['sites'][site_name]

  add_iptables_rule('INPUT', "-m tcp -p tcp --dport #{site['port']} -j ACCEPT", 100, 'Allow access to apache')

  web_app site_name do
    port site['port']
    cookbook site['cookbook']
    template site['template']
    server_name site['server_name']
    server_aliases site['server_alias']
    docroot site['docroot']
    allow_override site['allow_override']
    errorlog site['errorlog']
    customlog site['customlog']
    loglevel site['loglevel']
  end
  template "http-monitor-#{site['server_name']}" do
    cookbook 'pythonstack'
    source 'monitoring-remote-http.yaml.erb'
    path "/etc/rackspace-monitoring-agent.conf.d/#{site['server_name']}-http-monitor.yaml"
    owner 'root'
    group 'root'
    mode '0644'
    variables(
      apache_port: site['port'],
      server_name: site['server_name']
    )
    notifies 'restart', 'service[rackspace-monitoring-agent]', 'delayed'
    action 'create'
    only_if { node.deep_fetch('platformstack', 'cloud_monitoring', 'enabled') }
  end
end