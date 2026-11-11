t3kton github pages source
==========================

How to build and publish to github
----------------------------------

First checkout the source branch, and build::

  git switch source
  make html

Then checkout the master branch and commit::

  git switch master
  make copy
  git add .
  git commit -m 'updated documentation' -a
  git push origin master
