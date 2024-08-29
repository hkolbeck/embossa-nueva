module texturize(img, r, out_h, invert = false) {
  height = len(img);
  width = len(img[0]);

  zeros = [[for (x = [0 : width - 1]) 0]];
  padded = concat(zeros, img, zeros);

  h_delta = out_h / (height + 1);
  a_delta = 360 / width;
  inv = invert ? -1 : 1;

  function to_point(x, y) =
  let (pt_r = r + (inv * padded[y][x]), a = invert ? (width - x) * a_delta : x * a_delta)
    [cos(a) * pt_r, out_h - (h_delta * y), sin(a) * pt_r];

  points = [
    for (y = [0 : height + 1])
    for (x = [0 : width - 1])
    to_point(x, y)
    ];

  function reverse(list) = [for (i = [len(list)-1:-1:0]) list[i]];
  cap1 = [for (x = [0 : width - 1]) x];
  cap2 = [for (x = [width - 1 : -1 : 0]) x + ((height + 1) * width)];
  faces = concat(
    invert ? [[reverse(cap1)]] : [[cap1]],
    [
    for (x = [0 : width - 1])
    for (y = [0 : height])
    let (
      it = x + (y * width),
      r = ((x + 1) % width) + (y * width),
      d = x + ((y + 1) * width),
      rd = ((x + 1) % width) + ((y + 1) * width)
    )
      invert ? [[it, r, rd], [it, rd, d]] : [[it, rd, r], [it, d, rd]]
    ],
    invert ? [[reverse(cap2)]] : [[cap2]]
  );

  function flatten(l) = [for (a = l) for (b = a) b];
  difference() {
    polyhedron(points = points, faces = flatten(faces));
    translate([0, out_h / 2, 0]) rotate([90, 0, 0]) cylinder(r = r - 1.1, h = 2 * out_h, center = true);
  }
}

//TODO - Tweak things with rotation to actually allow different r/h to work
module negative_blank(r=15, h=60) {
  rail_inner=(h-5)/2;
  translate([-20, -45, 0]) union() {
    difference() {
      _blank(r=15,h=60);
      rotate([90, 0, 0]) {
        rotate_extrude(angle = 360) {
          polygon([
              [14, rail_inner],
              [14, -rail_inner],
              [15, -rail_inner],
              [15, rail_inner]
            ]);
        }
      };
    };

    rotate([90, 0, 0]) {
      rotate_extrude(angle = 360) {
        translate([r, rail_inner + 0.5]) rect(2,1);
        translate([r, -rail_inner - 0.5]) rect(2,1);
      }
    };
  };
};

//TODO - Tweak things with rotation to actually allow different r/h to work
module positive_blank(r=15, h=60) {
  rail_inner=(h-5)/2;

  translate([20, -45, 0])
    rotate([0, -90, 0])
      difference() {
        _blank(r=r,h=h);
        rotate([90, 0, 0]) {
          rotate_extrude(angle = 360) {
            translate([r, rail_inner + 0.5]) rect(2,1);
            translate([r, -rail_inner - 0.5]) rect(2,1);
          }
        };
      };
}

module positive_break(len=40) {
  translate([15, 0, 0]) linear_extrude(height=1, center=true) rect(1, len);
}

module rect(w,h) {
  polygon([
      [w/2, h/2],
      [w/2, -h/2],
      [-w/2, -h/2],
      [-w/2, h/2],
    ]);
}

module _blank(r, h, drive=12) {
  hh = h/2;

  difference() {
    rotate([90, 0, 0]) {
      rotate_extrude(angle = 360) {
        union() {
          translate([(r-1)/2,0, 0]) rect(r - 1, h);
          translate([(r)/2, 0, 0]) rect(r, h - 2);
          translate([r - 1, hh - 1]) circle(r = 1);
          translate([r - 1, -hh + 1]) circle(r = 1);
        };
      }
    }

    linear_extrude(height = 12, center = true)
      translate([0,hh - 6,0]) rect(12,10);

    translate([0, 30, 0]) rotate([90, 0, 0])
      linear_extrude(height = 1, scale = 12 / 14) rect(14,14);

    linear_extrude(height = 12, center = true)
      translate([0,-hh + 6,0]) rect(12,10);

    translate([0, -30, 0]) rotate([-90, 0, 0])
      linear_extrude(height = 1, scale = 12 / 14) rect(14,14);

  };
};

translate([50, 0, 30]) rotate([90, 0, 180]) translate([0, -30, 0]) union() {
  translate([0, 2.5, 0]) texturize(img = $input, r = 15, out_h = 55);
  translate([-20, 75, 0]) positive_blank();
}

translate([0, 0, 30]) rotate([90, 0, 0]) translate([0, -30, 0]) union() {
  translate([0, 2.5, 0]) texturize(img = $input, r = 15, out_h = 55, invert=true);
  translate([20, 75, 0]) negative_blank();
}
