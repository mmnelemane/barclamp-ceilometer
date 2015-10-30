# Copyright 2011 Dell, Inc.
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

package "openstack-ceilometer"
package "ceph-common" # we need it for ceph client setup
package "ceph-radosgw" # needed for REST APIs for Ceph
package "requests-aws" # needed for authentication with Radosgw

include_recipe "#{@cookbook_name}::common"

commands :os_cmd => "openstack"

def get_radosgw_keys
  # Get admin access and secret keys from controller
  if node.roles.include?("ceilometer-server")
    res = os_cmd(["user" "show" "admin" "-c id" "-f json"])
    admin_id = JSON.parse(res)[0]["Value"]

    res = os_cmd(["ec2", "credentials", "list", "-f json"])
    cred_list = JSON.parse(res)
    cred_list.each do |cred|
      if cred["User ID"] == admin_id
        access_key = cred["Access"]
        secret_key = cred["Secret"]
      end
    end
  end
  rgw_keys["access_key"] = access_key
  rgw_keys["secret_key"] = secret_key
  return rgw_keys
end

# radosgw user needs read access to ceilometer.conf
group node[:ceilometer][:group] do
  action :modify
  members node[:radosgw][:user]
  append true
end

file "/var/log/ceilometer/radosgw.log" do
  owner node[:ceilometer][:user]
  group node[:ceilometer][:group]
  mode "0664"
  action :create_if_missing
end
