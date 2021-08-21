<hr>

## 📂 `/script/`

There are 4 main scripts inside the `./script folder`. Master script is the one to run. The rest are helper scripts.

### 📜 `/script/SNAtoAA.pl`

This is the master script. Run this script in order to generate the plot.

### 📜 `/script/vcfToTsv_v3.pl`

Converts a human readable `vcf` to a `tsv`. 

### 📜 `/script/HGVStoBiomart.pl`

Converts mutations like 

>*XXXX_YYYYdelAATTAAGAGAAGCAACATCTCC>TCTC*

to variants separated by forward slash (default input of i-pv). 

Beware that you provide a single column of equations, it will check from your mRNA and protein sequence whether if your variants are correctly annotated. 

### 📜 `/script/invokeCircos.pl`

Invokes circos manually. Use this to invoke circos later or modify the datatracks created by the master script.

Suppose you exited the i-pv after generation of circos datatracks. And then you changed these datatracks a bit and now want to re-run i-pv. 

`invokeCircos` script remedies the problem of having to go through entire i-pv workflow by invoking circos with the datatracks in the `./datatracks` folder you generated earlier using the master script.

<hr>

## Recommendations

> 👉 If on windows, use strawberry perl. <br>
>
> 👉 Make sure dependencies of circos is met. <br>
>
> 👉 Use circos version 0.67-7. <br>
>
> 👉 If you are using perl 5.22 use the provided `circos-0.67-7_perl_5_22` circos distribution. If you are using perl 5.26, use the other. The only difference between these packages are the `SVG.pm` regex expressions.
>
> 👉 If on windows, versions of circos newer than 0.67-7 will give an error, replace the circos file in the *./bin folder* of circos with the same file coming from 0.67-7 version. <br>
>
> 👉 If you use these newer versions, a compulsory white background is added. So when your output from i-pv is generated, go to `./Output` folder and open the html file, search for a group with the id of `bg` and remove it. This should solve the white background issue. <br>
>

<hr>

## Directions for Usage

1. Extract the archive anywhere in your computer.
2. Open `SNPtoAA.pl` in `./script` folder and move to line 904. Search for a variable called `$circos`
3. Change the value of the `$circos` variable to the path to your version of circos script file. You are required to do this only the first time you are using i-PV.
4. Place the input files:
    - mRNA sequence
    - protein sequence
    - conservation scores (numbers separated by newlines)
    - variation (biomart-ensembl format) 
    <br> in the `./circos-p/input` folder.
5. If your variation file does not match the format than try the helper scripts as mentioned in the beginning of this readme.
6. Run `SNPtoAA.pl`.
7. Follow the onscreen instructions.
8. Your output will be located in the `./circos-p/Output` directory. Your datatracks will be generated in the `./circos-p/datatracks` folder. These are instructions for circos, you can delete or keep them to modify and use later with the `invokeCircos` script.
9. You only need the html file, the rest you can delete.
10. You can now send this html file to your colleagues or generate a static figure.

> Note: <br>
>
> 👉 Do not change the files in the `./template` folder. <br>
>
> 👉 You can watch the tutorial videos online at [**i-pv.org**](http://i-pv.org/)<br>
>
> 👉 Are you looking for the Javascript codes? Go to the [**circos-p/templates**](./circos-p/templates) folder, you will see 2 files:
> - `javascript.txt`
> - `javascript_noconnector.txt`
> <!---->
>
> If you did not specify any connectors, then `javascript_noconnector.txt` is used or vice versa. The javascript is encapsulated inside the html tag of which the svg will be embedded by the perl script.<br>
>
> 👉 `./circos-p/Outout` folder might include examples from previous versions.