node['unicorn']['applications'].each do |app_name, app_config|
  group app_config['group']

  user app_config['user'] do
    home app_config['dir']
    system true
  end

  execute "chown-#{app_name}-dir" do
    command "chown -R #{app_config['user']}:#{app_config['group']} #{app_config['dir']}"
  end

  # TODO(jpg): Change ownership of application directory recursively

  template ::File.join('/etc/init', "#{app_name}.conf") do
    source 'upstart.erb'
    variables app_name: app_name, app_config: app_config
    user app_config['user']
    group app_config['group']
  end

  service app_name do
    provider Chef::Provider::Service::Upstart
    action :nothing
  end

  template ::File.join(app_config['dir'], 'config/unicorn.rb') do
    source 'unicorn.erb'
    variables app_name: app_name, app_config: app_config
    user app_config['user']
    group app_config['group']
    notifies :reload, "service[#{app_name}]"
  end

  %w(pids scripts log).each do |d|
    directory ::File.join(app_config['dir'], d)
    user app_config['user']
    group app_config['group']
  end
  
  template ::File.join('/etc/nginx/conf.d', app_name + '.conf') do
    source 'nginx.erb'
    variables app_name: app_name, app_config: app_config
    user app_config['user']
    group app_config['group']
  end

  template ::File.join('/etc/logrotate.d', app_name) do
    source 'logrotate.erb'
    variables app_name: app_name, app_config: app_config
    user app_config['user']
    group app_config['group']
  end
end
