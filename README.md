# teracy-dev-essential

This is an extension to set up a good enough basic essential dev workstation by adding more useful
features for dev workstation.


## How to use

Configure `workspace/teracy-dev-entry/config_default.yaml` with the following similar content:

```yaml
teracy-dev:
  extensions:
    - _id: "entry-0"
      path:
        extension: teracy-dev-essential
      location:
        git: https://github.com/teracyhq-incubator/teracy-dev-essential.git
        branch: develop
      require_version: ">= 0.1.0-SNAPSHOT"
      enabled: true
```


## How to develop

Configure `workspace/teracy-dev-entry/config_override.yaml` with the follow similar content:


```yaml
teracy-dev:
  extensions:
    - _id: "entry-0"
      path:
        lookup: workspace # use workspace directory to lookup for this extension
      location:
        git: git@github.com:hoatle/teracy-dev-essential.git # your forked repo
```

With this override configuration, you tells `teracy-dev` to use the `teracy-dev-essential` extension
from the `workspace` directory
