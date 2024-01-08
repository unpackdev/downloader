// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Math.sol";

import "./Globals.sol";

abstract contract AbstractSlasher {
    using SafeMath for uint256;
    using Math for uint256;

    uint256 public constant MAX_EXIT_FEE = 90 * PRECISION;
    uint256 public constant MIN_EXIT_FEE = 20 * PRECISION;
    uint256 public constant EXIT_FEE_DURATION = 100 days;

    function getSlashingPercentage(uint256 startTime) public view returns (uint256) {
        startTime = startTime == 0 || startTime > block.timestamp ? block.timestamp : startTime;

        uint256 feeSpan = MAX_EXIT_FEE.sub(MIN_EXIT_FEE);
        uint256 feePerSecond = feeSpan.div(EXIT_FEE_DURATION);
        uint256 fee = Math.min(block.timestamp.sub(startTime).mul(feePerSecond), feeSpan);

        return MAX_EXIT_FEE.sub(fee);
    }

    function getSlashingPercentage() external view virtual returns (uint256);

    function _applySlashing(uint256 amount, uint256 startTime) internal view returns (uint256) {
        return amount.sub(_getSlashed(amount, startTime));
    }

    function _getSlashed(uint256 amount, uint256 startTime) internal view returns (uint256) {
        return amount.mul(getSlashingPercentage(startTime)).div(PERCENTAGE_100);
    }
}
