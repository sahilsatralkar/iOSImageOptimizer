# 🛡️ Branch Protection Setup Guide

## Recommended Settings for Repository Owner Control

### Go to: GitHub Repository → Settings → Branches → Add Rule

**Rule for `main` branch**:
- ✅ **Require status checks to pass before merging**
  - ✅ Require branches to be up to date before merging
  - ✅ Status checks required: `Run Tests`
- ✅ **Require pull request reviews before merging**
  - ✅ Required approving reviews: 1 (you)
  - ✅ Dismiss stale reviews when new commits are pushed
- ✅ **Require review from code owners** (optional)
- ✅ **Include administrators** (applies rules to you too - recommended)
- ❌ **Allow force pushes** (disabled for safety)
- ❌ **Allow deletions** (disabled for safety)

## Result
- Tests must pass ✅
- YOU must manually approve ✅  
- YOU control all merges ✅
- No auto-merge capability ✅

## Optional: Create CODEOWNERS file
Create `.github/CODEOWNERS` with:
```
* @sahilsatralkar
```
This makes you the required reviewer for ALL changes.