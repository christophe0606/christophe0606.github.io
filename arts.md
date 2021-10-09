---
layout: page
title: Arts
permalink: /arts/
cat: True
---
{% for post in site.categories.arts %} 

* [{{ post.title | escape }} ({{post.date | date_to_string}})]({{ post.url | relative_url }})

{% endfor %}