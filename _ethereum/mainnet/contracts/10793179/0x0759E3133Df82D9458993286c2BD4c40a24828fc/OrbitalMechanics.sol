/**
SPDX-License-Identifier: UNLICENSED
See https://github.com/OpenZeppelin/openzeppelin-contracts/blob/2a0f2a8ba807b41360e7e092c3d5bb1bfbeb8b50/LICENSE and https://github.com/NovakDistributed/macroverse/blob/eea161aff5dba9d21204681a3b0f5dbe1347e54b/LICENSE
*/

pragma solidity ^0.6.10;


/**
 * RealMath: fixed-point math library, based on fractional and integer parts.
 * Using int128 as real88x40, which isn't in Solidity yet.
 * 40 fractional bits gets us down to 1E-12 precision, while still letting us
 * go up to galaxy scale counting in meters.
 * Internally uses the wider int256 for some math.
 *
 * Note that for addition, subtraction, and mod (%), you should just use the
 * built-in Solidity operators. Functions for these operations are not provided.
 *
 * Note that the fancy functions like sqrt, atan2, etc. aren't as accurate as
 * they should be. They are (hopefully) Good Enough for doing orbital mechanics
 * on block timescales in a game context, but they may not be good enough for
 * other applications.
 */
library RealMath {
    
    /**@dev
     * How many total bits are there?
     */
    int256 constant REAL_BITS = 128;
    
    /**@dev
     * How many fractional bits are there?
     */
    int256 constant REAL_FBITS = 40;
    
    /**@dev
     * How many integer bits are there?
     */
    int256 constant REAL_IBITS = REAL_BITS - REAL_FBITS;
    
    /**@dev
     * What's the first non-fractional bit
     */
    int128 constant REAL_ONE = int128(1) << int128(REAL_FBITS);
    
    /**@dev
     * What's the last fractional bit?
     */
    int128 constant REAL_HALF = REAL_ONE >> int128(1);
    
    /**@dev
     * What's two? Two is pretty useful.
     */
    int128 constant REAL_TWO = REAL_ONE << int128(1);
    
    /**@dev
     * And our logarithms are based on ln(2).
     */
    int128 constant REAL_LN_TWO = 762123384786;
    
    /**@dev
     * It is also useful to have Pi around.
     */
    int128 constant REAL_PI = 3454217652358;
    
    /**@dev
     * And half Pi, to save on divides.
     * TODO: That might not be how the compiler handles constants.
     */
    int128 constant REAL_HALF_PI = 1727108826179;
    
    /**@dev
     * And two pi, which happens to be odd in its most accurate representation.
     */
    int128 constant REAL_TWO_PI = 6908435304715;
    
    /**@dev
     * What's the sign bit?
     */
    int128 constant SIGN_MASK = int128(1) << int128(127);
    

    /**
     * Convert an integer to a real. Preserves sign.
     */
    function toReal(int88 ipart) public pure returns (int128) {
        return int128(ipart) * REAL_ONE;
    }
    
    /**
     * Convert a real to an integer. Preserves sign.
     */
    function fromReal(int128 real_value) public pure returns (int88) {
        return int88(real_value / REAL_ONE);
    }
    
    /**
     * Round a real to the nearest integral real value.
     */
    function round(int128 real_value) public pure returns (int128) {
        // First, truncate.
        int88 ipart = fromReal(real_value);
        if ((fractionalBits(real_value) & (uint40(1) << uint40(REAL_FBITS - 1))) > 0) {
            // High fractional bit is set. Round up.
            if (real_value < int128(0)) {
                // Rounding up for a negative number is rounding down.
                ipart -= 1;
            } else {
                ipart += 1;
            }
        }
        return toReal(ipart);
    }
    
    /**
     * Get the absolute value of a real. Just the same as abs on a normal int128.
     */
    function abs(int128 real_value) public pure returns (int128) {
        if (real_value > 0) {
            return real_value;
        } else {
            return -real_value;
        }
    }
    
    /**
     * Returns the fractional bits of a real. Ignores the sign of the real.
     */
    function fractionalBits(int128 real_value) public pure returns (uint40) {
        return uint40(abs(real_value) % REAL_ONE);
    }
    
    /**
     * Get the fractional part of a real, as a real. Ignores sign (so fpart(-0.5) is 0.5).
     */
    function fpart(int128 real_value) public pure returns (int128) {
        // This gets the fractional part but strips the sign
        return abs(real_value) % REAL_ONE;
    }

    /**
     * Get the fractional part of a real, as a real. Respects sign (so fpartSigned(-0.5) is -0.5).
     */
    function fpartSigned(int128 real_value) public pure returns (int128) {
        // This gets the fractional part but strips the sign
        int128 fractional = fpart(real_value);
        if (real_value < 0) {
            // Add the negative sign back in.
            return -fractional;
        } else {
            return fractional;
        }
    }
    
    /**
     * Get the integer part of a fixed point value.
     */
    function ipart(int128 real_value) public pure returns (int128) {
        // Subtract out the fractional part to get the real part.
        return real_value - fpartSigned(real_value);
    }
    
    /**
     * Multiply one real by another. Truncates overflows.
     */
    function mul(int128 real_a, int128 real_b) public pure returns (int128) {
        // When multiplying fixed point in x.y and z.w formats we get (x+z).(y+w) format.
        // So we just have to clip off the extra REAL_FBITS fractional bits.
        return int128((int256(real_a) * int256(real_b)) >> REAL_FBITS);
    }
    
    /**
     * Divide one real by another real. Truncates overflows.
     */
    function div(int128 real_numerator, int128 real_denominator) public pure returns (int128) {
        // We use the reverse of the multiplication trick: convert numerator from
        // x.y to (x+z).(y+w) fixed point, then divide by denom in z.w fixed point.
        return int128((int256(real_numerator) * REAL_ONE) / int256(real_denominator));
    }
    
    /**
     * Create a real from a rational fraction.
     */
    function fraction(int88 numerator, int88 denominator) public pure returns (int128) {
        return div(toReal(numerator), toReal(denominator));
    }
    
    // Now we have some fancy math things (like pow and trig stuff). This isn't
    // in the RealMath that was deployed with the original Macroverse
    // deployment, so it needs to be linked into your contract statically.
    
    /**
     * Raise a number to a positive integer power in O(log power) time.
     * See <https://stackoverflow.com/a/101613>
     */
    function ipow(int128 real_base, int88 exponent) public pure returns (int128) {
        if (exponent < 0) {
            // Negative powers are not allowed here.
            revert();
        }
        
        // Start with the 0th power
        int128 real_result = REAL_ONE;
        while (exponent != 0) {
            // While there are still bits set
            if ((exponent & 0x1) == 0x1) {
                // If the low bit is set, multiply in the (many-times-squared) base
                real_result = mul(real_result, real_base);
            }
            // Shift off the low bit
            exponent = exponent >> 1;
            // Do the squaring
            real_base = mul(real_base, real_base);
        }
        
        // Return the final result.
        return real_result;
    }
    
    /**
     * Zero all but the highest set bit of a number.
     * See <https://stackoverflow.com/a/53184>
     */
    function hibit(uint256 val) internal pure returns (uint256) {
        // Set all the bits below the highest set bit
        val |= (val >>  1);
        val |= (val >>  2);
        val |= (val >>  4);
        val |= (val >>  8);
        val |= (val >> 16);
        val |= (val >> 32);
        val |= (val >> 64);
        val |= (val >> 128);
        return val ^ (val >> 1);
    }
    
    /**
     * Given a number with one bit set, finds the index of that bit.
     */
    function findbit(uint256 val) internal pure returns (uint8 index) {
        index = 0;
        // We and the value with alternating bit patters of various pitches to find it.
        
        if (val & 0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA != 0) {
            // Picth 1
            index |= 1;
        }
        if (val & 0xCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC != 0) {
            // Pitch 2
            index |= 2;
        }
        if (val & 0xF0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0 != 0) {
            // Pitch 4
            index |= 4;
        }
        if (val & 0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00 != 0) {
            // Pitch 8
            index |= 8;
        }
        if (val & 0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000 != 0) {
            // Pitch 16
            index |= 16;
        }
        if (val & 0xFFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000 != 0) {
            // Pitch 32
            index |= 32;
        }
        if (val & 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000 != 0) {
            // Pitch 64
            index |= 64;
        }
        if (val & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000000000000000000000000000 != 0) {
            // Pitch 128
            index |= 128;
        }
    }
    
    /**
     * Shift real_arg left or right until it is between 1 and 2. Return the
     * rescaled value, and the number of bits of right shift applied. Shift may be negative.
     *
     * Expresses real_arg as real_scaled * 2^shift, setting shift to put real_arg between [1 and 2).
     *
     * Rejects 0 or negative arguments.
     */
    function rescale(int128 real_arg) internal pure returns (int128 real_scaled, int88 shift) {
        if (real_arg <= 0) {
            // Not in domain!
            revert();
        }
        
        // Find the high bit
        int88 high_bit = findbit(hibit(uint256(real_arg)));
        
        // We'll shift so the high bit is the lowest non-fractional bit.
        shift = high_bit - int88(REAL_FBITS);
        
        if (shift < 0) {
            // Shift left
            real_scaled = real_arg << int128(-shift);
        } else if (shift >= 0) {
            // Shift right
            real_scaled = real_arg >> int128(shift);
        }
    }
    
    /**
     * Calculate the natural log of a number. Rescales the input value and uses
     * the algorithm outlined at <https://math.stackexchange.com/a/977836> and
     * the ipow implementation.
     *
     * Lets you artificially limit the number of iterations.
     *
     * Note that it is potentially possible to get an un-converged value; lack
     * of convergence does not throw.
     */
    function lnLimited(int128 real_arg, int max_iterations) public pure returns (int128) {
        if (real_arg <= 0) {
            // Outside of acceptable domain
            revert();
        }
        
        if (real_arg == REAL_ONE) {
            // Handle this case specially because people will want exactly 0 and
            // not ~2^-39 ish.
            return 0;
        }
        
        // We know it's positive, so rescale it to be between [1 and 2)
        int128 real_rescaled;
        int88 shift;
        (real_rescaled, shift) = rescale(real_arg);
        
        // Compute the argument to iterate on
        int128 real_series_arg = div(real_rescaled - REAL_ONE, real_rescaled + REAL_ONE);
        
        // We will accumulate the result here
        int128 real_series_result = 0;
        
        for (int88 n = 0; n < max_iterations; n++) {
            // Compute term n of the series
            int128 real_term = div(ipow(real_series_arg, 2 * n + 1), toReal(2 * n + 1));
            // And add it in
            real_series_result += real_term;
            if (real_term == 0) {
                // We must have converged. Next term is too small to represent.
                break;
            }
            // If we somehow never converge I guess we will run out of gas
        }
        
        // Double it to account for the factor of 2 outside the sum
        real_series_result = mul(real_series_result, REAL_TWO);
        
        // Now compute and return the overall result
        return mul(toReal(shift), REAL_LN_TWO) + real_series_result;
        
    }
    
    /**
     * Calculate a natural logarithm with a sensible maximum iteration count to
     * wait until convergence. Note that it is potentially possible to get an
     * un-converged value; lack of convergence does not throw.
     */
    function ln(int128 real_arg) public pure returns (int128) {
        return lnLimited(real_arg, 100);
    }
    
    /**
     * Calculate e^x. Uses the series given at
     * <http://pages.mtu.edu/~shene/COURSES/cs201/NOTES/chap04/exp.html>.
     *
     * Lets you artificially limit the number of iterations.
     *
     * Note that it is potentially possible to get an un-converged value; lack
     * of convergence does not throw.
     */
    function expLimited(int128 real_arg, int max_iterations) public pure returns (int128) {
        // We will accumulate the result here
        int128 real_result = 0;
        
        // We use this to save work computing terms
        int128 real_term = REAL_ONE;
        
        for (int88 n = 0; n < max_iterations; n++) {
            // Add in the term
            real_result += real_term;
            
            // Compute the next term
            real_term = mul(real_term, div(real_arg, toReal(n + 1)));
            
            if (real_term == 0) {
                // We must have converged. Next term is too small to represent.
                break;
            }
            // If we somehow never converge I guess we will run out of gas
        }
        
        // Return the result
        return real_result;
        
    }
    
    /**
     * Calculate e^x with a sensible maximum iteration count to wait until
     * convergence. Note that it is potentially possible to get an un-converged
     * value; lack of convergence does not throw.
     */
    function exp(int128 real_arg) public pure returns (int128) {
        return expLimited(real_arg, 100);
    }
    
    /**
     * Raise any number to any power, except for negative bases to fractional powers.
     */
    function pow(int128 real_base, int128 real_exponent) public pure returns (int128) {
        if (real_exponent == 0) {
            // Anything to the 0 is 1
            return REAL_ONE;
        }
        
        if (real_base == 0) {
            if (real_exponent < 0) {
                // Outside of domain!
                revert();
            }
            // Otherwise it's 0
            return 0;
        }
        
        if (fpart(real_exponent) == 0) {
            // Anything (even a negative base) is super easy to do to an integer power.
            
            if (real_exponent > 0) {
                // Positive integer power is easy
                return ipow(real_base, fromReal(real_exponent));
            } else {
                // Negative integer power is harder
                return div(REAL_ONE, ipow(real_base, fromReal(-real_exponent)));
            }
        }
        
        if (real_base < 0) {
            // It's a negative base to a non-integer power.
            // In general pow(-x^y) is undefined, unless y is an int or some
            // weird rational-number-based relationship holds.
            revert();
        }
        
        // If it's not a special case, actually do it.
        return exp(mul(real_exponent, ln(real_base)));
    }
    
    /**
     * Compute the square root of a number.
     */
    function sqrt(int128 real_arg) public pure returns (int128) {
        return pow(real_arg, REAL_HALF);
    }
    
    /**
     * Compute the sin of a number to a certain number of Taylor series terms.
     */
    function sinLimited(int128 real_arg, int88 max_iterations) public pure returns (int128) {
        // First bring the number into 0 to 2 pi
        // TODO: This will introduce an error for very large numbers, because the error in our Pi will compound.
        // But for actual reasonable angle values we should be fine.
        real_arg = real_arg % REAL_TWO_PI;
        
        int128 accumulator = REAL_ONE;
        
        // We sum from large to small iteration so that we can have higher powers in later terms
        for (int88 iteration = max_iterations - 1; iteration >= 0; iteration--) {
            accumulator = REAL_ONE - mul(div(mul(real_arg, real_arg), toReal((2 * iteration + 2) * (2 * iteration + 3))), accumulator);
            // We can't stop early; we need to make it to the first term.
        }
        
        return mul(real_arg, accumulator);
    }
    
    /**
     * Calculate sin(x) with a sensible maximum iteration count to wait until
     * convergence.
     */
    function sin(int128 real_arg) public pure returns (int128) {
        return sinLimited(real_arg, 15);
    }
    
    /**
     * Calculate cos(x).
     */
    function cos(int128 real_arg) public pure returns (int128) {
        return sin(real_arg + REAL_HALF_PI);
    }
    
    /**
     * Calculate tan(x). May overflow for large results. May throw if tan(x)
     * would be infinite, or return an approximation, or overflow.
     */
    function tan(int128 real_arg) public pure returns (int128) {
        return div(sin(real_arg), cos(real_arg));
    }
    
    /**
     * Calculate atan(x) for x in [-1, 1].
     * Uses the Chebyshev polynomial approach presented at
     * https://www.mathworks.com/help/fixedpoint/examples/calculate-fixed-point-arctangent.html
     * Uses polynomials received by personal communication.
     * 0.999974x-0.332568x^3+0.193235x^5-0.115729x^7+0.0519505x^9-0.0114658x^11
     */
    function atanSmall(int128 real_arg) public pure returns (int128) {
        int128 real_arg_squared = mul(real_arg, real_arg);
        return mul(mul(mul(mul(mul(mul(
            - 12606780422,  real_arg_squared) // x^11
            + 57120178819,  real_arg_squared) // x^9
            - 127245381171, real_arg_squared) // x^7
            + 212464129393, real_arg_squared) // x^5
            - 365662383026, real_arg_squared) // x^3
            + 1099483040474, real_arg);       // x^1
    }
    
    /**
     * Compute the nice two-component arctangent of y/x.
     */
    function atan2(int128 real_y, int128 real_x) public pure returns (int128) {
        int128 atan_result;
        
        // Do the angle correction shown at
        // https://www.mathworks.com/help/fixedpoint/examples/calculate-fixed-point-arctangent.html
        
        // We will re-use these absolute values
        int128 real_abs_x = abs(real_x);
        int128 real_abs_y = abs(real_y);
        
        if (real_abs_x > real_abs_y) {
            // We are in the (0, pi/4] region
            // abs(y)/abs(x) will be in 0 to 1.
            atan_result = atanSmall(div(real_abs_y, real_abs_x));
        } else {
            // We are in the (pi/4, pi/2) region
            // abs(x) / abs(y) will be in 0 to 1; we swap the arguments
            atan_result = REAL_HALF_PI - atanSmall(div(real_abs_x, real_abs_y));
        }
        
        // Now we correct the result for other regions
        if (real_x < 0) {
            if (real_y < 0) {
                atan_result -= REAL_PI;
            } else {
                atan_result = REAL_PI - atan_result;
            }
        } else {
            if (real_y < 0) {
                atan_result = -atan_result;
            }
        }
        
        return atan_result;
    }
}

// This code is part of Macroverse and is licensed: MIT

/**
 * Provides methods for doing orbital mechanics calculations, based on
 * RealMath.
 * 
 * DON'T use these functions for computing positions for things every frame;
 * the RealMath library isn't really accurate enough for that. Use these in
 * smart contract game logic, on a time scale of one or more blocks.
 */
contract OrbitalMechanics {
    using RealMath for *;

    /**@dev
     * We need the gravitational constant. Calculated by solving the mean
     * motion equation for Earth. We can be mostly precise here, because we
     * know the semimajor axis and year length (in Julian years) to a few
     * places.
     *
     * This is 132712875029098577920 m^3 s^-2 sols^-1
     */
    int128 constant REAL_G_PER_SOL = 145919349250077040774785972305920;

    // TODO: We have to copy-paste constants from RealMath because Solidity doesn't expose them by import.

    /**@dev
     * It is also useful to have Pi around.
     * We can't pull it in from the library.
     */
    int128 constant REAL_PI = 3454217652358;

    /**@dev
     * And two pi, which happens to be odd in its most accurate representation.
     */
    int128 constant REAL_TWO_PI = 6908435304715;

    /**@dev
     * How many fractional bits are there?
     */
    int256 constant REAL_FBITS = 40;

    /**@dev
     * What's the first non-fractional bit
     */
    int128 constant REAL_ONE = int128(1) << int128(REAL_FBITS);

    /**@dev
     * What's the last fractional bit?
     */
    int128 constant REAL_HALF = REAL_ONE >> int128(1);

    /**@dev
     * We need 2 for constants in numerical methods.
     */
    int128 constant REAL_TWO = REAL_ONE * 2;
    
    /**@dev
     * We need 3 for constants in numerical methods.
     */
    int128 constant REAL_THREE = REAL_ONE * 3;

    /**@dev
     * A "year" is 365.25 days. We use Julian years.
     */
    int128 constant REAL_SECONDS_PER_YEAR = 34697948144703898000;

    

    // Functions for orbital mechanics. Maybe should be a library?
    // Are NOT controlled access, since they don't talk to the RNG.
    // Please don't do these in Solidity unless you have to; you can do orbital mechanics in JS just fine with actual floats.
    // The steps to compute an orbit are:
    // 
    // 1. Compute the semimajor axis as (apoapsis + periapsis) / 2 (do this yourself)
    // 2. Compute the mean angular motion, n = sqrt(central mass * gravitational constant / semimajor axis^3)
    // 3. Compute the Mean Anomaly, as n * time since epoch + MA at epoch, and wrap to an angle 0 to 2 pi
    // 4. Compute the Eccentric Anomaly numerically to solve MA = EA - eccentricity * sin(EA)
    // 5. Compute the True Anomaly as 2 * atan2(sqrt(1 - eccentricity) * cos(EA / 2), sqrt(1 + eccentricity) * sin(EA / 2))
    // 6. Compute the current radius as r = semimajor * (1 - eccentricity^2) / (1 + eccentricity * cos(TA))
    // 7. Compute Cartesian X (toward longitude 0) = radius * (cos(LAN) * cos(AOP + TA) - sin(LAN) * sin(AOP + TA) * cos(inclination))
    // 8. Compute Cartesian Y (in plane) = radius * (sin(LAN) * cos(AOP + TA) + cos(LAN) * sin(AOP + TA) * cos(inclination))
    // 9. Compute Cartesian Z (above plane) = radius * sin(inclination) * sin(AOP + TA)


    /**
     * Compute the mean angular motion, in radians per Julian year (365.25
     * days), given a star mass in sols and a semimajor axis in meters.
     */
    function computeMeanAngularMotion(int128 real_central_mass_in_sols, int128 real_semimajor_axis) public pure returns (int128) {
        // REAL_G_PER_SOL is big, but nothing masses more than 100s of sols, so we can do the multiply.
        // But the semimajor axis in meters may be very big so we can't really do the cube for the denominator.
        // And since values in radians per second are tiny, their squares are even tinier and probably out of range.
        // So we scale up to radians per year
        return real_central_mass_in_sols.mul(REAL_G_PER_SOL)
            .div(real_semimajor_axis)
            .mul(REAL_SECONDS_PER_YEAR)
            .div(real_semimajor_axis)
            .mul(REAL_SECONDS_PER_YEAR).div(real_semimajor_axis).sqrt();
    }

    /**
     * Compute the mean anomaly, from 0 to 2 PI, given the mean anomaly at
     * epoch, mean angular motion (in radians per Julian year) and the time (in
     * Julian years) since epoch.
     */
    function computeMeanAnomaly(int128 real_mean_anomaly_at_epoch, int128 real_mean_angular_motion, int128 real_years_since_epoch) public pure returns (int128) {
        return (real_mean_anomaly_at_epoch + real_mean_angular_motion.mul(real_years_since_epoch)) % REAL_TWO_PI;
    }

    /**
     * Compute the eccentric anomaly, given the mean anomaly and eccentricity.
     * Uses numerical methods to solve MA = EA - eccentricity * sin(EA). Limit to a certain iteration count.
     */
    function computeEccentricAnomalyLimited(int128 real_mean_anomaly, int128 real_eccentricity, int88 max_iterations) public pure returns (int128) {
        // We are going to find the root of EA - eccentricity * sin(EA) - MA, in EA.
        // We use Newton's Method.
        // f(EA) =  EA - eccentricity * sin(EA) - MA
        // f'(EA) = 1 - eccentricity * cos(EA)
        // x_n = x_n-1 - f(x_n) / f'(x_n)

        // Start with the 3rd-order approximation from http://alpheratz.net/dynamics/twobody/KeplerIterations_summary.pdf
        // "A Practical Method for Solving the Kepler Equation"
        int128 e2 = real_eccentricity.mul(real_eccentricity);
        int128 e3 = e2.mul(real_eccentricity);
        int128 cosMA = real_mean_anomaly.cos();
        int128 real_guess = real_mean_anomaly + ((-REAL_HALF).mul(e3) + real_eccentricity + 
            (e2 + cosMA.mul(e3).mul(REAL_THREE).div(REAL_TWO)).mul(cosMA)).mul(real_mean_anomaly.sin());
            
        for (int88 i = 0; i < max_iterations; i++) {
            int128 real_value = real_guess - real_eccentricity.mul(real_guess.sin()) - real_mean_anomaly;
            
            if (real_value.abs() <= 5) {
                // We found the root within epsilon.
                // Note that we are implicitly turning this random small number into a tiny real.
                break;
            }
            
            // Otherwise we update
            int128 real_derivative = REAL_ONE - real_eccentricity.mul(real_guess.cos());
            // The derivative can never be 0. If it were, since cos() is <= 1, the eccentricity would be 1.
            // Eccentricity must be <= 1
            assert(real_derivative != 0);
            real_guess = real_guess - real_value.div(real_derivative);
        }

        // Bound to 0 to 2 pi angle range.
        return real_guess % REAL_TWO_PI;
    }

    /**
     * Compute the eccentric anomaly, given the mean anomaly and eccentricity.
     * Uses numerical methods to solve MA = EA - eccentricity * sin(EA). Internally limited to a reasonable iteration count.
     */
    function computeEccentricAnomaly(int128 real_mean_anomaly, int128 real_eccentricity) public pure returns (int128) {
        return computeEccentricAnomalyLimited(real_mean_anomaly, real_eccentricity, 10);
    }

    /**
     * Compute the true anomaly from the eccentric anomaly and the eccentricity.
     */
    function computeTrueAnomaly(int128 real_eccentric_anomaly, int128 real_eccentricity) public pure returns (int128) {
        int128 real_half_ea = real_eccentric_anomaly.div(REAL_TWO);
        return RealMath.atan2((REAL_ONE - real_eccentricity).sqrt().mul(real_half_ea.cos()), (REAL_ONE + real_eccentricity).sqrt().mul(real_half_ea.sin())).mul(REAL_TWO);
    }

    /**
     * Compute the current orbit radius (distance from parent body) from the true anomaly, semimajor axis, and eccentricity.
     * Operates on distances in meters.
     */
    function computeRadius(int128 real_true_anomaly, int128 real_semimajor_axis, int128 real_eccentricity) public pure returns (int128) {
         return real_semimajor_axis.mul(REAL_ONE - real_eccentricity.mul(real_eccentricity)).div(REAL_ONE + real_eccentricity.mul(real_true_anomaly.cos()));
    }

    /**
     * Compute Cartesian X, Y, and Z offset from center of parent body to orbiting body.
     * Operates on distances in meters.
     * X is toward longitude 0 of the parent body.
     * Y is the other in-plane direction.
     * Z is up out of the plane.
     */
    function computeCartesianOffset(int128 real_radius, int128 real_true_anomaly, int128 real_lan, int128 real_inclination,
        int128 real_aop) public pure returns (int128 real_x, int128 real_y, int128 real_z) {
        
        // Compute some intermediates
        int128 cos_lan = real_lan.cos();
        int128 sin_lan = real_lan.sin();
        int128 aop_ta_cos = (real_aop + real_true_anomaly).cos();
        int128 aop_ta_sin = (real_aop + real_true_anomaly).sin();
        int128 inclination_cos = real_inclination.cos();
        int128 inclination_sin = real_inclination.sin();

        // Compute the actual coordinates
        real_x = real_radius.mul(cos_lan.mul(aop_ta_cos) - sin_lan.mul(aop_ta_sin).mul(inclination_cos));
        real_y = real_radius.mul(sin_lan.mul(aop_ta_cos) + cos_lan.mul(aop_ta_sin).mul(inclination_cos));
        real_z = real_radius.mul(inclination_sin).mul(aop_ta_sin);

    }
}

// This code is part of Macroverse and is licensed: UNLICENSED