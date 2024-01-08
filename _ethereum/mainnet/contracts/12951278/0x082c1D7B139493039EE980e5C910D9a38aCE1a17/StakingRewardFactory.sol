// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "./CustomStakingRewardUpgradeableProxy.sol";
import "./IStakingRewards.sol";

contract StakingRewardFactory{

    address public logicImplement;

    event StakingRewardCreated(address indexed token);

    constructor(address _logicImplement) public {
        logicImplement = _logicImplement;
    }

    function createStakingReward(address _stakingToken, address _rewardsToken, address owner, address proxyAdmin) external returns (address) {
        CustomStakingRewardUpgradeableProxy proxyStaking = new CustomStakingRewardUpgradeableProxy(logicImplement, proxyAdmin, "");

        IStakingRewardsInitialize staking = IStakingRewardsInitialize(address(proxyStaking));
        staking.initialize(_stakingToken, _rewardsToken, owner);
        emit StakingRewardCreated(address(staking));
        return address(staking);
    }
}
