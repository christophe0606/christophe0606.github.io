---
layout: page
title: Sites
permalink: /sites/
---

Web sites I read.

{% for blog in site.data.blogs %} 

* [{{ blog.name | escape }} ]({{ blog.url | relative_url }})

{% endfor %}