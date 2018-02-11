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

scheme = rule (all (any https, http), sdelim),
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

  testURL = (url, expected) ->
    test url, ->
      assert.deepEqual expected, parseURL url

  testBadURL = (url, expected) ->
    test "Bad URL: #{url}", ->
      assert.equal undefined, parseURL url

  print await test "URL Parser", [

    testURL "http://foo",
      protocol: "http"
      path: "/foo"
      components: [ "foo" ]

    testURL "https://foo/bar",
      protocol: "https"
      path: "/foo/bar"
      components: [ "foo", "bar" ]

    testURL "https://foo/bar?baz=123",
      protocol: "https"
      path: "/foo/bar"
      components: [ "foo", "bar" ]
      query: baz: "123"

    testURL "https://foo/bar?baz=123&fizz=buzz",
      protocol: "https"
      path: "/foo/bar"
      components: [ "foo", "bar" ]
      query: baz: "123", fizz: "buzz"

    testBadURL "htp://foo/bar?baz=123"
    testBadURL "http:/foo/bar?baz=123"
    testBadURL "http://foo:bar?baz=123"
    testBadURL "http://foo/bar,baz=123"
    testBadURL "http://foo/bar?baz=123?fizz=buzz"
    testBadURL "http://foo/bar?baz=123&fizz-buzz"
    testBadURL "http://foo/bar?baz=123&fizz/buzz"
  ]
