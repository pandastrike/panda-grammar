import assert from "assert"
import {print, test} from "amen"

import {re, word, any, optional,
  list, all, many, rule, grammar} from "../src/index"

# For now, our test case is simple URL parser, which
# exercises all the functions except ws

separator = word "/"
symbol = re /^\w+/
qdelim = word "?"
cdelim = word "&"
equal = word "="
http = word "http"
https = word "https"
sdelim = word ":"
root = word "//"

scheme = rule (all (any http, https), sdelim),
  ({value: [protocol]}) -> {protocol}

path = rule (all root, list separator, symbol),
  ({value: [, components]}) -> {components, path: "/" + (components.join "/")}

assignment = rule (all symbol, equal, symbol),
  ({value: [key, , value]}) -> [key, value]

query = rule (all qdelim, list cdelim, assignment),
  ({value: [, pairs]}) ->
    query = {}
    query[k] = v for [k, v] in pairs
    {query}

url = rule (all scheme, path, (optional query)),
  ({value}) -> Object.assign value...

parseURL = grammar url


do ->
  print await test "URL Parser", [
    test "http://foo", ->
      assert.deepEqual
        protocol: "http"
        path: "/foo"
        components: [ "foo" ]
      ,
        parseURL "http://foo"

    test "https://foo/bar", ->
      assert.deepEqual
        protocol: "https"
        path: "/foo/bar"
        components: [ "foo", "bar" ]
      ,
        parseURL "https://foo/bar"

  ]
