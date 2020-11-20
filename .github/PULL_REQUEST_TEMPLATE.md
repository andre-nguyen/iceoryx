## Pre-Review Checklist for the PR Author

1. [ ] Branch follows the naming format (`iox-#123-this-is-a-branch`)
1. [ ] Commits messages are according to this [guideline][commit-guidelines]
    - [ ] Commit messages have the issue ID (`iox-#123 commit text`)
    - [ ] Commit messages are signed (`git commit -s`)
    - [ ] Commit author matches [Eclipse Contributor Agreement][eca] (and ECA is signed)
1. [ ] Update the PR title
   - Follow the same conventions as for commit messages
   - Link to the relevant issue
1. [ ] Relevant issues are linked
1. [ ] Add sensible notes for the reviewer
1. [ ] All checks have passed
1. [ ] Assign PR to reviewer

[commit-guidelines]: https://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html
[eca]: http://www.eclipse.org/legal/ECA.php

## Notes for Reviewer
<!-- Items in addition to the checklist below that the reviewer should look for -->

## Checklist for the PR Reviewer

- [ ] Commits are properly organized and messages are according to the guideline
- [ ] Code according to our coding style and naming conventions
- [ ] Unit tests have been written for new behavior
- [ ] Public API changes are documented via doxygen
- [ ] Copyright owner are updated in the changed files
- [ ] PR title describes the changes

## Post-review Checklist for the PR Author

1. [ ] All open points are addressed and tracked via issues

## Post-review Checklist for the Eclipse Committer

1. [ ] All checkboxes in the PR checklist are checked or crossed out
1. [ ] Merge

## References

- Closes **TBD**