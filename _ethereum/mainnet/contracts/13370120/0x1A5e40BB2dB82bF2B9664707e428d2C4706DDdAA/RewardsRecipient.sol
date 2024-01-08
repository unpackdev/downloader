// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

abstract contract RewardsRecipient {
    address public rewardsDistributor;

    modifier onlyRewardsDistributor() {
        require(msg.sender == rewardsDistributor, "!rewardsDistributor");
        _;
    }

    function notifyRewardAmount(uint256 rewardTokenIndex, uint256 amount) external virtual;
}
