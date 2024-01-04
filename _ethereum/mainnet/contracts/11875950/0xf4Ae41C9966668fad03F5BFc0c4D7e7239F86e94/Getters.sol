// SPDX-License-Identifier: MIT

pragma solidity =0.5.16;

import "./State.sol";

/**
 * NOTE: Contract MahaswapV1Pair should be the owner of this controller.
 */
contract Getters is State {
    function getPenaltyPrice() public view returns (uint256) {
        // If (useOracle) then get penalty price from an oracle
        // else get from a variable.
        // This variable is settable from the factory.
        return penaltyPrice;
    }

    function getRewardIncentivePrice() public view returns (uint256) {
        // If (useOracle) then get reward price from an oracle
        // else get from a variable.
        // This variable is settable from the factory.
        return rewardPrice;
    }
}
