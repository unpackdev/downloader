// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "./LPStakingRewards.sol";

contract LPStakingRewardsFactory is Ownable {
    address public immutable treasuryAddress;
    mapping(address => address) public stakingRewards;

    event LPStakingRewardsCreated(
        address indexed stakingRewards,
        address indexed stakingToken,
        address rewardsToken,
        uint256 rewardRate,
        uint256 periodFinish
    );

    constructor(address _treasuryAddress) {
        treasuryAddress = _treasuryAddress;
    }

    function createLPStakingRewards(
        address _stakingToken,
        address _rewardsToken,
        uint256 _rewardRate,
        uint256 _periodFinish
    ) external onlyOwner {
        require(
            stakingRewards[_stakingToken] == address(0) ||
                LPStakingRewards(stakingRewards[_stakingToken])
                    .lastTimeRewardApplicable() <
                block.timestamp,
            "already exists"
        );

        LPStakingRewards rewards = new LPStakingRewards(
            treasuryAddress,
            _stakingToken,
            _rewardsToken,
            _rewardRate,
            _periodFinish
        );

        rewards.transferOwnership(msg.sender);

        stakingRewards[_stakingToken] = address(rewards);

        emit LPStakingRewardsCreated(
            address(rewards),
            _stakingToken,
            _rewardsToken,
            _rewardRate,
            _periodFinish
        );
    }
}
