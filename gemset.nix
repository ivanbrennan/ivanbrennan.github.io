{
  addressable = {
    dependencies = ["public_suffix"];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0viqszpkggqi8hq87pqp0xykhvz60g99nwmkwsb0v45kc2liwxvk";
      type = "gem";
    };
    version = "2.5.2";
  };
  colorator = {
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0f7wvpam948cglrciyqd798gdc6z3cfijciavd0dfixgaypmvy72";
      type = "gem";
    };
    version = "1.1.0";
  };
  concurrent-ruby = {
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "183lszf5gx84kcpb779v6a2y0mx9sssy8dgppng1z9a505nj1qcf";
      type = "gem";
    };
    version = "1.0.5";
  };
  em-websocket = {
    dependencies = ["eventmachine" "http_parser.rb"];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1bsw8vjz0z267j40nhbmrvfz7dvacq4p0pagvyp17jif6mj6v7n3";
      type = "gem";
    };
    version = "0.5.1";
  };
  eventmachine = {
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "08477hl609rmmngwfy8dmsqz5zvsg8xrsrrk6xi70jf48majwli0";
      type = "gem";
    };
    version = "1.2.6";
  };
  ffi = {
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0zw6pbyvmj8wafdc7l5h7w20zkp1vbr2805ql5d941g2b20pk4zr";
      type = "gem";
    };
    version = "1.9.23";
  };
  forwardable-extended = {
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "15zcqfxfvsnprwm8agia85x64vjzr2w0xn9vxfnxzgcv8s699v0v";
      type = "gem";
    };
    version = "2.6.0";
  };
  "http_parser.rb" = {
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "15nidriy0v5yqfjsgsra51wmknxci2n2grliz78sf9pga3n0l7gi";
      type = "gem";
    };
    version = "0.6.0";
  };
  i18n = {
    dependencies = ["concurrent-ruby"];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "038qvz7kd3cfxk8bvagqhakx68pfbnmghpdkx7573wbf0maqp9a3";
      type = "gem";
    };
    version = "0.9.5";
  };
  jekyll = {
    dependencies = ["addressable" "colorator" "em-websocket" "i18n" "jekyll-sass-converter" "jekyll-watch" "kramdown" "liquid" "mercenary" "pathutil" "rouge" "safe_yaml"];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "01s1r5pjfdvk5r1pz3j4smz42jsfv5vvp4q7fg0mrzxn9xk2nvi6";
      type = "gem";
    };
    version = "3.8.1";
  };
  jekyll-feed = {
    dependencies = ["jekyll"];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0kr3kyaq4z3jixn6ay8h16bxxlv6slvvp7nqnl05jdymhkl0bmm9";
      type = "gem";
    };
    version = "0.9.3";
  };
  jekyll-paginate = {
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0r7bcs8fq98zldih4787zk5i9w24nz5wa26m84ssja95n3sas2l8";
      type = "gem";
    };
    version = "1.1.0";
  };
  jekyll-sass-converter = {
    dependencies = ["sass"];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "008ikh5fk0n6ri54mylcl8jn0mq8p2nfyfqif2q3pp0lwilkcxsk";
      type = "gem";
    };
    version = "1.5.2";
  };
  jekyll-watch = {
    dependencies = ["listen"];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0m7scvj3ki8bmyx5v8pzibpg6my10nycnc28lip98dskf8iakprp";
      type = "gem";
    };
    version = "2.0.0";
  };
  kramdown = {
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0mkrqpp01rrfn3rx6wwsjizyqmafp0vgg8ja1dvbjs185r5zw3za";
      type = "gem";
    };
    version = "1.16.2";
  };
  liquid = {
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "17fa0jgwm9a935fyvzy8bysz7j5n1vf1x2wzqkdfd5k08dbw3x2y";
      type = "gem";
    };
    version = "4.0.0";
  };
  listen = {
    dependencies = ["rb-fsevent" "rb-inotify" "ruby_dep"];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "01v5mrnfqm6sgm8xn2v5swxsn1wlmq7rzh2i48d4jzjsc7qvb6mx";
      type = "gem";
    };
    version = "3.1.5";
  };
  mercenary = {
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "10la0xw82dh5mqab8bl0dk21zld63cqxb1g16fk8cb39ylc4n21a";
      type = "gem";
    };
    version = "0.3.6";
  };
  octopress = {
    dependencies = ["jekyll" "mercenary" "octopress-deploy" "octopress-escape-code" "octopress-hooks" "redcarpet" "titlecase"];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "10d8rin6in1xy3115dqm5q8dl2snfj28390lzpqs7xvx3sm3nc5z";
      type = "gem";
    };
    version = "3.0.11";
  };
  octopress-deploy = {
    dependencies = ["colorator"];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0h5kqfl8a50xkljby2lrm3qn89f25gqi0f6lc5lb7l42lr9ka5zp";
      type = "gem";
    };
    version = "1.3.0";
  };
  octopress-escape-code = {
    dependencies = ["jekyll"];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "00va9a9jb0d5jzmbk7mba4zi8ahf5csr6hcqw90gwqs6y4i6hg60";
      type = "gem";
    };
    version = "2.1.1";
  };
  octopress-hooks = {
    dependencies = ["jekyll"];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1qdn0p2zqxf8kl1dz2c4n7jgmf38468qcbr89nnxw89cczvfyfw0";
      type = "gem";
    };
    version = "2.6.2";
  };
  octopress-image-tag = {
    dependencies = ["jekyll"];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0f2zkrhig1f656zha4qddis4sccwg8fvbrn6pvivzh36l9jghwhl";
      type = "gem";
    };
    version = "1.1.0";
  };
  pathutil = {
    dependencies = ["forwardable-extended"];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0wc18ms1rzi44lpjychyw2a96jcmgxqdvy2949r4vvb5f4p0lgvz";
      type = "gem";
    };
    version = "0.16.1";
  };
  public_suffix = {
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1x5h1dh1i3gwc01jbg01rly2g6a1qwhynb1s8a30ic507z1nh09s";
      type = "gem";
    };
    version = "3.0.2";
  };
  rb-fsevent = {
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1lm1k7wpz69jx7jrc92w3ggczkjyjbfziq5mg62vjnxmzs383xx8";
      type = "gem";
    };
    version = "0.10.3";
  };
  rb-inotify = {
    dependencies = ["ffi"];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0yfsgw5n7pkpyky6a9wkf1g9jafxb0ja7gz0qw0y14fd2jnzfh71";
      type = "gem";
    };
    version = "0.9.10";
  };
  redcarpet = {
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0h9qz2hik4s9knpmbwrzb3jcp3vc5vygp9ya8lcpl7f1l9khmcd7";
      type = "gem";
    };
    version = "3.4.0";
  };
  rouge = {
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1sfhy0xxqjnzqa7qxmpz1bmy0mzcr55qyvi410gsb6d6i4ialbw3";
      type = "gem";
    };
    version = "3.1.1";
  };
  ruby_dep = {
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1c1bkl97i9mkcvkn1jks346ksnvnnp84cs22gwl0vd7radybrgy5";
      type = "gem";
    };
    version = "1.5.0";
  };
  safe_yaml = {
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1hly915584hyi9q9vgd968x2nsi5yag9jyf5kq60lwzi5scr7094";
      type = "gem";
    };
    version = "1.0.4";
  };
  sass = {
    dependencies = ["sass-listen"];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "19wyzp9qsg8hdkkxlsv713w0qmy66qrdp0shj42587ssx4qhrlag";
      type = "gem";
    };
    version = "3.5.6";
  };
  sass-listen = {
    dependencies = ["rb-fsevent" "rb-inotify"];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0xw3q46cmahkgyldid5hwyiwacp590zj2vmswlll68ryvmvcp7df";
      type = "gem";
    };
    version = "4.0.0";
  };
  tale = {
    dependencies = ["jekyll" "jekyll-paginate"];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "047xxz8bfasjjy940h66k57w40l7zjzk5dswlhx7mwaqpmqry0h4";
      type = "gem";
    };
    version = "0.1.2";
  };
  titlecase = {
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1njx4d3iavqc8b0rb749jlph7yq1f0f9q57sm2bfw0qz7wiw8gsi";
      type = "gem";
    };
    version = "0.1.1";
  };
}