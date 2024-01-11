// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Math.sol";

import "./Globals.sol";

abstract contract AbstractSlasher {
    using SafeMath for uint256;
    using Math for uint256;

    uint256 public constant MIN_EXIT_FEE = 20 * PRECISION;

    function getSlashingPercentage() public pure returns (uint256) {
        return MIN_EXIT_FEE;
    }

    function _applySlashing(uint256 amount) internal pure returns (uint256) {
        return amount.sub(_getSlashed(amount));
    }

    function _getSlashed(uint256 amount) internal pure returns (uint256) {
        return amount.mul(getSlashingPercentage()).div(PERCENTAGE_100);
    }
}
