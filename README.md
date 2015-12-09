# github-export-items
Export GitHub Items from GitHub API

## Requirements

```
$ gem install octocat
```

## Synopsis/Usage

```shell
Usage:
  ./github-export-items.rb <COMMAND> <GITHUB_REPOSITORY>

Commands:
  pulls                    Export Pull Requests(all)
  pulls_open               Export Pull Requests(only opened)
  pull_requests_comments   Export Review Comments
  issues_comments          Export Issues Comments

Examples:
  ./github-export-items.rb pulls git/git
```


