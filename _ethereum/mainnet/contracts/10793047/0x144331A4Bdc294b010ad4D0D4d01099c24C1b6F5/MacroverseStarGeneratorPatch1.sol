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

library RNG {
    using RealMath for *;

    /**
     * We are going to define a RandNode struct to allow for hash chaining.
     * You can extend a RandNode with a bunch of different stuff and get a new RandNode.
     * You can then use a RandNode to get a single, repeatable random value.
     * This eliminates the need for concatenating string selfs, which is a huge pain in Solidity.
     */
    struct RandNode {
        // We hash this together with whatever we're mixing in to get the child hash.
        bytes32 _hash;
    }
    
    // All the functions that touch RandNodes need to be internal.
    // If you want to pass them in and out of contracts just use the bytes32.
    
    // You can get all these functions as methods on RandNodes by "using RNG for *" in your library/contract.
    
    /**
     * Mix string data into a RandNode. Returns a new RandNode.
     */
    function derive(RandNode memory self, string memory entropy) internal pure returns (RandNode memory) {
        // Hash what's there now with the new stuff.
        return RandNode(sha256(abi.encodePacked(self._hash, entropy)));
    }
    
    /**
     * Mix signed int data into a RandNode. Returns a new RandNode.
     */
    function derive(RandNode memory self, int256 entropy) internal pure returns (RandNode memory) {
        return RandNode(sha256(abi.encodePacked(self._hash, entropy)));
    }
    
     /**
     * Mix unsigned int data into a RandNode. Returns a new RandNode.
     */
    function derive(RandNode memory self, uint256 entropy) internal pure returns (RandNode memory) {
        return RandNode(sha256(abi.encodePacked(self._hash, entropy)));
    }

    /**
     * Returns the base RNG hash for the given RandNode.
     * Does another round of hashing in case you made a RandNode("Stuff").
     */
    function getHash(RandNode memory self) internal pure returns (bytes32) {
        return sha256(abi.encodePacked(self._hash));
    }
    
    /**
     * Return true or false with 50% probability.
     */
    function getBool(RandNode memory self) internal pure returns (bool) {
        return uint256(getHash(self)) & 0x1 > 0;
    }
    
    /**
     * Get an int128 full of random bits.
     */
    function getInt128(RandNode memory self) internal pure returns (int128) {
        // Just cast to int and truncate
        return int128(int256(getHash(self)));
    }
    
    /**
     * Get a real88x40 between 0 (inclusive) and 1 (exclusive).
     */
    function getReal(RandNode memory self) internal pure returns (int128) {
        return getInt128(self).fpart();
    }
    
    /**
     * Get an integer between low, inclusive, and high, exclusive. Represented as a normal int, not a real.
     */
    function getIntBetween(RandNode memory self, int88 low, int88 high) internal pure returns (int88) {
        return RealMath.fromReal((getReal(self).mul(RealMath.toReal(high) - RealMath.toReal(low))) + RealMath.toReal(low));
    }
    
    /**
     * Get a real between realLow (inclusive) and realHigh (exclusive).
     * Only actually has the bits of entropy from getReal, so some values will not occur.
     */
    function getRealBetween(RandNode memory self, int128 realLow, int128 realHigh) internal pure returns (int128) {
        return getReal(self).mul(realHigh - realLow) + realLow;
    }
    
    /**
     * Roll a number of die of the given size, add/subtract a bonus, and return the result.
     * Max size is 100.
     */
    function d(RandNode memory self, int8 count, int8 size, int8 bonus) internal pure returns (int16) {
        if (count == 1) {
            // Base case
            return int16(getIntBetween(self, 1, size)) + bonus;
        } else {
            // Loop and sum
            int16 sum = bonus;
            for(int8 i = 0; i < count; i++) {
                // Roll each die with no bonus
                sum += d(derive(self, i), 1, size, 0);
            }
            return sum;
        }
    }
}

// This code is part of Macroverse and is licensed: MIT

/**
 * Interface for an access control strategy for Macroverse contracts.
 * Can be asked if a certain query should be allowed, and will return true or false.
 * Allows for different access control strategies (unrestricted, minimum balance, subscription, etc.) to be swapped in.
 */
abstract contract AccessControl {
    /**
     * Should a query be allowed for this msg.sender (calling contract) and this tx.origin (calling user)?
     */
    function allowQuery(address sender, address origin) virtual public view returns (bool);
}

// This code is part of Macroverse and is licensed: UNLICENSED

// This code is part of OpenZeppelin and is licensed: MIT
/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// This code is part of OpenZeppelin and is licensed: MIT
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * Represents a contract that is Ownable, and which has methods that are to be protected by an AccessControl strategy selected by the owner.
 */
contract ControlledAccess is Ownable {

    // This AccessControl contract determines who can run onlyControlledAccess methods.
    AccessControl accessControl;
    
    /**
     * Make a new ControlledAccess contract, controlling access with the given AccessControl strategy.
     */
    constructor(address originalAccessControl) internal {
        accessControl = AccessControl(originalAccessControl);
    }
    
    /**
     * Change the access control strategy of the prototype.
     */
    function changeAccessControl(address newAccessControl) public onlyOwner {
        accessControl = AccessControl(newAccessControl);
    }
    
    /**
     * Only allow queries approved by the access control contract.
     */
    modifier onlyControlledAccess {
        if (!accessControl.allowQuery(msg.sender, tx.origin)) revert();
        _;
    }
    

}

// This code is part of Macroverse and is licensed: UNLICENSED

/**
 * Represents a Macroverse Generator for a galaxy.
 *
 * Permission to call methods on this contract is regulated by a configurable
 * AccessControl contract. One such set of terms might be to require that the
 * account initiating a transaction have a certain minimum MRV token balance.
 *
 * The owner of this contract reserves the right to supersede it with a new
 * version, and to modify the terms for accessing this contract, at any time,
 * for any reason, and without notice. This includes the right to indefinitely
 * or permanently suspend or terminate access to this contract for any person,
 * account, or other contract, or for all persons, accounts, or other
 * contracts. The owner also reserves the right to not do any of the above.
 */
contract MacroverseStarGenerator is ControlledAccess {
    // TODO: RNG doesn't get linked against because we can't pass the struct to the library...
    using RNG for *;
    using RealMath for *;
    // No SafeMath or it might confuse RealMath

    // How big is a sector on a side in LY?
    int16 constant SECTOR_SIZE = 25;
    // How far out does the sector system extend?
    int16 constant MAX_SECTOR = 10000;
    // How big is the galaxy?
    int16 constant DISK_RADIUS_IN_SECTORS = 6800;
    // How thick is its disk?
    int16 constant DISK_HALFHEIGHT_IN_SECTORS = 40;
    // How big is the central sphere?
    int16 constant CORE_RADIUS_IN_SECTORS = 1000;
    
    // There are kinds of stars.
    // We can add more later; these are from http://www.mit.edu/afs.new/sipb/user/sekullbe/furble/planet.txt
    //                 0           1      2             3           4            5
    enum ObjectClass { Supergiant, Giant, MainSequence, WhiteDwarf, NeutronStar, BlackHole }
    // Actual stars have a spectral type
    //                  0      1      2      3      4      5      6      7
    enum SpectralType { TypeO, TypeB, TypeA, TypeF, TypeG, TypeK, TypeM, NotApplicable }
    // Each type has subtypes 0-9, except O which only has 5-9
    
    // This root RandNode provides the seed for the universe.
    RNG.RandNode root;
    
    /**
     * Deploy a new copy of the Macroverse generator contract. Use the given seed to generate a galaxy, down to the star level.
     * Use the contract at the given address to regulate access.
     */
    constructor(bytes32 baseSeed, address accessControlAddress) ControlledAccess(accessControlAddress) public {
        root = RNG.RandNode(baseSeed);
    }
    
    /**
     * Get the density (between 0 and 1 as a fixed-point real88x40) of stars in the given sector. Sector 0,0,0 is centered on the galactic origin.
     * +Y is upwards.
     */
    function getGalaxyDensity(int16 sectorX, int16 sectorY, int16 sectorZ) public view onlyControlledAccess returns (int128 realDensity) {
        // We have a central sphere and a surrounding disk.
        
        // Enforce absolute bounds.
        if (sectorX > MAX_SECTOR) return 0;
        if (sectorY > MAX_SECTOR) return 0;
        if (sectorZ > MAX_SECTOR) return 0;
        if (sectorX < -MAX_SECTOR) return 0;
        if (sectorY < -MAX_SECTOR) return 0;
        if (sectorZ < -MAX_SECTOR) return 0;
        
        if (int(sectorX) * int(sectorX) + int(sectorY) * int(sectorY) + int(sectorZ) * int(sectorZ) < int(CORE_RADIUS_IN_SECTORS) * int(CORE_RADIUS_IN_SECTORS)) {
            // Central sphere
            return RealMath.fraction(9, 10);
        } else if (int(sectorX) * int(sectorX) + int(sectorZ) * int(sectorZ) < int(DISK_RADIUS_IN_SECTORS) * int(DISK_RADIUS_IN_SECTORS) && sectorY < DISK_HALFHEIGHT_IN_SECTORS && sectorY > -DISK_HALFHEIGHT_IN_SECTORS) {
            // Disk
            return RealMath.fraction(1, 2);
        } else {
            // General background object rate
            // Set so that some background sectors do indeed have an object in them.
            return RealMath.fraction(1, 60);
        }
    }
    
    /**
     * Get the number of objects in the sector at the given coordinates.
     */
    function getSectorObjectCount(int16 sectorX, int16 sectorY, int16 sectorZ) public view onlyControlledAccess returns (uint16) {
        // Decide on a base item count
        RNG.RandNode memory sectorNode = root.derive(sectorX).derive(sectorY).derive(sectorZ);
        int16 maxObjects = sectorNode.derive("count").d(3, 20, 0);
        
        // Multiply by the density function
        int128 presentObjects = RealMath.toReal(maxObjects).mul(getGalaxyDensity(sectorX, sectorY, sectorZ));
        
        return uint16(RealMath.fromReal(RealMath.round(presentObjects)));
    }
    
    /**
     * Get the seed for an object in a sector.
     */
    function getSectorObjectSeed(int16 sectorX, int16 sectorY, int16 sectorZ, uint16 object) public view onlyControlledAccess returns (bytes32) {
        return root.derive(sectorX).derive(sectorY).derive(sectorZ).derive(uint(object))._hash;
    }
    
    /**
     * Get the class of the star system with the given seed.
     */
    function getObjectClass(bytes32 seed) public view onlyControlledAccess returns (ObjectClass) {
        // Make a node for rolling for the class.
        RNG.RandNode memory node = RNG.RandNode(seed).derive("class");
        // Roll an impractical d10,000
        int88 roll = node.getIntBetween(1, 10000);
        
        if (roll == 1) {
            // Should be a black hole
            return ObjectClass.BlackHole;
        } else if (roll <= 3) {
            // Should be a neutron star
            return ObjectClass.NeutronStar;
        } else if (roll <= 700) {
            // Should be a white dwarf
            return ObjectClass.WhiteDwarf;
        } else if (roll <= 9900) {
            // Most things are main sequence
            return ObjectClass.MainSequence;
        } else if (roll <= 9990) {
            return ObjectClass.Giant;
        } else {
            return ObjectClass.Supergiant;
        }
    }
    
    /**
     * Get the spectral type for an object with the given seed of the given class.
     */
    function getObjectSpectralType(bytes32 seed, ObjectClass objectClass) public view onlyControlledAccess returns (SpectralType) {
        RNG.RandNode memory node = RNG.RandNode(seed).derive("type");
        int88 roll = node.getIntBetween(1, 10000000); // Even more implausible dice

        if (objectClass == ObjectClass.MainSequence) {
            if (roll <= 3) {
                return SpectralType.TypeO;
            } else if (roll <= 13003) {
                return SpectralType.TypeB;
            } else if (roll <= 73003) {
                return SpectralType.TypeA;
            } else if (roll <= 373003) {
                return SpectralType.TypeF;
            } else if (roll <= 1133003) {
                return SpectralType.TypeG;
            } else if (roll <= 2343003) {
                return SpectralType.TypeK;
            } else {
                return SpectralType.TypeM;
            }
        } else if (objectClass == ObjectClass.Giant) {
            if (roll <= 500000) {
                return SpectralType.TypeF;
            } else if (roll <= 1000000) {
                return SpectralType.TypeG;
            } else if (roll <= 5500000) {
                return SpectralType.TypeK;
            } else {
                return SpectralType.TypeM;
            }
        } else if (objectClass == ObjectClass.Supergiant) {
            if (roll <= 1000000) {
                return SpectralType.TypeB;
            } else if (roll <= 2000000) {
                return SpectralType.TypeA;
            } else if (roll <= 4000000) {
                return SpectralType.TypeF;
            } else if (roll <= 6000000) {
                return SpectralType.TypeG;
            } else if (roll <= 8000000) {
                return SpectralType.TypeK;
            } else {
                return SpectralType.TypeM;
            }
        } else {
            // TODO: No spectral class for anyone else.
            return SpectralType.NotApplicable;
        }
        
    }
    
    /**
     * Get the position of a star within its sector, as reals from 0 to 25.
     * Note that stars may end up implausibly close together. Such is life in the Macroverse.
     */
    function getObjectPosition(bytes32 seed) public view onlyControlledAccess returns (int128 realX, int128 realY, int128 realZ) {
        RNG.RandNode memory node = RNG.RandNode(seed).derive("position");
        
        realX = node.derive("x").getRealBetween(RealMath.toReal(0), RealMath.toReal(25));
        realY = node.derive("y").getRealBetween(RealMath.toReal(0), RealMath.toReal(25));
        realZ = node.derive("z").getRealBetween(RealMath.toReal(0), RealMath.toReal(25));
    }
    
    /**
     * Get the mass of a star, in solar masses as a real, given its seed and class and spectral type.
     */
    function getObjectMass(bytes32 seed, ObjectClass objectClass, SpectralType spectralType) public view onlyControlledAccess returns (int128) {
        RNG.RandNode memory node = RNG.RandNode(seed).derive("mass");
         
        if (objectClass == ObjectClass.BlackHole) {
            return node.getRealBetween(RealMath.toReal(5), RealMath.toReal(50));
        } else if (objectClass == ObjectClass.NeutronStar) {
            return node.getRealBetween(RealMath.fraction(11, 10), RealMath.toReal(2));
        } else if (objectClass == ObjectClass.WhiteDwarf) {
            return node.getRealBetween(RealMath.fraction(3, 10), RealMath.fraction(11, 10));
        } else if (objectClass == ObjectClass.MainSequence) {
            if (spectralType == SpectralType.TypeO) {
                return node.getRealBetween(RealMath.toReal(16), RealMath.toReal(40));
            } else if (spectralType == SpectralType.TypeB) {
                return node.getRealBetween(RealMath.fraction(21, 10), RealMath.toReal(16));
            } else if (spectralType == SpectralType.TypeA) {
                return node.getRealBetween(RealMath.fraction(14, 10), RealMath.fraction(21, 10));
            } else if (spectralType == SpectralType.TypeF) {
                return node.getRealBetween(RealMath.fraction(104, 100), RealMath.fraction(14, 10));
            } else if (spectralType == SpectralType.TypeG) {
                return node.getRealBetween(RealMath.fraction(80, 100), RealMath.fraction(104, 100));
            } else if (spectralType == SpectralType.TypeK) {
                return node.getRealBetween(RealMath.fraction(45, 100), RealMath.fraction(80, 100));
            } else if (spectralType == SpectralType.TypeM) {
                return node.getRealBetween(RealMath.fraction(8, 100), RealMath.fraction(45, 100));
            }
        } else if (objectClass == ObjectClass.Giant) {
            // Just make it really big
            return node.getRealBetween(RealMath.toReal(40), RealMath.toReal(50));
        } else if (objectClass == ObjectClass.Supergiant) {
            // Just make it really, really big
            return node.getRealBetween(RealMath.toReal(50), RealMath.toReal(70));
        }
    }
    
    /**
     * Determine if the given star has any orbiting planets or not.
     */
    function getObjectHasPlanets(bytes32 seed, ObjectClass objectClass, SpectralType spectralType) public view onlyControlledAccess returns (bool) {
        RNG.RandNode memory node = RNG.RandNode(seed).derive("hasplanets");
        int88 roll = node.getIntBetween(1, 1000);

        if (objectClass == ObjectClass.MainSequence) {
            if (spectralType == SpectralType.TypeO || spectralType == SpectralType.TypeB) {
                return (roll <= 1);
            } else if (spectralType == SpectralType.TypeA) {
                return (roll <= 500);
            } else if (spectralType == SpectralType.TypeF || spectralType == SpectralType.TypeG || spectralType == SpectralType.TypeK) {
                return (roll <= 990);
            } else if (spectralType == SpectralType.TypeM) {
                return (roll <= 634);
            }
        } else if (objectClass == ObjectClass.Giant) {
            return (roll <= 90);
        } else if (objectClass == ObjectClass.Supergiant) {
            return (roll <= 50);
        } else {
           // Black hole, neutron star, or white dwarf
           return (roll <= 70);
        }
    }
    

}

// This code is part of Macroverse and is licensed: UNLICENSED

/**
 * Provides extra methods not present in the original MacroverseStarGenerator
 * that generate new properties of the galaxy's stars. Meant to be deployed and
 * queried alongside the original.
 *
 * Permission to call methods on this contract is regulated by a configurable
 * AccessControl contract. One such set of terms might be to require that the
 * account initiating a transaction have a certain minimum MRV token balance.
 *
 * The owner of this contract reserves the right to supersede it with a new
 * version, and to modify the terms for accessing this contract, at any time,
 * for any reason, and without notice. This includes the right to indefinitely
 * or permanently suspend or terminate access to this contract for any person,
 * account, or other contract, or for all persons, accounts, or other
 * contracts. The owner also reserves the right to not do any of the above.
 */
contract MacroverseStarGeneratorPatch1 is ControlledAccess {
    // TODO: RNG doesn't get linked against because we can't pass the struct to the library...
    using RNG for *;
    using RealMath for *;
    // No SafeMath or it might confuse RealMath

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
    int128 constant REAL_HALF = REAL_ONE >> 1;

    /**@dev
     * It is useful to have Pi around.
     * We can't pull it in from the library.
     */
    int128 constant REAL_PI = 3454217652358;

    /**
     * Deploy a new copy of the patch generator.
     * Use the contract at the given address to regulate access.
     */
    constructor(address accessControlAddress) ControlledAccess(accessControlAddress) public {
        // Nothing to do!
    }

    /**
     * If the object has any planets at all, get the planet count. Will return
     * nonzero numbers always, so make sure to check getObjectHasPlanets in the
     * Star Generator.
     */
    function getObjectPlanetCount(bytes32 starSeed, MacroverseStarGenerator.ObjectClass objectClass,
        MacroverseStarGenerator.SpectralType spectralType) public view onlyControlledAccess returns (uint16) {
        
        RNG.RandNode memory node = RNG.RandNode(starSeed).derive("planetcount");
        
        
        uint16 limit;

        if (objectClass == MacroverseStarGenerator.ObjectClass.MainSequence) {
            if (spectralType == MacroverseStarGenerator.SpectralType.TypeO ||
                spectralType == MacroverseStarGenerator.SpectralType.TypeB) {
                
                limit = 5;
            } else if (spectralType == MacroverseStarGenerator.SpectralType.TypeA) {
                limit = 7;
            } else if (spectralType == MacroverseStarGenerator.SpectralType.TypeF ||
                spectralType == MacroverseStarGenerator.SpectralType.TypeG ||
                spectralType == MacroverseStarGenerator.SpectralType.TypeK) {
                
                limit = 12;
            } else if (spectralType == MacroverseStarGenerator.SpectralType.TypeM) {
                limit = 14;
            }
        } else if (objectClass == MacroverseStarGenerator.ObjectClass.Giant) {
            limit = 2;
        } else if (objectClass == MacroverseStarGenerator.ObjectClass.Supergiant) {
            limit = 2;
        } else {
           // Black hole, neutron star, or white dwarf
           limit = 2;
        }
        
        uint16 roll = uint16(node.getIntBetween(1, int88(limit + 1)));
        
        return roll;
    }

    /**
     * Compute the luminosity of a stellar object given its mass and class.
     * We didn't define this in the star generator, but we need it for the planet generator.
     *
     * Returns luminosity in solar luminosities.
     */
    function getObjectLuminosity(bytes32 starSeed, MacroverseStarGenerator.ObjectClass objectClass, int128 realObjectMass) public view onlyControlledAccess returns (int128) {
        
        RNG.RandNode memory node = RNG.RandNode(starSeed);

        int128 realBaseLuminosity;
        if (objectClass == MacroverseStarGenerator.ObjectClass.BlackHole) {
            // Black hole luminosity is going to be from the accretion disk.
            // See <https://astronomy.stackexchange.com/q/12567>
            // We'll return pretty much whatever and user code can back-fill the accretion disk if any.
            if(node.derive("accretiondisk").getBool()) {
                // These aren't absurd masses; they're on the order of world annual food production per second.
                realBaseLuminosity = node.derive("luminosity").getRealBetween(RealMath.toReal(1), RealMath.toReal(5));
            } else {
                // No accretion disk
                realBaseLuminosity = 0;
            }
        } else if (objectClass == MacroverseStarGenerator.ObjectClass.NeutronStar) {
            // These will be dim and not really mass-related
            realBaseLuminosity = node.derive("luminosity").getRealBetween(RealMath.fraction(1, 20), RealMath.fraction(2, 10));
        } else if (objectClass == MacroverseStarGenerator.ObjectClass.WhiteDwarf) {
            // These are also dim
            realBaseLuminosity = RealMath.pow(realObjectMass.mul(REAL_HALF), RealMath.fraction(35, 10));
        } else {
            // Normal stars follow a normal mass-lumoinosity relationship
            realBaseLuminosity = RealMath.pow(realObjectMass, RealMath.fraction(35, 10));
        }
        
        // Perturb the generated luminosity for fun
        return realBaseLuminosity.mul(node.derive("luminosityScale").getRealBetween(RealMath.fraction(95, 100), RealMath.fraction(105, 100)));
    }

    /**
     * Get the inner and outer boundaries of the habitable zone for a star, in meters, based on its luminosity in solar luminosities.
     * This is just a rule-of-thumb; actual habitability is going to depend on atmosphere (see Venus, Mars)
     */
    function getObjectHabitableZone(int128 realLuminosity) public view onlyControlledAccess returns (int128 realInnerRadius, int128 realOuterRadius) {
        // Light per unit area scales with the square of the distance, so if we move twice as far out we get 1/4 the light.
        // So if our star is half as bright as the sun, the habitable zone radius is 1/sqrt(2) = sqrt(1/2) as big
        // So we scale this by the square root of the luminosity.
        int128 realScale = RealMath.sqrt(realLuminosity);
        // Wikipedia says nobody knows the bounds for Sol, but let's say 0.75 to 2.0 AU to be nice and round and also sort of average
        realInnerRadius = RealMath.toReal(112198400000).mul(realScale);
        realOuterRadius = RealMath.toReal(299195700000).mul(realScale);
    }

    /**
     * Get the Y and X axis angles for the rotational axis of the object, relative to galactic up.
     *
     * Defines a vector normal to the XY plane for the star system's local
     * coordinates, relative to which orbital inclinations are measured.
     *
     * The object's rotation axis starts straight up towards galactic +Z.
     * Then the object is rotated in Y, around the axis by the Y angle.
     * Then it is rotated forward (what would be toward the viewer) in the
     * object's transformed X by the X axis angle.
     * Both angles are in radians.
     * The X angle is never negative, because the Y angle would just be the opposite direction.
     * It is also never greater than Pi, because otherwise we would just measure around the other way.
     *
     * Most users won't need this unless they want to be able to work out
     * directions from things in one system to other systems.
     */
    function getObjectYXAxisAngles(bytes32 seed) public view onlyControlledAccess returns (int128 realYRadians, int128 realXRadians) {
        // The Y angle should be uniform over all angles.
        realYRadians = RNG.RandNode(seed).derive("axisy").getRealBetween(-REAL_PI, REAL_PI);

        // The X angle will also be uniform from 0 to pi.
        // This makes us pick a point in a flat 2d angle plane, so we will, on the sphere, have more density towards the poles.
        // See http://corysimon.github.io/articles/uniformdistn-on-sphere/
        // Being uniform on the sphere would require some trig, and non-uniformity makes sense since the galaxy has a preferred plane.
        realXRadians = RNG.RandNode(seed).derive("axisx").getRealBetween(0, REAL_PI);
        
    }

    

}

// This code is part of Macroverse and is licensed: UNLICENSED