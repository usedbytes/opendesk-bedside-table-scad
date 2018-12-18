$fn = 16;
width = 440;
depth = 440;
material_thickness = 18;
radius = 3.5;

RELIEF_NONE = 0;
RELIEF_LEAD_IN = 1;
RELIEF_LEAD_OUT = 2;

function circle_points(centre = [0, 0], radius = 5) =
	arc_points(centre = centre, start = 0, angle = 360, radius = 5);

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

function generate_corner(points, i) = let(relief = points[i][2])
	relief == RELIEF_NONE ?
		[ [points[i][0], points[i][1]] ]
	: relief == RELIEF_LEAD_IN ?
		relief_lead_in_points([
				[ points[i - 1][0], points[i - 1][1] ],
				[ points[i][0], points[i][1] ],
				[ points[i + 1][0], points[i + 1][1]]
			], radius = radius)
	: // relief == RELIEF_LEAD_OUT
		relief_lead_out_points([
				[ points[i - 1][0], points[i - 1][1] ],
				[ points[i][0], points[i][1] ],
				[ points[i + 1][0], points[i + 1][1]]
			], radius = radius);

function generate_outline(points, acc_=[], i = 0) =
	i == len(points) ? acc_ :
		generate_outline(points,
			acc_ = concat(acc_, generate_corner(points, i)), i = i + 1);

function generate_holes(holes) =
	[ for (hole = holes) circle_points(centre = hole) ];

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
	holes = generate_holes(holes);

	points = concat(outline, flatten(holes));
	paths = generate_paths(concat([outline], holes));

	polygon(points = points, paths = paths);
}

module top(w = width, d = depth, material_thickness = material_thickness) {
	// Anticlockwise
	outline = [
		// Bottom
		[0, 0, RELIEF_NONE],
		[w / 3, 0, RELIEF_NONE],
		[w / 3, material_thickness, RELIEF_LEAD_OUT],
		[2 * w / 3, material_thickness, RELIEF_LEAD_IN],
		[2 * w / 3, 0, RELIEF_NONE],

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
	holes = [[50, 30], [10, 10]];

	draw_part(outline, holes = holes);
};

top();
