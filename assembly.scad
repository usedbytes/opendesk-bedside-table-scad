$fn = 128;

scl = 1;
width = 400 * scl;
depth = 500 * scl;
height = 600 * scl;
tongue_w = (width * 2 / 3);
material_thickness = 18 * scl;
shelf_h = (height * 2 / 3);
radius = 3.5 * scl;
drill_radius = 3.5 * scl;
slop = 0.03;

include <parts.scad>

translate([0, material_thickness, 0])
	rotate([90, 0, 0])
	linear_extrude(height = material_thickness) front_left();

translate([width, material_thickness, 0])
	rotate([90, 0, 0])
	linear_extrude(height = material_thickness) front_right();

translate([0, 0, shelf_h - material_thickness])
	rotate([0, 0, 0])
	linear_extrude(height = material_thickness) shelf();

translate([material_thickness, depth, 0])
	rotate([90, 0, -90])
	linear_extrude(height = material_thickness) left_side();

translate([width - material_thickness, depth, 0])
	rotate([90, 0, 90])
	linear_extrude(height = material_thickness) right_side();

translate([0, depth, 0])
	rotate([90, 0, 0])
	linear_extrude(height = material_thickness) back();

translate([0, 0, height - material_thickness])
	linear_extrude(height = material_thickness) top();

linear_extrude(height = material_thickness) foot();

translate([width, 0, 0])
	rotate([0, 0, 90])
	linear_extrude(height = material_thickness) foot();

translate([width, depth, 0])
	rotate([0, 0, 180])
	linear_extrude(height = material_thickness) foot();

translate([0, depth, 0])
	rotate([0, 0, 270])
	linear_extrude(height = material_thickness) foot();
