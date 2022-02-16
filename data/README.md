# `data` folder

This folder contains raw trait data and related files. The generated database with standardised trait values is NOT located here; it is compiled into `../output/observations.csv`, then copied to the website folder `../docs`.

## Encoding

CSV files are encoded in UTF-8. UTF-8 is used so that accented
characters can be used reliably and portably.  Google sheets handles
UTF-8 by default, but MS Excel requires some effort, see:

- [Is it possible to force Excel recognize UTF-8 CSV files automatically?](https://stackoverflow.com/questions/6002256/is-it-possible-to-force-excel-recognize-utf-8-csv-files-automatically)
- [How to open UTF-8 CSV file in Excel without mis-conversion of characters in Japanese and Chinese language for both Mac and Windows?](https://answers.microsoft.com/en-us/msoffice/forum/all/how-to-open-utf-8-csv-file-in-excel-without-mis/1eb15700-d235-441e-8b99-db10fafff3c2)

or query the Internet for `UTF8 CSV`. After editing a CSV file in Excel, be careful to either `Save As` and specify `Save as type: CSV (Comma delimited) (*.csv)`, or else `Export` to file type `CSV (Comma delimited) (*.csv)`. Simply clicking `Save` may save the file with the wrong format (e.g. tab-separated values).

In R, UTF-8 CSV files can be
opened by using `read.csv(..., encoding = "UTF-8")`. See this post for
reading UTF-8 in Python: [Reading a UTF8 CSV file with
Python](https://stackoverflow.com/questions/904041/reading-a-utf8-csv-file-with-python). Raw files can be written from R using `write.csv(..., row.names = FALSE, fileEncoding = "UTF-8", na = "")`.


## Sub-folders

| Folder | Description |
| ------ | ----------- |
| [`raw`](raw) | Contains raw data in UTF-8 encoded CSV files. Sub-folders are used to organise files, but do not affect processing in any way. |
| [`Endnote-dbs`](Endnote-dbs) | Contains an Endnote database that contains references for all of the raw data sources. |

## Files

| File | Description |
| ---- | ----------- |
| `README.md` | This file |
| `Template.xlsx` | Documents the structure of the raw files. Contains 2 tabs: Column descriptions and Raw data template. |
| `Template.csv` | This is the "Raw data template" tab from Template.xlsx in CSV format. This file can be copied and renamed to create a new raw data file. |
| `Too Hard Reference List.docx` | Word document that lists candidate data sources that were not included in the database. Each data source has a comment that describes why it was excluded from the database. |
| `checked-taxa.csv` | List of taxa that have been checked by the database compilation process. Used to speed up the compilation process by caching taxon queries to reduce the number of queries required. |
| `database-column-definitions.xlsx` | Spreadsheet that describes the columns in the compiled database. This is converted to CSV by the database compilation process. |

