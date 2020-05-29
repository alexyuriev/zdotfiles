#
# systemd::action::enable - enables unit file in the multi-user target
#
#                  $unit_source_dir is a directory where the $name unit file is located
#                  $target defines ${target}.wants linkage
#                  If $start is set to true, then systemd is instucted to start a unit file
#                  If $target os not set, then $target becomes multi-user.target
#


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
