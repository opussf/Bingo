# Repo Notes

This repo is an experiment to make the "Develop" branch as the default branch.

The Default branch is the default target of all Pull/Merge Requests.

In this case, all issues are merged into "Develop" as they are addressed.

Merging Develop into Master, and tagging Master will still trigger a release.
Which still follows the GitFlow model.

I feel like this also complies to the idea of the "single branch" workflow.
All features, and bug fixes are merged into "Develop", and "Develop" should always maintain the releaseable status.
