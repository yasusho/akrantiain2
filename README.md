# akrantiain
A domain-specific language designed to describe conlangs' orthographies

## Documentations
[English manual about .snoj file](https://sozysozbot.github.io/akrantiain2/manuals/manuals_en.htm) (Incomplete)  
[English manual about modules](https://sozysozbot.github.io/akrantiain2/manuals/module_en.htm) (Incomplete)  
[.snojファイルについての日本語マニュアル](https://sozysozbot.github.io/akrantiain2/manuals/manuals_ja.htm) (未完)  
[akrantiain変換部についての日本語マニュアル](https://sozysozbot.github.io/akrantiain2/manuals/conversions_ja.htm) (未完)  
ny lirsesen [kanteluescosti virle lineparine](https://sozysozbot.github.io/akrantiain2/manuals/manuals_conlang_lpa.htm)  
## Getting Started

All files handled by akrantiain must be in UTF-8.

### Installing
#### Ubuntu (16.04)
Clone the repo and run:
```
$ make
```

Try it out by running:
```
$ echo lineparine | ./akrantiain2 samples/sample_lineparine.snoj
```

Or use it interactively:
```
$ ./akrantiain2 samples/sample_lineparine.snoj
```

Or read from file:
```
$ ./akrantiain2 samples/sample_lineparine.snoj < samples/input_sample_lineparine.txt
```

#### Windows (7 and 10)
1. Install Haskell Platform (>= 7.10.2).
2. Clone the repo.
3. Run:
```
$ ghc --make akrantiain2.hs
```

Try it out by running:
```
$ echo lineparine | akrantiain2 samples\sample_lineparine.snoj
```

Or use it interactively:
```
$ akrantiain2 samples\sample_lineparine.snoj
```

Or read from file:
```
$ chcp 65001
$ akrantiain2 samples\sample_lineparine.snoj --file < samples\input_sample_lineparine.txt
```

Note: In Windows, interactive mode does not work when the input contains multi-byte characters.
In such cases, use "read from file" mode for akrantiain to function properly.
