# `docs` folder

This folder contains the source for the animal traits database website. It is implemented using [GitHub pages](https://pages.github.com/), which uses [Jekyll](https://docs.github.com/en/pages/setting-up-a-github-pages-site-with-jekyll). 

The website is available at https://animaltraits.org/.

The descriptive statistics on the website are filled in interactively by some javascript that reads the database and updates the page accordingly.

To work on this site locally (i.e. if you are trying to edit the website), follow the [Jekyll](https://docs.github.com/en/pages/setting-up-a-github-pages-site-with-jekyll) instructions for testing your GitHub pages site locally (and obviously clone the repo to your computer). Once everything is installed and working, run the server with the command `bundle exec jekyll serve`, then browse to [http://localhost:4000](http://localhost:4000). Note that the Javascript won't work when running locally due to security restrictions.
