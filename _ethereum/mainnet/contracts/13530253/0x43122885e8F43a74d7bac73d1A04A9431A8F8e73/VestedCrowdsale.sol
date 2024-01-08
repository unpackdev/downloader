// SPDX-License-Identifier: Apache-2.0
// Copyright 2021 Enjinstarter
pragma solidity ^0.7.6;

import "./Crowdsale.sol";
import "./IVesting.sol";

/**
 * @title VestedCrowdsale
 * @author Enjinstarter
 * @dev Extension of Crowdsale contract where purchased tokens are transferred to a vesting schedule.
 */
abstract contract VestedCrowdsale is Crowdsale {
    address public vestingContract;

    constructor(address vestingContract_) {
        require(
            vestingContract_ != address(0),
            "VestedCrowdsale: zero vesting address"
        );

        vestingContract = vestingContract_;
    }

    function _startDistribution(uint256 scheduleStartTimestamp) internal {
        IVesting(vestingContract).setScheduleStartTimestamp(
            scheduleStartTimestamp
        );
    }

    /**
     * @dev Overrides delivery by transferring tokens to vesting schedule upon purchase.
     * @param beneficiary Token purchaser
     * @param tokenAmount Number of tokens to be vested
     */
    function _deliverTokens(address beneficiary, uint256 tokenAmount)
        internal
        override
    {
        IVesting(vestingContract).addVestingGrant(
            beneficiary,
            tokenAmount,
            false
        );
    }
}
