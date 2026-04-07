## What does this PR do?

<!-- Brief description of your change -->

## Type

- [ ] bug fix
- [ ] new animation
- [ ] new language
- [ ] documentation
- [ ] infrastructure / CI
- [ ] other: ___

## How to test

<!-- How did you verify your change works? -->

```bash
# Example commands you ran:
bash scripts/cheer.sh
CHEERER_LANG=en CHEERER_DUMB=true bash scripts/cheer.sh
```

## Checklist

- [ ] `shellcheck --severity=error` passes on all shell files
- [ ] Smoke test passes (see CONTRIBUTING.md)
- [ ] No secrets, API keys, or env vars committed (`bash scripts/check-secrets.sh`)
- [ ] READMEs updated if adding an animation or language
- [ ] Commits are focused and have clear messages
