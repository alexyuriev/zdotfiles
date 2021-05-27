# aws-save-ec2-tags

The tool is used query ec2 tags from AWS EC2 instance and write them onto the local file system.


The following is an example of a configuration of a tag-control-file that can be used with `aws-save-ec2-tags` command executed with `--tag-control-file=<json>` switch.
```
{
    "tags" : [
        {
            "tag"         : "masterless-puppet",
            "output-file" : "/etc/cloud/masterless-puppet-classes",
            "overwrite"   : "0",
            "mode"        : "0444"
        },
        {
            "tag"         : "zapp-server-id",
            "output-file" : "/etc/cloud/zapp-server-id",
            "overwrite"   : "0",
            "mode"        : "0444"
        },
        {
            "tag"         : "zapp-name",
            "output-file" : "/etc/cloud/zapp-name",
            "overwrite"   : "0",
            "mode"        : "0444"
        },
        {
            "tag"         : "zapp-ephemeral",
            "output-file" : "/etc/cloud/zapp-ephemeral",
            "overwrite"   : "0",
            "mode"        : "0444"
        },
        {
            "tag"         : "zapp-class",
            "output-file" : "/etc/cloud/zapp-class",
            "overwrite"   : "0",
            "mode"        : "0444"
        }
    ]
}
```
