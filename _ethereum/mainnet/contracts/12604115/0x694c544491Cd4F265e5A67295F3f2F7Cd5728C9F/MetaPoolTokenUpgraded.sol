// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "./MetaPoolToken.sol";

contract MetaPoolTokenUpgraded is MetaPoolToken {
    bool public newlyAddedVariable;

    function initializeUpgrade() public override onlyAdmin {
        newlyAddedVariable = true;
    }
}
