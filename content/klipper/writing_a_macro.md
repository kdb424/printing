+++
title = "Writing a macro"
weight = 1
sort_by = "weight"
+++

Klipper macros are useful for automating anything you want about your printer.
You can find the basics at
[https://www.klipper3d.org/Command_Templates.html](https://www.klipper3d.org/Command_Templates.html)
and klipper's built in gcodes at
[https://www.klipper3d.org/G-Codes.html](https://www.klipper3d.org/G-Codes.html)
Today we will build a very basic macro, and make it more complex to teach you
how to design a macro from scratch.

## Macro basics

The most basic micro can just be a single command if you want. An example of
that would look like this.

```jinja2
[gcode_macro HOME]
gcode:
    G28
```

That would let you type `HOME` and it will run G28 for you. Not very useful, but
that's the basics of how to write a macro. Onto something useful.

## Chamber warm macro

So let's say we want to warm up a chamber automatically. Let's start with a very
basic macro to warm up the bed.

```jinja2
[gcode_macro CHAMBER_WARMER]
gcode:
    SET_HEATER_TEMPERATURE HEATER=heater_bed TARGET=110
```

All that will do is set the bed to 110c, which will warm up the chamber, but how
do we know when it's done? Let's add more automation. Let's use a thermistor to
measure the temperature. In this example, we'll use the hotend thermistor so you
don't need an extra, but you can of course use a dedicated thermistor to measure
the chamber temperature.

```jinja2
[gcode_macro CHAMBER_WARMER]
gcode:
    # Warm up the bed
    SET_HEATER_TEMPERATURE HEATER=heater_bed TARGET=110

    # Wait for extruder to get to 40c
    TEMPERATURE_WAIT SENSOR="temperature_sensor chamber" MINIMUM=40
```

Now we have a macro that can warm up the bed, and it will wait until it's 40c.
But what if we don't always want 40c? We can do better. We need variables.
Variables are just named things that can change, or be "variable". These are
pretty simple in most cases. Let's look at how that works.

## Chamber warmer with variables

```jinja2
{% set chamberTemp = params.TEMPERATURE|default(40)|int %}
```

This makes a variable with the name chamberTemp. It sets it by default to 40,
and `int` means that it's an integer, which is just a fancy word for `a whole
number`, and not something like 1.68 which is not a whole number. The
`params.TEMPERATURE` is what it's called when you send it in as a parameter
calling the gcode. This works just like when you use `SET_HEATER_TEMPERATURE
HEATER=heater_bed` where `HEATER` is the parameter name. To use these variables
by name instead of the number, you would just type the name in `{}` so it knows
that's not normal text and it's meant to understand what it means.


With the below macro, we can call it like this if we want a temperature that's
not default `CHAMBER_WARMER TEMPERATURE=60` and that would set the chamber
temperature target to 60c instead of the default 40 if you just use
`CHAMBER_WARMER` without specifying a temperature as it will go to default.


```jinja2
[gcode_macro CHAMBER_WARMER]
gcode:
    # This creates a variable called ChamberTemp. If the macro is called without
    # setting a temperature, it will default to 40
    {% set chamberTemp = params.TEMPERATURE|default(40)|int %}
    
    # Warm up the bed
    SET_HEATER_TEMPERATURE HEATER=heater_bed TARGET=110

    # Wait for extruder to get to chamberTemp
    TEMPERATURE_WAIT SENSOR="temperature_sensor chamber" MINIMUM={chamberTemp}
```

Hopefully that's making sense with an example. Let's try to add a bit more. We
can move the fan over the bed and use the part cooling fan.

```jinja2
[gcode_macro CHAMBER_WARMER]
gcode:
    # This creates a variable called ChamberTemp. If the macro is called without
    # setting a temperature, it will default to 40
    {% set chamberTemp = params.TEMPERATURE|default(40)|int %}
    
    # Move the toolhead over the bed at X60 Y60 Z5
    G90 # Absolute position
    G1 X60 Y60 Z5
    
    # Max out part cooling to cycle chamber air
    M106 S255
    
    # Warm up the bed
    SET_HEATER_TEMPERATURE HEATER=heater_bed TARGET=110

    # Wait for extruder to get to chamberTemp
    TEMPERATURE_WAIT SENSOR="temperature_sensor chamber" MINIMUM={chamberTemp}
    
    # Turn the part cooling fan off again
    M106 S0
```

This works well for small 120mm printers, but we'd need to change it for every
printer. Maybe we also want to make the Z heigh easy to find and configure.
Let's move those to the top to make it easy, all thanks to variables!

```jinja2
[gcode_macro CHAMBER_WARMER]
gcode:
    # X Y and Z positions to park while warming
    {% set x = params.X|default(60)|int %}
    {% set y = params.Y|default(60)|int %}
    {% set z = params.Z|default(5)|int %}

    # This creates a variable called ChamberTemp. If the macro is called without
    # setting a temperature, it will default to 40
    {% set chamberTemp = params.TEMPERATURE|default(40)|int %}
    
    # Move the toolhead over the bed at X60 Y60 Z5
    G90 # Absolute position
    G1 X{x} Y{y} Z{z} # These are now variables
    
    # Max out part cooling to cycle chamber air
    M106 S255
    
    # Warm up the bed
    SET_HEATER_TEMPERATURE HEATER=heater_bed TARGET=110

    # Wait for extruder to get to chamberTemp
    TEMPERATURE_WAIT SENSOR="temperature_sensor chamber" MINIMUM={chamberTemp}
    
    # Turn the part cooling fan off again
    M106 S0
```

## Chamber warmer with better automation

That's pretty good. It does what we need, and is configurable. Let's add one
last touch so it will work with any printer size without having to mess with
configuration. This isn't needed, but makes it more easy to share without having
things to adjust. We are going to access the maximum x and y variables you
already set for your printer already in the config so it runs, and use those as
variables! Let's focus just on the changed line so we don't miss it.

```jinja2
G1 X{printer.toolhead.axis_maximum.x/2} Y{printer.toolhead.axis_maximum.y/2} Z{z}
```

This is using `printer.toolhead.axis_maximum` and we are dividing it by 2 to get
the center of the bed. If your max is 300, then it would be 150. We are doing
the same with Y. This will automagically adapt for any printer size so there's
less to configure. Let's wrap it all up together and get our macro.

```jinja2
[gcode_macro CHAMBER_WARMER]
gcode:
    # Z position to park while warming
    {% set z = params.Z|default(5)|int %}

    # This creates a variable called ChamberTemp. If the macro is called without
    # setting a temperature, it will default to 40
    {% set chamberTemp = params.TEMPERATURE|default(40)|int %}
    
    # Move the toolhead over the bed at X60 Y60 Z5
    G90 # Absolute position
    G1 X{printer.toolhead.axis_maximum.x/2} Y{printer.toolhead.axis_maximum.y/2} Z{z}
    
    # Max out part cooling to cycle chamber air
    M106 S255
    
    # Warm up the bed
    SET_HEATER_TEMPERATURE HEATER=heater_bed TARGET=110

    # Wait for extruder to get to chamberTemp
    TEMPERATURE_WAIT SENSOR="temperature_sensor chamber" MINIMUM={chamberTemp}
    
    # Turn the part cooling fan off again
    M106 S0
```


## Conclusion

There are lots of things you could do to make this more advanced. You could add
under bed fans, or chamber heaters, change LED colours, or anything else wrapped
into this. Macros are just simple instructions put together and followed by the
machine, so the possibilities are endless. Hopefully this inspires you to make
some macros to make your printing life better.
