// SPDX-License-Identifier: MIT AND AGPL-3.0-only
pragma solidity 0.8.6;

import "./Constants.sol";
import "./Errors.sol";

abstract contract Modifiers is Constants, Errors {

    function _isStakingAllowed() internal view returns (bool) {
        return
            block.timestamp >= STAKING_START_TIMESTAMP
            && block.timestamp < STAKING_START_TIMESTAMP + STAKING_PERIOD
            && DOM_TOKEN.balanceOf(address(this)) >= TOTAL_DOM;
    }

    // allow calling during deposit period i.e 0 to 7 days
    modifier duringStaking() {
        require(_isStakingAllowed(), ERROR_STAKING_PROHIBITED);
        _;
    }
}
