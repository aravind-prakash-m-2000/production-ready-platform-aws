# Incident post-mortem template

**Incident ID:**  
**Date:**  
**Authors:**  
**Severity:** SEV-0 / SEV-1 / SEV-2 / SEV-3  
**Status:** Draft / Reviewed  

## Summary

One paragraph: what broke, who was affected, how long, what fixed it.

## Impact

- Customer-facing: (error rate, latency, failed checkouts)
- Internal: (on-call pages, blocked deploys)
- SLO / error budget consumed:

## Timeline (UTC)

| Time | Event |
| --- | --- |
| HH:MM | Alert fired (`CheckoutAvailabilitySLOBurn`) |
| HH:MM | Incident channel opened / Jira `SRE-####` created |
| HH:MM | Mitigated |
| HH:MM | Resolved |

## Detection

How did we learn? Was MTTD acceptable?

## Response

What was tried? What actually worked?

## Root cause

Five whys. Distinguish trigger vs root cause.

## Contributing factors

- Change: (git SHA / Terraform plan)
- Capacity / saturation
- Missing alert or runbook gap

## What went well

## What went poorly

## Action items

| Action | Owner | Due | Tracking |
| --- | --- | --- | --- |
| | | | Jira / GitHub issue |

## Appendix

- Grafana:  
- AMP queries:  
- Relevant PRs:  
