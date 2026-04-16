# Contributing to resume-forge

First off, thank you for taking the time to contribute!

This document covers how to ask questions, report issues, suggest enhancements, and contribute code.

---

## I just have a question

Please don't file an issue to ask a question. Use [GitHub Discussions](https://github.com/shekar-raja/resume-forge/discussions) instead — it's the right place to ask questions, share ideas, or get help.

Before posting, check whether your question is addressed in the [README](README.md) or has already been asked in the discussions. If it has but the answer doesn't satisfy you, add a comment to the existing discussion rather than opening a new one.

---

## Submit an issue

Bugs and feature requests are tracked as [GitHub issues](https://github.com/shekar-raja/resume-forge/issues).

Before submitting, search existing issues to see if your problem has already been reported. If it has and the issue is still open, comment on it instead of opening a new one. If you only find closed issues, open a new one and link to the closed ones in your description.

**Good issue titles** are clear and specific — e.g. `forge command fails on zsh when company name has a space` rather than `bug in forge`.

---

## Contribute code

A good place to start:
- Issues labeled [`good first issue`](https://github.com/shekar-raja/resume-forge/issues?q=label%3A%22good+first+issue%22) — small, self-contained changes
- Issues labeled [`help wanted`](https://github.com/shekar-raja/resume-forge/issues?q=label%3A%22help+wanted%22) — more involved work

If you found a bug and want to fix it, please open an issue first before submitting a PR. Same for new features — a feature request issue lets the discussion about the idea stay separate from the discussion about the implementation.

Some areas that would be especially welcome:
- Windows support for `setup.sh` and `forge.sh`
- Additional master CV templates for different roles (data engineer, PM, designer, etc.)
- Shell compatibility improvements (fish, bash edge cases)

---

## Commits

There are no strict rules, but these make the history easier to follow:

- Use the present tense and imperative mood: `Add Windows support` not `Added Windows support`
- Avoid vague messages like `fix`, `update`, or `typo`
- Keep commits focused — one logical change per commit
- Use `git commit --amend` to clean up before pushing rather than piling on fix commits

---

## Pull requests

- Keep PRs small and focused — one feature or fix per PR
- If your change touches `setup.sh` or `forge.sh`, test it on a clean shell session
- Update the README if your change affects usage or setup steps

---

Have fun, and thanks again for contributing!
