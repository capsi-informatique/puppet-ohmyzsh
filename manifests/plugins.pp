# == Define: ohmyzsh::plugins
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
# plugins: (string) space separated list of tmux plugins
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
define ohmyzsh::plugins(
  Array[String] $plugins        = ['git'],
  Hash[String,
    Struct[{
        source   => Enum[git],
        url      => Stdlib::Httpsurl,
        ensure   => Enum[present, latest],
        revision => Optional[String],
        depth    => Optional[Integer]
    }]
  ]             $custom_plugins = {},
) {

  include ohmyzsh

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

  $custom_plugins_path = "${home}/.oh-my-zsh/custom/plugins"

  $custom_plugins.each |$key, $plugin| {
    vcsrepo { "${custom_plugins_path}/${key}":
      ensure   => $plugin[ensure],
      provider => $plugin[source],
      source   => $plugin[url],
      depth    => $plugin[depth],
      revision => $plugin[revision],
      require  => ::Ohmyzsh::Install[$name],
    }
  }

  $all_plugins = union($plugins, keys($custom_plugins))

  $plugins_real = join($all_plugins, ' ')

  if !$ohmyzsh::concat {
    file_line { "${name}-${plugins_real}-install":
      path    => "${home}/.zshrc",
      line    => "plugins=(${plugins_real})",
      match   => '^plugins=',
      require => Ohmyzsh::Install[$name],
    }
  } else {
    concat::fragment { "${home}/.zshrc:plugins":
      target  => "${home}/.zshrc",
      content => "plugins=(${plugins_real})\n",
      order   => '060',
      require => Ohmyzsh::Install[$name],
    }
  }
}
