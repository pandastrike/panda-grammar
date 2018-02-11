"use strict";

var _powerAssertRecorder = function () { function PowerAssertRecorder() { this.captured = []; } PowerAssertRecorder.prototype._capt = function _capt(value, espath) { this.captured.push({ value: value, espath: espath }); return value; }; PowerAssertRecorder.prototype._expr = function _expr(value, source) { var capturedValues = this.captured; this.captured = []; return { powerAssertContext: { value: value, events: capturedValues }, source: source }; }; return PowerAssertRecorder; }();

var _powerAssert = require("power-assert");

var _powerAssert2 = _interopRequireDefault(_powerAssert);

var _amen = require("amen");

var _index = require("../src/index");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _asyncToGenerator(fn) { return function () { var gen = fn.apply(this, arguments); return new Promise(function (resolve, reject) { function step(key, arg) { try { var info = gen[key](arg); var value = info.value; } catch (error) { reject(error); return; } if (info.done) { resolve(value); } else { return Promise.resolve(value).then(function (value) { step("next", value); }, function (err) { step("throw", err); }); } } return step("next"); }); }; }

var assignment, cdelim, equal, http, https, parseURL, path, qdelim, query, root, scheme, sdelim, separator, symbol, url;

// For now, our test case is simple URL parser, which
// exercises all the functions except ws
separator = (0, _index.word)("/");

symbol = (0, _index.re)(/^\w+/);

qdelim = (0, _index.word)("?");

cdelim = (0, _index.word)("&");

equal = (0, _index.word)("=");

http = (0, _index.word)("http");

https = (0, _index.word)("https");

sdelim = (0, _index.word)(":");

root = (0, _index.word)("//");

scheme = (0, _index.rule)((0, _index.all)((0, _index.any)(https, http), sdelim), function ({
  value: [protocol]
}) {
  return { protocol };
});

path = (0, _index.rule)((0, _index.all)(root, (0, _index.list)(separator, symbol)), function ({
  value: [, components]
}) {
  return {
    components,
    path: "/" + components.join("/")
  };
});

assignment = (0, _index.rule)((0, _index.all)(symbol, equal, symbol), function ({
  value: [key,, value]
}) {
  return [key, value];
});

query = (0, _index.rule)((0, _index.all)(qdelim, (0, _index.list)(cdelim, assignment)), function ({
  value: [, pairs]
}) {
  var i, k, len, v;
  query = {};
  for (i = 0, len = pairs.length; i < len; i++) {
    [k, v] = pairs[i];
    query[k] = v;
  }
  return { query };
});

url = (0, _index.rule)((0, _index.all)(scheme, path, (0, _index.optional)(query)), function ({ value }) {
  return Object.assign(...value);
});

parseURL = (0, _index.grammar)(url);

_asyncToGenerator(function* () {
  var testBadURL, testURL;
  testURL = function (url, expected) {
    return (0, _amen.test)(url, function () {
      var _rec = new _powerAssertRecorder(),
          _rec2 = new _powerAssertRecorder();

      return _powerAssert2.default.deepEqual(_rec._expr(_rec._capt(expected, "arguments/0"), {
        content: "assert.deepEqual(expected, parseURL(url))",
        filepath: "index.coffee",
        line: 45
      }), _rec2._expr(_rec2._capt(parseURL(_rec2._capt(url, "arguments/1/arguments/0")), "arguments/1"), {
        content: "assert.deepEqual(expected, parseURL(url))",
        filepath: "index.coffee",
        line: 45
      }));
    });
  };
  testBadURL = function (url, expected) {
    return (0, _amen.test)(`Bad URL: ${url}`, function () {
      var _rec3 = new _powerAssertRecorder(),
          _rec4 = new _powerAssertRecorder();

      return _powerAssert2.default.equal(_rec3._expr(_rec3._capt(void 0, "arguments/0"), {
        content: "assert.equal(void 0, parseURL(url))",
        filepath: "index.coffee",
        line: 49
      }), _rec4._expr(_rec4._capt(parseURL(_rec4._capt(url, "arguments/1/arguments/0")), "arguments/1"), {
        content: "assert.equal(void 0, parseURL(url))",
        filepath: "index.coffee",
        line: 49
      }));
    });
  };
  return (0, _amen.print)((yield (0, _amen.test)("URL Parser", [testURL("http://foo", {
    protocol: "http",
    path: "/foo",
    components: ["foo"]
  }), testURL("https://foo/bar", {
    protocol: "https",
    path: "/foo/bar",
    components: ["foo", "bar"]
  }), testURL("https://foo/bar?baz=123", {
    protocol: "https",
    path: "/foo/bar",
    components: ["foo", "bar"],
    query: {
      baz: "123"
    }
  }), testURL("https://foo/bar?baz=123&fizz=buzz", {
    protocol: "https",
    path: "/foo/bar",
    components: ["foo", "bar"],
    query: {
      baz: "123",
      fizz: "buzz"
    }
  }), testBadURL("htp://foo/bar?baz=123"), testBadURL("http:/foo/bar?baz=123"), testBadURL("http://foo:bar?baz=123"), testBadURL("http://foo/bar,baz=123"), testBadURL("http://foo/bar?baz=123?fizz=buzz"), testBadURL("http://foo/bar?baz=123&fizz-buzz"), testBadURL("http://foo/bar?baz=123&fizz/buzz")])));
})();