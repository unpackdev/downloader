// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "./StakingRewards.sol";

contract Stake_XUS_XUSD is StakingRewards {
    constructor(
        address _dev,
        uint256 _fee,
        address _rewardsToken,
        address _stakingToken,
        address _xusd_address,
        address _timelock_address,
        uint256 _pool_weight
    ) 
    StakingRewards(_dev, _fee, _rewardsToken, _stakingToken, _xusd_address, _timelock_address, _pool_weight)
    public {}
}
