<p align="center">
  <img alt="gitleaks" src="https://raw.githubusercontent.com/zricethezav/gifs/master/gitleakslogo.png" height="70" />
</p>

A fork from [oficial Gitleaks Action](https://github.com/zricethezav/gitleaks-action), provides a simple way to run gitleaks in your CI/CD pipeline.


### Sample Workflow
```yaml
name: gitleaks

on: [push, pull_request, workflow_dispatch]

jobs:
  gitleaks:
    runs-on: ubuntu-latest
    steps:
      - name: Run checkout
        uses: actions/checkout@v2
        with:
          fetch-depth: 0

      - name: Run Gitleaks
        id: gitleaks
        uses: olxbr/gitleaks-action@main

```

### Using your own .gitleaks.toml configuration
```yaml
name: gitleaks

on: [push, pull_request, workflow_dispatch]

jobs:
  gitleaks:
    runs-on: ubuntu-latest
    steps:
      - name: Run checkout
        uses: actions/checkout@v2
        with:
          fetch-depth: 0

      - name: Run Gitleaks
        id: gitleaks
        uses: olxbr/gitleaks-action@main
        with:
          config_path: security/.gitleaks.toml

```
> The `config_path` is relative to your GitHub Worskpace

## Important
You must use `actions/checkout` before the `olxbr/gitleaks-action` step. If you are using `actions/checkout@v2` you must specify a commit depth other than the default which is 1. 

Using a fetch-depth of '0' clones the entire history. If you want to do a more efficient clone, use '2', but that is not guaranteed to work with pull requests.   
