# Change Log

## [v0.4.0][] (2019-03-06)

- Features:
  + should allow route traffic via public network interface #8

Details: https://github.com/teracyhq-incubator/teracy-dev-essential/milestone/4?closed=1


## [v0.3.0][] (2018-01-22)

- Features:
  + should add support for vagrant-gatling-rsync auto restart when crashed #34

- Improvements:
  + should not use hard-coded network interface names #21
  + should select accessible IP address by priority for the vagrant-hostmanager plugin #20
  + should force '$ vagrant gatling-rsync-auto' to use '$ vagrant up' instead #39
  + should check guest machine state before run rsync recovery #44
  + should sync created files from Linux host due to inotify bug for the rsync #40

- Bug Fixes:
  + should not warn when the same domain alias is duplicated #36


Details: https://github.com/teracyhq-incubator/teracy-dev-essential/milestone/3?closed=1


## [v0.2.0][] (2018-12-07)

- Improvements:
  + vagrant hostmanager should remove duplicate hostnames/aliases in /etc/hosts of the host machine #24
  + should update to name \_id with best practices #26

- Bug Fixes:
  + wrong auto network interface selection when vmware and virtualbox are installed on Windows #27


Details: https://github.com/teracyhq-incubator/teracy-dev-essential/milestone/2?closed=1


## [v0.1.0][] (2018-09-21)


Initial release version which:

- add auto select bridge network interface for public_network
- save mac address feature for public_network
- vagrant-hostmanager should work properly


Details: https://github.com/teracyhq-incubator/teracy-dev-essential/milestone/1?closed=1


[v0.1.0]: https://github.com/teracyhq-incubator/teracy-dev-essential/milestone/1?closed=1
[v0.2.0]: https://github.com/teracyhq-incubator/teracy-dev-essential/milestone/2?closed=1
[v0.3.0]: https://github.com/teracyhq-incubator/teracy-dev-essential/milestone/3?closed=1
[v0.4.0]: https://github.com/teracyhq-incubator/teracy-dev-essential/milestone/4?closed=1

