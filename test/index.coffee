import assert from "assert"
import {print, test} from "amen"

import {re, string, any, optional,
  list, all, many, rule, grammar} from "../src/index"

# For now, our test case is simple URL parser, which
# exercises all the functions except ws

separator = string "/"
word = re /^\w+/
qdelim = string "?"
cdelim = string "&"
equal = string "="
protocol = re /^https?/
sdelim = string ":"
root = string "//"

scheme = rule (all protocol, sdelim),
  ({value: [protocol]}) -> {protocol}

path = rule (all root, list separator, word),
  ({value: [, components]}) -> {components, path: "/" + (components.join "/")}

assignment = rule (all word, equal, word),
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
