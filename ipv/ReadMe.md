There are 4 main scripts inside the *./script folder*. The master script is the script that starts with SNPtoAA.. 
The part after underscore designates the new feature that belongs to that release. 
The 3 other scripts are helper scripts:

 * vcfToTsv_v3 converts a human readable vcf to a tsv. 
 * _HGVStoBiomart_ converts mutations like 
 
 ```XXXX_YYYYdelAATTAAGAGAAGCAACATCTCC>TCTC``` 
 
 to variants separated by forward slash (A/T/C/G [*default input of i-pv*](http://i-pv.org/intro_ipv_alt4.html)). 
 Beware that you provide a single column of equations, it will check from your mRNA and protein sequence whether if your variants are correctly annotated. 
 * _invokeCircos_ does what it says, suppose you exited the i-pv after generation of circos datatracks. 
And then you changed these datatracks a bit and now want to re-run i-pv. 
*invokeCircos* script remedies the problem of having to through entire i-pv workflow by simply taking your mRNA, protein fasta seq and invoking circos with the datatracks in the *./datatracks* folder.

__Recommendations__: If on windows, use strawberry perl. Make sure dependencies of circos is met. Use circos version 0.67-7. 
If on windows, versions of circos newer than 0.67-7 will give an error, replace the circos file in the *./bin* folder of circos with the same file coming from 0.67-7 version. 
If you use these newer version a compulsory white background is added. So when your output from i-pv is generated, go to *./Output* folder and open the html file, search for a group with the id of bg and remove it. 
This should solve the white background issue.

__Directions__:

 1. Extract the archive anywhere in your computer.
 2. Open SNPtoAA_44_colorMuts.pl in *./script* folder and move to line 880. Search for a variable called $circos
 3. Change the value of the $circos variable to the path to your version of circos script file. You are required to do this only the first time you are using i-PV.
 4. Place the input files (mRNA sequence, protein sequence, conservation scores(numbers separated by newlines) and variation (biomart-ensembl format) ) in the input folder.
 5. If your variation file does not match the format than try the helper scripts as mentioned in the beginning of this readme.
 6. Run the SNPtoAA_44_colorMuts.pl in the script folder.
 7. Follow the onscreen instructions.
 8. Your output will be located in the *./Output* directory. Your datatracks will be generated in the *./datatracks* folder. These are instructions for circos, you can delete them or keep for to modify and use later with the invokeCircos script.
 9. You only need the html file, the rest you can delete.
 10. You can now send this html file to your colleagues or generate a static figure.

__Note__: Do not change the files in the *./template* folder.
You can watch the tutorial videos online at i-pv.org
Are you looking for the Javascript codes? Go to the circos-p/templates folder, you will see 2 files; javascript.txt and javascript_noconnector.txt.
If you did not specify any connectors, than javascript_noconnector.txt is used or vice versa. The javascript is encapsulated inside the html tag of which the svg will be embedded by the perl script.

***The examples belong to version 1.44.