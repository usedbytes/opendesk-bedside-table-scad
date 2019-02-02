$fn = 128;

scl = 1;
width = 400 * scl;
depth = 500 * scl;
height = 600 * scl;
tongue_w = (width * 2 / 3);
material_thickness = 18 * scl;
shelf_h = (height * 2 / 3);
radius = 3.25 * scl;
drill_radius = 3.5 / 2;
slop = 0.18;

include <parts.scad>

foot();

/*
translate([0, 0, 0]) shelf();

translate([100, 0, 0]) left_side();

translate([300, 0, 0]) right_side();

translate([0, 120, 0]) top();

translate([100, 120, 0]) back();

translate([200, 120, 0]) front_left();

translate([250, 120, 0]) front_right();

translate([260, 120, 0]) foot();

translate([280, 120, 0]) foot();

translate([260, 140, 0]) foot();

translate([280, 140, 0]) foot();
*/

