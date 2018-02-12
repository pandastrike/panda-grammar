match = (re, s) -> s.match re

escape = (s) -> s.replace /[.*+?^${}()|[\]\\]/g, "\\$&"

re = (re) ->
  (s) ->
    if ($m = (match re, s))?
      [value] = $m
      rest = s[($m.index + value.length)..]
      {value, rest}

word = re /^\w+/

ws = re /^\s+/

string = (s) -> re ///^#{escape s}///

any = (px...) ->
  (s) ->
    for p in px
      $m = p s
      return $m if $m?
    return null

optional = (p) -> any p, ((s) -> rest: s)

all = (px...) ->
  (s) ->
    values = []
    for p in px
      $m = p s
      return null unless $m?
      {value, rest} = $m
      s = rest
      values.push value
    {value: values, rest: s}

many = (p) ->
  (s) ->
    r = []
    while (s.length > 0) && ($m = p s)?
      r.push $m.value
      s = $m.rest
    {value: r, rest: s} if r.length > 0

list = (d, p) ->
  (rest) ->
    _value = []
    while rest.length > 0
      if ($m = (p rest))?
        {value, rest} = $m
        _value.push value
        if ($m = d rest)?
          {rest} = $m
        else
          return {value: _value, rest}
      else
        return null

between = (open, close, p) ->
  rule (all open, p, close), ({value: [,v]}) -> v

forward = (fn) -> (s) -> fn()(s)

rule = (p, a) ->
  (s) ->
    $m = p s
    if $m?
      {value: a($m), rest: $m.rest}

tag = (name, p) -> rule p, ({value}) -> [name]: value

merge = (p) -> rule p, ({value}) -> Object.assign {}, value...

join = (p) -> rule p, ({value}) -> value.join ""

grammar = (r) ->
  (s) ->
    $m = r(s)
    if $m?
      {value, rest} = $m
      if rest == ""
        value

module.exports = {re, string, word, ws, any, optional, forward,
  all, many, list, between,
  rule, tag, merge, join,
  grammar}
