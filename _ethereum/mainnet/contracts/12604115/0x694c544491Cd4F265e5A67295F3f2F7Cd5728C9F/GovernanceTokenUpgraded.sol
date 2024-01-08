// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "./GovernanceToken.sol";

contract GovernanceTokenUpgraded is GovernanceToken {
    bool public newlyAddedVariable;

    function initializeUpgrade() public override onlyAdmin {
        newlyAddedVariable = true;
    }
}
