# HWZ forums scraper for the EDMW neural network

This is a Ruby script to scrape the HardwareZone forums (specifically EDMW)
for raw post content. The goal of the script is non-commercial and academic: 
we aim to build a corpus large enough to train a neural network to
speak Singaporean colloquial English, Singlish.

You can read about this project
[here](https://blog.wtf.sg/2015/05/29/generating-singlish-with-lstms/), or 
view the demo here: [https://wtf.sg/edmw-nn/](https://wtf.sg/edmw-nn/)

# Usage

```sh
bundle install # for dependencies
ruby scrape.rb

ruby scrape.rb --help

  Usage: ruby scrape.rb [options]
      -o, --output [filename]          Output file. Default: 'data.txt'
      -t, --threads [threads]          Number of threads for multithreading. Default: 15
      -p, --pages [pages]              Number of pages to scrape (latest). Default: 100
```

Note: We do not recommend setting the number of threads to more than 20, as
that can be constituted as a denial of service attack which we are not responsible
for.

---

We will not release or rehost the dataset publicly.

### License

MIT
