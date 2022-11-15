## Dry Questions

### Question 1

**SnappingSheetController** is used. This controller allows the developer to change the position of the snap (with or without specified animation) or to stop the snapping. In additions, it provides the developer with an information about the position of the snap or its current state of an animation.

### Question 2

**SnappingPosition** holds the parameters of the position to snap into, a type of the animation (*snappingCurve*) and its duration (*snappingDuration*). A list of **SnappingPosition**s may be sent as a parameter (*snappingPositions*) to the constructor to define permanently positions and animations of the snap or used one-time via the controller.

### Question 3

**Inkwell** provides a fancy animation of the wave from the point of the click, but **GestureDetector** allows to recognize different types of touches (double touch, long touch etc).