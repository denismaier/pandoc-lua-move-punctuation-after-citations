local function ends_with_punctuation(str)
  return str:sub(-1) == '.'
    or str:sub(-1) == ','
    or str:sub(-1) == ';'
    or str:sub(-1) == '!'
    or str:sub(-1) == '?'
end

local function is_punct_last_in_quote (doublequote)
  return doublequote and doublequote.t == 'Quoted' and doublequote.quotetype == 'DoubleQuote'
    and doublequote.content[#doublequote.content].t == 'Str'
    and ends_with_punctuation(doublequote.content[#doublequote.content].text)
end

local function is_quote_space_before_normal_citation (doublequote, spc, cite)
  return 
  doublequote and doublequote.t == 'Quoted' and doublequote.quotetype == 'DoubleQuote'
  and spc and spc.t == 'Space'
  and cite and cite.t == 'Cite'
  -- citationMode must be NormalCitation
  and cite.citations[1].mode == 'NormalCitation'
end

local function is_quote_punctuation_space_before_normal_citation (doublequote, punct, spc, cite)
    return 
      doublequote and doublequote.t == 'Quoted' and doublequote.quotetype == 'DoubleQuote'
      and punct and punct.t == 'Str' and (punct.text == '.'  or punct.text == ',' or punct.text == ';')
      and spc and spc.t == 'Space'
      and cite and cite.t == 'Cite'
      -- citationMode must be NormalCitation
      and cite.citations[1].mode == 'NormalCitation'
end

  
function Inlines (inlines)
  -- both loops go from end to start to avoid problems with shifting indices.

  -- doublequote punct space citation => doublequote space citation punct
  for i = #inlines-3, 1, -1 do
      if is_quote_punctuation_space_before_normal_citation(inlines[i], inlines[i+1], inlines[i+2], inlines[i+3]) then
        -- save current inline elements
        local doublequote = inlines[i]
        local punctuation = inlines[i+1]
        local space = inlines[i+2] 
        local cite = inlines[i+3]
        -- swap inline element order
        inlines[i] = doublequote
        inlines[i+1] = space
        inlines[i+2] = cite
        inlines[i+3] = punctuation
      end
    end

  -- punct doublequote space citation => doublequote space citation punct
  for i = #inlines-2, 1, -1 do
    if is_punct_last_in_quote(inlines[i]) and is_quote_space_before_normal_citation (inlines[i], inlines[i+1], inlines[i+2]) then
      -- get punctuation
      punctuation = pandoc.Str(inlines[i].content[#inlines[i].content].text:sub(-1))
      -- remove punctuation from quotation
      inlines[i].content[#inlines[i].content].text = inlines[i].content[#inlines[i].content].text:sub(1,-2)
      -- reinsert punctuation after cite element
      inlines:insert(i+3, punctuation)
    end
  end
  return inlines
end