# Parser-combinators work by leveraging the power of
# regular expressions.  We define "parts of speech" for a language [things like
# operator, symbol, string, etc.].  We create a parser for each one that examines
# the input looking for a particular regular expression.
#
# Now, these "parts of speech" parsers pretty low-level.  They are not useful by
# themselves, but we can daisy chain them together.  This is the combinator part
# of Sugar.  We create more parsers that can call the low level parsers, looking
# for patterns.  This way we turn "parts of speech" into "grammar".  We keep
# building higher and higher level parsers until we can call a single parser to
# kickstart a translation of the entire codebase.

# Parsers always follow the same basic form.  They either take an input, or are
# called with the "do" keyword.  Inside every parser, we call a generic function
# that is passed the original, unconsumed code as a string.  The parser performs
# some sort of test on the string and returns true or false.  In addition, the
# parser must also return any portion of the string that remains unconsumed.
# Other parsers will attempt to process this section.

# Below this code is the original, vanilla JavaScript parser we're still converting. 



# To make everything easier, we create a result object that holds the true-false
# match condition and remaining portion of the string to be processed.  Every
# time we return a parser result, we need to pass both to this object.

result = (match, rest) -> {match, rest}

#===============================================================================
# Regular Expressions - # This simple function is the root of Sugar.  This
# regular expression parser will be called by many low level parsers directly
# examining the code.
#===============================================================================
RegularExpression = (regex) ->

  (input) ->
    hit = input.match(regex)

    if hit
      # We found what we were looking for.  Fill out the "result" object.
      return result hit[0], input[ hit[0].length.. ]
    else
      # Didn't find what we were looking for.  Return empty object.
      return {}



#===============================================================================
# Blocks - These are the building blocks.  Each one will call upon the
# above "RegularExpression" function to match patterns in the input string.
#===============================================================================
WhiteSpace = do ->
  # This will search for any whitespace, plain and simple.

  search = RegularExpression ///^(  # Searches restricted to the begining of the input string
                            \s*     # zero or more whitespace character(s).
                            )///

  (input) ->

    {match, rest} = search (input)

    if match?
      # We found what we were looking for.  Fill out the "result" object.
      return result { type:"WhiteSpace", name: match}, rest
    else
      # Didn't find what we were looking for.  Return empty object.
      return {}



ArithmeticOperator = do ->
  # This will search for operators related to basic math.

  search = RegularExpression ///^(
            \+ | \- | \* | \/ | =  # single +, -, *, /, or = character.
                              )///

  (input) ->

    {match, rest} = search (input)

    if match?
      # We found what we were looking for.  Fill out the "result" object.
      return result {type:"Operator", operator: match}, rest
    else
      # Didn't find what we were looking for.  Return empty object.
      return {}



ComparisonOperator = do ->
  # This will search for operators that deal with comparisons.

  search = RegularExpression ///^(   # Searches restricted to the begining of the input string
          == | < | > | <= | >= | !=  # single ==, <, >, <=, >=, or != character(s).
                             )///

  (input) ->

    {match, rest} = search (input)

    if match?
      # We found what we were looking for.  Fill out the "result" object.
      return result {type:"Operator", operator: match}, rest
    else
      # Didn't find what we were looking for.  Return empty object.
      return {}


LogicOperator = do ->
  # This will search for operators that deal with logic.

  search = RegularExpression ///^(   # Searches restricted to the begining of the input string
                          or | and   # "or" or "and" operator.
                             )///

  (input) ->

    {match, rest} = search (input)

    if match?
      # We found what we were looking for.  Fill out the "result" object.
      return result {type:"Operator", operator: match}, rest
    else
      # Didn't find what we were looking for.  Return empty object.
      return {}


UnitaryOperator = do ->
  # This will search for operators that iterate variable value.

  search = RegularExpression ///^(   # Searches restricted to the begining of the input string
                        \+\+ | --    # ++ or -- iterative operator.
                             )///

  (input) ->

    {match, rest} = search (input)

    if match?
      # We found what we were looking for.  Fill out the "result" object.
      return result {type:"Operator", operator: match}, rest
    else
      # Didn't find what we were looking for.  Return empty object.
      return {}




Symbol = do ->
  # The catch-all.  This will search for any chunk of characters that are not whitespace, an
  # operator, a string, a reserved word, or whatever...

  search = RegularExpression ///^(   # Searches restricted to the begining of the input string
      [ \w \. \( \) \{ \} \[ \] ]+   # one or more of [A-Z], [a-z], [0-9], _, or ., (, ), {, }, [, ] character.
                            )///

  (input) ->

    {match, rest} = search (input)

    if match?
      # We found what we were looking for.  Fill out the "result" object.
      return result {type:"Symbol", name: match}, rest
    else
      # Didn't find what we were looking for.  Return empty object.
      return {}


String = do ->
  # This is slightly more advanced.  For strings, we need to detect closure, which
  # is a little annoying.  We'll need to start by figuring out if we're dealing
  # with double or single quote.  Afterward, we have to scoop up all the characters
  # inside the quote, ignoring their normal functions.  We continue until we find
  # another single/double quote to finish off this string.

  search = RegularExpression ///^(   # Searches restricted to the begining of the input string
                          ' | "      # one ' or " character.
                            )///

  (input) ->

    {match, rest} = search (input)

    if match?
      # We found the first quote.  We may continue
      temp = match     # Temporary string to hold opening character.

      if match == "\""
        search = RegularExpression ///^(   # Searches restricted to the begining of the input string
                      [\w \s \. \n \']*    # Zero or more of characters: [A-Z],[a-z],[0-9], _, ., newline, or '
                                )///

      else
        search = RegularExpression ///^(   # Searches restricted to the begining of the input string
                      [\w \s \. \n \"]*    # Zero or more of characters: [A-Z],[a-z],[0-9], _, ., newline, or "
                                )///

      # Continue searching.
      input = rest
      {match, rest} = search (input)

      if match?
        # We have the text of the string.  Append the start and end quotes.  Don't forget to
        # adjust the unconsumed string to pick up that dangling quotation mark.
        match = temp + match + temp
        rest = rest[1..]

        # Fill out the "result" object and return
        result {type: "String", value: match},  rest
      else
          # Didn't find what we were looking for.  Return empty object.
          # This would actually be bad.  Come put error handling here.
          return {}


    else
        # Didn't find what we were looking for.  Return empty object.
        return {}



#===============================================================================
# Rules - We're done making the building blocks.  Now we start chaining them
# together.  The following prototype "rule" does just that.  It take a list of
# building blocks and calls those functions in sequence, parsing the code.
#===============================================================================


PrototypeRule = (block_chain..., action) ->
  # This is the prototype rule.  Every rule will call this function, take a list of
  # building blocks (block_chain) and try to match a pattern.  This pattern is
  # higher level than before.  While we still pass these rules raw text, it
  # is really just passed to the lower-level parsers.  We are looking for patterns
  # with intelligence, beyond what a regular expression matcher could find by itself.

  (input) ->

    # This array holds the series of grouped characters from the original string.
    # They will be utilized by the "action" passed to this rule.
    tokens = []

    # Eack low-level block consumes part of the original string.  If the rule fails
    # we need to restore the string so we can try another rule.  Therefore, until the
    # rule completes successsfully, input must be copied into a temporary string
    # to be modified.  Once the rule passes, the changes are made permanent.
    string_buffer = input

    # Iterate through the commands in this rule.
    while block_chain.length > 0
      block = block_chain.shift()

      # See if we get a pattern match
      {match, rest} = block string_buffer

      if match?
        # We found what we were looking for.  Add this result to tokens.
        tokens.push match unless match is true

        # Continue to the next block.
        string_buffer = rest
      else
        # Didn't find what we were looking for.  Return a failure for this whole rule.  Restore input.
        return result false, input


    # If we have escaped the while loop, we have successfully parsed the original
    # string using the blocks stipulated.  It's time to utlize the specified action on tokens.
    action tokens


    # Return a success...  We must make the temporary changes stored in string_buffer permanent.
    return result true, rest



#===============================================================================
# Meta-Rule Modifiers = Now we're getting crazy.  Even though we can define
# rules, it's still not enough.  We need to be able to string rules
# together or provide option branching. These modifiers are the source of a
# parser-combinator's power.
#===============================================================================

# =======
# Atomic
# =======
# Meta_Until = (block_chain...) ->
#   # This meta-rule will try all the blocks passed to it until one returns true.
#   # Once that happens, it keeps that answer and returns true.
#
#   (input) ->
#     while input.length > 0 and chunk_chain.length > 0
#       block = block_chain.shift()
#
#       {match, rest} = block input
#
#       if match?
#         # We have a winner.  Return the result object.
#         return result match, rest
#       else
#         # We didn't find what we were looking for.  Keep going.
#         continue
#
#     # If we've made it out of the loop without a match, none of the blocks match.  Return failure.
#     return {}


Meta_Many = (block_chain...) ->
  # This meta-rule will try all the blocks passed to it until one returns false.
  # Once that happens, all previous results that have passed are returned.  It's for
  # when you need to try multiple blocks, but not all need to pass.

  collection = []

  (input) ->
    while input.length > 0 and chunk_chain.length > 0
      block = block_chain.shift()

      {match, rest} = block input

      if match?
        # Successful.  Collect the result. Update the input. Keep going.
        collection.push match
        input = rest
        continue
      else
        # Failure.  Return all successful results.
        return result collection, input

    # If we've made it out of the loop, all of the blocks match.  Return complete list.
    return result collection, rest



# =======
# Generator -
# Generators are operators that have a signature of F(R) => R, taking a given
# rule and returning another rule, such as ignore, which parses a given rule and
# throws away the result.

# Generator operators are converted (via Meta_Multi) into functions that
# can also take a list or array of rules and return an array of new rules as
# though the function had been called on each rule in turn (which is what actually happens).

# This converts generators into de facto vectors, allowing easier mixing with vectors.
# =======


Meta_Optional = (block) ->
  # This meta-rule will try the block passed to it. Even if it fails,
  # this funtion still returns true.  If it fails, it returns the input string.

  (input) ->
    while input.length > 0

      {match, rest} = block input

      if match?
        # Successful.  Return the result.
        return result match, rest
      else
        # Failure.  Return true and the input string.
        return result true, input



Meta_Not = (block) ->
  # This meta-rule will try the block passed to it. If it passes
  # the meta-rule returns false.  Bizzaro-World logic reigns.

  (input) ->
    while input.length > 0

      {match, rest} = block input

      if match?
        # Successful.  Which in Bizzaro-World means it fails.  Return failure.
        return {}
      else
        # Failure.  Which in Bizzaro-World means it succeeds.
        return result true, input


Meta_Ignore = (block) ->
  # This meta-rule will try the block passed to it. Regardless of whether the
  # block passes or not, the meta-rule passes "true".  The importatnt thing is
  # that this returns an updated string of unconsumed input, it just doesn't do
  # anything with it.

  (input) ->
    while input.length > 0

      {match, rest} = block input

      if match?
        # Successful.  Return true result with new string.
        return result true, rest
      else
        # Failure.  Return true result with old string.
        return result true, input


# Product ->  wft??

Meta_Cache = (block) ->
  # This meta-rule will try all the blocks passed to it. Regardless of whether the
  # block passes or not, the meta-rule stores the result.  This is important, because
  # if we are repeatedly attempting to parse a section with slightly different
  # rules, we don't have to re-parse sections that are the same.  This saves us
  # time because it reduces a convoluted caluclation into a lookup.

  (input) ->
    while input.length > 0

      if cache?
        {match, rest} = cache
      else
        {match, rest} = block input

      if match?
        # Successful.  Return result object.
        cache = {match, rest}
        return result match, rest
      else
        # Failure.  Cache fail. Return fail.
        cache = {false, input}
        return result false, input


# =======
# Vector -
# Vector operators are those that have a signature of F(R1,R2,...) => R, take a
# list of rules and returning a new rule, such as each.
# =======

###
Meta_Multi = (meta_rule, block_chain...) ->
  # This meta-rule will accept a meta-rule followed by a chain of blocks for processing.
  # This function processes them all, and will faithfully return the parsing outcome,
  # even if it's false.  This allows combination with vectors.

  (input) ->
    while input.length > 0 and block_chain.length > 0
      block = block_chain.shift()

      search = meta_rule block
###

Meta_Any = (block_chain...) ->
  # Logical OR.  This meta-rule will try all the blocks passed to it until one returns true.
  # Once that happens, it returns that result.

  (input) ->
    while input.length > 0 and chunk_chain.length > 0
      block = block_chain.shift()

      {match, rest} = block input

      if match?
        # Successful.  Return result object
        return result match, rest
      else
        # Failure.  Keep going.
        continue

    # If we've made it out of the loop, none of the blocks passed. Return failure.
    return result false, input


Meta_Each = (block_chain...) ->
  # Logical AND.   This meta-rule will try all the blocks passed to it until one returns false.
  # Once that happens, it returns failure.  If it makes it through the whole list,
  # it returns a list of results.

  collection = []

  (input) ->
    while input.length > 0 and chunk_chain.length > 0
      block = block_chain.shift()

      {match, rest} = block input

      if match?
        # Successful.  Collect results. Keep going.
        collection.push match
        continue
      else
        # Failure.  Return failure.
        return result false, input

    # If we've made it out of the loop, all of the blocks passed. Return results.
    return result collection, rest

Meta_All = (block_chain...) ->
  # This meta-rule is based off of Meta_Each. All blocks will be tried, but they are all
  # considered Meta_Optional.  Successes will take effect and failures will be ingored.

  Meta_Each Meta_Otional block_chain...


# =======
# Delimited
# =======
Sequence = (field, delimiter) ->
  # This meta-rule will chain together symbols that are delimited.  The most common example
  # will be symbols delimited by commas in a function statement.  The function accepts
  # (block, regular_expression) as its arguments.

  collection = []

  (input) ->
    while input.length > 0

      {match, rest} = field input

      if match?
        # We have a match for the field.  Check for delimiter.
        search = RegularExpression delimiter
        {match, rest} = search rest

        if match?
          # We found a delimiter.  Keep going.
          collection.push match
          input = rest
          continue
        else
          # There is no delimiter.  Exit loop.
          break

      else
        # We have not found what we are looking for.  Exit loop.
        break

    # We have exited the loop.  Return what we found and fail if we found nothing.
    if collection.length == 0
      return {}
    else
      return result collection, rest


# =========
# Composite - These are helpers that join other meta-rules together to leverage more power.
# =========
Meta_Between = (before, field, after) ->
  # This helper function checks that a field of interest is between two other blocks.
  # These blocks's presence is Meta_Optional.

  search = Meta_Each Meta_Optional(before), field, Meta_Optional(after)

  (input) ->
    while input.length > 0

      {match, rest} = search input

      if match?
        # Successful.  Return the result.
        return result match, rest
      else
        # Failure.  Return failure
        return {}



Meta_Set = (block_chain..) ->
  # This helper function allows you to search for a collection of blocks.  Every block
  # must be present, but their order is unimportant.  For example, if we have five blocks
  # to deal with, that's 120 combinations.  We would prefer to cover this with one rule.

  collection = []

  # Start by creating a copy of all the blocks.  This will be our working copy.
  working_copy = []
  working_copy.push(block) for block in block_chain

  (input) ->

    # First, check to make sure we are dealing with more than one block.  If there
    # is just one, we don't have to do that much work.
    if working_copy.length == 1

      {match, rest} = working_copy[0] input

      if match?
        # Success.  Return result object.
        return result match, rest
      else
        # Failure.  Return failure.
        return {}

    else
      finished = false

    # We must recursively search for matching blocks.  If we find a match, we delete
    # that block from block_chain, which means we have less to search for in the next iteration.

    while finished == false
      for i in [0..working_copy.length]

        {match, rest} = working_copy[i] input

        if match?
          # We found a block that matches.
          if working_copy.length == 1
            # Success.  We're done.  Return the result object.
            collection.push match
            return result collection, rest
          else
            # Delete this block from the chain and start over.
            working_copy.splice i, 1
            collection.push match
            input = rest
            break
        else
          # We didn't find what we were looking for.  Keep going.
          continue

      # If we have exited the for-loop, the input doesn't contain what's needed.  Return failure.
      return {}



# list....

# forward...


# =======
# Translation
# =======
# replace
# process
# min
  


#     var _ = $P.Operators = {
#         //
#         // Tokenizers
#         //
#         rtoken: function (r) { // regex token
#             return function (s) {
#                 var mx = s.match(r);
#                 if (mx) { 
#                     return ([ mx[0], s.substring(mx[0].length) ]); 
#                 } else { 
#                     throw new $P.Exception(s); 
#                 }
#             };
#         },
#         token: function (s) { // whitespace-eating token
#             return function (s) {
#                 return _.rtoken(new RegExp("^\s*" + s + "\s*"))(s);
#                 // Removed .strip()
#                 // return _.rtoken(new RegExp("^\s*" + s + "\s*"))(s).strip();
#             };
#         },
#         stoken: function (s) { // string token
#             return _.rtoken(new RegExp("^" + s)); 
#         },
# 
#         //
#         // Atomic Operators
#         // 
# 
#         until: function (p) {
#             return function (s) {
#                 var qx = [], rx = null;
#                 while (s.length) { 
#                     try { 
#                         rx = p.call(this, s); 
#                     } catch (e) { 
#                         qx.push(rx[0]); 
#                         s = rx[1]; 
#                         continue; 
#                     }
#                     break;
#                 }
#                 return [ qx, s ];
#             };
#         },
#         many: function (p) {
#             return function (s) {
#                 var rx = [], r = null; 
#                 while (s.length) { 
#                     try { 
#                         r = p.call(this, s); 
#                     } catch (e) { 
#                         return [ rx, s ]; 
#                     }
#                     rx.push(r[0]); 
#                     s = r[1];
#                 }
#                 return [ rx, s ];
#             };
#         },
# 
#         // generator operators -- see below
#         optional: function (p) {
#             return function (s) {
#                 var r = null; 
#                 try { 
#                     r = p.call(this, s); 
#                 } catch (e) { 
#                     return [ null, s ]; 
#                 }
#                 return [ r[0], r[1] ];
#             };
#         },
#         not: function (p) {
#             return function (s) {
#                 try { 
#                     p.call(this, s); 
#                 } catch (e) { 
#                     return [null, s]; 
#                 }
#                 throw new $P.Exception(s);
#             };
#         },
#         ignore: function (p) {
#             return p ? 
#             function (s) { 
#                 var r = null; 
#                 r = p.call(this, s); 
#                 return [null, r[1]]; 
#             } : null;
#         },
#         product: function () {
#             var px = arguments[0], 
#             qx = Array.prototype.slice.call(arguments, 1), rx = [];
#             for (var i = 0 ; i < px.length ; i++) {
#                 rx.push(_.each(px[i], qx));
#             }
#             return rx;
#         },
#         cache: function (rule) { 
#             var cache = {}, r = null; 
#             return function (s) {
#                 try { 
#                     r = cache[s] = (cache[s] || rule.call(this, s)); 
#                 } catch (e) { 
#                     r = cache[s] = e; 
#                 }
#                 if (r instanceof $P.Exception) { 
#                     throw r; 
#                 } else { 
#                     return r; 
#                 }
#             };
#         },
#           
#         // vector operators -- see below
#         any: function () {
#             var px = arguments;
#             return function (s) { 
#                 var r = null;
#                 for (var i = 0; i < px.length; i++) { 
#                     if (px[i] == null) { 
#                         continue; 
#                     }
#                     try { 
#                         r = (px[i].call(this, s)); 
#                     } catch (e) { 
#                         r = null; 
#                     }
#                     if (r) { 
#                         return r; 
#                     }
#                 } 
#                 throw new $P.Exception(s);
#             };
#         },
#         each: function () { 
#             var px = arguments;
#             return function (s) { 
#                 var rx = [], r = null;
#                 for (var i = 0; i < px.length ; i++) { 
#                     if (px[i] == null) { 
#                         continue; 
#                     }
#                     try { 
#                         r = (px[i].call(this, s)); 
#                     } catch (e) { 
#                         throw new $P.Exception(s); 
#                     }
#                     rx.push(r[0]); 
#                     s = r[1];
#                 }
#                 return [ rx, s]; 
#             };
#         },
#         all: function () { 
#             var px = arguments, _ = _; 
#             return _.each(_.optional(px)); 
#         },
# 
#         // delimited operators
#         sequence: function (px, d, c) {
#             d = d || _.rtoken(/^\s*/);  
#             c = c || null;
#             
#             if (px.length == 1) { 
#                 return px[0]; 
#             }
#             return function (s) {
#                 var r = null, q = null;
#                 var rx = []; 
#                 for (var i = 0; i < px.length ; i++) {
#                     try { 
#                         r = px[i].call(this, s); 
#                     } catch (e) { 
#                         break; 
#                     }
#                     rx.push(r[0]);
#                     try { 
#                         q = d.call(this, r[1]); 
#                     } catch (ex) { 
#                         q = null; 
#                         break; 
#                     }
#                     s = q[1];
#                 }
#                 if (!r) { 
#                     throw new $P.Exception(s); 
#                 }
#                 if (q) { 
#                     throw new $P.Exception(q[1]); 
#                 }
#                 if (c) {
#                     try { 
#                         r = c.call(this, r[1]);
#                     } catch (ey) { 
#                         throw new $P.Exception(r[1]); 
#                     }
#                 }
#                 return [ rx, (r?r[1]:s) ];
#             };
#         },
#                 
#             //
#             // Composite Operators
#             //
#                 
#         between: function (d1, p, d2) { 
#             d2 = d2 || d1; 
#             var _fn = _.each(_.ignore(d1), p, _.ignore(d2));
#             return function (s) { 
#                 var rx = _fn.call(this, s); 
#                 return [[rx[0][0], r[0][2]], rx[1]]; 
#             };
#         },
#         list: function (p, d, c) {
#             d = d || _.rtoken(/^\s*/);  
#             c = c || null;
#             return (p instanceof Array ?
#                 _.each(_.product(p.slice(0, -1), _.ignore(d)), p.slice(-1), _.ignore(c)) :
#                 _.each(_.many(_.each(p, _.ignore(d))), px, _.ignore(c)));
#         },
#         set: function (px, d, c) {
#             d = d || _.rtoken(/^\s*/); 
#             c = c || null;
#             return function (s) {
#                 // r is the current match, best the current 'best' match
#                 // which means it parsed the most amount of input
#                 var r = null, p = null, q = null, rx = null, best = [[], s], last = false;
# 
#                 // go through the rules in the given set
#                 for (var i = 0; i < px.length ; i++) {
# 
#                     // last is a flag indicating whether this must be the last element
#                     // if there is only 1 element, then it MUST be the last one
#                     q = null; 
#                     p = null; 
#                     r = null; 
#                     last = (px.length == 1); 
# 
#                     // first, we try simply to match the current pattern
#                     // if not, try the next pattern
#                     try { 
#                         r = px[i].call(this, s);
#                     } catch (e) { 
#                         continue; 
#                     }
# 
#                     // since we are matching against a set of elements, the first
#                     // thing to do is to add r[0] to matched elements
#                     rx = [[r[0]], r[1]];
# 
#                     // if we matched and there is still input to parse and 
#                     // we don't already know this is the last element,
#                     // we're going to next check for the delimiter ...
#                     // if there's none, or if there's no input left to parse
#                     // than this must be the last element after all ...
#                     if (r[1].length > 0 && ! last) {
#                         try { 
#                             q = d.call(this, r[1]); 
#                         } catch (ex) { 
#                             last = true; 
#                         }
#                     } else { 
#                         last = true; 
#                     }
# 
#                                     // if we parsed the delimiter and now there's no more input,
#                                     // that means we shouldn't have parsed the delimiter at all
#                                     // so don't update r and mark this as the last element ...
#                     if (!last && q[1].length === 0) { 
#                         last = true; 
#                     }
# 
# 
#                                     // so, if this isn't the last element, we're going to see if
#                                     // we can get any more matches from the remaining (unmatched)
#                                     // elements ...
#                     if (!last) {
# 
#                         // build a list of the remaining rules we can match against,
#                         // i.e., all but the one we just matched against
#                         var qx = []; 
#                         for (var j = 0; j < px.length ; j++) { 
#                             if (i != j) { 
#                                 qx.push(px[j]); 
#                             }
#                         }
# 
#                         // now invoke recursively set with the remaining input
#                         // note that we don't include the closing delimiter ...
#                         // we'll check for that ourselves at the end
#                         p = _.set(qx, d).call(this, q[1]);
# 
#                         // if we got a non-empty set as a result ...
#                         // (otw rx already contains everything we want to match)
#                         if (p[0].length > 0) {
#                             // update current result, which is stored in rx ...
#                             // basically, pick up the remaining text from p[1]
#                             // and concat the result from p[0] so that we don't
#                             // get endless nesting ...
#                             rx[0] = rx[0].concat(p[0]); 
#                             rx[1] = p[1]; 
#                         }
#                     }
# 
#                                     // at this point, rx either contains the last matched element
#                                     // or the entire matched set that starts with this element.
# 
#                                     // now we just check to see if this variation is better than
#                                     // our best so far, in terms of how much of the input is parsed
#                     if (rx[1].length < best[1].length) { 
#                         best = rx; 
#                     }
# 
#                                     // if we've parsed all the input, then we're finished
#                     if (best[1].length === 0) { 
#                         break; 
#                     }
#                 }
# 
#                             // so now we've either gone through all the patterns trying them
#                             // as the initial match; or we found one that parsed the entire
#                             // input string ...
# 
#                             // if best has no matches, just return empty set ...
#                 if (best[0].length === 0) { 
#                     return best; 
#                 }
# 
#                             // if a closing delimiter is provided, then we have to check it also
#                 if (c) {
#                     // we try this even if there is no remaining input because the pattern
#                     // may well be optional or match empty input ...
#                     try { 
#                         q = c.call(this, best[1]); 
#                     } catch (ey) { 
#                         throw new $P.Exception(best[1]); 
#                     }
# 
#                     // it parsed ... be sure to update the best match remaining input
#                     best[1] = q[1];
#                 }
# 
#                             // if we're here, either there was no closing delimiter or we parsed it
#                             // so now we have the best match; just return it!
#                 return best;
#             };
#         },
#         forward: function (gr, fname) {
#             return function (s) { 
#                 return gr[fname].call(this, s); 
#             };
#         },
# 
#         //
#         // Translation Operators
#         //
#         replace: function (rule, repl) {
#             return function (s) { 
#                 var r = rule.call(this, s); 
#                 return [repl, r[1]]; 
#             };
#         },
#         process: function (rule, fn) {
#             return function (s) {  
#                 var r = rule.call(this, s); 
#                 return [fn.call(this, r[0]), r[1]]; 
#             };
#         },
#         min: function (min, rule) {
#             return function (s) {
#                 var rx = rule.call(this, s); 
#                 if (rx[0].length < min) { 
#                     throw new $P.Exception(s); 
#                 }
#                 return rx;
#             };
#         }
#     };
#         
# 
#         // Generator Operators And Vector Operators
# 
#         // Generators are operators that have a signature of F(R) => R,
#         // taking a given rule and returning another rule, such as 
#         // ignore, which parses a given rule and throws away the result.
# 
#         // Vector operators are those that have a signature of F(R1,R2,...) => R,
#         // take a list of rules and returning a new rule, such as each.
# 
#         // Generator operators are converted (via the following _generator
#         // function) into functions that can also take a list or array of rules
#         // and return an array of new rules as though the function had been
#         // called on each rule in turn (which is what actually happens).
# 
#         // This allows generators to be used with vector operators more easily.
#         // Example:
#         // each(ignore(foo, bar)) instead of each(ignore(foo), ignore(bar))
# 
#         // This also turns generators into vector operators, which allows
#         // constructs like:
#         // not(cache(foo, bar))
#         
#     var _generator = function (op) {
#         return function () {
#             var args = null, rx = [];
#             if (arguments.length > 1) {
#                 args = Array.prototype.slice.call(arguments);
#             } else if (arguments[0] instanceof Array) {
#                 args = arguments[0];
#             }
#             if (args) { 
#                 for (var i = 0, px = args.shift() ; i < px.length ; i++) {
#                     args.unshift(px[i]); 
#                     rx.push(op.apply(null, args)); 
#                     args.shift();
#                     return rx;
#                 } 
#             } else { 
#                 return op.apply(null, arguments); 
#             }
#         };
#     };
#     
#     var gx = "optional not ignore cache".split(/\s/);
#     
#     for (var i = 0 ; i < gx.length ; i++) { 
#         _[gx[i]] = _generator(_[gx[i]]); 
#     }
# 
#     var _vector = function (op) {
#         return function () {
#             if (arguments[0] instanceof Array) { 
#                 return op.apply(null, arguments[0]); 
#             } else { 
#                 return op.apply(null, arguments); 
#             }
#         };
#     };
#     
#     var vx = "each any all".split(/\s/);
#     
#     for (var j = 0 ; j < vx.length ; j++) { 
#         _[vx[j]] = _vector(_[vx[j]]); 
#     }
#         
# }());
# 
# (function () {
#     var $D = Date, $P = $D.prototype, $C = $D.CultureInfo;
# 
#     var flattenAndCompact = function (ax) { 
#         var rx = []; 
#         for (var i = 0; i < ax.length; i++) {
#             if (ax[i] instanceof Array) {
#                 rx = rx.concat(flattenAndCompact(ax[i]));
#             } else { 
#                 if (ax[i]) { 
#                     rx.push(ax[i]); 
#                 }
#             }
#         }
#         return rx;
#     };
#     
#     $D.Grammar = {};
#         
#     $D.Translator = {
#         hour: function (s) { 
#             return function () { 
#                 this.hour = Number(s); 
#             }; 
#         },
#         minute: function (s) { 
#             return function () { 
#                 this.minute = Number(s); 
#             }; 
#         },
#         second: function (s) { 
#             return function () { 
#                 this.second = Number(s); 
#             }; 
#         },
#         meridian: function (s) { 
#             return function () { 
#                 this.meridian = s.slice(0, 1).toLowerCase(); 
#             }; 
#         },
#         timezone: function (s) {
#             return function () {
#                 var n = s.replace(/[^\d\+\-]/g, "");
#                 if (n.length) { 
#                     this.timezoneOffset = Number(n); 
#                 } else { 
#                     this.timezone = s.toLowerCase(); 
#                 }
#             };
#         },
#         day: function (x) { 
#             var s = x[0];
#             return function () { 
#                 this.day = Number(s.match(/\d+/)[0]); 
#             };
#         }, 
#         month: function (s) {
#             return function () {
#                 this.month = (s.length == 3) ? "jan feb mar apr may jun jul aug sep oct nov dec".indexOf(s)/4 : Number(s) - 1;
#             };
#         },
#         year: function (s) {
#             return function () {
#                 var n = Number(s);
#                 this.year = ((s.length > 2) ? n : 
#                     (n + (((n + 2000) < $C.twoDigitYearMax) ? 2000 : 1900))); 
#             };
#         },
#         rday: function (s) { 
#             return function () {
#                 switch (s) {
#                 case "yesterday": 
#                     this.days = -1;
#                     break;
#                 case "tomorrow":  
#                     this.days = 1;
#                     break;
#                 case "today": 
#                     this.days = 0;
#                     break;
#                 case "now": 
#                     this.days = 0; 
#                     this.now = true; 
#                     break;
#                 }
#             };
#         },
#         finishExact: function (x) {  
#             x = (x instanceof Array) ? x : [ x ]; 
# 
#             for (var i = 0 ; i < x.length ; i++) { 
#                 if (x[i]) { 
#                     x[i].call(this); 
#                 }
#             }
#             
#             var now = new Date();
#             
#             if ((this.hour || this.minute) && (!this.month && !this.year && !this.day)) {
#                 this.day = now.getDate();
#             }
# 
#             if (!this.year) {
#                 this.year = now.getFullYear();
#             }
#             
#             if (!this.month && this.month !== 0) {
#                 this.month = now.getMonth();
#             }
#             
#             if (!this.day) {
#                 this.day = 1;
#             }
#             
#             if (!this.hour) {
#                 this.hour = 0;
#             }
#             
#             if (!this.minute) {
#                 this.minute = 0;
#             }
# 
#             if (!this.second) {
#                 this.second = 0;
#             }
# 
#             if (this.meridian && this.hour) {
#                 if (this.meridian == "p" && this.hour < 12) {
#                     this.hour = this.hour + 12;
#                 } else if (this.meridian == "a" && this.hour == 12) {
#                     this.hour = 0;
#                 }
#             }
#             
#             if (this.day > $D.getDaysInMonth(this.year, this.month)) {
#                 throw new RangeError(this.day + " is not a valid value for days.");
#             }
# 
#             var r = new Date(this.year, this.month, this.day, this.hour, this.minute, this.second);
# 
#             if (this.timezone) { 
#                 r.set({ timezone: this.timezone }); 
#             } else if (this.timezoneOffset) { 
#                 r.set({ timezoneOffset: this.timezoneOffset }); 
#             }
#             
#             return r;
#         },                      
#         finish: function (x) {
#             x = (x instanceof Array) ? flattenAndCompact(x) : [ x ];
# 
#             if (x.length === 0) { 
#                 return null; 
#             }
# 
#             for (var i = 0 ; i < x.length ; i++) { 
#                 if (typeof x[i] == "function") {
#                     x[i].call(this); 
#                 }
#             }
#             
#             var today = $D.today();
#             
#             if (this.now && !this.unit && !this.operator) { 
#                 return new Date(); 
#             } else if (this.now) {
#                 today = new Date();
#             }
#             
#             var expression = !!(this.days && this.days !== null || this.orient || this.operator);
#             
#             var gap, mod, orient;
#             orient = ((this.orient == "past" || this.operator == "subtract") ? -1 : 1);
#             
#             if(!this.now && "hour minute second".indexOf(this.unit) != -1) {
#                 today.setTimeToNow();
#             }
# 
#             if (this.month || this.month === 0) {
#                 if ("year day hour minute second".indexOf(this.unit) != -1) {
#                     this.value = this.month + 1;
#                     this.month = null;
#                     expression = true;
#                 }
#             }
#             
#             if (!expression && this.weekday && !this.day && !this.days) {
#                 var temp = Date[this.weekday]();
#                 this.day = temp.getDate();
#                 if (!this.month) {
#                     this.month = temp.getMonth();
#                 }
#                 this.year = temp.getFullYear();
#             }
#             
#             if (expression && this.weekday && this.unit != "month") {
#                 this.unit = "day";
#                 gap = ($D.getDayNumberFromName(this.weekday) - today.getDay());
#                 mod = 7;
#                 this.days = gap ? ((gap + (orient * mod)) % mod) : (orient * mod);
#             }
#             
#             if (this.month && this.unit == "day" && this.operator) {
#                 this.value = (this.month + 1);
#                 this.month = null;
#             }
#        
#             if (this.value != null && this.month != null && this.year != null) {
#                 this.day = this.value * 1;
#             }
#      
#             if (this.month && !this.day && this.value) {
#                 today.set({ day: this.value * 1 });
#                 if (!expression) {
#                     this.day = this.value * 1;
#                 }
#             }
# 
#             if (!this.month && this.value && this.unit == "month" && !this.now) {
#                 this.month = this.value;
#                 expression = true;
#             }
# 
#             if (expression && (this.month || this.month === 0) && this.unit != "year") {
#                 this.unit = "month";
#                 gap = (this.month - today.getMonth());
#                 mod = 12;
#                 this.months = gap ? ((gap + (orient * mod)) % mod) : (orient * mod);
#                 this.month = null;
#             }
# 
#             if (!this.unit) { 
#                 this.unit = "day"; 
#             }
#             
#             if (!this.value && this.operator && this.operator !== null && this[this.unit + "s"] && this[this.unit + "s"] !== null) {
#                 this[this.unit + "s"] = this[this.unit + "s"] + ((this.operator == "add") ? 1 : -1) + (this.value||0) * orient;
#             } else if (this[this.unit + "s"] == null || this.operator != null) {
#                 if (!this.value) {
#                     this.value = 1;
#                 }
#                 this[this.unit + "s"] = this.value * orient;
#             }
# 
#             if (this.meridian && this.hour) {
#                 if (this.meridian == "p" && this.hour < 12) {
#                     this.hour = this.hour + 12;
#                 } else if (this.meridian == "a" && this.hour == 12) {
#                     this.hour = 0;
#                 }
#             }
#             
#             if (this.weekday && !this.day && !this.days) {
#                 var temp = Date[this.weekday]();
#                 this.day = temp.getDate();
#                 if (temp.getMonth() !== today.getMonth()) {
#                     this.month = temp.getMonth();
#                 }
#             }
#             
#             if ((this.month || this.month === 0) && !this.day) { 
#                 this.day = 1; 
#             }
#             
#             if (!this.orient && !this.operator && this.unit == "week" && this.value && !this.day && !this.month) {
#                 return Date.today().setWeek(this.value);
#             }
# 
#             if (expression && this.timezone && this.day && this.days) {
#                 this.day = this.days;
#             }
#             
#             return (expression) ? today.add(this) : today.set(this);
#         }
#     };
# 
#     var _ = $D.Parsing.Operators, g = $D.Grammar, t = $D.Translator, _fn;
# 
#     g.datePartDelimiter = _.rtoken(/^([\s\-\.\,\/\x27]+)/); 
#     g.timePartDelimiter = _.stoken(":");
#     g.whiteSpace = _.rtoken(/^\s*/);
#     g.generalDelimiter = _.rtoken(/^(([\s\,]|at|@|on)+)/);
#   
#     var _C = {};
#     g.ctoken = function (keys) {
#         var fn = _C[keys];
#         if (! fn) {
#             var c = $C.regexPatterns;
#             var kx = keys.split(/\s+/), px = []; 
#             for (var i = 0; i < kx.length ; i++) {
#                 px.push(_.replace(_.rtoken(c[kx[i]]), kx[i]));
#             }
#             fn = _C[keys] = _.any.apply(null, px);
#         }
#         return fn;
#     };
#     g.ctoken2 = function (key) { 
#         return _.rtoken($C.regexPatterns[key]);
#     };
# 
#     // hour, minute, second, meridian, timezone
#     g.h = _.cache(_.process(_.rtoken(/^(0[0-9]|1[0-2]|[1-9])/), t.hour));
#     g.hh = _.cache(_.process(_.rtoken(/^(0[0-9]|1[0-2])/), t.hour));
#     g.H = _.cache(_.process(_.rtoken(/^([0-1][0-9]|2[0-3]|[0-9])/), t.hour));
#     g.HH = _.cache(_.process(_.rtoken(/^([0-1][0-9]|2[0-3])/), t.hour));
#     g.m = _.cache(_.process(_.rtoken(/^([0-5][0-9]|[0-9])/), t.minute));
#     g.mm = _.cache(_.process(_.rtoken(/^[0-5][0-9]/), t.minute));
#     g.s = _.cache(_.process(_.rtoken(/^([0-5][0-9]|[0-9])/), t.second));
#     g.ss = _.cache(_.process(_.rtoken(/^[0-5][0-9]/), t.second));
#     g.hms = _.cache(_.sequence([g.H, g.m, g.s], g.timePartDelimiter));
#   
#     // _.min(1, _.set([ g.H, g.m, g.s ], g._t));
#     g.t = _.cache(_.process(g.ctoken2("shortMeridian"), t.meridian));
#     g.tt = _.cache(_.process(g.ctoken2("longMeridian"), t.meridian));
#     g.z = _.cache(_.process(_.rtoken(/^((\+|\-)\s*\d\d\d\d)|((\+|\-)\d\d\:?\d\d)/), t.timezone));
#     g.zz = _.cache(_.process(_.rtoken(/^((\+|\-)\s*\d\d\d\d)|((\+|\-)\d\d\:?\d\d)/), t.timezone));
#     
#     g.zzz = _.cache(_.process(g.ctoken2("timezone"), t.timezone));
#     g.timeSuffix = _.each(_.ignore(g.whiteSpace), _.set([ g.tt, g.zzz ]));
#     g.time = _.each(_.optional(_.ignore(_.stoken("T"))), g.hms, g.timeSuffix);
#           
#     // days, months, years
#     g.d = _.cache(_.process(_.each(_.rtoken(/^([0-2]\d|3[0-1]|\d)/), 
#         _.optional(g.ctoken2("ordinalSuffix"))), t.day));
#     g.dd = _.cache(_.process(_.each(_.rtoken(/^([0-2]\d|3[0-1])/), 
#         _.optional(g.ctoken2("ordinalSuffix"))), t.day));
#     g.ddd = g.dddd = _.cache(_.process(g.ctoken("sun mon tue wed thu fri sat"), 
#         function (s) { 
#             return function () { 
#                 this.weekday = s; 
#             }; 
#         }
#     ));
#     g.M = _.cache(_.process(_.rtoken(/^(1[0-2]|0\d|\d)/), t.month));
#     g.MM = _.cache(_.process(_.rtoken(/^(1[0-2]|0\d)/), t.month));
#     g.MMM = g.MMMM = _.cache(_.process(
#         g.ctoken("jan feb mar apr may jun jul aug sep oct nov dec"), t.month));
#     g.y = _.cache(_.process(_.rtoken(/^(\d\d?)/), t.year));
#     g.yy = _.cache(_.process(_.rtoken(/^(\d\d)/), t.year));
#     g.yyy = _.cache(_.process(_.rtoken(/^(\d\d?\d?\d?)/), t.year));
#     g.yyyy = _.cache(_.process(_.rtoken(/^(\d\d\d\d)/), t.year));
#         
#         // rolling these up into general purpose rules
#     _fn = function () { 
#         return _.each(_.any.apply(null, arguments), _.not(g.ctoken2("timeContext")));
#     };
#     
#     g.day = _fn(g.d, g.dd); 
#     g.month = _fn(g.M, g.MMM); 
#     g.year = _fn(g.yyyy, g.yy);
# 
#     // relative date / time expressions
#     g.orientation = _.process(g.ctoken("past future"), 
#         function (s) { 
#             return function () { 
#                 this.orient = s; 
#             }; 
#         }
#     );
#     g.operator = _.process(g.ctoken("add subtract"), 
#         function (s) { 
#             return function () { 
#                 this.operator = s; 
#             }; 
#         }
#     );  
#     g.rday = _.process(g.ctoken("yesterday tomorrow today now"), t.rday);
#     g.unit = _.process(g.ctoken("second minute hour day week month year"), 
#         function (s) { 
#             return function () { 
#                 this.unit = s; 
#             }; 
#         }
#     );
#     g.value = _.process(_.rtoken(/^\d\d?(st|nd|rd|th)?/), 
#         function (s) { 
#             return function () { 
#                 this.value = s.replace(/\D/g, ""); 
#             }; 
#         }
#     );
#     g.expression = _.set([ g.rday, g.operator, g.value, g.unit, g.orientation, g.ddd, g.MMM ]);
# 
#     // pre-loaded rules for different date part order preferences
#     _fn = function () { 
#         return  _.set(arguments, g.datePartDelimiter); 
#     };
#     g.mdy = _fn(g.ddd, g.month, g.day, g.year);
#     g.ymd = _fn(g.ddd, g.year, g.month, g.day);
#     g.dmy = _fn(g.ddd, g.day, g.month, g.year);
#     g.date = function (s) { 
#         return ((g[$C.dateElementOrder] || g.mdy).call(this, s));
#     }; 
# 
#     // parsing date format specifiers - ex: "h:m:s tt" 
#     // this little guy will generate a custom parser based
#     // on the format string, ex: g.format("h:m:s tt")
#     g.format = _.process(_.many(
#         _.any(
#         // translate format specifiers into grammar rules
#         _.process(
#         _.rtoken(/^(dd?d?d?|MM?M?M?|yy?y?y?|hh?|HH?|mm?|ss?|tt?|zz?z?)/), 
#         function (fmt) { 
#         if (g[fmt]) { 
#             return g[fmt]; 
#         } else { 
#             throw $D.Parsing.Exception(fmt); 
#         }
#     }
#     ),
#     // translate separator tokens into token rules
#     _.process(
#     _.rtoken(/^[^dMyhHmstz]+/), // all legal separators 
#         function (s) { 
#             return _.ignore(_.stoken(s)); 
#         } 
#     )
#     )), 
#         // construct the parser ...
#         function (rules) { 
#             return _.process(_.each.apply(null, rules), t.finishExact); 
#         }
#     );
#     
#     var _F = {
#                 //"M/d/yyyy": function (s) { 
#                 //      var m = s.match(/^([0-2]\d|3[0-1]|\d)\/(1[0-2]|0\d|\d)\/(\d\d\d\d)/);
#                 //      if (m!=null) { 
#                 //              var r =  [ t.month.call(this,m[1]), t.day.call(this,m[2]), t.year.call(this,m[3]) ];
#                 //              r = t.finishExact.call(this,r);
#                 //              return [ r, "" ];
#                 //      } else {
#                 //              throw new Date.Parsing.Exception(s);
#                 //      }
#                 //}
#                 //"M/d/yyyy": function (s) { return [ new Date(Date._parse(s)), ""]; }
#         }; 
#     var _get = function (f) { 
#         return _F[f] = (_F[f] || g.format(f)[0]);      
#     };
#   
#     g.formats = function (fx) {
#         if (fx instanceof Array) {
#             var rx = []; 
#             for (var i = 0 ; i < fx.length ; i++) {
#                 rx.push(_get(fx[i])); 
#             }
#             return _.any.apply(null, rx);
#         } else { 
#             return _get(fx); 
#         }
#     };
# 
#         // check for these formats first
#     g._formats = g.formats([
#         "\"yyyy-MM-ddTHH:mm:ssZ\"",
#         "yyyy-MM-ddTHH:mm:ssZ",
#         "yyyy-MM-ddTHH:mm:ssz",
#         "yyyy-MM-ddTHH:mm:ss",
#         "yyyy-MM-ddTHH:mmZ",
#         "yyyy-MM-ddTHH:mmz",
#         "yyyy-MM-ddTHH:mm",
#         "ddd, MMM dd, yyyy H:mm:ss tt",
#         "ddd MMM d yyyy HH:mm:ss zzz",
#         "MMddyyyy",
#         "ddMMyyyy",
#         "Mddyyyy",
#         "ddMyyyy",
#         "Mdyyyy",
#         "dMyyyy",
#         "yyyy",
#         "Mdyy",
#         "dMyy",
#         "d"
#     ]);
# 
#         // starting rule for general purpose grammar
#     g._start = _.process(_.set([ g.date, g.time, g.expression ], 
#         g.generalDelimiter, g.whiteSpace), t.finish);
#         
#         // real starting rule: tries selected formats first, 
#         // then general purpose rule
#     g.start = function (s) {
#         try { 
#             var r = g._formats.call({}, s); 
#             if (r[1].length === 0) {
#                 return r; 
#             }
#         } catch (e) {}
#         return g._start.call({}, s);
#     };
