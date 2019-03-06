# teracy-dev-essential

This is an extension to set up a good enough basic essential dev workstation by adding more useful
features for dev workstation.


## How to use

Configure `workspace/teracy-dev-entry/config_default.yaml` with the following similar content:

- Use a specific version:

```yaml
teracy-dev:
  extensions:
    - _id: "entry-essential"
      path:
        extension: teracy-dev-essential
      location:
        git:
          remote:
            origin: https://github.com/teracyhq-incubator/teracy-dev-essential.git
          branch: v0.4.0
      require_version: ">= 0.4.0"
      enabled: true
```

- Use the latest stable version (auto update):

```yaml
teracy-dev:
  extensions:
    - _id: "entry-essential"
      path:
        extension: teracy-dev-essential
      location:
        git:
          remote:
            origin: https://github.com/teracyhq-incubator/teracy-dev-essential.git
          branch: master
      require_version: ">= 0.4.0"
      enabled: true
```

- Use the latest develop version (auto update):

```yaml
teracy-dev:
  extensions:
    - _id: "entry-essential"
      path:
        extension: teracy-dev-essential
      location:
        git:
          remote:
            origin: https://github.com/teracyhq-incubator/teracy-dev-essential.git
          branch: develop
      require_version: ">= 0.5.0-SNAPSHOT"
      enabled: true
```


## How to develop

You should configure the forked git repo into the `workspace` directory by adding the following
similar content into `workspace/teracy-dev-entry/config_override.yaml`:


```yaml
teracy-dev:
  extensions:
    - _id: "entry-essential" # must match the _id configured from the config_default.yaml file
      path:
        lookup: workspace # use workspace directory to lookup for this extension
      location:
        git:
          remote:
            origin: git@github.com:hoatle/teracy-dev-essential.git # your forked repo
          branch: develop
      require_version: ">= 0.5.0-SNAPSHOT"
```
