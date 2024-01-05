// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

import 'Math.sol';
import 'SafeMath.sol';

library FixedSafeMath {
    int256 private constant _INT256_MIN = -2**255;
    int256 internal constant ONE = 10**18;

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), 'FM_ADDITION_OVERFLOW');

        return c;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), 'FM_SUBTRACTION_OVERFLOW');

        return c;
    }

    function f18Mul(int256 a, int256 b) internal pure returns (int256) {
        return _div(_mul(a, b), ONE);
    }

    function f18Div(int256 a, int256 b) internal pure returns (int256) {
        return _div(_mul(a, ONE), b);
    }

    function f18Sqrt(int256 value) internal pure returns (int256) {
        require(value >= 0, 'FM_SQUARE_ROOT_OF_NEGATIVE');
        return int256(Math.sqrt(SafeMath.mul(uint256(value), uint256(ONE))));
    }

    function _mul(int256 a, int256 b) private pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), 'FM_MULTIPLICATION_OVERFLOW');

        int256 c = a * b;
        require(c / a == b, 'FM_MULTIPLICATION_OVERFLOW');

        return c;
    }

    function _div(int256 a, int256 b) private pure returns (int256) {
        require(b != 0, 'FM_DIVISION_BY_ZERO');
        require(!(b == -1 && a == _INT256_MIN), 'FM_DIVISION_OVERFLOW');

        int256 c = a / b;

        return c;
    }
}
