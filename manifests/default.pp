$home = '/home/vagrant'

Exec {
  path => ['/usr/sbin', '/usr/bin', '/sbin', '/bin']
}

exec { "apt-update":
  command => "/usr/bin/apt-get update"
}

Exec["apt-update"] -> Package <| |>

# -

include apt

File { owner => 0, group => 0, mode => 0644 }

file { '/etc/motd':
  content => "Welcome to your Vagrant-built virtual machine for Rails development!
  Managed by Puppet."
}

stage { 'preinstall':
  before => Stage['main']
}

package { ['curl', 'build-essential', 'zlib1g-dev', 'git-core', 'libsqlite3-dev']:
  ensure => installed
} ->

package { ['python-software-properties', 'software-properties-common']:
  ensure => installed
} ->

# Nokogiri dependencies
package { ['libxml2', 'libxml2-dev', 'libxslt1-dev']:
  ensure => installed
} ->

# ExecJS runtime.
package { 'nodejs':
  ensure => installed
} ->

apt::ppa { 'ppa:pitti/postgresql':
} ->
package { 'libpq-dev':
  ensure => installed
} ->
class { 'postgresql':
  charset => 'UTF8',
  version => '9.2',
} ->
class { 'postgresql::server':
  config_hash => {
    'ip_mask_deny_postgres_user' => '0.0.0.0/32',
    'ip_mask_allow_all_users'    => '0.0.0.0/0',
    'listen_addresses'           => '*',
    'ipv4acls'                   => ['local all all md5'],
    'postgres_password'          => 'password'
  }
} ->
exec { 'utf8 postgres':
  command => 'pg_dropcluster --stop 9.2 main ; pg_createcluster --start --locale en_US.UTF-8 9.2 main',
  unless  => 'sudo -u postgres psql -t -c "\l" | grep template1 | grep -q UTF',
  require => Class['postgresql::server'],
  path    => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
} ->
package { 'postgresql-contrib-9.2':
} ->
postgresql::db { 'pensieve_development':
  user => 'def',
  password => 'password'
} ->
postgresql::db { 'pensieve_test':
  user => 'def',
  password => 'password'
} ->
postgresql::role { 'pensieve':
  password_hash => postgresql_password('pensieve', 'password'),
  createdb => true,
  createrole => true,
  login => true,
  superuser => true
} ->
postgresql::database_grant{'pensieve_development_privilege':
  privilege => 'ALL',
  db => 'pensieve_development',
  role => 'pensieve'
} ->
postgresql::database_grant{'pensieve_test_privilege':
  privilege => 'ALL',
  db => 'pensieve_test',
  role => 'pensieve'
} ->
exec { "install_ruby_build":
  command => "git clone https://github.com/sstephenson/ruby-build.git && cd ruby-build && sudo ./install.sh",
  cwd => $home,
  creates => "/usr/local/bin/ruby-build",
  path => "/usr/bin/:/bin/",
  logoutput => true,
} ->
exec { "install_ruby":
  command => "ruby-build 2.1.1 /home/vagrant/.rubies/ruby-2.1.1",
  cwd => $home,
  creates => "/home/vagrant/.rubies/ruby-2.1.1",
  timeout => 600,
  path => "/usr/local/bin:/usr/bin/:/bin/",
  logoutput => true,
} ->
exec { "install_chruby":
  command => "wget -O chruby-0.3.4.tar.gz https://github.com/postmodern/chruby/archive/v0.3.4.tar.gz && tar -xzvf chruby-0.3.4.tar.gz && cd chruby-0.3.4/ && sudo make install",
  cwd => $home,
  creates => '/usr/local/bin/chruby-exec',
  path => "/usr/local/bin:/usr/bin/:/bin/",
  logoutput => true,
} ->
file { '/etc/profile.d/chruby.sh':
  content => '[ -n "$BASH_VERSION" ] || [ -n "$ZSH_VERSION" ] || return
source /usr/local/share/chruby/chruby.sh
source /usr/local/share/chruby/auto.sh'
} ->
file_line { "default_chruby":
  line => "chruby ruby-2.1.1",
  path => '/home/vagrant/.bashrc'
} ->
exec { "install_bundler":
  command => "/home/vagrant/.rubies/ruby-2.1.1/bin/gem install bundler",
  cwd => $home,
  path => "/usr/local/bin:/usr/bin/:/bin/"
} ->
package { 'vim-gtk':
  ensure => installed
} ->
class { 'janus':
} ->
janus::install { 'vagrant': }
