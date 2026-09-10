# scripts

| File | Notes |
| --- | --- |
| `cluster_health.sh` | Requires AWS credentials and kubectl. |
| `dr_backup.sh` | Requires Terraform initialized in the env dir and `DR_BUCKET`. |
| `blue_green_shift.sh` | Weights must sum to 100. |
| `jira_incident.py` | `--serve` listens on `:8080` for Alertmanager. |
| `test_checkout_api.sh` | Local unit tests; no AWS required. |

Make executable after clone:

```bash
git update-index --chmod=+x scripts/*.sh scripts/*.py
```

On Windows, run the `.sh` files from Git Bash or WSL.
