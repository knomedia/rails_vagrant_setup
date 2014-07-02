# rails_vagrant_setup

basic setup for a rails + postgres project in vagrant


## Basic Usage

Install [VirtualBox](https://www.virtualbox.org).

Install [Vagrant](http://vagrantup.com)

Install [Puppet](http://puppetlabs.com) & [librarian-puppet](http://librarian-puppet.com/) via RubyGems

``` sh
$ gem install puppet
$ gem install librarian-puppet
$ rails new your_project --database=postgresql
$ cd your_project
```

Copy files from this project (without the `.git` and this `README.md` file) into your new project

Edit `manifests/defaults.pp` to change out db names and users (TODO: build something to automate this)

```sh
$ librarian-puppet install
$ vagrant up
```
