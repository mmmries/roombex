Roombex
=======

A functional library that translates from Elixir literals to the [Create 2 Open Interface](https://www.adafruit.com/datasheets/create_2_Open_Interface_Spec.pdf).

I'm using this with some [iRobot Create 2's](http://www.irobot.com/About-iRobot/STEM/Create-2.aspx) but it should work with any roomba after the 600 series.

I've started by supporting only a few of the basic commands and sensors, but there are a lot of open issues for supporting the rest of the interface. It would also be great to get feedback on whether the Genserver (`Roombex.DJ`) is useful to other people and/or how it might be made more useful.
