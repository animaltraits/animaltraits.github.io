---
show_downloads: true
---

The animal traits database is a curated database containing body mass,
metabolic rate and brain size measurements across a wide range of
terrestrial animal taxa. The database is described in the (as yet
unpublished) paper:

Herberstein, M. E. et al. 2021. An animal trait database for body mass, metabolic rate and brain size.

The database and associated software can be freely reused with no
restrictions. If you use the database in your research, we request
that you cite the paper, and, when possible, also cite the relevant
original data sources that are identified in the database.

The distinctive value of this new animal trait database is four-fold:
<ol class="descr-list">
  <li>Open access: the data are openly available to researchers without restrictions; </li>
  <li>Taxonomic breadth: the database includes a broad taxonomic range of terrestrial animal species including several groups of tetrapods and arthropods, as well as molluscs and annelids; </li>
  <li>Clean, empirical data: all data are sourced from the original publication that made and reported on the included measurements, and are entered into the database using the original metrics - all subsequent transformations can be applied to these original data, meaning it is eminently reusable by future researchers; </li>
  <li>Annotation: we have included useful methodological metadata that allow researchers to filter the dataset as needed.</li>
</ol>

### Data formats

The buttons at the top of this page provide download access to the database. 

The database can be downloaded as either a UTF-8 encoded CSV file or as an Excel (.xlsx) file. UTF-8 encoding is used so that accented characters in the references are represented correctly. Some software assumes that CSV files are UTF-8 encoded, however in some situations it is necessary to specify the encoding when opening a CSV file. To open such a file in Microsoft Excel, use the [Text Import Wizard](https://support.microsoft.com/en-us/office/text-import-wizard-c5b02af6-fda1-4440-899f-f78bafe41857). If reading the file using base [R](https://www.r-project.org/), use `read.csv(file, encoding = "UTF-8")`.

The `Download docs` button provides access to a CSV file that documents the columns in the database. The Excel version of the database contains the column documentation as a second worksheet.

### Content

<div>
The database contains:
<ul class="descr-list">
  <li><span class="count" id="sources"></span> data sources;</li>
  <li><span class="count" id="observations"></span> observations;</li>
  <li><span class="count" id="species"></span> species;</li>
  <li><span class="count" id="mass"></span> species with mass;</li>
  <li><span class="count" id="metabolicrate"></span> species with metabolic rate;</li>
  <li><span class="count" id="brainsize"></span> species with brain size.</li>
</ul>
</div>


### License

<p xmlns:dct="http://purl.org/dc/terms/">
  <a rel="license"
     href="http://creativecommons.org/publicdomain/zero/1.0/">
    <img src="http://i.creativecommons.org/p/zero/1.0/88x31.png" style="border-style: none;" alt="CC0" />
  </a>
  <br />
  To the extent possible under law,
  <a rel="dct:publisher"
     href="https://animaltraits.org">https://animaltraits.org</a>
  has waived all copyright and related or neighboring rights to
  <span property="dct:title">the animal traits database</span>.
</p>

### Source accessibility

The raw data and source code for compiling the raw data into the
database are available on
[GitHub](https://github.com/animaltraits/animaltraits.github.io).

<script type = "text/javascript">
// Get some database statistics and enter them into the page
// Note that this doesn't work when running locally
let url = "{{ site.csv_url | absolute_url }}";
Papa.parse(url, {
    download: true,
    header: true,
    worker: true,
    complete: function(results) {
        let species = new Set();
        let mass = new Set();
        let mr = new Set();
        let brain = new Set();
        let sources = new Set();
        let observations = 0;
        results.data.forEach(row => {
            if (row.inTextReference !== undefined) sources.add(row.inTextReference);
            if (row.phylum !== undefined) observations++;
            if (row.species !== undefined) {
                species.add(row.species);
                if (row.mass || row.mass == "0") mass.add(row.species);
                if (row["metabolic rate"] || row["metabolic rate"] == "0") mr.add(row.species);
                if (row["brain size"] || row["brain size"] == "0") brain.add(row.species);
            }
        });
        document.getElementById("sources").innerHTML = sources.size;
        document.getElementById("observations").innerHTML = observations;
        document.getElementById("species").innerHTML = species.size;
        document.getElementById("mass").innerHTML = mass.size;
        document.getElementById("metabolicrate").innerHTML = mr.size;
        document.getElementById("brainsize").innerHTML = brain.size;
    }
});
</script>

