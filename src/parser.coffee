# tokenizers...

regexp = (re) ->
  (s) ->
    if (match = s.match(re))?
      [matched, value] = match
      rest = s[matched.length..]
      {value, rest}

word = (t) ->
  regexp(///^(#{t})///)

ws = regexp(/^(\s*)/)

any = (px...) ->
  (s) ->
    for p in px
      match = p(s)
      return match if match?
    return null

all = (px...) ->
  (s) ->
    values = []
    for p in px
      match = p(s)
      return null unless match?
      {value, rest} = match
      s = rest
      values.push value
    {value: values, rest: s}

optional = (p) ->
  (s) ->
    if (match = p(s))?
      match
    else
      {rest: s}

many = (p) ->
  (s) ->
    r = []
    while (s.length > 0) && (match = p(s))?
      r.push match.value
      s = match.rest
    {value: r, rest: s} if r.length > 0

rule = (p, a) ->
  (s) ->
    match = p(s)
    if match?
      {value: a(match), rest: match.rest}

grammar = (r) ->
  (s) ->
    match = r(s)
    if match?
      {value, rest} = match
      if rest == ""
        value

module.exports = {regexp, word, ws, any, all, many, optional, rule, grammar}
