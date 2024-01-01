// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

library Errors {
    error DuplicatedVault(address vault);
    error InvalidTotalWeight(uint256 totalWeight);
    error NotAuthorized(address actual, address expected);
    error InvalidVotingPowerUpdate(
        uint256 actualTotalPower,
        uint256 givenTotalPower
    );
    error MultisigSunset();

    error ZeroDivision();
}
