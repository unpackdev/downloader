// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Math.sol";

library Amount {

    using Math for uint256;
    using SafeMath for uint256;

    // ============ Constants ============

    uint256 constant BASE = 10**18;

    // A Principal Amount is an amount that's been adjusted by an index

    struct Principal {
        bool sign; // true if positive
        uint256 value;
    }

    function zero()
        internal
        pure
        returns (Principal memory)
    {
        return Principal({
            sign: false,
            value: 0
        });
    }

    function sub(
        Principal memory a,
        Principal memory b
    )
        internal
        pure
        returns (Principal memory)
    {
        return add(a, negative(b));
    }

    function add(
        Principal memory a,
        Principal memory b
    )
        internal
        pure
        returns (Principal memory)
    {
        Principal memory result;

        if (a.sign == b.sign) {
            result.sign = a.sign;
            result.value = SafeMath.add(a.value, b.value);
        } else {
            if (a.value >= b.value) {
                result.sign = a.sign;
                result.value = SafeMath.sub(a.value, b.value);
            } else {
                result.sign = b.sign;
                result.value = SafeMath.sub(b.value, a.value);
            }
        }
        return result;
    }

    function equals(
        Principal memory a,
        Principal memory b
    )
        internal
        pure
        returns (bool)
    {
        if (a.value == b.value) {
            if (a.value == 0) {
                return true;
            }
            return a.sign == b.sign;
        }
        return false;
    }

    function negative(
        Principal memory a
    )
        internal
        pure
        returns (Principal memory)
    {
        return Principal({
            sign: !a.sign,
            value: a.value
        });
    }

    function calculateAdjusted(
        Principal memory a,
        uint256 index
    )
        internal
        pure
        returns (uint256)
    {
        return Math.getPartial(a.value, index, BASE);
    }

    function calculatePrincipal(
        uint256 value,
        uint256 index,
        bool sign
    )
        internal
        pure
        returns (Principal memory)
    {
        return Principal({
            sign: sign,
            value: Math.getPartial(value, BASE, index)
        });
    }

}
