"use strict";

(function () {
  var all, any, between, escape, forward, grammar, join, list, many, match, merge, optional, re, rule, string, tag, word, ws;

  match = function (re, s) {
    return s.match(re);
  };

  escape = function (s) {
    return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  };

  re = function (re) {
    return function (s) {
      var $m, rest, value;
      if (($m = match(re, s)) != null) {
        [value] = $m;
        rest = s.slice($m.index + value.length);
        return { value, rest };
      }
    };
  };

  word = re(/^\w+/);

  ws = re(/^\s+/);

  string = function (s) {
    return re(RegExp(`^${escape(s)}`));
  };

  any = function (...px) {
    return function (s) {
      var $m, i, len, p;
      for (i = 0, len = px.length; i < len; i++) {
        p = px[i];
        $m = p(s);
        if ($m != null) {
          return $m;
        }
      }
      return null;
    };
  };

  optional = function (p) {
    return any(p, function (s) {
      return {
        rest: s
      };
    });
  };

  all = function (...px) {
    return function (s) {
      var $m, i, len, p, rest, value, values;
      values = [];
      for (i = 0, len = px.length; i < len; i++) {
        p = px[i];
        $m = p(s);
        if ($m == null) {
          return null;
        }
        ({ value, rest } = $m);
        s = rest;
        values.push(value);
      }
      return {
        value: values,
        rest: s
      };
    };
  };

  many = function (p) {
    return function (s) {
      var $m, r;
      r = [];
      while (s.length > 0 && ($m = p(s)) != null) {
        r.push($m.value);
        s = $m.rest;
      }
      if (r.length > 0) {
        return {
          value: r,
          rest: s
        };
      }
    };
  };

  list = function (d, p) {
    return function (rest) {
      var $m, _value, value;
      _value = [];
      while (rest.length > 0) {
        if (($m = p(rest)) != null) {
          ({ value, rest } = $m);
          _value.push(value);
          if (($m = d(rest)) != null) {
            ({ rest } = $m);
          } else {
            return {
              value: _value,
              rest
            };
          }
        } else {
          return null;
        }
      }
    };
  };

  between = function ([open, close], p) {
    return rule(all(string(open), p, string(close)), function ({
      value: [, v]
    }) {
      return v;
    });
  };

  forward = function (fn) {
    return function (s) {
      return fn()(s);
    };
  };

  rule = function (p, a) {
    return function (s) {
      var $m;
      $m = p(s);
      if ($m != null) {
        return {
          value: a($m),
          rest: $m.rest
        };
      }
    };
  };

  tag = function (name, p) {
    return rule(p, function ({ value }) {
      return {
        [name]: value
      };
    });
  };

  merge = function (p) {
    return rule(p, function ({ value }) {
      return Object.assign({}, ...value);
    });
  };

  join = function (p) {
    return rule(p, function ({ value }) {
      return value.join("");
    });
  };

  grammar = function (r) {
    return function (s) {
      var $m, rest, value;
      $m = r(s);
      if ($m != null) {
        ({ value, rest } = $m);
        if (rest === "") {
          return value;
        }
      }
    };
  };

  module.exports = { re, string, word, ws, any, optional, forward, all, many, list, between, rule, tag, merge, join, grammar };
}).call(undefined);