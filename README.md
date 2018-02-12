# Panda Grammar

Panda Grammar is a parser combinator library for writing recursive descent parsers. What that means is that you write functions that consume input and return a value indicating what was parsed and combine these using other higher order functions. For example, you might have a function that parses a URL scheme. You could then use that function in a function that takes a sequence of such functions to parse entire URLs.

## Example: URL Parser

Let's start by defining a few simple elements of a URL. These use the `string` and `re` helpers from Panda Grammar, which consume strings and regular expressions, respectively.

(Examples in CoffeeScript because I like to write in CoffeeScript, but the semantics are the same as those of JavaScript.)

```coffee
separator = string "/"
word = re /^\w+/
qdelim = string "?"       # query delimiter
cdelim = string "&"       # query continuation delimeter
equal = string "="
protocol = re /^https?/
sdelim = string ":"       # scheme delimiter
root = string "//"
```

So far, so good. If you're familiar with the URL spec, you'll see that we're make a few simplifying assumptions, such as ignoring FTP URLs.

Next we want to build functions using these functions to parse the various parts of a URL, like the scheme and path.

```coffee
scheme = all protocol, sdelim
path = all root, list separator, word
```

PG provides combinators, like `all` and `list`, that allow to combine the simple functions we've already defined. The only problem is that these will return nested arrays of everything that's parsed. That isn't super useful, which is why PG provides a `rule` combinator, so that you can transform these arrays into useful values.

```coffee
scheme = rule (all protocol, sdelim),
  ({value: [protocol]}) -> {protocol}

path = rule (all root, list separator, word),
  ({value: [, components]}) -> {components, path: "/" + (components.join "/")}
```

Rules take a function and pass the return value to a second function that can modify it. The return value from PG function is an object containing two properties: the parsed `value` and the `rest` of the input.

For our `scheme` rule, we take the protocol and ignore the delimiter. For the `path` rule, we ignore the `//` and return both the path components and the reconstructed path.

Here's a rule for query parameters that returns an object based on the query.

```coffee
assignment = rule (all word, equal, word),
  ({value: [key, , value]}) -> [key, value]

query = rule (all qdelim, list cdelim, assignment),
  ({value: [, pairs]}) ->
    query = {}
    query[k] = v for [k, v] in pairs
    {query}
```

We pull them altogether into another rule that parses and entire URL and merges the result into a single object.

```coffee
url = rule (all scheme, path, (optional query)),
  ({value}) -> Object.assign value...
```

The finishing touch is to use the `grammar` combinator to define our `parseURL` function. The grammar helper checks to make sure that there's no input remaining to parse, returning undefined otherwise.

```coffee
parseURL = grammar url
```

Let's try it out:

```coffee
assert.deepEqual (parseURL "https://foo/bar?baz=123"),
  protocol: "https"
  path: "/foo/bar"
  components: [ "foo", "bar" ]
  query:
    baz: "123"
```

## Installation

```
npm i -S panda-grammar
```

## Usage

```coffee
import {<whichever functions you need>} from "panda-grammar"
```

## Limitations

While parser combinators are a powerful way to write parsers, Panda Grammar is still under development. It's missing combinators for sets (order doesn't matter, each rule can only match once), look-aheads (important for certain edge cases, particular for recursive rules), memoization (allows parsing in polynomial time), and error handling support.

That said, recursive descent parsers have an undeserved reputation for being impractical. [A benchmark of JSON parsers][1] demonstrate that parser combinator libraries ([Parsimmon][2] outperform conventional parser generator libraries like Jison and ANTLR. In fact, performance is comparable to a hand-written parser. Of course, JSON is relatively simple to parse, but the lesson remains: don't write off recursive descent parsers!

[1]:https://sap.github.io/chevrotain/performance/
[2]:https://github.com/jneen/parsimmon

## API

### Terminology

A _product_ is an object with two properties:

  - `value`: what was parsed
  - `rest`: what remains to be parsed

A _consumer_ is a function that takes a string as input and returns a product or null, if nothing could be parsed.

A _combinator_ is a function that takes consumers as arguments and returns another consumer.

### `re`

Takes a regular expression and returns a consumer that matches that regular expression.

```coffee
protocol = re /^https?/
```

> **Warning**
>
> Typically, you want to anchor the expression at the beginning of the input with `^`. Unanchored regular expressions are useful for lookahead.
>

### `word`

Equivalent to `re /^\w+/`.

### `ws`

Equivalent to `re /^\s+/`.

### `string`

Takes a string and returns a consumer that matches it.

```coffee
root = string "//"
```

### `any`

Takes a list of consumers as arguments and returns a consumer that will return the product of the first match or null.

```
food = any (string "pizza"), (string "wings"), (string "burrito")
```

### `optional`

Takes a consumer and returns a consumer that returns its product if it matches. Otherwise returns a product where `rest` is the input string.

```coffee
url = all scheme, path, (optional query)
```

### `all`

Takes a list of consumers as arguments and returns a consumer that matches each in the order given.

```coffee
url = all scheme, path, (optional query)
```

### `many`

Takes a consumer and matches against it as many times as possible.

```coffee
program = many expressions
```

### `list`

Takes two consumers, a delimiter and an item, and attempts to match items separated by delimiters.

```coffee
query = all qdelim, list cdelim, assignment
```

### `between`

Takes a delimiter-pair string and a consumer, and attempts to match the consumer between the delimiters.

```coffee
between (string "{"), (string "}"), expression
```

### `forward`

Takes a function that returns a consumer and returns a second consumer that delegates to it. Useful for referencing consumers that haven't been defined yet but exist within the closure of the function.

```coffee
program = many (forward -> expressions)
```

### `rule`

Takes a consumer and a function that accepts a product and returns a value and returns a consumer that passes the given consumer's product to the given function. Useful for transforming the value of the product.

```coffee
assignment = rule all variable equals expression, (product) ->
  {value: [variable, expression]} = product
  variables[variable] = evaluate expression
```

### `tag`

A rule that replaces the parsed value with an object with a property of the given name whose value is the parsed value.

```coffee
rule "variable", word
```

### `merge`

Merges object values together.

### `join`

Joins an array of values (presumably strings) together.

### `grammar`

Takes a consumer and returns it's value if `rest` is empty.

```coffee
parseURL = grammar url
assert.deepEqual (parseURL "https://foo/bar?baz=123"),
  protocol: "https"
  path: "/foo/bar"
  components: [ "foo", "bar" ]
  query:
    baz: "123"
```
