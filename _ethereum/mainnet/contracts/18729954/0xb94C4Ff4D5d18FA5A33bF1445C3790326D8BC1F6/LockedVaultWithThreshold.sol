// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "LockedVault.sol";
import "VaultWithThreshold.sol";

contract LockedVaultWithThreshold is LockedVault, VaultWithThreshold {
    constructor(
        address _owner,
        address _underlying,
        address _rewardsToken,
        address _daoTreasury
    ) LockedVault(_owner, _underlying, _rewardsToken, _daoTreasury) {}

    function initialize(
        uint256 _threshold,
        uint256 _withdrawalWaitDuration
    ) external initializer {
        __LockedVault_initialize(_withdrawalWaitDuration);
        threshold = _threshold;
    }

    function getTotalRawVotingPower()
        public
        view
        virtual
        override
        returns (uint256)
    {
        if (totalSupply < threshold) {
            return threshold;
        }
        return totalSupply;
    }
}
