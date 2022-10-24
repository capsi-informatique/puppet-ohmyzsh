# == Define: ohmyzsh::install
#
# This is the ohmyzsh module. It installs oh-my-zsh for a user and changes
# their shell to zsh. It has been tested under Ubuntu.
#
# This module is called ohmyzsh as Puppet does not support hyphens in module
# names.
#
# oh-my-zsh is a community-driven framework for managing your zsh configuration.
#
# === Parameters
#
# set_sh: (boolean) whether to change the user shell to zsh
# disable_auto_update: (boolean) whether to prompt for updates bi-weekly
#
# === Authors
#
# Leon Brocard <acme@astray.com>
# Zan Loy <zan.loy@gmail.com>
#
# === Copyright
#
# Copyright 2014
#
define ohmyzsh::install (
  Enum[present, latest] $ensure = latest,
  Boolean $set_sh               = false,
  Boolean $disable_auto_update  = false,
  Boolean $override_template    = false,
) {

  include ohmyzsh

  if !defined(Package['git']) {
    package { 'git':
      ensure => present,
    }
  }

  if !defined(Package['zsh']) {
    package { 'zsh':
      ensure => present,
    }
  }

  if $name == 'root' {
    $home  = '/root'
    $group = fact('os.family') ? {
      /(Free|Open)BSD/ => 'wheel',
      default          => 'root',
    }
  } else {
    $home  = "${ohmyzsh::home}/${name}"
    $group = $name
  }

  vcsrepo { "${home}/.oh-my-zsh":
    ensure   => $ensure,
    provider => git,
    source   => $ohmyzsh::source,
    revision => 'master',
    user     => $name,
    require  => Package['git'],
  }

  if !$ohmyzsh::concat {
    if $override_template {
      file { "${home}/.zshrc":
        ensure  => file,
        replace => 'no',
        owner   => $name,
        group   => $group,
        mode    => '0644',
        source  => "puppet:///modules/${module_name}/zshrc.zsh-template",
        require => Vcsrepo["${home}/.oh-my-zsh"],
      }
    } else {
      exec { "ohmyzsh::cp .zshrc ${name}":
        creates => "${home}/.zshrc",
        command => "cp ${home}/.oh-my-zsh/templates/zshrc.zsh-template ${home}/.zshrc",
        path    => ['/bin', '/usr/bin'],
        onlyif  => "getent passwd ${name} | cut -d : -f 6 | xargs test -e",
        user    => $name,
        require => Vcsrepo["${home}/.oh-my-zsh"],
        before  => File_Line["ohmyzsh::disable_auto_update ${name}"],
      }
    }
  } else {
    file { "${home}/.zshrc.local":
      ensure  => file,
      replace => 'no',
      owner   => $name,
      group   => $group,
      mode    => '0644',
      source  => "puppet:///modules/${module_name}/concat/zshrc.local",
      require => Vcsrepo["${home}/.oh-my-zsh"],
    }

    concat { "${home}/.zshrc":
      ensure  => present,
      owner   => $name,
      group   => $group,
      mode    => '0644',
      require => Vcsrepo["${home}/.oh-my-zsh"],
    }

    concat::fragment { "${home}/.zshrc:puppet":
      target  => "${home}/.zshrc",
      content => "### This file is managed by Puppet, any changes will be lost\n### Use the file ~/.zshrc.local for your changes\n",
      order   => '000',
    }

    concat::fragment { "${home}/.zshrc:template-010":
      target => "${home}/.zshrc",
      source => "puppet:///modules/${module_name}/concat/zshrc-010.zsh-template",
      order  => '010',
    }

    concat::fragment { "${home}/.zshrc:template-030":
      target => "${home}/.zshrc",
      source => "puppet:///modules/${module_name}/concat/zshrc-030.zsh-template",
      order  => '030',
    }

    concat::fragment { "${home}/.zshrc:template-050":
      target => "${home}/.zshrc",
      source => "puppet:///modules/${module_name}/concat/zshrc-050.zsh-template",
      order  => '050',
    }

    concat::fragment { "${home}/.zshrc:template-070":
      target => "${home}/.zshrc",
      source => "puppet:///modules/${module_name}/concat/zshrc-070.zsh-template",
      order  => '070',
    }

    concat::fragment { "${home}/.zshrc:template-090":
      target => "${home}/.zshrc",
      source => "puppet:///modules/${module_name}/concat/zshrc-090.zsh-template",
      order  => '090',
    }
  }

  if $set_sh {
    if !defined(User[$name]) {
      user { "ohmyzsh::user ${name}":
        ensure     => present,
        name       => $name,
        managehome => true,
        shell      => lookup('ohmyzsh::zsh_shell_path'),
        require    => Package['zsh'],
      }
    } else {
      User <| title == $name |> {
        shell => lookup('ohmyzsh::zsh_shell_path')
      }
    }
  }

  if !$ohmyzsh::concat {
    file_line { "ohmyzsh::disable_auto_update ${name}":
      path  => "${home}/.zshrc",
      line  => "DISABLE_AUTO_UPDATE=\"${disable_auto_update}\"",
      match => '.*DISABLE_AUTO_UPDATE.*',
    }
  } else {
    concat::fragment { "${home}/.zshrc:DISABLE_AUTO_UPDATE":
      target  => "${home}/.zshrc",
      content => "DISABLE_AUTO_UPDATE=\"${disable_auto_update}\"\n",
      order   => '040',
    }
  }

  # Fix permissions on '~/.oh-my-zsh/cache/completions'
  file { "${home}/.oh-my-zsh/cache/completions":
    ensure  => directory,
    replace => 'no',
    owner   => $name,
    group   => $group,
    mode    => '0755',
    require => Vcsrepo["${home}/.oh-my-zsh"],
  }
}
