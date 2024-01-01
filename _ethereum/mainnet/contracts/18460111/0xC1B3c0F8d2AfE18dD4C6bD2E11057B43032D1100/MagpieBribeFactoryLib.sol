// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./ERC20.sol";
import "./MintableERC20.sol";
import "./BribeRewardPool.sol";

library MagpieBribeFactoryLib {

    function createBribeRewarder(
        address _stakingToken,
        address _rewardToken,
        address _operator,
        address _rewardManager
    ) public returns (address){
        BribeRewardPool _rewarder = new BribeRewardPool(
            _stakingToken,
            _rewardToken,
            _operator,
            _rewardManager
        );
        return address(_rewarder);
    }
}
