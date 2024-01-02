// SPDX-License-Identifier: AGPL-3.0-only

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IWETH.sol";
import "./IRewardsDistribution.sol";

pragma solidity ^0.8.16;

contract RewardDistributor is Ownable {
    using SafeERC20 for IERC20;

    address public stakingPool;

    IWETH public immutable weth;

    constructor(IWETH weth_) {
        weth = weth_;
    }

    receive() external payable {}

    function depositRewards() external onlyOwner {
        weth.deposit{value: address(this).balance}();

        uint256 rewards = weth.balanceOf(address(this));

        weth.transfer(stakingPool, rewards);
        IRewardsDistribution(stakingPool).notifyRewardAmount(rewards);
    }

    function recover(address token) external onlyOwner {
        if (token == address(0)) {
            bool success;
            (success, ) = address(msg.sender).call{
                value: address(this).balance
            }("");
            return;
        } else {
            IERC20(token).safeTransfer(
                msg.sender,
                IERC20(token).balanceOf(address(this))
            );
        }
    }

    function setStakingPool(address stakingPool_) external onlyOwner {
        stakingPool = stakingPool_;
    }
}
