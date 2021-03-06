There are 4 main scripts inside the _./scripts folder_. The master script is the script that starts with **SNPtoAA..** The part after underscore designates the new feature that belongs to that release. The 3 other scripts are helper scripts. **vcfToTsv_v3** converts a human readable vcf to a tsv. HGVStoBiomart converts mutations like 

>*XXXX_YYYYdelAATTAAGAGAAGCAACATCTCC>TCTC*

to variants separated by forward slash(default input of i-pv). Beware that you provide a single column of equations, it will check from your mRNA and protein sequence whether if your variants are correctly annotated. **invokeCircos** does what it says, suppose you exited the i-pv after generation of circos datatracks. And then you changed these datatracks a bit and now want to re-run i-pv. **invokeCircos** script remedies the problem of having to through entire i-pv workflow by simply taking your mRNA, protein fasta seq and invoking circos with the datatracks in the _./datatracks_ folder.

Recommendations: If on windows, use strawberry perl. Make sure dependencies of circos is met. Use circos version 0.67-7. 
If on windows, versions of circos newer than 0.67-7 will give an error, replace the circos file in the *./bin folder* of circos with the same file coming from 0.67-7 version. If you use these newer version a compulsory white background is added. So when your output from i-pv is generated, go to _./Output_ folder and open the html file, search for a group with the id of bg and remove it. This should solve the white background issue.

Directions:

1. Extract the archive anywhere in your computer.
2. Open **SNPtoAA_45_indoril.pl** in _./script_ folder and move to line 903. Search for a variable called **$circos**
3. Change the value of the **$circos** variable to the path to your version of circos script file. You are required to do this only the first time you are using i-PV.
4. Place the input files (mRNA sequence, protein sequence, conservation scores(numbers separated by newlines) and variation (biomart-ensembl format) ) in the input folder.
5. If your variation file does not match the format than try the helper scripts as mentioned in the beginning of this readme.
6. Run the **SNPtoAA_45_indoril.pl**.
7. Follow the onscreen instructions.
8. Your output will be located in the _./Output_ directory. Your datatracks will be generated in the _./datatracks_ folder. These are instructions for circos, you can delete them or keep for to modify and use later with the **invokeCircos** script.
9. You only need the html file, the rest you can delete.
10. You can now send this html file to your colleagues or generate a static figure.

Note: Do not change the files in the _./template_ folder.
You can watch the tutorial videos online at [**i-pv.org**](http://i-pv.org/)
Are you looking for the Javascript codes? Go to the [**circos-p/templates**](./circos-p/templates) folder, you will see 2 files; **javascript.txt** and **javascript_noconnector.txt**.
If you did not specify any connectors, than **javascript_noconnector.txt** is used or vice versa. The javascript is encapsulated inside the html tag of which the svg will be embedded by the perl script.

_**The examples belong to version 1.45.**_