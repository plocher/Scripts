# Testing Policy

Cross-repo policy for the SPCoast/jBOM/kproj project family. Applies to all
implementers and reviewers in all repos unless a repo's own WARP.md explicitly
overrides a clause.

## Two-tier test volatility

Tests belong to exactly one of two tiers with opposite volatility contracts:

### Tier 1 — Behave/Gherkin scenarios (durable requirements contract)
- Scenarios encode **user-sourced functional requirements**.
- They are **permanently binding** until a requirement changes.
- A diff that **deletes or weakens** a scenario is a **requirements change**
  and MUST be justified by a traceable ticket or requirement update — not by
  implementation convenience or refactoring.
- Scenario churn without a requirements citation is a **blocking review
  finding**.
- Scenarios added to cover new acceptance criteria survive all future
  refactors of the underlying implementation.

### Tier 2 — Unit tests (implementation-volatile)
- Unit tests pin **implementation correctness** — the behavior of specific
  functions, classes, or modules at a chosen granularity.
- They are **as volatile as the code they test**: unit tests MUST be
  deleted, rewritten, or replaced whenever the implementation they track
  changes. Stale unit tests that no longer reflect the implementation are
  a **defect**, not inert dead weight.
- Proactive pruning and evolution of unit tests during refactors is normal
  hygiene, not a red flag.
- A unit test whose fixture does not accurately represent the production
  case it claims to model is an advisory finding (missed implementation
  pin), never a blocking functional finding.

## Review corollaries (for adversarial reviewers)

1. **Functional findings cite Behave scenarios.** A missing or weak
   acceptance-criterion coverage finding MUST identify a missing or
   inadequate *scenario* in a `.feature` file. Citing a unit test as
   evidence of a functional gap is a category error.

2. **Unit tests cannot satisfy acceptance criteria.** A user-facing
   acceptance criterion is only satisfied by a Behave scenario that
   exercises the CLI/API at the described scope. A unit test that mocks
   the behavior under test is not a substitute, even if it passes.

3. **Scenario deletion = requirements change.** Always flag scenario
   removals as blocking unless the PR carries explicit requirements-change
   justification.

4. **Unit test deletion in refactors is expected.** Do not flag deleted
   or replaced unit tests as coverage regressions unless the corresponding
   Behave scenario also disappeared or weakened.

## Quick reference

| Test type    | Correct scope                  | Volatility      | Deletion OK?                        |
|--------------|-------------------------------|-----------------|-------------------------------------|
| Behave/BDD   | User requirement, CLI behavior | Durable         | Only with requirements-change ticket|
| Unit test    | Implementation correctness     | Match the code  | Yes — expected on refactor          |
