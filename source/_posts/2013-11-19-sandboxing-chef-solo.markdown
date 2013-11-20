---
layout: post
title: "sandboxing chef-solo"
date: 2013-11-19 22:31
comments: true
categories: chef, rails, devOps
---
I'm in the early stages of a team project. Our goal is to build a rails app that uses [chef-solo](http://docs.opscode.com/chef_solo.html) to automate the creation and provisioning of a DigitalOcean droplet, and deploys to it using [Capistrano](https://github.com/capistrano/capistrano). The idea is to let a user deploy their own app to a [DO](http://digitalocean.com/) server using our app to do the heavy lifting.

We're new to chef-solo, and initially I tried plowing through documentation, hoping to build a comprehensive understanding before diving into the project. But we really needed to get our hands dirty to get a feel for chef, so we started sandboxing tiny prototypes. We were flying blind at times, but the small successes kept us moving forward.

The zeroth step was to install some necessary tools, namely knife-solo and berkshelf. knife-solo is the command line tool for chef-solo, and berkshelf plays a role similar to Bundler, managing dependencies within chef.

For our first sandbox venture, we took an existing, chef-ready [rails server template](https://github.com/TalkingQuickly/rails-server-template) and used it to provision an existing server.

Next we created a project directory from scratch, initialized a chef repo within it, and cloned an existing cookbook into the cookbooks directory. Easier said than done, but the ascii-art made it all worth while.

{% img production http://i.imgur.com/gEGr6LJ.jpg 'production' 'production' %}

These little exercises were helpful, but we were still bogged down trying to map out the components and configurations encompassed by Chef. We backed up, got some helpful input from the TA's here at Flatiron School, and started mapping out the components necessary to *our* project, pinpointing the core functionality we needed to start with.

{% img sketch http://i.imgur.com/oih6feU.jpg 'sketch' 'sketch' %}

###Step 1: Get a local chef repo communicating with DigitalOcean

It turns out there's a plugin just for that: [knife-digital_ocean](https://github.com/rmoriz/knife-digital_ocean). We had to put our API-credentials from DigitalOcean into `knife.rb`, a configuration file for chef-solo, and add our SSH key to the DO account. Then we were able to create a new DO droplet with the desired OS and our SSH key, all in a single console command. Thank you knife-digital_ocean!

There's plenty more work ahead. Our rails app needs to:

- automate knife-digital_ocean commands
- take user input
	- Github url for the app they want to deploy
	- necessary credentials (handle the SSH keys)
- run provisioning as a background process (it takes a while)
- deploy with Capistrano

It feels much more manageable with step 1 behind us and the skeleton of the project sketched out. Still, I'm sure I'll be spending some more quality time in the Chef documentation.
