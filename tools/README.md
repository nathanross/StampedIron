


=== rcv

Probably the most esoteric part of this script is this function:

```
rcv() { local -n ret=$1; $2 ret "${@:3}"; }
```

From first glance this function exists as syntactic sugar for moving the return variable first that can be safely removed.

It is not merely that. It is a design pattern intended to pre-empt any mandelbugs from a particular bash local variable namespace papercut, as seen below:

```

format_headline() {
   local -n ret_headline=$1;
   local headline=$2;
   ret_headline=`echo $headline | tr '[:lower:]' '[:upper:]'   
}

rcv() { local -n ret=$1; $2 ret "${@:3}"; }

control() {
    local raw_headline='temperate weather'

    local new_headline
    format_headline new_headline raw_headline
    echo $new_headline
    # prints out 'TEMPERATE WEATHER'
}
    
# bug occurs regardless of whether return var
# previously declared locally or globally or
# not previously declared
bug() {
    local raw_headline='temperate weather'

    local headline
    format_headline headline raw_headline
    echo $headline
    # prints out nothing, var is undefined.
}

use_rcv_pattern(){
    local raw_headline='temperate weather'

    local headline
    rcv headline format_headline raw_headline
    echo $headline
    # prints out 'TEMPERATE WEATHER'
}


```