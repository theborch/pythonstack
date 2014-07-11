# Encoding: utf-8
#
# Cookbook Name:: pythonstack
# Recipe:: application_python
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

include_recipe 'pythonstack::apache'
include_recipe 'git'
include_recipe 'chef-sugar'
include_recipe 'python'

python_pip 'flask'
python_pip 'mysql-connector-python' do
  options '--allow-external'
end
python_pip 'gunicorn'
python_pip 'MySQL-python'

node['apache']['sites'].each do | site_name |
  site_name = site_name[0]

  application site_name do
    path node['apache']['sites'][site_name]['docroot']
    owner node['apache']['user']
    group node['apache']['group']
    deploy_key node['apache']['sites'][site_name]['deploy_key']
    repository node['apache']['sites'][site_name]['repository']
    revision node['apache']['sites'][site_name]['revision']
    notifies :restart, 'service[apppy]', :immediately
  end
end

template "/etc/init.d/apppy" do
  source 'init_script.erb'
  owner 'root'
  group 'root'
  mode '0755'
  variables({
    :app_path =>  "#{node['apache']['sites']['example.com']['docroot']}/current/apppy/flask",
    :app_name => 'apppy',
    :app_user => 'root'
  })
  action :create
end

service "apppy" do
  supports :status => true, :restart => true
  action [ :enable, :start ]
end

mysql_connection_info = {
  :host     => 'localhost',
  :username => 'root',
  :password => node['mysql']['server_root_password']
}

# Create a mysql database
mysql_database 'apppy' do
  connection mysql_connection_info
  action :create
end

mysql_database_user 'apppy' do
  connection mysql_connection_info
  password   'qwerty'
  action     :create
end

mysql_database_user 'apppy' do
  connection mysql_connection_info
  database_name 'apppy'
  host          'localhost'
  privileges    [:select,:update,:insert,:delete]
  action        :grant
end

template "/etc/apppy.conf" do
  source 'mysql_apppy.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables({
    :db_user =>  'apppy',
    :db_pass => 'qwerty',
    :db_host => 'localhost',
    :db_name => 'apppy'
  })
  action :create
end