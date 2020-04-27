tscript
=======

tscript for t3kton script is a Turing complete scripting language that is designed
to be executed in such a way its state can be fully serialized and stored in the
database while when not being actively executed.  The script is initially
parsed and loaded by the Foreman module.  When a subcontractor instance for the
site the script belongs to polls contractor for more tasks, the script is executed
to the point where it requires external input/execution, at which point the data
required for the external action is sent to subcontracor, and the script's state
is stored in the database.  It will remain there until the results of that execution
are returned.  This way jobs for sites that do not have a subcontractor executing are
not taking processing resources, as well as not requiring any type of message bus.  When
the script completes, the attached Structure/Foundation/Dependancy is changed state, if the
script was a create or destroy script.  If a non-terminal error occurs, the operator
is given the ability to reset to retry.  There is also a rollback option for
when the external function supports rolling back (ie: cleaning up a half deployed
vm).  Some errors are terminal, at which point the execution job is put in the
aborted state.  The script can also be paused so it will not execute further.
NOTE: this does not affect any external operations that may be on going, the script
will not continue after the results are returned.

The functions available to the script depend on the plugins installed and the type
of Foundation in use.


built in functions
------------------

 * len( array ) - return length of the `array`
 * slice( array, start, end ) - returns a slice of the `array` from `start` to `end` (same start end rules as python)
 * pop( array, index=-1 ) - returns and removes index `index` from `array`
 * append( array, value ) - appends `value` to the end of the `array`
 * index( array, value ) - returns the index(offset) or `value` in `array`
 * pause( msg ) - pause the script with the message `msg`
 * error( msg ) - cause a non fatal error with the message `msg`
 * fatal_error( msg ) - cause a fatal error with the message `msg`
 * delay( seconds=0, minutes=0, hours=0 ) - delay execution of the script for the specified `seconds`, `minutes`, and/or `hours`


examples
--------

 * https://github.com/T3kton/resources/blob/master/os-bases/os_base/usr/lib/contractor/resources/base_os.toml#L12
 * https://github.com/T3kton/resources/blob/master/os-bases/os_base/usr/lib/contractor/resources/base_os.toml#L52
 * https://github.com/T3kton/resources/blob/master/vmware/vmware/usr/lib/contractor/resources/vmware.toml#L23
 * https://github.com/T3kton/contractor_plugins/blob/master/resources/vcenter/usr/lib/contractor/resources/vcenter.toml#L12
 * https://github.com/T3kton/contractor_plugins/blob/master/resources/vcenter/usr/lib/contractor/resources/vcenter.toml#L33
 * https://github.com/T3kton/contractor_plugins/blob/master/resources/docker/usr/lib/contractor/resources/docker.toml#L11
 * https://github.com/T3kton/contractor_plugins/blob/master/resources/docker/usr/lib/contractor/resources/docker.toml#L21
 * https://github.com/T3kton/contractor_plugins/blob/master/resources/azure/lib/contractor/resources/azure.toml#L13
 * https://github.com/T3kton/contractor_plugins/blob/master/resources/azure/lib/contractor/resources/azure.toml#L24
 * https://github.com/T3kton/contractor_plugins/blob/master/resources/virtualbox/usr/lib/contractor/resources/virtualbox.toml#L11
 * https://github.com/T3kton/contractor_plugins/blob/master/resources/virtualbox/usr/lib/contractor/resources/virtualbox.toml#L24
 * https://github.com/T3kton/contractor_plugins/blob/master/resources/manual/usr/lib/contractor/resources/manual.toml#L16

gramer
------

tscript uses the parsimonious parser, here is its grammar::

  script              = lines
  lines               = line*
  line                = ( expression / ws_s ) comment? nl_p
  expression          = ws_s ( jump_point / goto / function / ifelse / whiledo / block / assignment / infix / boolean / not_ / none / exists / other / array_map_item / array / map / variable / time / number_float / number_int / text ) ws_s
  value_expression    = ws_s ( function / assignment / infix / boolean / not_ / none / exists / array_map_item / array / map / variable / time / number_float / number_int / text ) ws_s
  constant_expression = ws_s ( boolean / none / time / number_float / number_int / text ) ws_s
  comment             = "#" ~"[^\\r\\n]*"
  jump_point          = ":" label
  goto                = "goto " label
  paramater_map       = ( ( ws_s label ws_s "=" value_expression "," )* ws_s label ws_s "=" value_expression )? ws_s
  const_paramater_map = ( ( ws_s label ws_s "=" constant_expression "," )* ws_s label ws_s "=" constant_expression )? ws_s
  block               = "begin(" const_paramater_map ")" lines ws_s "end"

  whiledo             = "while" value_expression "do" em_p expression
  other               = ( "continue" / "break" / "pass" )

  ifelse              = "if" value_expression "then" em_p expression ( em_s "elif" value_expression "then" em_p expression )* ( em_s "else" em_p expression )?

  not_                = ~"[Nn]ot" value_expression

  time                = ~"([0-9]{1,2}:){1,3}[0-9]{1,2}"
  number_float        = ~"[-+]?[0-9]+\.[0-9]+"
  number_int          = ~"[-+]?[0-9]+"
  text                = ( "'" ~"[^']*" "'" ) / ( '"' ~'[^"]*' '"' )
  boolean             = ~"[Tt]rue" / ~"[Ff]alse"
  none                = ~"[Nn]one"
  exists              = "exists(" ws_s ( array_map_item / variable ) ws_s ")"

  array               = "[" ( ( value_expression "," )* value_expression )? ws_s "]"
  map                 = "{" paramater_map "}"

  reserved            = ( "begin" / "end" / "while" / "do" / "goto" / "exists" / other ) !~"[a-zA-Z0-9_]"
  variable            = !reserved ( label "." )? label !"("

  function            = !reserved ( label "." )? label "(" paramater_map ")"
  array_map_item      = variable "[" value_expression "]"

  infix               = "(" value_expression ( "^" / "*" / "/" / "%" / "+" / "-" / "&" / "|" / "and"/ "or" / "==" / "!=" / "<=" / ">=" / ">" / "<" ) value_expression ")"

  assignment          = ( array_map_item / variable ) ws_s "=" value_expression

  label               = ~"[a-zA-Z][a-zA-Z0-9_]+"
  ws_o                = ~"[ \\x09]"
  ws_s                = ~"[ \\x09]*"
  ws_p                = ~"[ \\x09]+"
  nl_o                = ~"[\\x0d\\x0a]"
  nl_s                = ~"[\\x0d\\x0a]*"
  nl_p                = ~"[\\x0d\\x0a]+"
  em_o                = ~"[\\x0d\\x0a \\x09]"
  em_s                = ~"[\\x0d\\x0a \\x09]*"
  em_p                = ~"[\\x0d\\x0a \\x09]+"
