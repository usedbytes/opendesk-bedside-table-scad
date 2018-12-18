$fn = 16;
width = 440;
depth = 440;
material_thickness = 18;

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

module top(w = width, d = depth, material_thickness = material_thickness) {
	// Anticlockwise
	outline = [
		// Bottom
		[0, 0],
		[w / 3, 0],
		[w / 3, material_thickness],
		[2 * w / 3, material_thickness],
		[2 * w / 3, 0],

		// Right
		[w, 0],
		[w, d / 3],
		[w - material_thickness, d / 3],
		[w - material_thickness, 2 * d / 3],
		[w, 2 * d / 3],

		// Top
		[w, d],
		[2 * w / 3, d],
		[2 * w / 3, d - material_thickness],
		[w / 3, d - material_thickness],
		[w / 3, d],

		// Left
		[0, d],
		[0, 2 * d / 3],
		[0 + material_thickness, 2 * d / 3],
		[0 + material_thickness, d / 3],
		[0, d / 3],
	];

	polygon(points = outline);
}
