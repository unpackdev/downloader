/**
SPDX-License-Identifier: UNLICENSED
See https://github.com/OpenZeppelin/openzeppelin-contracts/blob/2a0f2a8ba807b41360e7e092c3d5bb1bfbeb8b50/LICENSE and https://github.com/NovakDistributed/macroverse/blob/eea161aff5dba9d21204681a3b0f5dbe1347e54b/LICENSE
*/

pragma solidity ^0.6.10;


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
 * Library which exists to hold types shared across the Macroverse ecosystem.
 * Never actually needs to be linked into any dependents, since it has no functions.
 */
library Macroverse {

    /**
     * Define different types of planet or moon.
     * 
     * There are two main progressions:
     * Asteroidal, Lunar, Terrestrial, Jovian are rocky things.
     * Cometary, Europan, Panthalassic, Neptunian are icy/watery things, depending on temperature.
     * The last thing in each series is the gas/ice giant.
     *
     * Asteroidal and Cometary are only valid for moons; we don't track such tiny bodies at system scale.
     *
     * We also have rings and asteroid belts. Rings can only be around planets, and we fake the Roche limit math we really should do.
     * 
     */
    enum WorldClass {Asteroidal, Lunar, Terrestrial, Jovian, Cometary, Europan, Panthalassic, Neptunian, Ring, AsteroidBelt}

}

// This code is part of Macroverse and is licensed: UNLICENSED

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
 * Contains a portion of the MacroverseStstemGenerator implementation code.
 * The contract is split up due to contract size limitations.
 * We can't do access control here sadly.
 */
library MacroverseSystemGeneratorPart1 {
    // TODO: RNG doesn't get linked against because we can't pass the struct to the library...
    using RNG for *;
    using RealMath for *;
    // No SafeMath or it might confuse RealMath

    /**@dev
     * It is useful to have Pi around.
     * We can't pull it in from the library.
     */
    int128 constant REAL_PI = 3454217652358;

    /**@dev
     * Also perpare pi/2
     */
    int128 constant REAL_HALF_PI = REAL_PI >> 1;

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
     * What's two? Two is pretty useful.
     */
    int128 constant REAL_TWO = REAL_ONE << int128(1);

    /**@dev
     * And zero
     */
    int128 constant REAL_ZERO = 0;

    /**
     * Get the seed for a planet or moon from the seed for its parent (star or planet) and its child number.
     */
    function getWorldSeed(bytes32 parentSeed, uint16 childNumber) public pure returns (bytes32) {
        return RNG.RandNode(parentSeed).derive(uint(childNumber))._hash;
    }
    
    /**
     * Decide what kind of planet a given planet is.
     * It depends on its place in the order.
     * Takes the *planet*'s seed, its number, and the total planets in the system.
     */
    function getPlanetClass(bytes32 seed, uint16 planetNumber, uint16 totalPlanets) public pure returns (Macroverse.WorldClass) {
        // TODO: do something based on metallicity?
        RNG.RandNode memory node = RNG.RandNode(seed).derive("class");
        
        int88 roll = node.getIntBetween(0, 100);
        
        // Inner planets should be more planet-y, ideally smaller
        // Asteroid belts shouldn't be first that often
        
        if (planetNumber == 0 && totalPlanets != 1) {
            // Innermost planet of a multi-planet system
            // No asteroid belts allowed!
            // Also avoid too much watery stuff here because we don't want to deal with the water having been supposed to boil off.
            if (roll < 69) {
                return Macroverse.WorldClass.Lunar;
            } else if (roll < 70) {
                return Macroverse.WorldClass.Europan;
            } else if (roll < 79) {
                return Macroverse.WorldClass.Terrestrial;
            } else if (roll < 80) {
                return Macroverse.WorldClass.Panthalassic;
            } else if (roll < 90) {
                return Macroverse.WorldClass.Neptunian;
            } else {
                return Macroverse.WorldClass.Jovian;
            }
        } else if (planetNumber < totalPlanets / 2) {
            // Inner system
            if (roll < 15) {
                return Macroverse.WorldClass.Lunar;
            } else if (roll < 20) {
                return Macroverse.WorldClass.Europan;
            } else if (roll < 35) {
                return Macroverse.WorldClass.Terrestrial;
            } else if (roll < 40) {
                return Macroverse.WorldClass.Panthalassic;
            } else if (roll < 70) {
                return Macroverse.WorldClass.Neptunian;
            } else if (roll < 80) {
                return Macroverse.WorldClass.Jovian;
            } else {
                return Macroverse.WorldClass.AsteroidBelt;
            }
        } else {
            // Outer system
            if (roll < 5) {
                return Macroverse.WorldClass.Lunar;
            } else if (roll < 20) {
                return Macroverse.WorldClass.Europan;
            } else if (roll < 22) {
                return Macroverse.WorldClass.Terrestrial;
            } else if (roll < 30) {
                return Macroverse.WorldClass.Panthalassic;
            } else if (roll < 60) {
                return Macroverse.WorldClass.Neptunian;
            } else if (roll < 90) {
                return Macroverse.WorldClass.Jovian;
            } else {
                return Macroverse.WorldClass.AsteroidBelt;
            }
        }
    }
    
    /**
     * Decide what the mass of the planet or moon is. We can't do even the mass of
     * Jupiter in the ~88 bits we have in a real (should we have used int256 as
     * the backing type?) so we work in Earth masses.
     *
     * Also produces the masses for moons.
     */
    function getWorldMass(bytes32 seed, Macroverse.WorldClass class) public pure returns (int128) {
        RNG.RandNode memory node = RNG.RandNode(seed).derive("mass");
        
        if (class == Macroverse.WorldClass.Asteroidal) {
            // For tiny bodies like this we work in nano-earths
            return node.getRealBetween(RealMath.fraction(1, 1000000000), RealMath.fraction(10, 1000000000));
        } else if (class == Macroverse.WorldClass.Cometary) {
            return node.getRealBetween(RealMath.fraction(1, 1000000000), RealMath.fraction(10, 1000000000));
        } else if (class == Macroverse.WorldClass.Lunar) {
            return node.getRealBetween(RealMath.fraction(1, 100), RealMath.fraction(9, 100));
        } else if (class == Macroverse.WorldClass.Europan) {
            return node.getRealBetween(RealMath.fraction(8, 1000), RealMath.fraction(80, 1000));
        } else if (class == Macroverse.WorldClass.Terrestrial) {
            return node.getRealBetween(RealMath.fraction(10, 100), RealMath.toReal(9));
        } else if (class == Macroverse.WorldClass.Panthalassic) {
            return node.getRealBetween(RealMath.fraction(80, 1000), RealMath.toReal(9));
        } else if (class == Macroverse.WorldClass.Neptunian) {
            return node.getRealBetween(RealMath.toReal(7), RealMath.toReal(20));
        } else if (class == Macroverse.WorldClass.Jovian) {
            return node.getRealBetween(RealMath.toReal(50), RealMath.toReal(400));
        } else if (class == Macroverse.WorldClass.AsteroidBelt) {
            return node.getRealBetween(RealMath.fraction(1, 100), RealMath.fraction(20, 100));
        } else if (class == Macroverse.WorldClass.Ring) {
            // Saturn's rings are maybe about 5-15 micro-earths
            return node.getRealBetween(RealMath.fraction(1, 1000000), RealMath.fraction(20, 1000000));
        } else {
            // Not real!
            revert();
        }
    }
    
    // Define the orbit shape

    /**
     * Given the parent star's habitable zone bounds, the planet seed, the planet class
     * to be generated, and the "clearance" radius around the previous planet
     * in meters, produces orbit statistics (periapsis, apoapsis, and
     * clearance) in meters.
     *
     * The first planet uses a previous clearance of 0.
     *
     * TODO: realOuterRadius from the habitable zone never gets used. We should remove it.
     */
    function getPlanetOrbitDimensions(int128 realInnerRadius, int128 realOuterRadius, bytes32 seed, Macroverse.WorldClass class, int128 realPrevClearance)
        public pure returns (int128 realPeriapsis, int128 realApoapsis, int128 realClearance) {

        // We scale all the random generation around the habitable zone distance.

        // Make the planet RNG node to use for all the computations
        RNG.RandNode memory node = RNG.RandNode(seed);
        
        // Compute the statistics with their own functions
        realPeriapsis = getPlanetPeriapsis(realInnerRadius, realOuterRadius, node, class, realPrevClearance);
        realApoapsis = getPlanetApoapsis(realInnerRadius, realOuterRadius, node, class, realPeriapsis);
        realClearance = getPlanetClearance(realInnerRadius, realOuterRadius, node, class, realApoapsis);
    }

    /**
     * Decide what the planet's orbit's periapsis is, in meters.
     * This is the first statistic about the orbit to be generated.
     *
     * For the first planet, realPrevClearance is 0. For others, it is the
     * clearance (i.e. distance from star that the planet has cleared out) of
     * the previous planet.
     */
    function getPlanetPeriapsis(int128 realInnerRadius, int128 /* realOuterRadius */, RNG.RandNode memory planetNode, Macroverse.WorldClass class, int128 realPrevClearance)
        internal pure returns (int128) {
        
        // We're going to sample 2 values and take the minimum, to get a nicer distribution than uniform.
        // We really kind of want a log scale but that's expensive.
        RNG.RandNode memory node1 = planetNode.derive("periapsis");
        RNG.RandNode memory node2 = planetNode.derive("periapsis2");
        
        // Define minimum and maximum periapsis distance above previous planet's
        // cleared band. Work in % of the habitable zone inner radius.
        int88 minimum;
        int88 maximum;
        if (class == Macroverse.WorldClass.Lunar || class == Macroverse.WorldClass.Europan) {
            minimum = 20;
            maximum = 60;
        } else if (class == Macroverse.WorldClass.Terrestrial || class == Macroverse.WorldClass.Panthalassic) {
            minimum = 20;
            maximum = 70;
        } else if (class == Macroverse.WorldClass.Neptunian) {
            minimum = 50;
            maximum = 1000;
        } else if (class == Macroverse.WorldClass.Jovian) {
            minimum = 300;
            maximum = 500;
        } else if (class == Macroverse.WorldClass.AsteroidBelt) {
            minimum = 20;
            maximum = 500;
        } else {
            // Not real!
            revert();
        }
        
        int128 realSeparation1 = node1.getRealBetween(RealMath.toReal(minimum), RealMath.toReal(maximum));
        int128 realSeparation2 = node2.getRealBetween(RealMath.toReal(minimum), RealMath.toReal(maximum));
        int128 realSeparation = realSeparation1 < realSeparation2 ? realSeparation1 : realSeparation2;
        return realPrevClearance + RealMath.mul(realSeparation, realInnerRadius).div(RealMath.toReal(100)); 
    }
    
    /**
     * Decide what the planet's orbit's apoapsis is, in meters.
     * This is the second statistic about the orbit to be generated.
     */
    function getPlanetApoapsis(int128 realInnerRadius, int128 /* realOuterRadius */, RNG.RandNode memory planetNode, Macroverse.WorldClass class, int128 realPeriapsis)
        internal pure returns (int128) {
        
        RNG.RandNode memory node1 = planetNode.derive("apoapsis");
        RNG.RandNode memory node2 = planetNode.derive("apoapsis2");
        
        // Define minimum and maximum apoapsis distance above planet's periapsis.
        // Work in % of the habitable zone inner radius.
        int88 minimum;
        int88 maximum;
        if (class == Macroverse.WorldClass.Lunar || class == Macroverse.WorldClass.Europan) {
            minimum = 0;
            maximum = 6;
        } else if (class == Macroverse.WorldClass.Terrestrial || class == Macroverse.WorldClass.Panthalassic) {
            minimum = 0;
            maximum = 10;
        } else if (class == Macroverse.WorldClass.Neptunian) {
            minimum = 20;
            maximum = 500;
        } else if (class == Macroverse.WorldClass.Jovian) {
            minimum = 10;
            maximum = 200;
        } else if (class == Macroverse.WorldClass.AsteroidBelt) {
            minimum = 10;
            maximum = 100;
        } else {
            // Not real!
            revert();
        }
        
        int128 realWidth1 = node1.getRealBetween(RealMath.toReal(minimum), RealMath.toReal(maximum));
        int128 realWidth2 = node2.getRealBetween(RealMath.toReal(minimum), RealMath.toReal(maximum));
        int128 realWidth = realWidth1 < realWidth2 ? realWidth1 : realWidth2; 
        return realPeriapsis + RealMath.mul(realWidth, realInnerRadius).div(RealMath.toReal(100)); 
    }
    
    /**
     * Decide how far out the cleared band after the planet's orbit is.
     */
    function getPlanetClearance(int128 realInnerRadius, int128 /* realOuterRadius */, RNG.RandNode memory planetNode, Macroverse.WorldClass class, int128 realApoapsis)
        internal pure returns (int128) {
        
        RNG.RandNode memory node1 = planetNode.derive("cleared");
        RNG.RandNode memory node2 = planetNode.derive("cleared2");
        
        // Define minimum and maximum clearance.
        // Work in % of the habitable zone inner radius.
        int88 minimum;
        int88 maximum;
        if (class == Macroverse.WorldClass.Lunar || class == Macroverse.WorldClass.Europan) {
            minimum = 20;
            maximum = 60;
        } else if (class == Macroverse.WorldClass.Terrestrial || class == Macroverse.WorldClass.Panthalassic) {
            minimum = 40;
            maximum = 70;
        } else if (class == Macroverse.WorldClass.Neptunian) {
            minimum = 300;
            maximum = 700;
        } else if (class == Macroverse.WorldClass.Jovian) {
            minimum = 300;
            maximum = 500;
        } else if (class == Macroverse.WorldClass.AsteroidBelt) {
            minimum = 20;
            maximum = 500;
        } else {
            // Not real!
            revert();
        }
        
        int128 realSeparation1 = node1.getRealBetween(RealMath.toReal(minimum), RealMath.toReal(maximum));
        int128 realSeparation2 = node2.getRealBetween(RealMath.toReal(minimum), RealMath.toReal(maximum));
        int128 realSeparation = realSeparation1 < realSeparation2 ? realSeparation1 : realSeparation2;
        return realApoapsis + RealMath.mul(realSeparation, realInnerRadius).div(RealMath.toReal(100)); 
    }
}

// This code is part of Macroverse and is licensed: UNLICENSED

/**
 * Contains a portion of the MacroverseStstemGenerator implementation code.
 * The contract is split up due to contract size limitations.
 * We can't do access control here sadly.
 */
library MacroverseSystemGeneratorPart2 {
    using RNG for *;
    using RealMath for *;
    // No SafeMath or it might confuse RealMath

    /**@dev
     * It is useful to have Pi around.
     * We can't pull it in from the library.
     */
    int128 constant REAL_PI = 3454217652358;

    /**@dev
     * Also perpare pi/2
     */
    int128 constant REAL_HALF_PI = REAL_PI >> 1;

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
     * What's two? Two is pretty useful.
     */
    int128 constant REAL_TWO = REAL_ONE << int128(1);

    /**@dev
     * And zero
     */
    int128 constant REAL_ZERO = 0;
    
    /**
     * Convert from periapsis and apoapsis to semimajor axis and eccentricity.
     */
    function convertOrbitShape(int128 realPeriapsis, int128 realApoapsis) public pure returns (int128 realSemimajor, int128 realEccentricity) {
        // Semimajor axis is average of apoapsis and periapsis
        realSemimajor = RealMath.div(realApoapsis + realPeriapsis, RealMath.toReal(2));
        
        // Eccentricity is ratio of difference and sum
        realEccentricity = RealMath.div(realApoapsis - realPeriapsis, realApoapsis + realPeriapsis);
    }
    
    // Define the orbital plane
    
    /**
     * Get the longitude of the ascending node for a planet or moon. For
     * planets, this is the angle from system +X to ascending node. For
     * moons, we use system +X transformed into the planet's equatorial plane
     * by the equatorial plane/rotation axis angles.
     */ 
    function getWorldLan(bytes32 seed) public pure returns (int128) {
        RNG.RandNode memory node = RNG.RandNode(seed).derive("LAN");
        // Angles should be uniform from 0 to 2 PI
        return node.getRealBetween(RealMath.toReal(0), RealMath.mul(RealMath.toReal(2), REAL_PI));
    }
    
    /**
     * Get the inclination (angle from system XZ plane to orbital plane at the ascending node) for a planet.
     * For a moon, this is done in the moon generator instead.
     * Inclination is always positive. If it were negative, the ascending node would really be the descending node.
     * Result is a real in radians.
     */ 
    function getPlanetInclination(bytes32 seed, Macroverse.WorldClass class) public pure returns (int128) {
        RNG.RandNode memory node = RNG.RandNode(seed).derive("inclination");
    
        // Define minimum and maximum inclinations in milliradians
        // 175 milliradians = ~ 10 degrees
        int88 minimum;
        int88 maximum;
        if (class == Macroverse.WorldClass.Lunar || class == Macroverse.WorldClass.Europan) {
            minimum = 0;
            maximum = 175;
        } else if (class == Macroverse.WorldClass.Terrestrial || class == Macroverse.WorldClass.Panthalassic) {
            minimum = 0;
            maximum = 87;
        } else if (class == Macroverse.WorldClass.Neptunian) {
            minimum = 0;
            maximum = 35;
        } else if (class == Macroverse.WorldClass.Jovian) {
            minimum = 0;
            maximum = 52;
        } else if (class == Macroverse.WorldClass.AsteroidBelt) {
            minimum = 0;
            maximum = 262;
        } else {
            // Not real!
            revert();
        }
        
        // Decide if we should be retrograde (PI-ish inclination)
        int128 real_retrograde_offset = 0;
        if (node.derive("retrograde").d(1, 100, 0) < 3) {
            // This planet ought to move retrograde
            real_retrograde_offset = REAL_PI;
        }

        return real_retrograde_offset + RealMath.div(node.getRealBetween(RealMath.toReal(minimum), RealMath.toReal(maximum)), RealMath.toReal(1000));    
    }
    
    // Define the orbit's embedding in the plane (and in time)
    
    /**
     * Get the argument of periapsis (angle from ascending node to periapsis position, in the orbital plane) for a planet or moon.
     */
    function getWorldAop(bytes32 seed) public pure returns (int128) {
        RNG.RandNode memory node = RNG.RandNode(seed).derive("AOP");
        // Angles should be uniform from 0 to 2 PI.
        // We already made sure planets/moons wouldn't get too close together when laying out the orbits.
        return node.getRealBetween(RealMath.toReal(0), RealMath.mul(RealMath.toReal(2), REAL_PI));
    }
    
    /**
     * Get the mean anomaly (which sweeps from 0 at periapsis to 2 pi at the next periapsis) at epoch (time 0) for a planet or moon.
     */
    function getWorldMeanAnomalyAtEpoch(bytes32 seed) public pure returns (int128) {
        RNG.RandNode memory node = RNG.RandNode(seed).derive("MAE");
        // Angles should be uniform from 0 to 2 PI.
        return node.getRealBetween(RealMath.toReal(0), RealMath.mul(RealMath.toReal(2), REAL_PI));
    }

    /**
     * Determine if the world is tidally locked, given its seed and its number
     * out from the parent, starting with 0.
     * Overrides getWorldZXAxisAngles and getWorldSpinRate. 
     * Not used for asteroid belts or rings.
     */
    function isTidallyLocked(bytes32 seed, uint16 worldNumber) public pure returns (bool) {
        // Tidal lock should be common near the parent and less common further out.
        return RNG.RandNode(seed).derive("tidal_lock").getReal() < RealMath.fraction(1, int88(worldNumber + 1));
    }

    /**
     * Get the Y and X axis angles for a world, in radians.
     * The world's rotation axis starts straight up in its orbital plane.
     * Then the planet is rotated in Y, around the axis by the Y angle.
     * Then it is rotated forward (what would be toward the pureer) in the
     * world's transformed X by the X axis angle.
     * Both angles are in radians.
     * The X angle is never negative, because the Y angle would just be the opposite direction.
     * It is also never greater than Pi, because otherwise we would just measure around the other way.
     * Not used for asteroid belts or rings.
     * For a tidally locked world, ignore these values and use 0 for both angles.
     */
    function getWorldYXAxisAngles(bytes32 seed) public pure returns (int128 realYRadians, int128 realXRadians) {
       
        // The Y angle should be uniform over all angles.
        realYRadians = RNG.RandNode(seed).derive("axisy").getRealBetween(-REAL_PI, REAL_PI);

        // The X angle will be mostly small positive or negative, with some sideways and some near Pi/2 (meaning retrograde rotation)
        int16 tilt_die = RNG.RandNode(seed).derive("tilt").d(1, 6, 0);
        
        // Start with low tilt, right side up
        // Earth is like 0.38 radians overall
        int128 real_tilt_limit = REAL_HALF;
        if (tilt_die >= 5) {
            // Be high tilt
            real_tilt_limit = REAL_HALF_PI;
        }
    
        RNG.RandNode memory x_node = RNG.RandNode(seed).derive("axisx");
        realXRadians = x_node.getRealBetween(0, real_tilt_limit);

        if (tilt_die == 4 || tilt_die == 5) {
            // Flip so the tilt we have is relative to upside-down
            realXRadians = REAL_PI - realXRadians;
        }

        // So we should have 1/2 low tilt prograde, 1/6 low tilt retrograde, 1/6 high tilt retrograde, and 1/6 high tilt prograde
    }

    /**
     * Get the spin rate of the world in radians per Julian year around its axis.
     * For a tidally locked world, ignore this value and use the mean angular
     * motion computed by the OrbitalMechanics contract, given the orbit
     * details.
     * Not used for asteroid belts or rings.
     */
    function getWorldSpinRate(bytes32 seed) public pure returns (int128) {
        // Earth is something like 2k radians per Julian year.
        return RNG.RandNode(seed).derive("spin").getRealBetween(REAL_ZERO, RealMath.toReal(8000)); 
    }

}

// This code is part of Macroverse and is licensed: UNLICENSED

/**
 * Represents a Macroverse generator for planetary systems around stars and
 * other stellar objects.
 *
 * Because of contract size limitations, some code in this contract is shared
 * between planets and moons, while some code is planet-specific. Moon-specific
 * code lives in the MacroverseMoonGenerator.
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
contract MacroverseSystemGenerator is ControlledAccess {
    

    /**
     * Deploy a new copy of the MacroverseSystemGenerator.
     */
    constructor(address accessControlAddress) ControlledAccess(accessControlAddress) public {
        // Nothing to do!
    }
    
    /**
     * Get the seed for a planet or moon from the seed for its parent (star or planet) and its child number.
     */
    function getWorldSeed(bytes32 parentSeed, uint16 childNumber) public view onlyControlledAccess returns (bytes32) {
        return MacroverseSystemGeneratorPart1.getWorldSeed(parentSeed, childNumber);
    }
    
    /**
     * Decide what kind of planet a given planet is.
     * It depends on its place in the order.
     * Takes the *planet*'s seed, its number, and the total planets in the system.
     */
    function getPlanetClass(bytes32 seed, uint16 planetNumber, uint16 totalPlanets) public view onlyControlledAccess returns (Macroverse.WorldClass) {
        return MacroverseSystemGeneratorPart1.getPlanetClass(seed, planetNumber, totalPlanets);
    }
    
    /**
     * Decide what the mass of the planet or moon is. We can't do even the mass of
     * Jupiter in the ~88 bits we have in a real (should we have used int256 as
     * the backing type?) so we work in Earth masses.
     *
     * Also produces the masses for moons.
     */
    function getWorldMass(bytes32 seed, Macroverse.WorldClass class) public view onlyControlledAccess returns (int128) {
        return MacroverseSystemGeneratorPart1.getWorldMass(seed, class);
    }
    
    // Define the orbit shape

    /**
     * Given the parent star's habitable zone bounds, the planet seed, the planet class
     * to be generated, and the "clearance" radius around the previous planet
     * in meters, produces orbit statistics (periapsis, apoapsis, and
     * clearance) in meters.
     *
     * The first planet uses a previous clearance of 0.
     *
     * TODO: realOuterRadius from the habitable zone never gets used. We should remove it.
     */
    function getPlanetOrbitDimensions(int128 realInnerRadius, int128 realOuterRadius, bytes32 seed, Macroverse.WorldClass class, int128 realPrevClearance)
        public view onlyControlledAccess returns (int128 realPeriapsis, int128 realApoapsis, int128 realClearance) {
        
        return MacroverseSystemGeneratorPart1.getPlanetOrbitDimensions(realInnerRadius, realOuterRadius, seed, class, realPrevClearance);
    }

    /**
     * Convert from periapsis and apoapsis to semimajor axis and eccentricity.
     */
    function convertOrbitShape(int128 realPeriapsis, int128 realApoapsis) public view onlyControlledAccess returns (int128 realSemimajor, int128 realEccentricity) {
        return MacroverseSystemGeneratorPart2.convertOrbitShape(realPeriapsis, realApoapsis);
    }
    
    // Define the orbital plane
    
    /**
     * Get the longitude of the ascending node for a planet or moon. For
     * planets, this is the angle from system +X to ascending node. For
     * moons, we use system +X transformed into the planet's equatorial plane
     * by the equatorial plane/rotation axis angles.
     */ 
    function getWorldLan(bytes32 seed) public view onlyControlledAccess returns (int128) {
        return MacroverseSystemGeneratorPart2.getWorldLan(seed);
    }
    
    /**
     * Get the inclination (angle from system XZ plane to orbital plane at the ascending node) for a planet.
     * For a moon, this is done in the moon generator instead.
     * Inclination is always positive. If it were negative, the ascending node would really be the descending node.
     * Result is a real in radians.
     */ 
    function getPlanetInclination(bytes32 seed, Macroverse.WorldClass class) public view onlyControlledAccess returns (int128) {
        return MacroverseSystemGeneratorPart2.getPlanetInclination(seed, class);
    }
    
    // Define the orbit's embedding in the plane (and in time)
    
    /**
     * Get the argument of periapsis (angle from ascending node to periapsis position, in the orbital plane) for a planet or moon.
     */
    function getWorldAop(bytes32 seed) public view onlyControlledAccess returns (int128) {
        return MacroverseSystemGeneratorPart2.getWorldAop(seed);
    }
    
    /**
     * Get the mean anomaly (which sweeps from 0 at periapsis to 2 pi at the next periapsis) at epoch (time 0) for a planet or moon.
     */
    function getWorldMeanAnomalyAtEpoch(bytes32 seed) public view onlyControlledAccess returns (int128) {
        return MacroverseSystemGeneratorPart2.getWorldMeanAnomalyAtEpoch(seed);
    }

    /**
     * Determine if the world is tidally locked, given its seed and its number
     * out from the parent, starting with 0.
     * Overrides getWorldZXAxisAngles and getWorldSpinRate. 
     * Not used for asteroid belts or rings.
     */
    function isTidallyLocked(bytes32 seed, uint16 worldNumber) public view onlyControlledAccess returns (bool) {
        return MacroverseSystemGeneratorPart2.isTidallyLocked(seed, worldNumber);
    }

    /**
     * Get the Y and X axis angles for a world, in radians.
     * The world's rotation axis starts straight up in its orbital plane.
     * Then the planet is rotated in Y, around the axis by the Y angle.
     * Then it is rotated forward (what would be toward the viewer) in the
     * world's transformed X by the X axis angle.
     * Both angles are in radians.
     * The X angle is never negative, because the Y angle would just be the opposite direction.
     * It is also never greater than Pi, because otherwise we would just measure around the other way.
     * Not used for asteroid belts or rings.
     * For a tidally locked world, ignore these values and use 0 for both angles.
     */
    function getWorldYXAxisAngles(bytes32 seed) public view onlyControlledAccess returns (int128 realYRadians, int128 realXRadians) {
        return MacroverseSystemGeneratorPart2.getWorldYXAxisAngles(seed); 
    }

    /**
     * Get the spin rate of the world in radians per Julian year around its axis.
     * For a tidally locked world, ignore this value and use the mean angular
     * motion computed by the OrbitalMechanics contract, given the orbit
     * details.
     * Not used for asteroid belts or rings.
     */
    function getWorldSpinRate(bytes32 seed) public view onlyControlledAccess returns (int128) {
        return MacroverseSystemGeneratorPart2.getWorldSpinRate(seed);
    }

}

// This code is part of Macroverse and is licensed: UNLICENSED