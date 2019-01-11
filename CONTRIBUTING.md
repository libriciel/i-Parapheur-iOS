Contributing
=============

# Dependancies

Cocoa pods is required to build the project
```
$ [sudo] gem install cocoapods
```

```
$ pod install
```


# Opening project.

After pods installation, open the iParapheur.xcworkspace with Xcode/AppCode.  
The iParapheur.xcodeproj file doesn't contain pods dependancies, and should not be opened.


# Install GitLab-CI Runner

Gitlab specifies who to install the `gitlab-runner` for a specific project :
https://gitlab.libriciel.fr/i-parapheur/iParapheur-iOS/settings/ci_cd

TLDR :
```
sudo curl --output /usr/local/bin/gitlab-runner https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-darwin-amd64
sudo chmod +x /usr/local/bin/gitlab-runner
cd ~
gitlab-runner install
gitlab-runner register
  # url : https://gitlab.libriciel.fr/
  # token : (find it in the project CI/CD settings)
  # executor : shell
gitlab-runner start
```

Every other shared runners should be disabled, since those are Linux ones.  
We should only register one (or several) MacOS runners here.


# Launching GitLab-CI Runner

`$ sudo gitlab-runner run --working-directory /some/existing/folder --user the_current_non_root_user`