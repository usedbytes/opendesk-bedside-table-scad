$fn = 16;
width = 440;
depth = 440;
height = 400;
tongue_w = 302;
material_thickness = 18;
shelf_h = 222;
radius = 3.5;
drill_radius = 2;

RELIEF_NONE = 0;
RELIEF_LEAD_IN = 1;
RELIEF_LEAD_OUT = 2;

function circle_points(centre = [0, 0], radius = 5) =
	arc_points(centre = centre, start = 0, angle = 360, radius = radius);

function arc_points(centre = [0, 0], start = 0, angle = 180, radius = 5) =
	let(
		points = [
			for (theta = [ start : sign(angle) * 360 / $fn : start + angle])
				centre + [radius * cos(theta), radius * sin(theta)],
		]
	) points;

module arc(centre = [0, 0], start = 0, angle = 180, radius = 5) {
	polygon(arc_points(centre, start, angle, radius));
}

function relief_points(corner = [0, 0], radius = 5) =
	let(
		line = [ [corner[0] - radius , corner[1]], corner ],

		notch = arc_points(centre = line[0] - [0, radius],
				start = 270, angle = -180, radius = radius),

		fillet = arc_points(centre = line[0] - [0, 3 * radius],
				start = 0, angle = 90, radius = radius)
	) concat(fillet, notch, line);

module relief(corner = [0, 0], radius = 5) {
	polygon(relief_points(corner = corner, radius = radius));
}

function relief_lead_in_points(corner = [[0, -30], [0, 0], [30, 0]], radius = 5) =
	let(
		rot_mat = corner[0][0] == corner[1][0] ? [[1, 0],[0, 1]] : [[0, 1], [1, 0]],

		before = rot_mat * corner[0],
		at = rot_mat * corner[1],
		after = rot_mat * corner[2],

		mirror_x = at[0] < after[0] ? 1 : -1,
		mirror_y = at[1] > before[1] ? 1 : -1,
		mirror_mat = [ [mirror_x, 0], [0, mirror_y] ],

		canonical_points = relief_points([0, 0], radius = radius),

		points = [ for ( i = [0:len(canonical_points) - 1] )
			(rot_mat * mirror_mat * canonical_points[i]) + corner[1]
		]
	) points;

module relief_lead_in(corner = [[0, -30], [0, 0], [30, 0]], radius = 5) {
	polygon(relief_lead_in_points(corner = corner, radius = radius));
}

function reverse (points, i = 0) =
    len(points) > i ? concat(reverse(points, i + 1), [points[i]]) : [];

function relief_lead_out_points(corner = [[0, -30], [0, 0], [30, 0]], radius = 5) =
	reverse(relief_lead_in_points(corner = reverse(corner), radius = radius));

module relief_lead_out(corner = [[0, -30], [0, 0], [30, 0]], radius = 5) {
	polygon(relief_lead_out_points(corner = corner, radius = radius));
}

function corner_points(points, i) = let(last = len(points) - 1)
	i == 0 ? [
			[ points[last][0], points[last][1] ],
			[ points[i][0], points[i][1] ],
			[ points[i + 1][0], points[i + 1][1] ]
		]
	: i == last ? [
			[ points[i - 1][0], points[i - 1][1] ],
			[ points[i][0], points[i][1] ],
			[ points[0][0], points[0][1] ]
		]
	: [
			[ points[i - 1][0], points[i - 1][1] ],
			[ points[i][0], points[i][1] ],
			[ points[i + 1][0], points[i + 1][1] ]
		];


function generate_corner(points, i) = let(relief = points[i][2])
	relief == RELIEF_NONE ?
		[ [points[i][0], points[i][1]] ]
	: relief == RELIEF_LEAD_IN ?
		relief_lead_in_points(corner_points(points, i), radius = radius)
	: // relief == RELIEF_LEAD_OUT
		relief_lead_out_points(corner_points(points, i), radius = radius);

function generate_outline(points, acc_=[], i = 0) =
	i == len(points) ? acc_ :
		generate_outline(points,
			acc_ = concat(acc_, generate_corner(points, i)), i = i + 1);

function generate_drills(holes, radius = drill_radius) =
	[ for (hole = holes) circle_points(centre = hole, radius = drill_radius) ];

function generate_path(points, start = 0) = [for (i = [start : start + len(points) - 1]) i ];

function generate_paths(paths, acc_ = [], start = 0) = let(i = len(acc_))
	i == len(paths) ? acc_ :
		generate_paths(
			paths = paths,
			acc_ = concat(acc_, [generate_path(paths[i], start = start)]),
			start = start + len(paths[i]));

// From the wiki - https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/List_Comprehensions
// input : nested list
// output : list with the outer level nesting removed
function flatten(l) = [ for (a = l) for (b = a) b ] ;

module draw_part(outline, holes = []) {
	outline = generate_outline(outline);

	points = concat(outline, flatten(holes));
	paths = generate_paths(concat([outline], holes));

	polygon(points = points, paths = paths);
}

module top(w = width, d = depth, material_thickness = material_thickness) {
	// Anticlockwise
	outline = [
		// Bottom
		[0, 0, RELIEF_NONE],

		// Right
		[w, 0, RELIEF_NONE],
		[w, d / 3, RELIEF_NONE],
		[w - material_thickness, d / 3, RELIEF_LEAD_OUT],
		[w - material_thickness, 2 * d / 3, RELIEF_LEAD_IN],
		[w, 2 * d / 3, RELIEF_NONE],

		// Top
		[w, d, RELIEF_NONE],
		[2 * w / 3, d, RELIEF_NONE],
		[2 * w / 3, d - material_thickness, RELIEF_LEAD_OUT],
		[w / 3, d - material_thickness, RELIEF_LEAD_IN],
		[w / 3, d, RELIEF_NONE],

		// Left
		[0, d, RELIEF_NONE],
		[0, 2 * d / 3, RELIEF_NONE],
		[0 + material_thickness, 2 * d / 3, RELIEF_LEAD_OUT],
		[0 + material_thickness, d / 3, RELIEF_LEAD_IN],
		[0, d / 3, RELIEF_NONE],
	];
	holes = [
		[w - material_thickness / 2, d / 6],
		[w - material_thickness / 2, 5 * d / 6],
		[material_thickness / 2, d / 6],
		[material_thickness / 2, 5 * d / 6],
		[w - w / 6, d - material_thickness / 2],
		[0 + w / 6, d - material_thickness / 2],
	];

	draw_part(outline, holes = generate_drills(holes));
};

module shelf(w = width, d = depth, material_thickness = material_thickness) {
	x = (w - tongue_w) / 2;
	y = (d - tongue_w) / 2;

	outline = [
		[material_thickness, material_thickness, RELIEF_NONE],
		[x, material_thickness, RELIEF_LEAD_IN],
		[x, 0, RELIEF_NONE],
		[w - x, 0, RELIEF_NONE],
		[w - x, material_thickness, RELIEF_LEAD_OUT],

		[w - material_thickness, material_thickness, RELIEF_NONE],
		[w - material_thickness, y, RELIEF_LEAD_IN],
		[w, y, RELIEF_NONE],
		[w, d - y, RELIEF_NONE],
		[w - material_thickness, d - y, RELIEF_LEAD_OUT],

		[w - material_thickness, d - material_thickness, RELIEF_NONE],
		[w - x, d - material_thickness, RELIEF_LEAD_IN],
		[w - x, d, RELIEF_NONE],
		[x, d, RELIEF_NONE],
		[x, d - material_thickness, RELIEF_LEAD_OUT],

		[material_thickness, d - material_thickness, RELIEF_NONE],
		[material_thickness, d - y, RELIEF_LEAD_IN],
		[0, d - y, RELIEF_NONE],
		[0, y, RELIEF_NONE],
		[material_thickness, y, RELIEF_LEAD_OUT],
	];

	draw_part(outline);
}

module side(w = width, d = depth, h = height, material_thickness = material_thickness) {
	x = (w - tongue_w) / 2;

	outline = [
		// Rear foot
		[0, 0, RELIEF_NONE],
		[2 * material_thickness, 0, RELIEF_NONE],
		[2 * material_thickness, material_thickness, RELIEF_LEAD_OUT],

		// Rear slope
		[4 * material_thickness, material_thickness, RELIEF_NONE],
		[4 * material_thickness + (w / 10), shelf_h - material_thickness, RELIEF_NONE],

		// Shelf cutout
		[x, shelf_h - material_thickness, RELIEF_LEAD_IN],
		[x, shelf_h, RELIEF_LEAD_OUT],
		[w - x, shelf_h, RELIEF_LEAD_IN],
		[w - x, shelf_h - material_thickness, RELIEF_LEAD_OUT],

		// Front slope
		[w - (4 * material_thickness + (w / 10)), shelf_h - material_thickness, RELIEF_NONE],
		[w - 4 * material_thickness, material_thickness, RELIEF_NONE],

		// Front foot
		[w - 2 * material_thickness, material_thickness, RELIEF_LEAD_IN],
		[w - 2 * material_thickness, 0, RELIEF_NONE],

		// Front Side
		[w - material_thickness, 0, RELIEF_NONE],
		[w - material_thickness, shelf_h / 2, RELIEF_LEAD_IN],
		[w, shelf_h / 2, RELIEF_NONE],

		// Top
		[w, h - material_thickness, RELIEF_NONE],
		[2 * w / 3, h - material_thickness, RELIEF_LEAD_IN],
		[2 * w / 3, h, RELIEF_NONE],
		[w / 3, h, RELIEF_NONE],
		[w / 3, h - material_thickness, RELIEF_LEAD_OUT],

		// Back
		[0, h - material_thickness, RELIEF_NONE],
		[0, h - (h - shelf_h) / 2, RELIEF_NONE],
		[material_thickness, h - (h - shelf_h) / 2, RELIEF_LEAD_OUT],

		[material_thickness, shelf_h / 2, RELIEF_LEAD_IN],
		[0, shelf_h / 2, RELIEF_NONE],
	];

	draw_part(outline);
}

module left_side(w = width, d = depth, h = height, material_thickness = material_thickness) {
	side(w = w, d = d, h = h, material_thickness = material_thickness);
}

module right_side(w = width, d = depth, h = height, material_thickness = material_thickness) {
	translate([w, 0, 0]) mirror([1, 0, 0]) side(w = w, d = d, h = h, material_thickness = material_thickness);
}

module back(w = width, d = depth, h = height, material_thickness = material_thickness) {
	x = (w - tongue_w) / 2;

	outline = [
		// Foot
		[material_thickness, 0, RELIEF_NONE],
		[2 * material_thickness, 0, RELIEF_NONE],
		[2 * material_thickness, material_thickness, RELIEF_LEAD_OUT],

		// Slope
		[4 * material_thickness, material_thickness, RELIEF_NONE],
		[4 * material_thickness + (w / 10), shelf_h - material_thickness, RELIEF_NONE],

		// Shelf
		[x, shelf_h - material_thickness, RELIEF_LEAD_IN],
		[x, shelf_h, RELIEF_LEAD_OUT],
		[w - x, shelf_h, RELIEF_LEAD_IN],
		[w - x, shelf_h - material_thickness, RELIEF_LEAD_OUT],

		// Slope
		[w - (4 * material_thickness + (w / 10)), shelf_h - material_thickness, RELIEF_NONE],
		[w - 4 * material_thickness, material_thickness, RELIEF_NONE],
		[w - 2 * material_thickness, material_thickness, RELIEF_LEAD_IN],
		[w - 2 * material_thickness, 0, RELIEF_NONE],

		// Side
		[w - material_thickness, 0, RELIEF_NONE],
		[w - material_thickness, shelf_h / 2, RELIEF_LEAD_IN],
		[w, shelf_h / 2, RELIEF_NONE],
		[w, h - (h - shelf_h) / 2, RELIEF_NONE],
		[w - material_thickness, h - (h - shelf_h) / 2, RELIEF_LEAD_OUT],

		// Top
		[w - material_thickness, h - material_thickness, RELIEF_NONE],
		[2 * w / 3, h - material_thickness, RELIEF_LEAD_IN],
		[2 * w / 3, h, RELIEF_NONE],
		[w / 3, h, RELIEF_NONE],
		[w / 3, h - material_thickness, RELIEF_LEAD_OUT],

		// Side
		[material_thickness, h - material_thickness, RELIEF_NONE],
		[material_thickness, h - (h - shelf_h) / 2, RELIEF_LEAD_IN],
		[0, h - (h - shelf_h) / 2, RELIEF_NONE],
		[0, shelf_h / 2, RELIEF_NONE],
		[material_thickness, shelf_h / 2, RELIEF_LEAD_OUT],
		[material_thickness, 0, RELIEF_NONE],

	];

	draw_part(outline);
}

module front(w = width, d = depth, h = height, material_thickness = material_thickness) {
	x = (w - tongue_w) / 2;

	outline = [
		[0, 0, RELIEF_NONE],
		[2 * material_thickness, 0, RELIEF_NONE],
		[2 * material_thickness, material_thickness, RELIEF_LEAD_OUT],
		[4 * material_thickness, material_thickness, RELIEF_NONE],
		[4 * material_thickness + (w / 10), shelf_h - material_thickness, RELIEF_NONE],
		[x, shelf_h - material_thickness, RELIEF_LEAD_IN],
		[x, shelf_h, RELIEF_NONE],
		[material_thickness, shelf_h, RELIEF_NONE],
		[material_thickness, shelf_h / 2, RELIEF_LEAD_IN],
		[0, shelf_h / 2, RELIEF_NONE],
	];

	draw_part(outline);

}

module front_left(w = width, d = depth, h = height, material_thickness = material_thickness) {
	front(w = w, d = d, h = h, material_thickness = material_thickness);
}

module front_right(w = width, d = depth, h = height, material_thickness = material_thickness) {
	translate([4 * material_thickness + (w / 10), 0, 0]) mirror([1, 0, 0]) front(w = w, d = d, h = h, material_thickness = material_thickness);
}

module foot(material_thickness = material_thickness) {
	outline = [
		[2 * material_thickness, 0, RELIEF_NONE],
		[4 * material_thickness, 0, RELIEF_NONE],
		[4 * material_thickness, material_thickness, RELIEF_NONE],
		[material_thickness, 4 * material_thickness, RELIEF_NONE],
		[0, 4 * material_thickness, RELIEF_NONE],
		[0, 2 * material_thickness, RELIEF_NONE],
		[material_thickness, 2 * material_thickness, RELIEF_LEAD_OUT],
		[material_thickness, material_thickness, RELIEF_NONE],
		[2 * material_thickness, material_thickness, RELIEF_LEAD_IN],
	];

	draw_part(outline);
}
