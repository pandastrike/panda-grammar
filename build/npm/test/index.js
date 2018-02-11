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

scheme = (0, _index.rule)((0, _index.all)((0, _index.any)(http, https), sdelim), function ({
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
  return (0, _amen.print)((yield (0, _amen.test)("URL Parser", [(0, _amen.test)("http://foo", function () {
    var _rec = new _powerAssertRecorder(),
        _rec2 = new _powerAssertRecorder();

    return _powerAssert2.default.deepEqual(_rec._expr(_rec._capt({
      protocol: "http",
      path: "/foo",
      components: _rec._capt(["foo"], "arguments/0/properties/2/value")
    }, "arguments/0"), {
      content: "assert.deepEqual({ protocol: \"http\", path: \"/foo\", components: [\"foo\"] }, parseURL(\"http://foo\"))",
      filepath: "index.coffee",
      line: 44
    }), _rec2._expr(_rec2._capt(parseURL("http://foo"), "arguments/1"), {
      content: "assert.deepEqual({ protocol: \"http\", path: \"/foo\", components: [\"foo\"] }, parseURL(\"http://foo\"))",
      filepath: "index.coffee",
      line: 44
    }));
  }), (0, _amen.test)("https://foo/bar", function () {
    var _rec3 = new _powerAssertRecorder(),
        _rec4 = new _powerAssertRecorder();

    return _powerAssert2.default.deepEqual(_rec3._expr(_rec3._capt({
      protocol: "https",
      path: "/foo/bar",
      components: _rec3._capt(["foo", "bar"], "arguments/0/properties/2/value")
    }, "arguments/0"), {
      content: "assert.deepEqual({ protocol: \"https\", path: \"/foo/bar\", components: [\"foo\", \"bar\"] }, parseURL(\"https://foo/bar\"))",
      filepath: "index.coffee",
      line: 52
    }), _rec4._expr(_rec4._capt(parseURL("https://foo/bar"), "arguments/1"), {
      content: "assert.deepEqual({ protocol: \"https\", path: \"/foo/bar\", components: [\"foo\", \"bar\"] }, parseURL(\"https://foo/bar\"))",
      filepath: "index.coffee",
      line: 52
    }));
  })])));
})();