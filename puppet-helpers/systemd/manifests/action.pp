#
# systemd::action::define_unit - installs and enables unit file.
#
#                  $unit_source_dir is a directory where the $name unit file is located
#                  The source of the unit file is pulled from path ${unit_source_dir}/{$name}.
#
#                  If $target is defined, then
#                     1. Directory /etc/systemd/system/${target}.wants is created if does not exist
#                     2. unit is linked into /etc/systemd/system/${target.wants}
#                     3. if $start is set to true, the unit is started
#
#
#
# Typical usage
#
#  include "systemd::action"
#  systemd::action::define_unit  { 'home-playb-lockedroot-proc.mount':
#                                      unit_source_dir => "${mod_prefix}/wrks2/etc/systemd/system/",
#                                      target          => "local-fs.target",
#                                      start           => true,
#                                }
#
#  systemd::action::define_unit  { 'playb-chroot@.service' : unit_source_dir => "${mod_prefix}/wrks2/etc/systemd/system/" }
#
#  systemd::action::define_unit  { 'playb-chroot.socket' :
#                                     unit_source_dir => "${mod_prefix}/wrks2/etc/systemd/system/",
#                                     target          => "multi-user.target",
#                                     start           => true,
#                                }



define systemd::action::define_unit( String  $unit_source_dir,
                                     String  $target = "",
                                     Boolean $start  = false,
                                   ) {

    file { "${name}":
        ensure => 'file',
        path   => "/etc/systemd/system/${name}",
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => "${unit_source_dir}/${name}",
        notify => [
                    Exec['systemd-reload-units'],
                  ]
    }

    if ! empty($target)
        {

            if ! defined (File["/etc/systemd/system/${target}.wants"])
                {
                    file { "/etc/systemd/system/${target}.wants":
                        ensure => directory,
                        owner  => 'root',
                        group  => 'root',
                        mode   => '0755',
                    }
                }

            if ($start == false)
                {
                    file { "/etc/systemd/system/${target}.wants/${name}" :

                        ensure  => 'link',
                        target  => "/etc/systemd/system/${name}",
                        require =>  [
                                        File["/etc/systemd/system/${name}"],
                                    ],
                    }
                }
            else
                {
                    file { "/etc/systemd/system/${target}.wants/${name}" :

                        ensure  => 'link',
                        target  => "/etc/systemd/system/${name}",
                        require =>  [
                                        File["/etc/systemd/system/${name}"],
                                    ],
                        notify  =>  [
                                        Exec["systemd-start-${name}"],
                                    ],
                    }
                }

            exec { "systemd-start-${name}" :

                    user        => 'root',
                    group       => 'root',
                    provider    => 'shell',
                    path        => $globals::path,
                    command     => "systemctl start '${name}'",
                    refreshonly => true,
                    logoutput   => true,
            }
        }
}


class systemd::action {

    exec { "systemd-reload-units" :
            user        => 'root',
            group       => 'root',
            path        => $globals::path,
            command     => 'systemctl daemon-reload',
            refreshonly => true,
            logoutput   => true,
    }

}
