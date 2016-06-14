# is whyrun supported
def whyrun_supported?
  true
end

use_inline_resources if defined?(use_inline_resources)

action :create do
  # set tuned config path. Different for EL6/7
  libdir = (node['platform_version'].to_i < 7) ? '/etc/tune-profiles/' : '/usr/lib/tuned/'

  # defines local variables based on profile name
  profile = Mash.new(
    name: new_resource.name,
    libdir: libdir + new_resource.name
  )

  requirements

  # initialise empty attribute hash in case no attributes where specified
  # default [main] entry
  profile['values'] = node['tuned']['profile'][profile['name']] || { main: new_resource.main }.merge(new_resource.plugins)

  # create tuned profile directory
  directory profile[:libdir] do
    # recursive true
  end

  # create tuned profile file
  # pass in the profile name and attribute hash
  # for this profile
  template "#{profile[:libdir]}/tuned.conf" do
    source 'tuned_profile_skel.erb'
    owner 'root'
    group 'root'
    mode 00644
    cookbook 'tuned'
    variables profiles: profile
  end
end

action :enable do
  requirements

  profile = {
    :name => new_resource.name
  }

  # enables profile passed in by resource call
  execute "tuned #{profile[:name]} enable" do
    command "tuned-adm profile #{profile[:name]}"
  end
end

action :disable do
  requirements

  profile = {
    :name => new_resource.name
  }

  # disables profile passed in by resource call
  execute "tuned #{profile[:name]} disable" do
    command 'tuned-adm off'
  end
end

action :default do
  requirements

  profile = {
    :name => new_resource.name
  }

  # parses the recommended profile and enables it
  execute "tuned #{profile[:name]} default" do
    command 'tuned-adm recommend|xargs -r tuned-adm profile'
  end
end

def requirements
  # Requirement
  package 'tuned'

  service 'tuned' do
    action [:enable, :start]
  end
end
