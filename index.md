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

