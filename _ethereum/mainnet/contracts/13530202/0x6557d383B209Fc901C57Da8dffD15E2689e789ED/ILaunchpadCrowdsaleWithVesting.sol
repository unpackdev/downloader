// SPDX-License-Identifier: Apache-2.0
// Copyright 2021 Enjinstarter
pragma solidity ^0.7.6;

import "./ICrowdsale.sol";

/**
 * @title ILaunchpadCrowdsaleWithVesting
 * @author Enjinstarter
 */
interface ILaunchpadCrowdsaleWithVesting is ICrowdsale {
    function getAvailableLotsFor(address beneficiary)
        external
        view
        returns (uint256 availableLots);

    function getRemainingTokens()
        external
        view
        returns (uint256 remainingTokens);

    function pause() external;

    function unpause() external;

    function extendTime(uint256 newClosingTime) external;

    function startDistribution(uint256 scheduleStartTimestamp) external;

    function setGovernanceAccount(address account) external;

    function setCrowdsaleAdmin(address account) external;
}
