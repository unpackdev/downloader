// SPDX-License-Identifier: UNLICENSED
// Copyright 2022 Arran Schlosberg
pragma solidity >=0.8.9 <0.9.0;

import "./Strings.sol";

/**
@notice Mathematical functions used by the rendering library for the
generative-art collection, The Kiss Precise.
 */
library Maths {
    /**
    @notice Constants for use with fixed-point arithmetic at a given precision.
     */
    uint256 internal constant PRECISION = 64;
    uint256 private constant PRECISION_MINUS_TWO = 62;
    uint256 private constant DOUBLE_PRECISION = 128;
    uint256 private constant DOUBLE_PRECISION_PLUS_ONE = 129;
    int256 internal constant ONE = 2**64;
    int256 private constant DOUBLE_PRECISION_THREE = 3 * 2**128;

    /**
    @dev Default number of iterations for the Newtion–Raphson method.
     */
    uint16 private constant DEFAULT_NEWTON_ROUNDS = 32;

    /**
    @dev A numerator for calculating a fixed-point inverse without shifting.
     */
    int256 internal constant NUMERATOR_FOR_INVERSE = 2**128;

    /**
    @notice Returns the fixed-point square root of x.
    @param rounds Number of Newton–Raphson iterations to perform.
     */
    function sqrt(int256 x, uint16 rounds)
        internal
        pure
        returns (int256, bool)
    {
        if (x == 0) {
            return (0, true);
        }

        (int256 y, bool isReal) = inverseSqrt(x, rounds);
        assembly {
            // x*y = x * (1/sqrt(x)) = sqrt(x)
            y := sar(PRECISION, mul(x, y))
        }
        return (y, isReal);
    }

    /**
    @dev Convenience wrapper for sqrt(x, DEFAULT_NEWTON_ROUNDS).
     */
    function sqrt(int256 x) internal pure returns (int256, bool) {
        return sqrt(x, DEFAULT_NEWTON_ROUNDS);
    }

    /**
    @notice Returns the fixed-point inverse square root of x.
    @param rounds Number of Newton–Raphson iterations to perform.
     */
    function inverseSqrt(int256 x, uint16 rounds)
        internal
        pure
        returns (int256, bool)
    {
        require(x != 0, "Divide by zero");

        bool isReal = x > 0;
        if (!isReal) {
            x = -x;
        }
        // Newton-Raphson needs a good estimate for optimal convergence.
        //
        // Estimate y_0 with a crude calculation of log_2(x) and shifting ONE by
        // half that number (sqrt) in the "opposite" direction (inverse).
        uint256 log = 0;
        if (x > ONE) {
            assembly {
                for {
                    let pow := ONE
                } lt(pow, x) {
                    pow := shl(1, pow)
                } {
                    log := add(log, 1)
                }
            }
        } else {
            assembly {
                for {
                    let pow := ONE
                } gt(pow, x) {
                    pow := shr(1, log)
                } {
                    log := add(log, 1)
                }
            }
        }
        // sqrt is approximated by 2^{log/2}
        assembly {
            log := shr(1, log)
        }

        int256 y;
        if (x > ONE) {
            // Note shifting in the opposite direction for inverse
            assembly {
                y := shr(log, ONE)
            }
        } else {
            assembly {
                y := shl(log, ONE)
            }
        }

        // Actual Newton–Raphson only starts now.
        int256 ySq;
        assembly {
            for {
                let i := 0
            } lt(i, rounds) {
                i := add(i, 1)
            } {
                ySq := sar(PRECISION, mul(y, y))
                // Both multiplications require precision correction, so they
                // are collapsed and also combined with the divide by 2, hence
                // shifting by DOUBLE_PRECISION_PLUS_ONE.
                y := sar(
                    DOUBLE_PRECISION_PLUS_ONE,
                    mul(y, sub(DOUBLE_PRECISION_THREE, mul(x, ySq)))
                )
            }
        }
        return (y, isReal);
    }

    /**
    @notice A 2D point.
     */
    struct Point {
        int256 x;
        int256 y;
    }

    /**
    @notice Returns the complex fixed-point square root of p, where p.x is real
    and p.y is imaginary (like my friends).
    @param rounds Number of Newton–Raphson iterations to perform.
     */
    function complexSqrt(Point memory p, uint16 rounds)
        internal
        pure
        returns (Point memory)
    {
        // Short-circuit the process via regular sqrt if p is real.
        if (p.y == 0) {
            (int256 root, bool real) = sqrt(p.x, rounds);
            if (real) {
                return Point({x: root, y: 0});
            }
            return Point({x: 0, y: root});
        }

        // https://math.stackexchange.com/questions/44406/how-do-i-get-the-square root-of-a-complex-number/44500#44500

        int256 r = mod(p);

        Point memory zPlusR = Point({x: p.x + r, y: p.y});
        int256 modZPlusR = mod(zPlusR);

        // Note that r * inverseSqrt(r) is the same as sqrt(r) but with double
        // the precision, which is cancelled out when dividing by modZPlusR.
        // Using sqrt(r) directly would waste gas on a no-op set of shifts that
        // cancel each other.
        (int256 scale, bool isReal) = inverseSqrt(r, rounds);
        require(isReal, "imaginary vector scaling");
        scale = (r * scale) / modZPlusR;

        int256 re = zPlusR.x;
        int256 im = zPlusR.y;
        assembly {
            re := sar(PRECISION, mul(re, scale))
            im := sar(PRECISION, mul(im, scale))
        }
        return Point({x: re, y: im});
    }

    /**
    @dev Convenience wrapper complexSqrt sqrt(p, DEFAULT_NEWTON_ROUNDS).
    */
    function complexSqrt(Point memory p) internal pure returns (Point memory) {
        return complexSqrt(p, DEFAULT_NEWTON_ROUNDS);
    }

    /**
    @notice Returns the absolute value of x.
     */
    function abs(int256 x) internal pure returns (int256) {
        if (x < 0) {
            return -x;
        }
        return x;
    }

    /**
    @notice As it says on the tin.
     */
    struct Circle {
        Point center;
        int256 radius;
    }

    /**
    @notice For radii of tangent circles, returns their curvatures (1/r) and the
    radii of the two kissing circles tangent to the inputs.
     */
    function descartesRadii(
        int256 r0,
        int256 r1,
        int256 r2
    ) internal pure returns (int256[3] memory, int256[2] memory) {
        int256 b0 = NUMERATOR_FOR_INVERSE / r0;
        int256 b1 = NUMERATOR_FOR_INVERSE / r1;
        int256 b2 = NUMERATOR_FOR_INVERSE / r2;

        int256 x = b0 * b1 + b1 * b2 + b2 * b0;
        // Equivalent to multiplying by 4, which becomes x2 with sqrt.
        assembly {
            x := sar(PRECISION_MINUS_TWO, x)
        }
        (x, ) = sqrt(x);

        int256 base = b0 + b1 + b2;
        return (
            [b0, b1, b2],
            [
                NUMERATOR_FOR_INVERSE / (base + x),
                NUMERATOR_FOR_INVERSE / (base - x)
            ]
        );
    }

    /**
    @notice For tangent circles, returns the two kissing circles tangent to the
    inputs.
     */
    function descartes(Circle[3] memory circles)
        internal
        pure
        returns (Circle[2] memory)
    {
        int256[3] memory curvature;
        int256[2] memory radii;
        (curvature, radii) = descartesRadii(
            circles[0].radius,
            circles[1].radius,
            circles[2].radius
        );

        Point[3] memory scaled;
        for (uint256 i = 0; i < 3; i++) {
            scaled[i] = pointMulScalar(circles[i].center, curvature[i]);
        }

        Point memory root = complexSqrt(
            addPoints(
                complexMultiply(scaled[0], scaled[1]),
                complexMultiply(scaled[1], scaled[2]),
                complexMultiply(scaled[2], scaled[0])
            )
        );
        root.x *= 2;
        root.y *= 2;

        Point memory sum = addPoints(scaled[0], scaled[1], scaled[2]);

        // sum & diff refer to (c + r) and (c - r) where c is the sum of scaled
        // centers, and r is "root above". The first definition of "sum" upon
        // declaration is only a temporary value to avoid having to add the
        // scaled centers twice.
        Point memory diff = subPoints(sum, root);
        sum = addPoints(sum, root);

        Circle[2] memory squircles;
        squircles[0] = Circle(pointMulScalar(sum, radii[0]), radii[0]);
        squircles[1] = Circle(pointMulScalar(diff, radii[0]), radii[0]);
        return squircles;
    }

    /**
    @notice Returns the product of two complex numbers.
     */
    function complexMultiply(Point memory a, Point memory b)
        internal
        pure
        returns (Point memory)
    {
        int256 re = a.x * b.x - a.y * b.y;
        int256 im = a.x * b.y + a.y * b.x;

        assembly {
            re := sar(PRECISION, re)
            im := sar(PRECISION, im)
        }
        return Point(re, im);
    }

    /**
    @notice Returns the element-wise sum of two Points.
     */
    function addPoints(Point memory p, Point memory q)
        internal
        pure
        returns (Point memory)
    {
        return Point(p.x + q.x, p.y + q.y);
    }

    /**
    @notice Returns the element-wise sum of three Points.
     */
    function addPoints(
        Point memory p,
        Point memory q,
        Point memory r
    ) internal pure returns (Point memory) {
        return Point(p.x + q.x + r.x, p.y + q.y + r.y);
    }

    /**
    @notice Returns the element-wise different between three Points.
     */
    function subPoints(Point memory p, Point memory q)
        internal
        pure
        returns (Point memory)
    {
        return Point(p.x - q.x, p.y - q.y);
    }

    /**
    @notice Returns the Point scaled by k.
     */
    function pointMulScalar(Point memory p, int256 k)
        internal
        pure
        returns (Point memory)
    {
        int256 x = k * p.x;
        int256 y = k * p.y;

        assembly {
            x := sar(PRECISION, x)
            y := sar(PRECISION, y)
        }
        return Point(x, y);
    }

    /**
    @notice Returns the distance between two Points.
     */
    function distance(Point memory a, Point memory b)
        internal
        pure
        returns (int256)
    {
        int256 x = a.x - b.x;
        int256 y = a.y - b.y;

        int256 hypSq;
        assembly {
            hypSq := sar(PRECISION, add(mul(x, x), mul(y, y)))
        }
        (int256 dist, ) = sqrt(hypSq);
        return dist;
    }

    /**
    @notice Returns the distance from the Point to the origin.
     */
    function mod(Point memory p) internal pure returns (int256) {
        return distance(p, Point(0, 0));
    }

    /**
    @notice Equivalent to Strings.toString() but with a signed value, scaled for
    fixed-point precision. Instead of converting fractional elements to decimal,
    the integer is scaled by 2^fractionalBits to save gas.
    @dev If using values in SVGs, undo the scaling by multiplying the viewBox
    width and height by the same scale factor, thus zooming out.
     */
    function toString(int256 x, uint256 fractionalBits)
        internal
        pure
        returns (string memory)
    {
        bool neg = x < 0;
        if (neg) {
            x = -x;
        }
        assembly {
            x := shr(sub(PRECISION, fractionalBits), x)
        }

        string memory str = Strings.toString(uint256(x));
        if (neg) {
            return string(abi.encodePacked("-", str));
        }
        return str;
    }
}
