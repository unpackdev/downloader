// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Math.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

import "./IRateVoteable.sol";

contract CentralizedRateVote is OwnableUpgradeSafe {
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */
    uint256 public constant MAX_PERCENTAGE = 100;
    uint256 public votingEnabledTime;

    /* ========== CONSTRUCTOR ========== */

    function initialize(
    ) public virtual initializer {
        __Ownable_init();
    }

    function changeRate(IRateVoteable pool, uint256 rateMultiplier) external onlyOwner {
        pool.changeRate(rateMultiplier);
        emit RateSet(rateMultiplier);
    }

    /* ===Events=== */

    event RateSet(uint256 rateMultiplier);
}
