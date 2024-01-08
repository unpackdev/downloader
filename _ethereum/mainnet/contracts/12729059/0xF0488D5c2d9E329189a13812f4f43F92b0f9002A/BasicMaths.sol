// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

import "./SafeMath.sol";

library BasicMaths {
    /**
     * @dev Returns the abs of substraction of two unsigned integers
     *
     * _Available since v3.4._
     */
    function diff(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a >= b) {
            return a - b;
        } else {
            return b - a;
        }
    }

    /**
     * @dev Returns a - b if a > b, else return 0
     *
     * _Available since v3.4._
     */
    function sub2Zero(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a > b) {
            return a - b;
        } else {
            return 0;
        }
    }

    /**
     * @dev if isSub then Returns a - b, else return a + b
     *
     * _Available since v3.4._
     */
    function addOrSub(bool isAdd, uint256 a, uint256 b) internal pure returns (uint256) {
        if (isAdd) {
            return SafeMath.add(a, b);
        } else {
            return SafeMath.sub(a, b);
        }
    }

    /**
     * @dev if isSub then Returns sub2Zero(a, b), else return a + b
     *
     * _Available since v3.4._
     */
    function addOrSub2Zero(bool isAdd, uint256 a, uint256 b) internal pure returns (uint256) {
        if (isAdd) {
            return SafeMath.add(a, b);
        } else {
            if (a > b) {
                return a - b;
            } else {
                return 0;
            }
        }
    }
}
