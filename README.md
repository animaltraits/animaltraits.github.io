## Welcome to the Animal Traits database

### An animal trait database containing body mass, metabolic rate and brain size

This GitHub project is the website for the animal traits database. Its primary purpose is to provide straightforward access to the database. It is implemented using [GitHub pages](https://pages.github.com/), which uses [Jekyll](https://docs.github.com/en/pages/setting-up-a-github-pages-site-with-jekyll). The database is a simple spreadsheet available as CSV or Excel. The website simple provides download links.

The website is available at https://animaltraits.org/.

The descriptive statistics on the website are filled in interactively by some javascript that reads the database and updates the page accordingly.

To work on this site locally, follow the [Jekyll](https://docs.github.com/en/pages/setting-up-a-github-pages-site-with-jekyll) instructions for testing your GitHub pages site locally (and obviously clone the repo to your computer). Once everything is installed and working, run the server with the command `bundle exec jekyll serve`, then browse to [http://localhost:4000](http://localhost:4000). Note that the Javascript won't work when running locally due to security restrictions.
