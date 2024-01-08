// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./LibComitiumStorage.sol";
import "./LibOwnership.sol";

contract ChangeRewardsFacet {
    function changeRewardsAddress(address _rewards) public {
        LibOwnership.enforceIsContractOwner();

        LibComitiumStorage.Storage storage ds = LibComitiumStorage.comitiumStorage();
        ds.rewards = IRewards(_rewards);
    }
}
