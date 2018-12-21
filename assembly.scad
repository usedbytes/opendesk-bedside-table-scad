$fn = 16;

scale_f = 3/ 18;
width = 440 * scale_f;
depth = 440 * scale_f;
height = 400 * scale_f;
tongue_w = 302 * scale_f;
material_thickness = 3;
shelf_h = 222 * scale_f;
radius = 3.5 * scale_f;
drill_radius = 2 * scale_f;

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
