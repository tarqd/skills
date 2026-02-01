# Tera Filters Reference

Complete reference for all built-in Tera filters.

## String Filters

### lower
Converts string to lowercase.
```jinja2
{{ "HELLO" | lower }}  {# hello #}
```

### upper
Converts string to uppercase.
```jinja2
{{ "hello" | upper }}  {# HELLO #}
```

### capitalize
Lowercases all characters except the first, which is uppercased.
```jinja2
{{ "hello world" | capitalize }}  {# Hello world #}
```

### title
Capitalizes each word.
```jinja2
{{ "hello world" | title }}  {# Hello World #}
```

### trim
Removes leading and trailing whitespace.
```jinja2
{{ "  hello  " | trim }}  {# hello #}
```

### trim_start
Removes leading whitespace.
```jinja2
{{ "  hello  " | trim_start }}  {# hello   #}
```

### trim_end
Removes trailing whitespace.
```jinja2
{{ "  hello  " | trim_end }}  {#   hello #}
```

### trim_start_matches
Removes leading characters matching pattern.
```jinja2
{{ "///path" | trim_start_matches(pat="/") }}  {# path #}
```

### trim_end_matches
Removes trailing characters matching pattern.
```jinja2
{{ "path///" | trim_end_matches(pat="/") }}  {# path #}
```

### truncate
Truncates string to specified length with ellipsis.
Requires `builtins` feature.
```jinja2
{{ "Hello World" | truncate(length=8) }}  {# Hello... #}
{{ "Hello World" | truncate(length=8, end="") }}  {# Hello Wo #}
```

### wordcount
Returns number of words.
```jinja2
{{ "Hello World" | wordcount }}  {# 2 #}
```

### replace
Replaces occurrences of a string.
```jinja2
{{ "Hello Bob" | replace(from="Bob", to="Alice") }}  {# Hello Alice #}
```

### addslashes
Adds backslashes before quotes.
```jinja2
{{ "I'm here" | addslashes }}  {# I\'m here #}
```

### slugify
Transforms to ASCII lowercase with hyphens. Requires `builtins` feature.
```jinja2
{{ "Hello World!" | slugify }}  {# hello-world #}
```

### split
Splits string into array.
```jinja2
{{ "a,b,c" | split(pat=",") }}  {# ["a", "b", "c"] #}
```

### striptags
Removes HTML tags.
```jinja2
{{ "<b>Bold</b>" | striptags }}  {# Bold #}
```

### linebreaksbr
Replaces newlines with `<br>` tags.
```jinja2
{{ "line1\nline2" | linebreaksbr }}  {# line1<br>line2 #}
```

### spaceless
Removes whitespace between HTML tags.
```jinja2
{{ "<p> <a> </a> </p>" | spaceless }}  {# <p><a></a></p> #}
```

### indent
Indents each line with prefix.
```jinja2
{{ text | indent(prefix="  ") }}
{{ text | indent(prefix="  ", first=true) }}  {# indent first line too #}
{{ text | indent(prefix="  ", blank=true) }}  {# indent blank lines too #}
```

## Array Filters

### length
Returns length of array, object, or string.
```jinja2
{{ items | length }}
{{ "hello" | length }}  {# 5 #}
```

### first
Returns first element.
```jinja2
{{ [1, 2, 3] | first }}  {# 1 #}
```

### last
Returns last element.
```jinja2
{{ [1, 2, 3] | last }}  {# 3 #}
```

### nth
Returns element at index (0-based).
```jinja2
{{ [1, 2, 3] | nth(n=1) }}  {# 2 #}
```

### join
Joins array elements with separator.
```jinja2
{{ ["a", "b", "c"] | join(sep=", ") }}  {# a, b, c #}
```

### reverse
Reverses array or string.
```jinja2
{{ [1, 2, 3] | reverse }}  {# [3, 2, 1] #}
{{ "abc" | reverse }}  {# cba #}
```

### sort
Sorts array in ascending order.
```jinja2
{{ [3, 1, 2] | sort }}  {# [1, 2, 3] #}
{{ people | sort(attribute="name") }}
```

### unique
Removes duplicates.
```jinja2
{{ [1, 2, 1, 3] | unique }}  {# [1, 2, 3] #}
{{ items | unique(attribute="id") }}
{{ names | unique(case_sensitive=true) }}
```

### slice
Returns a portion of array.
```jinja2
{{ items | slice(start=1, end=3) }}
{{ items | slice(end=5) }}       {# first 5 #}
{{ items | slice(start=2) }}     {# skip first 2 #}
{{ items | slice(end=-2) }}      {# all but last 2 #}
```

### concat
Appends values to array.
```jinja2
{{ [1, 2] | concat(with=[3, 4]) }}  {# [1, 2, 3, 4] #}
{{ items | concat(with=new_item) }}  {# append single item #}
```

### filter
Filters array by attribute value.
```jinja2
{{ posts | filter(attribute="published", value=true) }}
{{ posts | filter(attribute="author.name", value="Alice") }}
{{ posts | filter(attribute="category") }}  {# remove nulls #}
```

### map
Extracts attribute from each object.
```jinja2
{{ users | map(attribute="name") }}  {# ["Alice", "Bob"] #}
{{ users | map(attribute="address.city") }}
```

### group_by
Groups array into map by attribute.
```jinja2
{% set by_year = posts | group_by(attribute="year") %}
{% for year, year_posts in by_year %}
    <h2>{{ year }}</h2>
    {% for post in year_posts %}
        {{ post.title }}
    {% endfor %}
{% endfor %}
```

## Number Filters

### abs
Returns absolute value.
```jinja2
{{ -5 | abs }}  {# 5 #}
```

### round
Rounds number.
```jinja2
{{ 3.7 | round }}  {# 4 #}
{{ 3.14159 | round(precision=2) }}  {# 3.14 #}
{{ 3.2 | round(method="ceil") }}  {# 4 #}
{{ 3.8 | round(method="floor") }}  {# 3 #}
```

### pluralize
Returns singular or plural suffix.
```jinja2
{{ count }} item{{ count | pluralize }}  {# 1 item, 2 items #}
{{ count }} categor{{ count | pluralize(singular="y", plural="ies") }}
```

### filesizeformat
Formats bytes as human-readable size. Requires `builtins` feature.
```jinja2
{{ 1048576 | filesizeformat }}  {# 1 MB #}
```

## Date Filters

### date
Formats timestamp or date string. Requires `builtins` feature.
```jinja2
{{ timestamp | date }}  {# YYYY-MM-DD #}
{{ timestamp | date(format="%Y-%m-%d %H:%M") }}
{{ "2024-01-15T10:30:00Z" | date(timezone="America/New_York") }}
{{ timestamp | date(format="%A %d %B", locale="fr_FR") }}
```

Format codes follow [chrono strftime](https://docs.rs/chrono/latest/chrono/format/strftime/).

## Encoding Filters

### escape
HTML-escapes string.
```jinja2
{{ "<script>" | escape }}  {# &lt;script&gt; #}
```

### escape_xml
XML-escapes string.
```jinja2
{{ "Tom & Jerry" | escape_xml }}  {# Tom &amp; Jerry #}
```

### safe
Marks content as safe (disables escaping). Must be last filter.
```jinja2
{{ html_content | safe }}
{{ content | upper | safe }}  {# correct #}
{{ content | safe | upper }}  {# will escape! #}
```

### urlencode
URL-encodes string (except `/`). Requires `builtins` feature.
```jinja2
{{ "/path?a=b" | urlencode }}  {# /path%3Fa%3Db #}
```

### urlencode_strict
URL-encodes all special characters including `/`.
```jinja2
{{ "/path?a=b" | urlencode_strict }}  {# %2Fpath%3Fa%3Db #}
```

### json_encode
Converts to JSON.
```jinja2
{{ data | json_encode | safe }}
{{ data | json_encode(pretty=true) | safe }}
```

## Conversion Filters

### int
Converts to integer.
```jinja2
{{ "42" | int }}
{{ "42" | int(default=0) }}
{{ "0xff" | int(base=16) }}
```

### float
Converts to float.
```jinja2
{{ "3.14" | float }}
{{ "invalid" | float(default=0.0) }}
```

### as_str
Converts to string.
```jinja2
{{ 42 | as_str }}
```

## Object Filters

### get
Gets value by key (for keys that aren't valid identifiers).
```jinja2
{{ config | get(key="my-setting") }}
{{ config | get(key="missing", default="fallback") }}
```

### default
Returns default value if undefined.
```jinja2
{{ maybe_undefined | default(value="fallback") }}
```

Note: Only checks if variable exists, not if it's falsy.

## Filter Sections

Apply filter to entire block:
```jinja2
{% filter upper %}
    This entire block
    will be uppercased.
{% endfilter %}

{% filter escape %}
    {% block user_content %}{% endblock %}
{% endfilter %}
```
