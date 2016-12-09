class vim(
  $user = undef,
  $group = $user,
  $mode = '0640',
  $home_dir = undef,
) {
  include wget

  validate_string($user)
  validate_string($group)
  validate_string($mode)
  validate_absolute_path($home_dir)

  case $::osfamily {
    'RedHat': { $vim_package = 'vim-enhanced' }
    default: { $vim_package = 'vim' }
  }

  package { 'vim':
    ensure => installed,
    name   => $vim_package,
  }

  File {
    owner  => $user,
    group  => $group,
    mode   => $mode,
  }

  file { [
    # The puppetlabs/accounts module manages the .vim file resource
    # TODO: need to make this into a conditional to handle not double managing a resource
    # "${home_dir}/.vim",
    "${home_dir}/.vim/autoload",
    "${home_dir}/.vim/bundle",
    ] :
    ensure => 'directory',
  }

  file { "${home_dir}/.vimrc.local" :
    replace => false,
    content => "\"Add here your custom options for vim, puppet will not override them\n",
  }

  wget::fetch { 'DownloadPathogen':
    source      => 'https://raw.github.com/tpope/vim-pathogen/master/autoload/pathogen.vim',
    destination => "${home_dir}/.vim/autoload/pathogen.vim",
    verbose     => true
  }

  file { "${home_dir}/.vim/autoload/pathogen.vim":
  }

  concat { 'vimrc':
    path  => "${home_dir}/.vimrc",
  }

  Concat::Fragment {
    target  => 'vimrc',
  }

  concat::fragment { 'rc-header':
    target  => 'vimrc',
    content => "\" generated by Puppet module vim\n\n",
    order   => '05',
  }

  vim::rc { 'vimrc-pathogen':
    content => "execute pathogen#infect()\ncall pathogen#helptags()",
  }

  vim::rc { 'vimrc-local':
    content => "if filereadable(glob(\"~/.vimrc.local\"))\n\tsource ~/.vimrc.local\nendif",
  }

  vim::rc { 'syntax on': }
  vim::rc { 'filetype plugin indent on': }

  Package['vim']
  -> File[
    "${home_dir}/.vim",
    "${home_dir}/.vim/autoload",
    "${home_dir}/.vim/bundle"
  ]
  -> Wget::Fetch['DownloadPathogen']
  -> File["${home_dir}/.vim/autoload/pathogen.vim"]
  -> Concat['vimrc']

}
