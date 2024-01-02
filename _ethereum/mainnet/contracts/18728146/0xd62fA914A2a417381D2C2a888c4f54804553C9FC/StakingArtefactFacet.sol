// Sources flattened with hardhat v2.16.1 https://hardhat.org

// File @openzeppelin/contracts/utils/math/Math.sol@v4.9.2

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}


// File @openzeppelin/contracts/utils/math/SignedMath.sol@v4.9.2

// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}


// File @openzeppelin/contracts/utils/Strings.sol@v4.9.2

// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;


/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}


// File @openzeppelin/contracts/utils/Context.sol@v4.9.2

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File @openzeppelin/contracts/utils/Counters.sol@v4.9.2

// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}


// File contracts/libraries/LibConstants.sol
pragma solidity ^0.8.0;

library LibConstants {
    address constant STAKED_ADDRESS = 0xeDEdEDedeDEdeDeDedeDEDeDEdEdededeDeDEdED;
    uint16 constant PERCENT_UNIT = 100; // 1%
    uint16 constant MAX_PERCENTAGE = 100 * PERCENT_UNIT; // 100%
    uint8 constant DEFAULT_NETWORK_ID = 137;
    uint32 constant RANK_DIFF_BLOCK_DIST = 1300000;
    uint8 constant MAX_RANK = 10;
}


// File contracts/interfaces/IDiamondCut.sol

pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}


// File contracts/libraries/LibDiamond.sol

pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct DiamondStorage {
        // maps function selectors to the facets that execute the functions.
        // and maps the selectors to their position in the selectorSlots array.
        // func selector => address facet, selector position
        mapping(bytes4 => bytes32) facets;
        // array of slots of function selectors.
        // each slot holds 8 function selectors.
        mapping(uint256 => bytes32) selectorSlots;
        // The number of function selectors in selectorSlots
        uint16 selectorCount;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    bytes32 constant CLEAR_ADDRESS_MASK = bytes32(uint256(0xffffffffffffffffffffffff));
    bytes32 constant CLEAR_SELECTOR_MASK = bytes32(uint256(0xffffffff << 224));

    // Internal function version of diamondCut
    // This code is almost the same as the external diamondCut,
    // except it is using 'Facet[] memory _diamondCut' instead of
    // 'Facet[] calldata _diamondCut'.
    // The code is duplicated to prevent copying calldata to memory which
    // causes an error for a two dimensional array.
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        DiamondStorage storage ds = diamondStorage();
        uint256 originalSelectorCount = ds.selectorCount;
        uint256 selectorCount = originalSelectorCount;
        bytes32 selectorSlot;
        // Check if last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8" 
        if (selectorCount & 7 > 0) {
            // get last selectorSlot
            // "selectorSlot >> 3" is a gas efficient division by 8 "selectorSlot / 8"
            selectorSlot = ds.selectorSlots[selectorCount >> 3];
        }
        // loop through diamond cut
        for (uint256 facetIndex; facetIndex < _diamondCut.length; ) {
            (selectorCount, selectorSlot) = addReplaceRemoveFacetSelectors(
                selectorCount,
                selectorSlot,
                _diamondCut[facetIndex].facetAddress,
                _diamondCut[facetIndex].action,
                _diamondCut[facetIndex].functionSelectors
            );

            unchecked {
                facetIndex++;
            }
        }
        if (selectorCount != originalSelectorCount) {
            ds.selectorCount = uint16(selectorCount);
        }
        // If last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8" 
        if (selectorCount & 7 > 0) {
            // "selectorSlot >> 3" is a gas efficient division by 8 "selectorSlot / 8"
            ds.selectorSlots[selectorCount >> 3] = selectorSlot;
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addReplaceRemoveFacetSelectors(
        uint256 _selectorCount,
        bytes32 _selectorSlot,
        address _newFacetAddress,
        IDiamondCut.FacetCutAction _action,
        bytes4[] memory _selectors
    ) internal returns (uint256, bytes32) {
        DiamondStorage storage ds = diamondStorage();
        require(_selectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        if (_action == IDiamondCut.FacetCutAction.Add) {
            enforceHasContractCode(_newFacetAddress, "LibDiamondCut: Add facet has no code");
            for (uint256 selectorIndex; selectorIndex < _selectors.length; ) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                require(address(bytes20(oldFacet)) == address(0), "LibDiamondCut: Can't add function that already exists");
                // add facet for selector
                ds.facets[selector] = bytes20(_newFacetAddress) | bytes32(_selectorCount);
                // "_selectorCount & 7" is a gas efficient modulo by eight "_selectorCount % 8" 
                // " << 5 is the same as multiplying by 32 ( * 32)
                uint256 selectorInSlotPosition = (_selectorCount & 7) << 5;
                // clear selector position in slot and add selector
                _selectorSlot = (_selectorSlot & ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) | (bytes32(selector) >> selectorInSlotPosition);
                // if slot is full then write it to storage
                if (selectorInSlotPosition == 224) {
                    // "_selectorSlot >> 3" is a gas efficient division by 8 "_selectorSlot / 8"
                    ds.selectorSlots[_selectorCount >> 3] = _selectorSlot;
                    _selectorSlot = 0;
                }
                _selectorCount++;

                unchecked {
                    selectorIndex++;
                }
            }
        } else if (_action == IDiamondCut.FacetCutAction.Replace) {
            enforceHasContractCode(_newFacetAddress, "LibDiamondCut: Replace facet has no code");
            for (uint256 selectorIndex; selectorIndex < _selectors.length; ) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                address oldFacetAddress = address(bytes20(oldFacet));
                // only useful if immutable functions exist
                require(oldFacetAddress != address(this), "LibDiamondCut: Can't replace immutable function");
                require(oldFacetAddress != _newFacetAddress, "LibDiamondCut: Can't replace function with same function");
                require(oldFacetAddress != address(0), "LibDiamondCut: Can't replace function that doesn't exist");
                // replace old facet address
                ds.facets[selector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(_newFacetAddress);

                unchecked {
                    selectorIndex++;
                }
            }
        } else if (_action == IDiamondCut.FacetCutAction.Remove) {
            require(_newFacetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
            // "_selectorCount >> 3" is a gas efficient division by 8 "_selectorCount / 8"
            uint256 selectorSlotCount = _selectorCount >> 3;
            // "_selectorCount & 7" is a gas efficient modulo by eight "_selectorCount % 8" 
            uint256 selectorInSlotIndex = _selectorCount & 7;
            for (uint256 selectorIndex; selectorIndex < _selectors.length; ) {
                if (_selectorSlot == 0) {
                    // get last selectorSlot
                    selectorSlotCount--;
                    _selectorSlot = ds.selectorSlots[selectorSlotCount];
                    selectorInSlotIndex = 7;
                } else {
                    selectorInSlotIndex--;
                }
                bytes4 lastSelector;
                uint256 oldSelectorsSlotCount;
                uint256 oldSelectorInSlotPosition;
                // adding a block here prevents stack too deep error
                {
                    bytes4 selector = _selectors[selectorIndex];
                    bytes32 oldFacet = ds.facets[selector];
                    require(address(bytes20(oldFacet)) != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
                    // only useful if immutable functions exist
                    require(address(bytes20(oldFacet)) != address(this), "LibDiamondCut: Can't remove immutable function");
                    // replace selector with last selector in ds.facets
                    // gets the last selector
                    // " << 5 is the same as multiplying by 32 ( * 32)
                    lastSelector = bytes4(_selectorSlot << (selectorInSlotIndex << 5));
                    if (lastSelector != selector) {
                        // update last selector slot position info
                        ds.facets[lastSelector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(ds.facets[lastSelector]);
                    }
                    delete ds.facets[selector];
                    uint256 oldSelectorCount = uint16(uint256(oldFacet));
                    // "oldSelectorCount >> 3" is a gas efficient division by 8 "oldSelectorCount / 8"
                    oldSelectorsSlotCount = oldSelectorCount >> 3;
                    // "oldSelectorCount & 7" is a gas efficient modulo by eight "oldSelectorCount % 8" 
                    // " << 5 is the same as multiplying by 32 ( * 32)
                    oldSelectorInSlotPosition = (oldSelectorCount & 7) << 5;
                }
                if (oldSelectorsSlotCount != selectorSlotCount) {
                    bytes32 oldSelectorSlot = ds.selectorSlots[oldSelectorsSlotCount];
                    // clears the selector we are deleting and puts the last selector in its place.
                    oldSelectorSlot =
                        (oldSelectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                    // update storage with the modified slot
                    ds.selectorSlots[oldSelectorsSlotCount] = oldSelectorSlot;
                } else {
                    // clears the selector we are deleting and puts the last selector in its place.
                    _selectorSlot =
                        (_selectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                }
                if (selectorInSlotIndex == 0) {
                    delete ds.selectorSlots[selectorSlotCount];
                    _selectorSlot = 0;
                }

                unchecked {
                    selectorIndex++;
                }
            }
            _selectorCount = selectorSlotCount * 8 + selectorInSlotIndex;
        } else {
            revert("LibDiamondCut: Incorrect FacetCutAction");
        }
        return (_selectorCount, _selectorSlot);
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            return;
        }
        enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");        
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                // bubble up error
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert InitializationFunctionReverted(_init, _calldata);
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}


// File contracts/interfaces/IStakeManager.sol

pragma solidity ^0.8.17;

/**
 * 
 * Source: https://etherscan.io/address/0xba9ac3c9983a3e967f0f387c75ccbd38ad484963#code
 * 
 */

interface IStakeManager {
    enum Status {Inactive, Active, Locked, Unstaked}

    struct Validator {
        uint256 amount;
        uint256 reward;
        uint256 activationEpoch;
        uint256 deactivationEpoch;
        uint256 jailTime;
        address signer;
        address contractAddress;
        Status status;
        uint256 commissionRate;
        uint256 lastCommissionUpdate;
        uint256 delegatorsReward;
        uint256 delegatedAmount;
        uint256 initialRewardPerStake;
    }

    // mapping(uint256 => Validator) public validators;

    function validators(uint256 validatorId) external view returns (Validator memory);
}


// File @openzeppelin/contracts/token/ERC20/IERC20.sol@v4.9.2

// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}


// File contracts/interfaces/IValidatorShare.sol

pragma solidity ^0.8.17;

interface IValidatorShare is IERC20 {
  function validatorId() external view returns (uint256);
}


// File contracts/libraries/LibERC721.sol

pragma solidity ^0.8.0;





library LibERC721 {

    using Counters for Counters.Counter;

    bytes32 constant ERC721_POSITION = keccak256("erc721.storage");

    struct TokenData {
        uint8 kindId; // 1: Boost APR ; 2: commission fees refunds ; 3: gas refunds; 4: gagnant d'un prix? 
        uint8 initialRankOffset; // 24 (if deleted we can have rewardedEver stored)
        uint16 percentage; // default: 0 = 0
        uint8 maxRewardPerYear; // default: 0 (unlimited) // 32
        uint128 receivedAtBlock; // rank not needed because computed based on receivedAtBlock // 96
    }

    struct ERC721Storage {
        string name;
        string symbol;

        Counters.Counter currentTokenId;
        Counters.Counter burnedToken;

        mapping (uint256 => address) _owners;
        mapping (address => uint256) _balances;

        // Mapping from token ID to approved address
        mapping(uint256 => address) _tokenApprovals;

        // Mapping from owner to operator approvals
        mapping(address => mapping(address => bool)) _operatorApprovals;

        mapping (uint256 => TokenData) tokenIdToData;

        mapping(uint256 => string) rankIdToRankName; // what is the name of the rank of rank ID
        mapping(uint256 => string) kindIdToKindName; // what is the name of the kind of kind ID
        
        mapping(uint256 => address) stakedArtefactHolder; // what is the address who staked the tokenId
        mapping(uint256 => mapping (address => uint256)) stakedArtefactByKindIdAndAddress; // staked tokenId for a kindId and an address
        mapping(address => address) rewardedAddress;
        mapping(address => uint256) rewardedNetwork;

        mapping (uint256 => string) additionalAttributes; // tokenId => json string

        uint256 nodeAPR; // 5% = 500
        string baseImageURI; // Base image URI for OWNART NFTs
        string description;

        IStakeManager stakeManager;
        IValidatorShare validatorShare;
        bool shouldFreezeCalculations;

        mapping(uint256 => uint16) kindIdToAdditionnalBoost; // kindId => boost
        mapping(uint256 => uint16) tokenIdToAdditionnalBoost; // kindId => max boost
    }

    // Return ERC721 storage struct for reading and writing
    function getStorage() internal pure returns (ERC721Storage storage storageStruct) {
        bytes32 position = ERC721_POSITION;
        assembly {
            storageStruct.slot := position
        }
    }

    function init(IStakeManager _stakeManager, IValidatorShare _validatorShare) internal {
        LibDiamond.enforceIsContractOwner();
        ERC721Storage storage s = getStorage();
        s.name = "PolStaking Artefacts";
        s.symbol = "PSA";
        s.nodeAPR = 500;
        s.baseImageURI = "http://storage.polstaking.io/image/";
        s.description = "Holding this NFT gives special bonuses if you're staking on Ownest validator (#47)! Ahoy there, adventurer! Have you heard of the mystical card that grants its owner the power to vanquish the vexing commissions on the Ownest validator node 47 of the treacherous Polygon network? With this mighty card in hand, you can boldly navigate the perilous waters of the blockchain and reap the rewards that await you at the end of your journey. The riches you seek will be sent straight to your rewarded address on the very network you fought so valiantly to conquer, or they can be claimed through the Ownest staking reward contract, the gateway to the vast treasures of the blockchain. So hoist your sails and set forth on your adventure, for with this card in your possession, the rewards are truly limitless!";
        s.stakeManager = _stakeManager;
        s.validatorShare = _validatorShare;

        s.rankIdToRankName[1] = "Venerable";
        s.rankIdToRankName[2] = "Veteran";
        s.rankIdToRankName[3] = "Regular";
        s.rankIdToRankName[4] = "Rookie";

        s.kindIdToKindName[1] = "APR Boost";
        s.kindIdToKindName[2] = "Commission fees refund";
        s.kindIdToKindName[3] = "Gas refund";
        s.kindIdToKindName[4] = "Trophee";
    }

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event ChangedRewardedAddress(address indexed owner, uint256 indexed tokenId, address previousRewardedAddress, address newRewardedAddress);
    event ChangedRewardedNetwork(address indexed owner, uint256 indexed tokenId, uint256 previousNetworkId, uint8 newNetworkId);

    // This is a very simplified implementation. 
    // It does not include all necessary validation of input. 
    // It is used to show diamond storage.
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        ERC721Storage storage s = getStorage();
        address tokenOwner = s._owners[_tokenId];
        require(tokenOwner == _from);
        s._owners[_tokenId] = _to;
        s._balances[_from]--;
        s._balances[_to]++;
        delete s._tokenApprovals[_tokenId];
        s.tokenIdToData[_tokenId].receivedAtBlock = uint128(block.number);

        emit Transfer(_from, _to, _tokenId);
    }

    function _mint(address _to, uint256 _tokenId) internal {
        ERC721Storage storage erc721Storage = getStorage();
        erc721Storage._owners[_tokenId] = _to;
        erc721Storage._balances[_to]++;
        emit Transfer(address(0), _to, _tokenId);
    }

    function _burn(uint256 _tokenId) internal {
        ERC721Storage storage erc721Storage = getStorage();
        address owner = erc721Storage._owners[_tokenId];
        require(owner != address(0));
        erc721Storage._balances[owner]--;
        delete erc721Storage._owners[_tokenId];
        erc721Storage.burnedToken.increment();
        emit Transfer(owner, address(0), _tokenId);
    }

    function _approve(address _to, uint256 _tokenId) internal {
        ERC721Storage storage s = getStorage();
        require(_to != s._owners[_tokenId], "ERC721: approval to current owner");
        s._tokenApprovals[_tokenId] = _to;
        emit Approval(s._owners[_tokenId], _to, _tokenId);
    }

    function _getApproved(uint256 _tokenId) internal view returns (address) {
        ERC721Storage storage s = getStorage();
        require(_exists(_tokenId), "ERC721: approved query for nonexistent token");
        return s._tokenApprovals[_tokenId];
    }

    function _setApprovalForAll(address _operator, bool _approved) internal {
        ERC721Storage storage s = getStorage();
        require(_operator != msg.sender, "ERC721: approve to caller");
        s._operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function _exists(uint256 _tokenId) internal view returns (bool) {
        ERC721Storage storage s = getStorage();
        return s._owners[_tokenId] != address(0);
    }

    function _isApprovedForAll(address _owner, address _operator) internal view returns (bool) {
        ERC721Storage storage s = getStorage();
        return s._operatorApprovals[_owner][_operator];
    }

    function _isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
        ERC721Storage storage s = getStorage();
        require(_exists(_tokenId), "ERC721: operator query for nonexistent token");
        address owner = s._owners[_tokenId];
        return (_spender == owner || _getApproved(_tokenId) == _spender || _isApprovedForAll(owner, _spender));
    }

    function _requireMinted(uint256 _tokenId) internal view {
        ERC721Storage storage s = getStorage();
        require(s._owners[_tokenId] != address(0), "ERC721: token does not exist");
    }

    function _ownerOrStakedOwner(uint256 tokenId) internal view returns (address) {
        ERC721Storage storage s = getStorage();
        return s._owners[tokenId] == LibConstants.STAKED_ADDRESS ? s.stakedArtefactHolder[tokenId] : s._owners[tokenId];
    }

    function _setRewardedAddress(uint256 tokenId, address _to) internal {
        ERC721Storage storage s = getStorage();
        address owner = _ownerOrStakedOwner(tokenId);
        address _from = s.rewardedAddress[owner];
        s.rewardedAddress[owner] = _to;

        // if the previous rewarded address was the owner, then set it to the current owner
        _from = _from == address(0) ? owner : _from;
        _to = _to == address(0) ? owner : _to;
        emit ChangedRewardedAddress(owner, tokenId, _from, _to);
    }

    function _setRewardedNetworkId(uint256 tokenId, uint8 _networkId) internal {
        require(_networkId == 1 || _networkId == 137, "networkId must be 1 or 2");
        address owner = _ownerOrStakedOwner(tokenId);
        ERC721Storage storage s = getStorage();
        uint256 _from = s.rewardedNetwork[owner];
        s.rewardedNetwork[owner] = _networkId;
        emit ChangedRewardedNetwork(owner, tokenId, _from, _networkId);
    }

    function _setKindIdAdditionnalBoost(uint256 _kindId, uint16 _boost) internal {
        ERC721Storage storage s = getStorage();
        s.kindIdToAdditionnalBoost[_kindId] = _boost;
    }

    function _setTokenIdAdditionnalBoost(uint256 _tokenId, uint16 _boost) internal {
        ERC721Storage storage s = getStorage();
        s.tokenIdToAdditionnalBoost[_tokenId] = _boost;
    }

    function _getPercentage(uint256 _tokenId) internal view returns (uint16 p) {
        ERC721Storage storage s = getStorage();
        p = s.tokenIdToData[_tokenId].percentage;
        if (p > 20 * LibConstants.PERCENT_UNIT) p = 20 * LibConstants.PERCENT_UNIT;
        p += s.kindIdToAdditionnalBoost[s.tokenIdToData[_tokenId].kindId];
        p += s.tokenIdToAdditionnalBoost[_tokenId];
    }
}


// File contracts/libraries/LibUtils.sol

pragma solidity ^0.8.0;

library LibUtils {

    using Strings for uint256;

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? b : a;
    }

    function division(uint256 decimalPlaces, uint256 numerator, uint256 denominator) internal pure returns(uint256 intPortion, uint256 decPortion, string memory result) {
      require(denominator > 0, "Division by zero");
      if (numerator == 0) return (0, 0, "0");
      uint256 factor = 10**decimalPlaces;
      intPortion  = numerator / denominator;
      decPortion = (numerator * factor / denominator) % factor;
      result = string.concat(intPortion.toString(), '.', decPortion.toString());
    }

    function formatAttribute(string memory trait_type, string memory value) internal pure returns(string memory) {
        return string.concat('{"trait_type": "', trait_type, '", "value": "', value, '"}');
    }

    function getNetwork(uint256 networkId) internal pure returns (string memory) {
      if (networkId == 137) return "Polygon";
      return "Ethereum";
    }
}


// File contracts/facets/StakingArtefactFacet.sol

pragma solidity ^0.8.0;





contract StakingArtefactFacet is Context {

    using Counters for Counters.Counter;

    event Stake(address indexed staker, uint256 indexed tokenId);
    event Unstake(address indexed staker, uint256 indexed tokenId);
    

    function isStaked(uint256 tokenId) public view returns (bool) {
        LibERC721.ERC721Storage storage s = LibERC721.getStorage();
        return s._owners[tokenId] == LibConstants.STAKED_ADDRESS;
    }

    function stake(uint256 tokenId) public {
        LibERC721.ERC721Storage storage s = LibERC721.getStorage();
        require(s._owners[tokenId] == _msgSender(), "not owner or staked");
        LibERC721._transfer(_msgSender(), LibConstants.STAKED_ADDRESS, tokenId);
        s.stakedArtefactHolder[tokenId] = _msgSender();
        
        uint256 kindId = s.tokenIdToData[tokenId].kindId;
        if (s.stakedArtefactByKindIdAndAddress[kindId][_msgSender()] > 0) {
            unstake(s.stakedArtefactByKindIdAndAddress[kindId][_msgSender()]);
        }

        s.stakedArtefactByKindIdAndAddress[kindId][_msgSender()] = tokenId;
        
        emit Stake(_msgSender(), tokenId);
    }

    function unstake(uint256 tokenId) public {
        LibERC721.ERC721Storage storage s = LibERC721.getStorage();
        require(s._owners[tokenId] == LibConstants.STAKED_ADDRESS, "StakingArtefactFacet: not staked");
        require(s.stakedArtefactHolder[tokenId] == _msgSender(), "StakingArtefactFacet: not staker");
        LibERC721._transfer(LibConstants.STAKED_ADDRESS, s.stakedArtefactHolder[tokenId], tokenId);
        delete s.stakedArtefactHolder[tokenId];
        
        uint256 kindId = s.tokenIdToData[tokenId].kindId;
        delete s.stakedArtefactByKindIdAndAddress[kindId][_msgSender()];
        
        emit Unstake(_msgSender(), tokenId);
    }

    function setRewardedAddress(uint256 tokenId, address rewardedAddress) public  {
        require(LibERC721._ownerOrStakedOwner(tokenId) == _msgSender(), "not owner");
        LibERC721._setRewardedAddress(tokenId, rewardedAddress);
    }

    function setRewardedNetworkId(uint256 tokenId, uint8 _networkId) public {
        require(LibERC721._ownerOrStakedOwner(tokenId) == _msgSender(), "not owner");
        LibERC721._setRewardedNetworkId(tokenId, _networkId);
    }

    function merge(uint256 tokenIdOne, uint256 tokenIdTwo) public {
        LibERC721.ERC721Storage storage s = LibERC721.getStorage();
        require(LibERC721._ownerOrStakedOwner(tokenIdOne) == _msgSender(), "not owner");
        require(LibERC721._ownerOrStakedOwner(tokenIdTwo) == _msgSender(), "not owner");
        require(s.tokenIdToData[tokenIdOne].kindId == s.tokenIdToData[tokenIdTwo].kindId && s.tokenIdToData[tokenIdOne].kindId == 1, 'Invalid kindId of one token');
        uint256 maxTokenId = s.tokenIdToData[tokenIdOne].percentage < s.tokenIdToData[tokenIdTwo].percentage ? tokenIdTwo : tokenIdOne;
        uint256 minTokenId = maxTokenId == tokenIdOne ? tokenIdTwo : tokenIdOne;
        if (isStaked(minTokenId) && !isStaked(maxTokenId)) {
            stake(maxTokenId);
        }
        s.tokenIdToData[maxTokenId].percentage += (s.tokenIdToData[minTokenId].percentage)/5 ;

        LibERC721._burn(minTokenId);
    }

    // --------
    // Admin functions
    // --------

    function setNodeAPR(uint256 newAPR) public {
        LibDiamond.enforceIsContractOwner();
        LibERC721.ERC721Storage storage s = LibERC721.getStorage();
        s.nodeAPR = newAPR;
    }

    function setBaseImageURI(string memory newBaseImageURI) public {
        LibDiamond.enforceIsContractOwner();
        LibERC721.ERC721Storage storage s = LibERC721.getStorage();
        s.baseImageURI = newBaseImageURI;
    }

    function setDescription(string memory newDescription) public {
        LibDiamond.enforceIsContractOwner();
        LibERC721.ERC721Storage storage s = LibERC721.getStorage();
        s.description = newDescription;
    }

    function setKindIdAdditionnalBoost(uint256 kindId, uint16 additionnalBoost) public {
        LibDiamond.enforceIsContractOwner();
        LibERC721._setKindIdAdditionnalBoost(kindId, additionnalBoost);
    }

    function setTokenAdditionnalBoost(uint256 tokenId, uint16 additionnalBoost) public {
        LibDiamond.enforceIsContractOwner();
        LibERC721._setTokenIdAdditionnalBoost(tokenId, additionnalBoost);
    }

    function setTokensAdditionnalBoost(uint256[] memory tokenIds, uint16[] memory additionnalBoost) public {
        LibDiamond.enforceIsContractOwner();
        require(tokenIds.length == additionnalBoost.length, "tokenIds and additionnalBoost must have the same length");
        for (uint256 i; i < tokenIds.length; i++) {
            LibERC721._setTokenIdAdditionnalBoost(tokenIds[i], additionnalBoost[i]);
        }
    }

    function mint(address[] calldata addresses, uint8 kindId, uint8 initialRankOffset, uint8 maxRewardPerYear, uint16 percentage) public {
        LibDiamond.enforceIsContractOwner();
        require(percentage <= LibConstants.MAX_PERCENTAGE, "Percentage must be <= 100%");
        LibERC721.ERC721Storage storage s = LibERC721.getStorage();
        uint128 blockNumber = uint128(block.number);
        for (uint256 i; i < addresses.length; i++) {
            s.currentTokenId.increment();

            uint256 newItemId = s.currentTokenId.current();
            LibERC721._mint(addresses[i], newItemId);
            
            // uint8 kindId; // 1: Boost APR ; 2: commission fees refunds ; 3: gas refunds; 4: gagnant d'un prix? 
            // uint8 networkId; // 16
            // uint8 initialRankOffset; // 24 (if deleted we can have rewardedEver stored)
            // uint16 percentage; // default: 0 = 0 // max 65000(=650%)
            // uint8 maxRewardPerYear; // default: 0 (unlimited); to multiply by 100 (80 = 8000), max: 256(=25600) // 32 
            // uint32 receivedAtBlock; // rank not needed because computed based on receivedAtBlock
            // address rewardedAddress; // 256

            s.tokenIdToData[newItemId] = LibERC721.TokenData(
                kindId,
                initialRankOffset,
                percentage,
                maxRewardPerYear,
                blockNumber
            );
        }
    }

    function setShouldFreezeCalculations(bool newValue) public {
        LibDiamond.enforceIsContractOwner();
        LibERC721.ERC721Storage storage s = LibERC721.getStorage();
        s.shouldFreezeCalculations = newValue;
    }    

    function setStakeManager(IStakeManager newAddress) public {
        LibDiamond.enforceIsContractOwner();
        LibERC721.ERC721Storage storage s = LibERC721.getStorage();
        s.stakeManager = newAddress;
    }
    
    function setValidatorShare(IValidatorShare newAddress) public {
        LibDiamond.enforceIsContractOwner();
        LibERC721.ERC721Storage storage s = LibERC721.getStorage();
        s.validatorShare = newAddress;
    }

    function setRankNameFromRankId(uint256 rankId, string memory rankName) public {
        LibDiamond.enforceIsContractOwner();
        LibERC721.ERC721Storage storage s = LibERC721.getStorage();
        s.rankIdToRankName[rankId] = rankName;
    }

    function setKindNameFromKindId(uint256 kindId, string memory kindName) public {
        LibDiamond.enforceIsContractOwner();
        LibERC721.ERC721Storage storage s = LibERC721.getStorage();
        s.kindIdToKindName[kindId] = kindName;
    }

    function setSpecificAttributeForTokenId(uint256 tokenId, string calldata value) public {
        LibDiamond.enforceIsContractOwner();
        LibERC721.ERC721Storage storage s = LibERC721.getStorage();
        s.additionalAttributes[tokenId] = value;
    }

    function setAttributesForMany(uint256[] calldata tokenIds, string[] calldata values) public {
        LibDiamond.enforceIsContractOwner();
        require(tokenIds.length == values.length, "StakingArtefactFacet: tokenIds and values length mismatch");
        for (uint256 i; i < tokenIds.length; i++) {
            setSpecificAttributeForTokenId(tokenIds[i], values[i]);
        }
    }
}