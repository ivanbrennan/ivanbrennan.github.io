---
layout: post
title: "Chef roles"
date: 2013-11-21 09:11
comments: true
categories: Chef, devOps
---
It took me a while to wrap my head around a Chef role. It sounds simple enough at first -- a collection of recipes that allows a node to act in a certain capacity, as say, a Redis server -- but Chef also deals in cookbooks, which are also collections of recipes. So then what's the difference between a cookbook and a role?

A cookbook is a collection of recipes relating to a particular piece of technology. The nginx cookbook, for example, contains several recipes related to building and configuring nginx: `nginx::source` builds nginx from source, `nginx::ohai_plugin` provides the Ohai plugin as a template, `nginx::passenger` builds the passenger gem, etc.

A node is a single server, and Chef can apply a variety of recipes to the node to set it up as needed. Those recipes can be selected from a variety of cookbooks, and we don't have to use every recipe in a given cookbook. So how do we package the particular mix of recipes we need for a certain type of node? In a role.

For lack of a better analogy, you could think of a role as a multi-course meal made from several recipes pulled from a variety of cookbooks. A couple from a Pasta cookbook, one from a French Cuisine cookbook, one from a Pastries cookbook. The meal won't be made from every single recipe in those books, just the desired ones.

Recipes can include each other too, like mixins in Ruby (the `nginx::source` recipe, for example, includes the `nginx::ohai_plugin` recipe as part of it) but let's not add to the confusion just yet.
