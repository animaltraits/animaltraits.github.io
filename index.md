---
show_downloads: true
---

The animal traits database is a curated database containing body mass, metabolic rate and brain size measurements across a wide range of terrestrial animal taxa. The database is described in the (as yet unpublished) paper:

Herberstein, M. E. et al. 2021. An animal trait database for body mass, metabolic rate and brain size.

If you use the database in your research, please cite this paper.

The distinctive value of this new animal trait database is four-fold:
<ol class="descr-list">
  <li>Open access: the data are openly available to researchers without restrictions; </li>
  <li>Taxonomic breadth: the database includes a broad taxonomic range of terrestrial animal species including several groups of tetrapods and arthropods, as well as molluscs and annelids; </li>
  <li>Clean, empirical data: all data are sourced from the original publication that made and reported on the included measurements, and are entered into the database using the original metrics - all subsequent transformations can be applied to these original data, meaning it is eminently reusable by future researchers; </li>
  <li>Annotation: we have included useful methodological metadata that allow researchers to filter the dataset as needed.</li>
</ol>

### Data formats

The database can be downloaded as either a UTF-8 encoded CSV file or as an Excel (.xlsx) file. UTF-8 encoding is used so that accented characters in the references are represented correctly. Some software assumes that CSV files are UTF-8 encoded, however in some situations it is necessary to specify the encoding when opening a CSV file. To open such a file in Microsoft Excel, use the [Text Import Wizard](https://support.microsoft.com/en-us/office/text-import-wizard-c5b02af6-fda1-4440-899f-f78bafe41857). If reading the file using base [R](https://www.r-project.org/), use `read.csv(file, encoding = "UTF-8")`.

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

<a rel="license" href="http://creativecommons.org/licenses/by/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by/4.0/88x31.png" /></a><br /><span xmlns:dct="http://purl.org/dc/terms/" href="http://purl.org/dc/dcmitype/Dataset" property="dct:title" rel="dct:type">The Animal traits database</span> is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by/4.0/">Creative Commons Attribution 4.0 International License</a>.


<script type = "text/javascript">
// Get some database statistics and enter them into the page
// Note that this doesn't work when running locally
let url = "{{ site.csv_url | relative_url }}";
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

