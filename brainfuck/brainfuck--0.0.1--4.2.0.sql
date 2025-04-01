DROP FUNCTION IF EXISTS @extschema@.brainfuck(code text, input text);
CREATE OR REPLACE FUNCTION @extschema@.brainfuck(code text, input text)
 RETURNS text
 LANGUAGE plv8
 IMMUTABLE STRICT
AS $function$
  var tokens = {
    ".": "output += String.fromCharCode(tape[pointer]);",
    ",": "tape[pointer] = input.length ? input.shift().charCodeAt(0) : 0;",
    "<": "pointer = pointer ? pointer - 1 : 255;",
    ">": "pointer = (pointer + 1) % 256;",
    "-": "tape[pointer] = tape[pointer] ? tape[pointer] - 1 : 255;",
    "+": "tape[pointer] = tape[pointer] ? (tape[pointer] + 1) % 256 : 1;",
    "[": "while(tape[pointer]){",
    "]": "}"
  };
  if (!input) {
    input = "";
  }
  var inner_code = "";
  for (var i=0; i<code.length; i++){
    if (tokens[code[i]]) {
      inner_code += tokens[code[i]] + "\n";
    }
  }
  var js_code = "input = Array.from(input + '');\nvar output = '';\nvar tape = [];\nvar pointer = 0;\n" + 
    inner_code + "return output;";
  var fn = new Function("input", js_code);
  return fn(input.split(','));
$function$;
