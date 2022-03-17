/*
    Prove: I know (x,y) such that:
    - x^2 + y^2 <= r^2
    - perlin(x, y) = p
    - MiMCSponge(x,y) = pub
*/

include "../../client/node_modules/circomlib/circuits/comparators.circom";
include "../range_proof/circuit.circom";

template Main(n) {
    /* coordinate inputs contain x and y coordinates */
    signal input a[n];
    signal input b[n];
    signal input c[n];
    signal input energy;
    signal input r;

    /* Check the range constrait of the three planet */
    component checkCoord[3];

    checkCoord[0] = CheckCoord();
    checkCoord[0].x <== a[0];
    checkCoord[0].y <== a[1];
    checkCoord[0].r <== r;

    checkCoord[1] = CheckCoord();
    checkCoord[1].x <== b[0];
    checkCoord[1].y <== b[1];
    checkCoord[1].r <== r;

    checkCoord[2] = CheckCoord();
    checkCoord[2].x <== c[0];
    checkCoord[2].y <== c[1];
    checkCoord[2].r <== r;
    
    /* Check the if a, b, c form a valid triangle */
    component len_ab = GetDistance(); 
    component len_ac = GetDistance(); 
    component len_bc = GetDistance();

    len_ab.ax <== a[0];
    len_ac.ax <== a[0];
    len_bc.ax <== b[0];
    len_ab.ay <== a[1];
    len_ac.ay <== a[1];
    len_bc.ay <== b[1];

    len_ab.bx <== b[0];
    len_ac.bx <== c[0];
    len_bc.bx <== c[0];
    len_ab.by <== b[1];
    len_ac.by <== c[1];
    len_bc.by <== c[1];

    component gt_ab = GreaterThan(32);
    component gt_ac = GreaterThan(32);
    component gt_bc = GreaterThan(32);

    gt_ab.in[0] <== len_bc.len + len_ac.len;
    gt_ab.in[1] <== len_ab.len;
    gt_ab.out === 1;


    gt_ac.in[0] <== len_ab.len + len_bc.len;
    gt_ac.in[1] <== len_ac.len;
    gt_ac.out === 1;

    gt_bc.in[0] <== len_ab.len + len_ac.len;
    gt_bc.in[1] <== len_bc.len;
    gt_bc.out === 1;

    /* Check energy */
    component let_ab = LessEqThan(32);
    component let_ac = LessEqThan(32);
    component let_bc = LessEqThan(32);

    let_ab.in[0] <== len_ab.len;
    let_ab.in[1] <== energy;
    let_ab.out === 1;

    let_ac.in[0] <== len_ac.len;
    let_ac.in[1] <== energy;
    let_ac.out === 1;

    let_bc.in[0] <== len_bc.len;
    let_bc.in[1] <== energy;
    let_bc.out === 1;

    
}

template GetDistance() {
    signal input ax;
    signal input bx;
    signal input ay;
    signal input by;
    signal output len;

    var x = (ax - bx) ** 2;
    var y = (ay - by) ** 2;
    var result = sqrt(x + y);
    len <-- result;
    
}


template CheckCoord() {    
    signal input x;
    signal input y;
    signal input r;
    
    /* check abs(x), abs(y), abs(r) < 2^32 */
    component rp = MultiRangeProof(2, 60, 2 ** 32);
    rp.in[0] <== x;
    rp.in[1] <== y;

    /* check x^2 + y^2 < r^2 */
    component comp = LessThan(32);
    signal xSq;
    signal ySq;
    signal rSq;
    xSq <== x * x;
    ySq <== y * y;
    rSq <== r * r;
    comp.in[0] <== xSq + ySq;
    comp.in[1] <== rSq;
    comp.out === 1;
}

function sqrt(n) {

    if (n == 0) {
        return 0;
    }

    // Test that have solution
    var res = n ** ((-1) >> 1);
//        if (res!=1) assert(false, "SQRT does not exists");
    if (res!=1) return 0;

    var m = 28;
    var c = 19103219067921713944291392827692070036145651957329286315305642004821462161904;
    var t = n ** 81540058820840996586704275553141814055101440848469862132140264610111;
    var r = n ** ((81540058820840996586704275553141814055101440848469862132140264610111+1)>>1);
    var sq;
    var i;
    var b;
    var j;

    while ((r != 0)&&(t != 1)) {
        sq = t*t;
        i = 1;
        while (sq!=1) {
            i++;
            sq = sq*sq;
        }

        // b = c ^ m-i-1
        b = c;
        for (j=0; j< m-i-1; j ++) b = b*b;

        m = i;
        c = b*b;
        t = t*c;
        r = r*b;
    }

    if (r < 0 ) {
        r = -r;
    }

    return r;
}

component main = Main(2);