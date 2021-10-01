## Welcome to the Animal Traits database

### An animal trait database containing body mass, metabolic rate and brain size

This is GitHub project for the animal traits database. It contains two components: the raw data and R scripts used to compile the database, and a website.

#### Database

To compile the database, trait observations were manually extracted from peer-reviewed publications. Observations were recorded in CSV files, which we term _raw_ files. The raw files are stored in a directory structure underneath the `data` directory.

Raw files are read by a set of R scripts that standardise the observations and compile the result into a single spreadsheet. The scripts are in the `R` directory (and its sub-directories). The output database is written to the `output` directory. The compiled database is written to two files, UTF-8 encoded `observations.csv` and the Excel spreadsheet format `observations.xlsx`. In addition, the file `column-documentation.csv` is copied from the `data` directory into the `output` directory. The data content of the two `observations.*` files is equivalent, although the spreadsheet contains a second worksheet that contains the documentation from the `column-documentation.csv` file.

#### Website

The website is intended to provide straightforward access to the compiled database. It is implemented using [GitHub pages](https://pages.github.com/), which uses [Jekyll](https://docs.github.com/en/pages/setting-up-a-github-pages-site-with-jekyll). The compiled database is a simple spreadsheet available as CSV or Excel. The website provides download links.

The website is available at https://animaltraits.org/.

The descriptive statistics on the website are filled in interactively by some javascript that reads the database and updates the page accordingly.

To work on this site locally (i.e. if you are trying to edit the website), follow the [Jekyll](https://docs.github.com/en/pages/setting-up-a-github-pages-site-with-jekyll) instructions for testing your GitHub pages site locally (and obviously clone the repo to your computer). Once everything is installed and working, run the server with the command `bundle exec jekyll serve`, then browse to [http://localhost:4000](http://localhost:4000). Note that the Javascript won't work when running locally due to security restrictions.
