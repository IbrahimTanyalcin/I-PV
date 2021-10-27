# I-PV <img src="https://github.com/IbrahimTanyalcin/I-PV/blob/master/img/logo.png?raw=true" width='70' height='auto' style='float:right;'>

[![NPM](https://nodei.co/npm/ibowankenobi-i-pv.png)](https://nodei.co/npm/ibowankenobi-i-pv/)

[![I-PV Website](https://img.shields.io/badge/ipv-website-orange)](http://www.i-pv.org/)
[![Readme](https://img.shields.io/badge/ipv-readme-azure
)](https://github.com/IbrahimTanyalcin/I-PV/tree/master/i-pv)

## Read the article

[![link](https://github.com/IbrahimTanyalcin/I-PV/blob/master/img/i-pv_article.jpeg?raw=true)](https://academic.oup.com/bioinformatics/article/32/3/447/1743584)

## Interactive Protein Sequence VIsualization/Viewer

I-PV aims to unify protein features in a single interactive figure. It is easy to generate and
highly customizable. Data is checked and then plotted. When you publish figures with I-PV, I recommed you also
post the files in the datatracks folder as supplementary. 

In I-PV is designed to convey complex proteomics information to the audience in an interesting format. 

Below are some [sample outputs](http://i-pv.org/EGFR.html).

![alt tag](https://github.com/IbrahimTanyalcin/I-PV/blob/master/img/sample.png?raw=true)

![alt tag 2](https://github.com/IbrahimTanyalcin/I-PV/blob/master/img/sample2.png?raw=true)

## Readme
[![Readme](https://img.shields.io/badge/ipv-readme-azure
)](https://github.com/IbrahimTanyalcin/I-PV/tree/master/i-pv)

## Publishing

- Run one of the publish scripts within `package.json`:

```
npm run publishPatchNPM
```
- The `gitTag.js` inside `/utils` can both update `npm` version and `org_ipv` version. 
- If you change peripheral files only, increment `npm` version. 
- If you change `SNPtoAA.pl`, increment both `npm` version and `org_ipv` version.
- Choose the right publish script based on above.