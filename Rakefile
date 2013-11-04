require 'rubygems'

SERVICE_NAME = 'winlock-primer'

desc 'register windows service'
task :register do
  require 'win32/service'
  include Win32

  # Create a new service
  Service.create({
    :service_name       => SERVICE_NAME,
    :service_type       => Service::WIN32_OWN_PROCESS,
    :description        => 'Primers',
    :start_type         => Service::AUTO_START,
    :error_control      => Service::ERROR_NORMAL,
    :binary_path_name   => 'c:\ruby\bin\rubyw.exe -C c:\winlock-primer service.rb',
    :load_order_group   => 'Network',
    :dependencies       => ['W32Time','Schedule'],
    :display_name       => SERVICE_NAME
  })
end

desc 'unregister windows service'
task :unregister do
  require 'win32/service'

  # NOTE: if the services applet is up during this operation, the service won't be removed from that ui
  # unitil you close and reopen it (it gets marked for deletion)
  Win32::Service.delete(SERVICE_NAME)
end

begin
  require 'rspec/core'
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec) do |spec|
      spec.pattern = FileList['spec/**/*_spec.rb']
  end
  task :default => :spec
rescue LoadError
end
